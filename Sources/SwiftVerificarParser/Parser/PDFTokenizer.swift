import Foundation

/// Tokenizes PDF data streams into discrete tokens.
///
/// `PDFTokenizer` is responsible for lexical analysis of PDF byte streams,
/// breaking the raw bytes into meaningful tokens (integers, strings, names,
/// keywords, delimiters, etc.) that can be consumed by higher-level parsers.
///
/// This struct corresponds to the Java `BaseParser` class from veraPDF-parser,
/// focusing specifically on tokenization functionality.
///
/// ## PDF Lexical Rules
///
/// PDF tokenization follows these rules (PDF 32000-1:2008 § 7.2):
///
/// - **Whitespace**: Space (0x20), tab (0x09), CR (0x0D), LF (0x0A), null (0x00), form feed (0x0C)
/// - **Delimiters**: `(`, `)`, `<`, `>`, `[`, `]`, `{`, `}`, `/`, `%`
/// - **Comments**: Start with `%` and run to end-of-line
/// - **Numbers**: Integer or real (with optional sign and decimal point)
/// - **Strings**: Literal `(...)` or hexadecimal `<...>`
/// - **Names**: Start with `/`, followed by any characters except whitespace/delimiters
/// - **Keywords**: Alphabetic tokens like `obj`, `endobj`, `true`, `false`, `null`
///
/// ## Usage
/// ```swift
/// let data = Data("42 3.14 /Name (Hello) [ << /Type /Page >>".utf8)
/// let stream = DataInputStream(data: data)
/// var tokenizer = PDFTokenizer(stream: stream)
///
/// while let token = try await tokenizer.nextToken() {
///     print(token)
/// }
/// ```
///
/// ## Thread Safety
/// `PDFTokenizer` is not thread-safe and should be used from a single async context.
/// However, it is `Sendable` because it operates on `Sendable` stream types.
public struct PDFTokenizer: Sendable {

    // MARK: - Errors

    /// Errors that can occur during tokenization.
    public enum TokenizerError: Error, CustomStringConvertible {
        /// Encountered an unexpected character or malformed token.
        case invalidToken(position: Int64, character: UInt8?)

        /// A string literal is not properly terminated.
        case unterminatedString(position: Int64)

        /// A hexadecimal string is not properly terminated.
        case unterminatedHexString(position: Int64)

        /// A name contains invalid characters.
        case invalidName(position: Int64)

        /// An unexpected end of stream was encountered.
        case unexpectedEndOfStream

        /// An invalid escape sequence in a string.
        case invalidEscapeSequence(position: Int64, sequence: String)

        public var description: String {
            switch self {
            case .invalidToken(let pos, let char):
                if let char = char {
                    return "Invalid token at position \(pos): '\(Character(UnicodeScalar(char)))' (0x\(String(format: "%02X", char)))"
                } else {
                    return "Invalid token at position \(pos)"
                }
            case .unterminatedString(let pos):
                return "Unterminated string at position \(pos)"
            case .unterminatedHexString(let pos):
                return "Unterminated hex string at position \(pos)"
            case .invalidName(let pos):
                return "Invalid name at position \(pos)"
            case .unexpectedEndOfStream:
                return "Unexpected end of stream"
            case .invalidEscapeSequence(let pos, let seq):
                return "Invalid escape sequence at position \(pos): \(seq)"
            }
        }
    }

    // MARK: - Properties

    /// The input stream to tokenize.
    private var stream: any SeekableStream

    /// The current position in the stream (internal use).
    private var position: Int64 {
        stream.position
    }

    /// The current byte offset of the tokenizer within the stream.
    ///
    /// This is useful when higher-level parsers need to read raw bytes
    /// (e.g., PDF stream data) from the same underlying data source.
    public var currentPosition: Int64 {
        stream.position
    }

    /// Repositions the tokenizer's internal stream to the specified byte offset.
    ///
    /// This is used after reading raw bytes from a separate stream handle,
    /// to advance the tokenizer past data that was consumed externally
    /// (e.g., PDF stream content between `stream` and `endstream` keywords).
    ///
    /// - Parameter position: The byte offset to seek to.
    public mutating func seek(to position: Int64) throws {
        try stream.seek(to: position)
    }

    // MARK: - Initialization

    /// Creates a tokenizer for the given input stream.
    ///
    /// - Parameter stream: A seekable input stream containing PDF data.
    public init(stream: any SeekableStream) {
        self.stream = stream
    }

    // MARK: - Tokenization

    /// Reads and returns the next token from the stream, or `nil` if at end of stream.
    ///
    /// This method skips whitespace automatically.
    ///
    /// - Returns: The next `PDFToken`, or `nil` if the stream is exhausted.
    /// - Throws: `TokenizerError` if a malformed token is encountered.
    public mutating func nextToken() async throws -> PDFToken? {
        // Skip whitespace
        try await skipWhitespace()

        // Check for end of stream
        guard let byte = try await peekByte() else {
            return nil
        }

        // Determine token type based on first character
        switch byte {
        case 0x25: // %
            return try await readComment()

        case 0x28: // (
            return try await readLiteralString()

        case 0x3C: // <
            return try await readAngleBracketToken()

        case 0x3E: // >
            // This should only appear as >> (dictionary end)
            _ = try await readByte() // consume first >
            guard let next = try await peekByte(), next == 0x3E else {
                throw TokenizerError.invalidToken(position: position, character: byte)
            }
            _ = try await readByte() // consume second >
            return .dictionaryEnd

        case 0x5B: // [
            _ = try await readByte()
            return .arrayStart

        case 0x5D: // ]
            _ = try await readByte()
            return .arrayEnd

        case 0x2F: // /
            return try await readName()

        case 0x2B, 0x2D, 0x2E, 0x30...0x39: // +, -, ., 0-9
            return try await readNumber()

        default:
            // Try to read a keyword (alphabetic token)
            if PDFCharacterSet.isAlphabetic(byte) {
                return try await readKeywordOrLiteral()
            }

            throw TokenizerError.invalidToken(position: position, character: byte)
        }
    }

    // MARK: - Private Tokenization Methods

    /// Reads a comment token (starting with %).
    private mutating func readComment() async throws -> PDFToken {
        _ = try await readByte() // consume first %

        // Check for %%EOF
        if let next = try await peekByte(), next == 0x25 { // second %
            _ = try await readByte() // consume second %
            // Read rest of line to check for EOF
            var bytes: [UInt8] = []
            while let byte = try await peekByte(), byte != 0x0A && byte != 0x0D {
                _ = try await readByte()
                bytes.append(byte)
            }
            let text = String(bytes: bytes, encoding: .utf8) ?? ""
            if text == "EOF" {
                return .endOfFile
            }
            // Otherwise treat as regular comment
            return .comment("%" + text)
        }

        var bytes: [UInt8] = []
        while let byte = try await readByte() {
            if byte == 0x0A || byte == 0x0D { // LF or CR
                // Handle CRLF
                if byte == 0x0D {
                    if let next = try await peekByte(), next == 0x0A {
                        _ = try await readByte()
                    }
                }
                break
            }
            bytes.append(byte)
        }

        let text = String(bytes: bytes, encoding: .utf8) ?? ""
        return .comment(text)
    }

    /// Reads a literal string token enclosed in parentheses.
    private mutating func readLiteralString() async throws -> PDFToken {
        _ = try await readByte() // consume opening (

        var bytes: [UInt8] = []
        var depth = 1 // Track nested parentheses
        let startPos = position

        while let byte = try await readByte() {
            switch byte {
            case 0x28: // (
                depth += 1
                bytes.append(byte)

            case 0x29: // )
                depth -= 1
                if depth == 0 {
                    // End of string
                    let data = Data(bytes)
                    return .string(data)
                }
                bytes.append(byte)

            case 0x5C: // backslash \
                // Escape sequence
                guard let next = try await readByte() else {
                    throw TokenizerError.unterminatedString(position: startPos)
                }
                switch next {
                case 0x6E: // n
                    bytes.append(0x0A) // LF
                case 0x72: // r
                    bytes.append(0x0D) // CR
                case 0x74: // t
                    bytes.append(0x09) // TAB
                case 0x62: // b
                    bytes.append(0x08) // BS
                case 0x66: // f
                    bytes.append(0x0C) // FF
                case 0x28, 0x29, 0x5C: // (, ), backslash
                    bytes.append(next)
                case 0x0A, 0x0D: // Line continuation
                    // Skip the newline
                    if next == 0x0D {
                        if let following = try await peekByte(), following == 0x0A {
                            _ = try await readByte()
                        }
                    }
                case 0x30...0x37: // Octal escape \ddd
                    var octal = Int(next - 0x30)
                    for _ in 0..<2 {
                        if let digit = try await peekByte(), digit >= 0x30 && digit <= 0x37 {
                            _ = try await readByte()
                            octal = octal * 8 + Int(digit - 0x30)
                        } else {
                            break
                        }
                    }
                    bytes.append(UInt8(octal & 0xFF))
                default:
                    // Unknown escape - include the backslash and character literally
                    bytes.append(0x5C)
                    bytes.append(next)
                }

            default:
                bytes.append(byte)
            }
        }

        throw TokenizerError.unterminatedString(position: startPos)
    }

    /// Reads a token starting with '<' (hex string or dictionary start).
    private mutating func readAngleBracketToken() async throws -> PDFToken {
        _ = try await readByte() // consume <

        guard let next = try await peekByte() else {
            throw TokenizerError.unexpectedEndOfStream
        }

        if next == 0x3C { // second <
            _ = try await readByte()
            return .dictionaryStart
        }

        // Hex string
        return try await readHexString()
    }

    /// Reads a hexadecimal string token (already consumed opening <).
    private mutating func readHexString() async throws -> PDFToken {
        var bytes: [UInt8] = []
        var nibble: UInt8? = nil
        let startPos = position

        while let byte = try await readByte() {
            if byte == 0x3E { // >
                // End of hex string
                // If odd number of nibbles, pad with 0
                if let n = nibble {
                    bytes.append(n << 4)
                }
                return .hexString(Data(bytes))
            }

            // Skip whitespace
            if PDFCharacterSet.isWhitespace(byte) {
                continue
            }

            // Parse hex digit
            guard let digit = hexDigitValue(byte) else {
                throw TokenizerError.invalidToken(position: position, character: byte)
            }

            if let n = nibble {
                // Complete the byte
                bytes.append((n << 4) | digit)
                nibble = nil
            } else {
                // Store first nibble
                nibble = digit
            }
        }

        throw TokenizerError.unterminatedHexString(position: startPos)
    }

    /// Reads a name token (starting with /).
    private mutating func readName() async throws -> PDFToken {
        _ = try await readByte() // consume /

        var bytes: [UInt8] = []

        while let byte = try await peekByte() {
            // Names end at whitespace or delimiters
            if PDFCharacterSet.isWhitespace(byte) || PDFCharacterSet.isDelimiter(byte) {
                break
            }

            _ = try await readByte() // consume byte

            // Handle hex escapes in names (#XX)
            if byte == 0x23 { // #
                guard let hex1 = try await readByte(),
                      let hex2 = try await readByte(),
                      let digit1 = hexDigitValue(hex1),
                      let digit2 = hexDigitValue(hex2) else {
                    throw TokenizerError.invalidName(position: position)
                }
                bytes.append((digit1 << 4) | digit2)
            } else {
                bytes.append(byte)
            }
        }

        let name = String(bytes: bytes, encoding: .utf8) ?? ""
        return .name(ASAtom(name))
    }

    /// Reads a numeric token (integer or real).
    private mutating func readNumber() async throws -> PDFToken {
        var bytes: [UInt8] = []
        var hasDecimalPoint = false

        // Read sign and digits
        while let byte = try await peekByte() {
            if byte == 0x2E { // .
                if hasDecimalPoint {
                    break // Second decimal point ends number
                }
                hasDecimalPoint = true
                bytes.append(byte)
                _ = try await readByte()
            } else if byte >= 0x30 && byte <= 0x39 { // 0-9
                bytes.append(byte)
                _ = try await readByte()
            } else if (byte == 0x2B || byte == 0x2D) && bytes.isEmpty { // + or - at start
                bytes.append(byte)
                _ = try await readByte()
            } else if PDFCharacterSet.isWhitespace(byte) || PDFCharacterSet.isDelimiter(byte) {
                break
            } else {
                break
            }
        }

        guard !bytes.isEmpty else {
            throw TokenizerError.invalidToken(position: position, character: nil)
        }

        let str = String(bytes: bytes, encoding: .utf8) ?? ""

        if hasDecimalPoint {
            if let value = Double(str) {
                return .real(value)
            }
        } else {
            if let value = Int64(str) {
                return .integer(value)
            }
        }

        // Try as real if integer parsing failed
        if let value = Double(str) {
            return .real(value)
        }

        throw TokenizerError.invalidToken(position: position, character: nil)
    }

    /// Reads a keyword or literal token (alphabetic).
    private mutating func readKeywordOrLiteral() async throws -> PDFToken {
        var bytes: [UInt8] = []

        while let byte = try await peekByte() {
            if PDFCharacterSet.isWhitespace(byte) || PDFCharacterSet.isDelimiter(byte) {
                break
            }
            bytes.append(byte)
            _ = try await readByte()
        }

        let str = String(bytes: bytes, encoding: .utf8) ?? ""

        // Check if it's a known keyword
        if let keyword = PDFKeyword(rawValue: str) {
            return .keyword(keyword)
        }

        // Otherwise treat as an error (unknown keyword)
        throw TokenizerError.invalidToken(position: position, character: bytes.first)
    }

    // MARK: - Helper Methods

    /// Skips whitespace only (not comments).
    private mutating func skipWhitespace() async throws {
        while let byte = try await peekByte() {
            if PDFCharacterSet.isWhitespace(byte) {
                _ = try await readByte()
            } else {
                break
            }
        }
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

    /// Converts a hex character to its numeric value (0-15).
    private func hexDigitValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39: // 0-9
            return byte - 0x30
        case 0x41...0x46: // A-F
            return byte - 0x41 + 10
        case 0x61...0x66: // a-f
            return byte - 0x61 + 10
        default:
            return nil
        }
    }
}

// MARK: - AsyncSequence

extension PDFTokenizer: AsyncSequence {
    public typealias Element = PDFToken

    /// An async iterator for tokens.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var tokenizer: PDFTokenizer

        fileprivate init(tokenizer: PDFTokenizer) {
            self.tokenizer = tokenizer
        }

        public mutating func next() async throws -> PDFToken? {
            try await tokenizer.nextToken()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(tokenizer: self)
    }
}
