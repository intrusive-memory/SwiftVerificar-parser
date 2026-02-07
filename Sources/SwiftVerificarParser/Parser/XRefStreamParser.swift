import Foundation

/// Parses cross-reference streams from PDF 1.5+ files.
///
/// PDF 1.5 introduced cross-reference streams as a more compact alternative
/// to traditional xref tables. Instead of text format, xref streams use binary
/// encoding and can be compressed (typically with FlateDecode).
///
/// A cross-reference stream is a stream object with type `/XRef` containing:
/// - **Stream dictionary keys:**
///   - `/Type` = `/XRef` (required)
///   - `/Size` = total number of entries (required)
///   - `/W` = array of field widths in bytes [F1 F2 F3] (required)
///   - `/Index` = array of subsection ranges [start count start count ...] (optional)
///   - `/Prev` = offset of previous xref section (optional)
///   - `/Root` = reference to catalog (required in primary xref stream)
///
/// - **Stream data encoding:**
///   Each entry consists of 1-3 fields (as specified by `/W`):
///   - **Field 1 (type)**: Entry type (0=free, 1=in-use, 2=compressed)
///   - **Field 2**: For type 1: byte offset; for type 2: object stream number
///   - **Field 3**: For type 1: generation; for type 2: index in stream
///
/// This type corresponds to the Java `XrefStreamParser` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let stream = COSStream(dictionary: xrefDict, data: xrefData)
/// let parser = XRefStreamParser(stream: stream)
/// let xrefTable = try parser.parse()
/// ```
public struct XRefStreamParser: Sendable {

    // MARK: - Errors

    /// Errors that can occur during xref stream parsing.
    public enum ParseError: Error, CustomStringConvertible {
        /// The stream is not a valid cross-reference stream.
        case notXRefStream

        /// The `/W` array is missing or invalid.
        case missingOrInvalidWidthArray

        /// The `/Size` entry is missing.
        case missingSize

        /// The stream data is too short for the expected entries.
        case truncatedStreamData

        /// An entry type is invalid (not 0, 1, or 2).
        case invalidEntryType(Int)

        public var description: String {
            switch self {
            case .notXRefStream:
                return "Stream is not a cross-reference stream (missing /Type /XRef)"
            case .missingOrInvalidWidthArray:
                return "Missing or invalid /W array"
            case .missingSize:
                return "Missing /Size entry"
            case .truncatedStreamData:
                return "Stream data is truncated"
            case .invalidEntryType(let type):
                return "Invalid entry type: \(type)"
            }
        }
    }

    // MARK: - Properties

    /// The cross-reference stream object.
    private let stream: COSStream

    // MARK: - Initialization

    /// Creates a parser for the given cross-reference stream.
    ///
    /// - Parameter stream: The xref stream object to parse.
    public init(stream: COSStream) {
        self.stream = stream
    }

    // MARK: - Parsing

    /// Parses the cross-reference stream into an `XRefTable`.
    ///
    /// - Returns: The parsed `XRefTable`.
    /// - Throws: `ParseError` if parsing fails.
    public func parse() throws -> XRefTable {
        // Verify this is an xref stream
        guard let typeValue = stream.dictionary[.type],
              case .name(let typeName) = typeValue,
              typeName.stringValue == "XRef" else {
            throw ParseError.notXRefStream
        }

        // Extract required entries
        guard let sizeValue = stream.dictionary[.size],
              let size = sizeValue.integerValue else {
            throw ParseError.missingSize
        }

        let widths = try parseWidthArray()
        let subsectionRanges = parseIndexArray(defaultSize: Int(size))

        // Decode the stream data
        guard let decodedData = stream.decodedData else {
            // If not decoded, use encoded data as fallback
            // In a full implementation, this would decode using filters
            throw ParseError.truncatedStreamData
        }

        // Parse entries
        var subsections: [XRefSubsection] = []
        var dataOffset = 0

        for (start, count) in subsectionRanges {
            var entries: [XRefEntry] = []

            for _ in 0..<count {
                let entry = try parseEntry(
                    from: decodedData,
                    offset: &dataOffset,
                    widths: widths
                )
                entries.append(entry)
            }

            subsections.append(XRefSubsection(
                startObjectNumber: start,
                entries: entries
            ))
        }

        // Build trailer dictionary from stream dictionary
        let trailer = PDFTrailer(dictionary: stream.dictionary)

        return XRefTable(
            subsections: subsections,
            trailer: trailer,
            byteOffset: 0 // Stream doesn't have a meaningful byte offset
        )
    }

    // MARK: - Private Parsing Methods

    /// Parses the `/W` array (field widths).
    ///
    /// - Returns: Array of three widths [F1, F2, F3].
    /// - Throws: `ParseError.missingOrInvalidWidthArray` if invalid.
    private func parseWidthArray() throws -> [Int] {
        guard let wValue = stream.dictionary[ASAtom("W")],
              let wArray = wValue.arrayValue,
              wArray.count == 3 else {
            throw ParseError.missingOrInvalidWidthArray
        }

        var widths: [Int] = []
        for element in wArray {
            guard let width = element.integerValue else {
                throw ParseError.missingOrInvalidWidthArray
            }
            widths.append(Int(width))
        }

        return widths
    }

    /// Parses the `/Index` array (subsection ranges).
    ///
    /// - Parameter defaultSize: The default size if `/Index` is not present.
    /// - Returns: Array of (start, count) tuples.
    private func parseIndexArray(defaultSize: Int) -> [(Int, Int)] {
        guard let indexValue = stream.dictionary[ASAtom("Index")],
              let indexArray = indexValue.arrayValue else {
            // Default: single subsection from 0 to size
            return [(0, defaultSize)]
        }

        var ranges: [(Int, Int)] = []
        var i = 0
        while i + 1 < indexArray.count {
            guard let start = indexArray[i].integerValue,
                  let count = indexArray[i + 1].integerValue else {
                break
            }
            ranges.append((Int(start), Int(count)))
            i += 2
        }

        return ranges.isEmpty ? [(0, defaultSize)] : ranges
    }

    /// Parses a single entry from the stream data.
    ///
    /// - Parameters:
    ///   - data: The decoded stream data.
    ///   - offset: The current offset in the data (updated after reading).
    ///   - widths: The field widths [F1, F2, F3].
    /// - Returns: The parsed `XRefEntry`.
    /// - Throws: `ParseError` if parsing fails.
    private func parseEntry(
        from data: Data,
        offset: inout Int,
        widths: [Int]
    ) throws -> XRefEntry {
        // Read fields according to widths
        let field1 = try readField(from: data, offset: &offset, width: widths[0])
        let field2 = try readField(from: data, offset: &offset, width: widths[1])
        let field3 = try readField(from: data, offset: &offset, width: widths[2])

        // Default type is 1 (in-use) if field 1 has width 0
        let entryType = widths[0] == 0 ? 1 : field1

        switch entryType {
        case 0:
            // Free entry: field2=next free object, field3=generation
            return .free(nextFreeObjectNumber: field2, generation: field3)
        case 1:
            // In-use entry: field2=offset, field3=generation
            return .inUse(offset: Int64(field2), generation: field3)
        case 2:
            // Compressed entry: field2=object stream number, field3=index
            return .compressed(objectStreamNumber: field2, index: field3)
        default:
            throw ParseError.invalidEntryType(entryType)
        }
    }

    /// Reads a multi-byte integer field from the stream data.
    ///
    /// - Parameters:
    ///   - data: The decoded stream data.
    ///   - offset: The current offset (updated after reading).
    ///   - width: The number of bytes to read (0-8).
    /// - Returns: The integer value.
    /// - Throws: `ParseError.truncatedStreamData` if insufficient data.
    private func readField(from data: Data, offset: inout Int, width: Int) throws -> Int {
        guard width >= 0 else {
            return 0
        }

        guard offset + width <= data.count else {
            throw ParseError.truncatedStreamData
        }

        if width == 0 {
            return 0
        }

        // Read big-endian integer
        var value = 0
        for i in 0..<width {
            value = (value << 8) | Int(data[offset + i])
        }
        offset += width

        return value
    }
}
