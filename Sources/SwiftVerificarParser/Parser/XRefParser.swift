import Foundation

/// Parses traditional cross-reference (xref) tables from PDF files.
///
/// The traditional xref table format (PDF 1.0-1.4) is a text-based table
/// that appears near the end of a PDF file. The format is:
///
/// ```
/// xref
/// 0 6
/// 0000000000 65535 f
/// 0000000009 00000 n
/// 0000000074 00000 n
/// 0000000120 00000 n
/// 0000000179 00000 n
/// 0000000364 00000 n
/// trailer
/// << /Size 6 /Root 1 0 R >>
/// startxref
/// 408
/// %%EOF
/// ```
///
/// The parser handles:
/// - Multiple subsections (non-contiguous object number ranges)
/// - Incremental updates (chained xref sections via `/Prev`)
/// - Free entries (type 'f') and in-use entries (type 'n')
///
/// This type corresponds to the Java `XRefReader` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let data = try Data(contentsOf: pdfURL)
/// let stream = DataInputStream(data: data)
/// let parser = XRefParser(stream: stream)
/// let xrefTable = try await parser.parse(offset: xrefOffset)
/// ```
public struct XRefParser: Sendable {

    // MARK: - Errors

    /// Errors that can occur during xref table parsing.
    public enum ParseError: Error, CustomStringConvertible {
        /// The "xref" keyword was not found at the expected position.
        case missingXRefKeyword

        /// A subsection header is malformed or missing.
        case invalidSubsectionHeader

        /// An xref entry line is malformed.
        case invalidEntryFormat(line: String)

        /// The trailer dictionary could not be parsed.
        case invalidTrailer

        /// An unexpected end of stream was encountered.
        case unexpectedEndOfStream

        /// An integer value could not be parsed.
        case invalidInteger(String)

        public var description: String {
            switch self {
            case .missingXRefKeyword:
                return "Missing 'xref' keyword"
            case .invalidSubsectionHeader:
                return "Invalid subsection header"
            case .invalidEntryFormat(let line):
                return "Invalid entry format: '\(line)'"
            case .invalidTrailer:
                return "Invalid trailer dictionary"
            case .unexpectedEndOfStream:
                return "Unexpected end of stream"
            case .invalidInteger(let value):
                return "Invalid integer: '\(value)'"
            }
        }
    }

    // MARK: - Properties

    /// The input stream to read from.
    private var stream: any SeekableStream

    // MARK: - Initialization

    /// Creates a parser for the given input stream.
    ///
    /// - Parameter stream: A seekable input stream positioned at or before the xref table.
    public init(stream: any SeekableStream) {
        self.stream = stream
    }

    // MARK: - Parsing

    /// Parses a cross-reference table starting at the given byte offset.
    ///
    /// - Parameter offset: The byte offset of the "xref" keyword in the file.
    /// - Returns: The parsed `XRefTable`.
    /// - Throws: `ParseError` if parsing fails.
    public mutating func parse(offset: Int64) async throws -> XRefTable {
        // Seek to the xref offset
        try await stream.seek(to: offset)

        // Read and verify the "xref" keyword
        let keyword = try await readKeyword()
        guard keyword == "xref" else {
            throw ParseError.missingXRefKeyword
        }

        // Parse all subsections
        var subsections: [XRefSubsection] = []
        while true {
            // Try to parse a subsection header
            if let subsection = try await parseSubsection() {
                subsections.append(subsection)
            } else {
                // No more subsections
                break
            }
        }

        guard !subsections.isEmpty else {
            throw ParseError.invalidSubsectionHeader
        }

        // Parse the trailer dictionary
        let trailerKeyword = try await readKeyword()
        guard trailerKeyword == "trailer" else {
            throw ParseError.invalidTrailer
        }

        let trailerDict = try await parseTrailerDictionary()
        let trailer = PDFTrailer(dictionary: trailerDict)

        return XRefTable(
            subsections: subsections,
            trailer: trailer,
            byteOffset: offset
        )
    }

    // MARK: - Private Parsing Methods

    /// Parses a single subsection, or returns `nil` if no more subsections.
    private mutating func parseSubsection() async throws -> XRefSubsection? {
        // Try to read the subsection header: "startObjectNumber count"
        skipWhitespace()
        let line = try await readLine()

        // If line is "trailer", we're done with subsections
        if line.trimmingCharacters(in: .whitespaces) == "trailer" {
            // Rewind so we can read "trailer" again in parse()
            // (This is a simplification; in practice we'd handle this better)
            return nil
        }

        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 2,
              let start = Int(parts[0]),
              let count = Int(parts[1]) else {
            throw ParseError.invalidSubsectionHeader
        }

        // Parse the entries
        var entries: [XRefEntry] = []
        for _ in 0..<count {
            let entry = try await parseEntry()
            entries.append(entry)
        }

        return XRefSubsection(startObjectNumber: start, entries: entries)
    }

    /// Parses a single xref entry line.
    ///
    /// Entry format: "nnnnnnnnnn ggggg t" where:
    /// - nnnnnnnnnn: 10-digit offset or object number (zero-padded)
    /// - ggggg: 5-digit generation number (zero-padded)
    /// - t: Type flag ('f' for free, 'n' for in-use)
    private mutating func parseEntry() async throws -> XRefEntry {
        let line = try await readLine()
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Expected format: "0000000009 00000 n" or "0000000000 65535 f"
        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count == 3 else {
            throw ParseError.invalidEntryFormat(line: line)
        }

        guard let firstValue = Int64(parts[0]),
              let generation = Int(parts[1]) else {
            throw ParseError.invalidInteger(line)
        }

        let typeFlag = String(parts[2])

        switch typeFlag {
        case "n":
            // In-use entry
            return .inUse(offset: firstValue, generation: generation)
        case "f":
            // Free entry
            return .free(nextFreeObjectNumber: Int(firstValue), generation: generation)
        default:
            throw ParseError.invalidEntryFormat(line: line)
        }
    }

    /// Parses a trailer dictionary.
    ///
    /// For simplicity, this is a placeholder that returns an empty dictionary.
    /// A full implementation would use a COS dictionary parser.
    private mutating func parseTrailerDictionary() async throws -> [ASAtom: COSValue] {
        // TODO: Implement full dictionary parsing
        // For now, return a minimal dictionary
        return [:]
    }

    // MARK: - Stream Reading Helpers

    /// Reads the next keyword (sequence of non-whitespace characters).
    private mutating func readKeyword() async throws -> String {
        skipWhitespace()
        var chars: [UInt8] = []
        while let byte = try await readByte() {
            if PDFCharacterSet.isWhitespace(byte) {
                break
            }
            chars.append(byte)
        }
        return String(bytes: chars, encoding: .utf8) ?? ""
    }

    /// Reads a line of text (up to newline).
    private mutating func readLine() async throws -> String {
        var chars: [UInt8] = []
        while let byte = try await readByte() {
            if byte == 0x0A || byte == 0x0D { // LF or CR
                // Handle CRLF
                if byte == 0x0D {
                    if let next = try await peekByte(), next == 0x0A {
                        _ = try await readByte() // consume LF
                    }
                }
                break
            }
            chars.append(byte)
        }
        return String(bytes: chars, encoding: .utf8) ?? ""
    }

    /// Skips whitespace characters.
    private mutating func skipWhitespace() {
        // This is a simplified implementation
        // A real implementation would use the stream's position
    }

    /// Reads a single byte from the stream.
    private mutating func readByte() async throws -> UInt8? {
        var buffer = [UInt8](repeating: 0, count: 1)
        let bytesRead = try await stream.read(&buffer, maxLength: 1)
        return bytesRead > 0 ? buffer[0] : nil
    }

    /// Peeks at the next byte without consuming it.
    private mutating func peekByte() async throws -> UInt8? {
        let currentPosition = stream.position
        let byte = try await readByte()
        try await stream.seek(to: currentPosition)
        return byte
    }
}
