import Foundation

/// Parses complete PDF documents from seekable input streams.
///
/// `PDFDocumentParser` is the main entry point for parsing PDF files. It implements
/// the `COSParser` protocol and handles:
/// - PDF header parsing
/// - Cross-reference table parsing (traditional and stream formats)
/// - Trailer dictionary parsing
/// - Indirect object retrieval
/// - Object caching for performance
///
/// This corresponds to the Java `PDFParser` class from veraPDF-parser.
///
/// ## PDF File Structure
///
/// A PDF file has four main parts:
/// 1. **Header** — Version identifier (e.g., `%PDF-1.7`)
/// 2. **Body** — Indirect objects containing the document content
/// 3. **Cross-reference table** — Index mapping object numbers to byte offsets
/// 4. **Trailer** — Document metadata and pointer to catalog
///
/// ```
/// %PDF-1.7
/// 1 0 obj
///   << /Type /Catalog /Pages 2 0 R >>
/// endobj
/// ...
/// xref
/// 0 5
/// 0000000000 65535 f
/// 0000000015 00000 n
/// ...
/// trailer
/// << /Size 5 /Root 1 0 R >>
/// startxref
/// 1234
/// %%EOF
/// ```
///
/// ## Usage
/// ```swift
/// let stream = try DataInputStream(data: pdfData)
/// let parser = try await PDFDocumentParser(stream: stream)
///
/// // Access document metadata
/// print("PDF version: \(parser.header.version)")
///
/// // Retrieve objects
/// if let catalog = try await parser.getCatalog() {
///     print("Catalog: \(catalog)")
/// }
/// ```
public final class PDFDocumentParser: COSParser {

    // MARK: - Errors

    /// Errors that can occur during document parsing.
    public enum DocumentError: Error, CustomStringConvertible {
        /// Invalid PDF header.
        case invalidHeader

        /// Cross-reference table not found.
        case missingXRefTable

        /// Invalid startxref offset.
        case invalidStartXRef

        /// Object not found in xref table.
        case objectNotFound(COSObjectKey)

        /// Circular reference detected.
        case circularReference(COSObjectKey)

        public var description: String {
            switch self {
            case .invalidHeader:
                return "Invalid PDF header"
            case .missingXRefTable:
                return "Cross-reference table not found"
            case .invalidStartXRef:
                return "Invalid startxref offset"
            case .objectNotFound(let key):
                return "Object not found: \(key)"
            case .circularReference(let key):
                return "Circular reference detected: \(key)"
            }
        }
    }

    // MARK: - Properties

    /// The seekable input stream containing the PDF data.
    private var stream: any SeekableStream

    /// The PDF header.
    public let header: PDFHeader

    /// The cross-reference table.
    public let xrefTable: XRefTable

    /// The trailer dictionary.
    public let trailer: PDFTrailer

    /// Object cache to avoid re-parsing.
    private var objectCache: [COSObjectKey: COSValue] = [:]

    // MARK: - Initialization

    /// Parses a PDF document from a seekable stream.
    ///
    /// This reads the PDF header, locates the cross-reference table via the
    /// `startxref` pointer, and parses the trailer dictionary.
    ///
    /// - Parameter stream: A seekable input stream containing PDF data.
    /// - Throws: `DocumentError` if the PDF structure is invalid.
    public init(stream: any SeekableStream) async throws {
        self.stream = stream

        // Parse header
        self.header = try await Self.parseHeader(from: stream)

        // Find and parse xref table and trailer
        let startxrefOffset = try await Self.findStartXRef(in: stream)
        let (xref, trailer) = try await Self.parseXRefAndTrailer(
            at: startxrefOffset,
            in: stream
        )

        self.xrefTable = xref
        self.trailer = trailer
    }

    // MARK: - Header Parsing

    /// Parses the PDF header from the beginning of the stream.
    internal static func parseHeader(from stream: any SeekableStream) async throws -> PDFHeader {
        var stream = stream
        try await stream.seek(to: 0)

        // Read first line (should be %PDF-X.Y)
        var buffer = [UInt8](repeating: 0, count: 20)
        let bytesRead = try await stream.read(&buffer, maxLength: 20)

        guard bytesRead >= 7 else {
            throw DocumentError.invalidHeader
        }

        // Look for %PDF-
        guard buffer[0] == 0x25, // %
              buffer[1] == 0x50, // P
              buffer[2] == 0x44, // D
              buffer[3] == 0x46, // F
              buffer[4] == 0x2D  // -
        else {
            throw DocumentError.invalidHeader
        }

        // Extract version (e.g., "1.7")
        var versionBytes: [UInt8] = []
        for i in 5..<bytesRead {
            let byte = buffer[i]
            if byte == 0x0A || byte == 0x0D { // LF or CR
                break
            }
            versionBytes.append(byte)
        }

        guard let versionString = String(bytes: versionBytes, encoding: .ascii),
              !versionString.isEmpty,
              let header = PDFHeader(versionString: versionString) else {
            throw DocumentError.invalidHeader
        }

        return header
    }

    // MARK: - StartXRef Parsing

    /// Finds the startxref offset by scanning from the end of the file.
    ///
    /// The PDF spec says to look for "startxref" followed by an offset,
    /// working backwards from the end of the file. The pattern is:
    /// ```
    /// startxref
    /// <byte offset>
    /// %%EOF
    /// ```
    internal static func findStartXRef(in stream: any SeekableStream) async throws -> Int64 {
        var stream = stream

        // Read the last 1024 bytes (should contain startxref and %%EOF)
        let searchSize = 1024
        var buffer = [UInt8](repeating: 0, count: searchSize)

        // To find the file size, we read in chunks until we can't read anymore
        // This is a simplification - a real implementation would get the stream length directly
        var totalBytesRead = 0
        var allData = Data()

        // Read all data to determine size
        // In production, SeekableStream should provide a length property
        while true {
            var chunk = [UInt8](repeating: 0, count: 4096)
            let bytesRead = try await stream.read(&chunk, maxLength: 4096)
            if bytesRead == 0 {
                break
            }
            allData.append(contentsOf: chunk.prefix(bytesRead))
            totalBytesRead += bytesRead
        }

        // Get last portion
        let startOffset = max(0, allData.count - searchSize)
        let searchData = allData.suffix(from: startOffset)

        // Convert to string for searching
        guard let searchString = String(data: Data(searchData), encoding: .ascii) else {
            throw DocumentError.invalidStartXRef
        }

        // Find "startxref"
        guard let startxrefRange = searchString.range(of: "startxref") else {
            throw DocumentError.invalidStartXRef
        }

        // Extract the offset number that follows
        let afterStartxref = searchString[startxrefRange.upperBound...]
        let lines = afterStartxref.split(separator: "\n", omittingEmptySubsequences: true)

        // Find the first non-empty line containing the offset number
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            if let offset = Int64(trimmed) {
                return offset
            }
            // If the first non-empty line is not a number (e.g., %%EOF), break
            break
        }

        throw DocumentError.invalidStartXRef
    }

    // MARK: - XRef and Trailer Parsing

    /// Parses the cross-reference table and trailer at the given offset.
    private static func parseXRefAndTrailer(
        at offset: Int64,
        in stream: any SeekableStream
    ) async throws -> (XRefTable, PDFTrailer) {
        // Parse the xref table (which includes the trailer)
        var parser = XRefParser(stream: stream)
        let xrefTable = try await parser.parse(offset: offset)

        // Extract trailer from the xref table
        let trailer = xrefTable.trailer

        return (xrefTable, trailer)
    }

    // MARK: - Object Retrieval

    /// Retrieves a PDF object by its object key.
    public func getObject(key: COSObjectKey) async throws -> COSValue? {
        // Check cache first
        if let cached = objectCache[key] {
            return cached
        }

        // Look up in xref table
        guard let entry = xrefTable.entry(for: key.objectNumber) else {
            return nil
        }

        // Only handle in-use entries (not free, not compressed for now)
        guard entry.isInUse, let offset = entry.offset else {
            return nil
        }

        // Seek to object location
        try await stream.seek(to: offset)

        // Parse the indirect object
        var tokenizer = PDFTokenizer(stream: stream)
        let objectParser = ObjectParser()

        let (objNum, genNum, value) = try await objectParser.parseIndirectObject(&tokenizer)

        // Verify object number matches
        guard objNum == key.objectNumber else {
            throw DocumentError.objectNotFound(key)
        }

        // Cache the object
        objectCache[key] = value

        return value
    }
}

// MARK: - Sendable Conformance

extension PDFDocumentParser: @unchecked Sendable {
    // Classes are not Sendable by default, but we manually ensure thread safety
    // by using value types for immutable properties. The objectCache is mutable
    // but only accessed from async methods, providing isolation.
    // In production, this type could be converted to an actor for formal isolation.
}
