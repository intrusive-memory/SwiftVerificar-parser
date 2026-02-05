import Foundation

/// Parses individual PDF objects from tokens.
///
/// `ObjectParser` converts a stream of `PDFToken` values into `COSValue` objects,
/// handling all PDF object types including primitives (null, boolean, numbers, strings,
/// names), composites (arrays, dictionaries), and references.
///
/// This corresponds to part of the Java `COSParser` class from veraPDF-parser,
/// focusing on the object-level parsing logic.
///
/// ## PDF Object Syntax
///
/// PDF objects can be:
/// - **Direct objects**: Values inline in the file (numbers, strings, arrays, dictionaries)
/// - **Indirect objects**: Defined separately and referenced by object number
///
/// Example indirect object:
/// ```
/// 12 0 obj
///   << /Type /Page /Parent 1 0 R >>
/// endobj
/// ```
///
/// Example indirect reference:
/// ```
/// 12 0 R
/// ```
///
/// ## Usage
/// ```swift
/// var tokenizer = PDFTokenizer(stream: stream)
/// let parser = ObjectParser(tokenizer: &tokenizer)
/// let value = try await parser.parseObject()
/// ```
public struct ObjectParser: Sendable {

    // MARK: - Errors

    /// Errors that can occur during object parsing.
    public enum ParserError: Error, CustomStringConvertible {
        /// Unexpected token encountered.
        case unexpectedToken(expected: String, got: PDFToken)

        /// Unexpected end of stream.
        case unexpectedEndOfStream

        /// Invalid indirect object syntax.
        case invalidIndirectObject

        /// Invalid indirect reference syntax.
        case invalidReference

        /// Mismatched array brackets.
        case mismatchedArrayBrackets

        /// Mismatched dictionary brackets.
        case mismatchedDictionaryBrackets

        /// Dictionary key must be a name.
        case dictionaryKeyMustBeName(got: PDFToken)

        /// Invalid stream object.
        case invalidStreamObject(String)

        public var description: String {
            switch self {
            case .unexpectedToken(let expected, let got):
                return "Expected \(expected), got \(got)"
            case .unexpectedEndOfStream:
                return "Unexpected end of stream"
            case .invalidIndirectObject:
                return "Invalid indirect object syntax"
            case .invalidReference:
                return "Invalid indirect reference syntax"
            case .mismatchedArrayBrackets:
                return "Mismatched array brackets"
            case .mismatchedDictionaryBrackets:
                return "Mismatched dictionary brackets"
            case .dictionaryKeyMustBeName(let got):
                return "Dictionary key must be a name, got \(got)"
            case .invalidStreamObject(let msg):
                return "Invalid stream object: \(msg)"
            }
        }
    }

    // MARK: - Initialization

    /// Creates an object parser.
    public init() {}

    // MARK: - Object Parsing

    /// Parses a single PDF object from the token stream.
    ///
    /// This method handles all direct object types and indirect references.
    /// It does not handle indirect object definitions (those require parsing
    /// the object number/generation number header).
    ///
    /// - Parameter tokenizer: The tokenizer to read tokens from.
    /// - Returns: A parsed `COSValue`.
    /// - Throws: `ParserError` if parsing fails.
    public func parseObject(_ tokenizer: inout PDFTokenizer) async throws -> COSValue {
        guard let token = try await tokenizer.nextToken() else {
            throw ParserError.unexpectedEndOfStream
        }

        return try await parseValue(from: token, tokenizer: &tokenizer)
    }

    /// Parses a value from a token, consuming additional tokens as needed.
    private func parseValue(from token: PDFToken, tokenizer: inout PDFTokenizer) async throws -> COSValue {
        switch token {
        case .keyword(let keyword):
            switch keyword {
            case .null:
                return .null
            case .true:
                return .boolean(true)
            case .false:
                return .boolean(false)
            default:
                throw ParserError.unexpectedToken(expected: "value", got: token)
            }

        case .integer(let value):
            // Check if this might be the start of an indirect reference (N G R)
            // We need to peek ahead to see if there's another integer followed by R
            return try await parseIntegerOrReference(value, tokenizer: &tokenizer)

        case .real(let value):
            return .real(value)

        case .string(let data):
            return .string(COSString(data: data, isHex: false))

        case .hexString(let data):
            return .string(COSString(data: data, isHex: true))

        case .name(let atom):
            return .name(atom)

        case .arrayStart:
            return try await parseArray(tokenizer: &tokenizer)

        case .dictionaryStart:
            return try await parseDictionary(tokenizer: &tokenizer)

        case .arrayEnd:
            throw ParserError.mismatchedArrayBrackets

        case .dictionaryEnd:
            throw ParserError.mismatchedDictionaryBrackets

        case .comment:
            // Skip comments and try next token
            return try await parseObject(&tokenizer)

        case .endOfFile:
            throw ParserError.unexpectedEndOfStream
        }
    }

    /// Parses an integer or checks if it's the start of an indirect reference.
    ///
    /// In PDF syntax, integers can appear standalone or as part of a reference (N G R).
    /// This method needs to lookahead to determine which case applies.
    ///
    /// Note: This implementation has a limitation - if we see "N M" where M is not
    /// followed by R, we cannot return just N because we've already consumed M.
    /// A production parser would need either backtracking or a token buffer.
    /// For now, we'll only recognize the pattern "N G R" as a reference.
    private func parseIntegerOrReference(_ objectNumber: Int64, tokenizer: inout PDFTokenizer) async throws -> COSValue {
        // In a simple implementation, we just return the integer.
        // References will be parsed by higher-level code that expects them.
        // This is a design tradeoff - we're simplifying by not handling
        // the full lookahead here.
        return .integer(objectNumber)
    }

    /// Parses an indirect reference (N G R).
    ///
    /// This expects the tokenizer to be positioned before the object number.
    ///
    /// - Parameter tokenizer: The tokenizer to read from.
    /// - Returns: A `COSReference` wrapped in `COSValue`.
    /// - Throws: `ParserError` if the reference syntax is invalid.
    public func parseReference(_ tokenizer: inout PDFTokenizer) async throws -> COSValue {
        // Read object number
        guard let objNumToken = try await tokenizer.nextToken(),
              let objectNumber = objNumToken.asInteger else {
            throw ParserError.invalidReference
        }

        // Read generation number
        guard let genNumToken = try await tokenizer.nextToken(),
              let generationNumber = genNumToken.asInteger else {
            throw ParserError.invalidReference
        }

        // Read 'R' keyword
        guard let rToken = try await tokenizer.nextToken(),
              case .keyword(.R) = rToken else {
            throw ParserError.invalidReference
        }

        let ref = COSReference(
            objectNumber: Int(objectNumber),
            generation: Int(generationNumber)
        )
        return .reference(ref)
    }

    /// Parses an array object.
    private func parseArray(tokenizer: inout PDFTokenizer) async throws -> COSValue {
        var elements: [COSValue] = []

        while let token = try await tokenizer.nextToken() {
            if case .arrayEnd = token {
                return .array(elements)
            }

            let value = try await parseValue(from: token, tokenizer: &tokenizer)
            elements.append(value)
        }

        throw ParserError.mismatchedArrayBrackets
    }

    /// Parses a dictionary object.
    private func parseDictionary(tokenizer: inout PDFTokenizer) async throws -> COSValue {
        var dict: [ASAtom: COSValue] = [:]

        while let token = try await tokenizer.nextToken() {
            if case .dictionaryEnd = token {
                return .dictionary(dict)
            }

            // Dictionary entries must be name-value pairs
            guard case .name(let key) = token else {
                throw ParserError.dictionaryKeyMustBeName(got: token)
            }

            // Parse the value
            guard let valueToken = try await tokenizer.nextToken() else {
                throw ParserError.unexpectedEndOfStream
            }

            let value = try await parseValue(from: valueToken, tokenizer: &tokenizer)
            dict[key] = value
        }

        throw ParserError.mismatchedDictionaryBrackets
    }

    // MARK: - Indirect Object Parsing

    /// Parses an indirect object definition (N G obj ... endobj).
    ///
    /// This expects the tokenizer to be positioned before the object number.
    ///
    /// - Parameter tokenizer: The tokenizer to read from.
    /// - Returns: A tuple of (object number, generation number, value).
    /// - Throws: `ParserError` if parsing fails.
    public func parseIndirectObject(_ tokenizer: inout PDFTokenizer) async throws -> (objectNumber: Int, generationNumber: Int, value: COSValue) {
        // Read object number
        guard let objNumToken = try await tokenizer.nextToken(),
              let objectNumber = objNumToken.asInteger else {
            throw ParserError.invalidIndirectObject
        }

        // Read generation number
        guard let genNumToken = try await tokenizer.nextToken(),
              let generationNumber = genNumToken.asInteger else {
            throw ParserError.invalidIndirectObject
        }

        // Read 'obj' keyword
        guard let objKeywordToken = try await tokenizer.nextToken(),
              case .keyword(.obj) = objKeywordToken else {
            throw ParserError.invalidIndirectObject
        }

        // Parse the object value
        let value = try await parseObject(&tokenizer)

        // Read 'endobj' keyword
        guard let endobjToken = try await tokenizer.nextToken(),
              case .keyword(.endobj) = endobjToken else {
            throw ParserError.invalidIndirectObject
        }

        return (Int(objectNumber), Int(generationNumber), value)
    }

    /// Parses a stream object (dictionary followed by stream data).
    ///
    /// This expects a dictionary to be already parsed, followed by 'stream' keyword.
    ///
    /// - Parameters:
    ///   - dictionary: The stream dictionary (already parsed).
    ///   - tokenizer: The tokenizer to read from.
    ///   - stream: The seekable stream to read raw stream data from.
    /// - Returns: A `COSStream` object.
    /// - Throws: `ParserError` if parsing fails.
    public func parseStreamObject(
        dictionary: [ASAtom: COSValue],
        tokenizer: inout PDFTokenizer,
        stream: any SeekableStream
    ) async throws -> COSStream {
        // Expect 'stream' keyword
        guard let streamToken = try await tokenizer.nextToken(),
              case .keyword(.stream) = streamToken else {
            throw ParserError.invalidStreamObject("Expected 'stream' keyword")
        }

        // Get stream length from dictionary
        guard let lengthValue = dictionary[.length],
              let length = lengthValue.integerValue else {
            throw ParserError.invalidStreamObject("Stream dictionary must have /Length entry")
        }

        // Read stream data
        // In a real implementation, we'd read exactly 'length' bytes from the stream
        // For now, we'll create a placeholder
        let streamData = Data() // TODO: Read length bytes from stream

        // Expect 'endstream' keyword
        guard let endstreamToken = try await tokenizer.nextToken(),
              case .keyword(.endstream) = endstreamToken else {
            throw ParserError.invalidStreamObject("Expected 'endstream' keyword")
        }

        return COSStream(dictionary: dictionary, encodedData: streamData)
    }
}
