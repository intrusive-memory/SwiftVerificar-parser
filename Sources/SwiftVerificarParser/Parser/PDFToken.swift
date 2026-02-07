import Foundation

/// A token extracted from a PDF data stream.
///
/// `PDFToken` represents the lexical tokens that appear in PDF files.
/// The PDF tokenizer breaks the byte stream into these discrete tokens,
/// which are then consumed by higher-level parsers to build the object model.
///
/// This enum corresponds to the Java `Token` class from veraPDF-parser,
/// consolidating `Token.Type` and the token value into a single Swift enum
/// with associated values.
///
/// ## Token Types
///
/// PDF tokens fall into several categories:
///
/// - **Literals**: Boolean (`true`, `false`), null, integers, real numbers
/// - **Strings**: Literal strings `(text)` and hex strings `<686578>`
/// - **Names**: Symbolic names like `/Type`, `/Font`
/// - **Delimiters**: Array `[ ]`, dictionary `<< >>`, stream boundaries
/// - **Structural**: Keywords like `obj`, `endobj`, `stream`, `R`
/// - **Comments**: Lines starting with `%`
/// - **End-of-file**: The `%%EOF` marker
///
/// ## Usage
/// ```swift
/// let tokens: [PDFToken] = [
///     .integer(42),
///     .name(ASAtom("Type")),
///     .keyword(.obj),
///     .string(Data("Hello".utf8))
/// ]
/// ```
///
/// ## Thread Safety
/// This enum is `Sendable` and safe to use across concurrency boundaries.
public enum PDFToken: Sendable, Equatable {

    // MARK: - Keyword Tokens

    /// A PDF structural keyword (e.g., `obj`, `endobj`, `stream`, `R`).
    case keyword(PDFKeyword)

    // MARK: - Numeric Tokens

    /// An integer literal (e.g., `42`, `-17`, `0`).
    case integer(Int64)

    /// A real (floating-point) literal (e.g., `3.14`, `-0.5`, `.25`).
    case real(Double)

    // MARK: - String Tokens

    /// A literal string enclosed in parentheses: `(text)`.
    ///
    /// The associated data contains the decoded string bytes (after processing
    /// escape sequences like `\n`, `\r`, `\\`, `\(`, `\)`, octal escapes, etc.).
    case string(Data)

    /// A hexadecimal string enclosed in angle brackets: `<686578>`.
    ///
    /// The associated data contains the decoded bytes. Each pair of hex digits
    /// represents one byte. Whitespace is ignored. If an odd number of digits
    /// is present, a trailing `0` is assumed.
    case hexString(Data)

    // MARK: - Name Token

    /// A name object, starting with `/` (e.g., `/Type`, `/Font`, `/BBox`).
    ///
    /// The associated `ASAtom` holds the name's string value without the leading `/`.
    case name(ASAtom)

    // MARK: - Array Delimiters

    /// The left bracket `[`, marking the start of an array.
    case arrayStart

    /// The right bracket `]`, marking the end of an array.
    case arrayEnd

    // MARK: - Dictionary Delimiters

    /// The double left angle bracket `<<`, marking the start of a dictionary.
    case dictionaryStart

    /// The double right angle bracket `>>`, marking the end of a dictionary.
    case dictionaryEnd

    // MARK: - Comment

    /// A comment line (starting with `%` and continuing to end-of-line).
    ///
    /// The associated string contains the comment text (excluding the `%` prefix).
    /// Most parsers ignore comments, but they may be useful for debugging or
    /// preserving metadata.
    case comment(String)

    // MARK: - End of File

    /// The end-of-file marker `%%EOF`.
    case endOfFile

    // MARK: - Properties

    /// Whether this token is a keyword.
    public var isKeyword: Bool {
        if case .keyword = self { return true }
        return false
    }

    /// Whether this token is an integer.
    public var isInteger: Bool {
        if case .integer = self { return true }
        return false
    }

    /// Whether this token is a real number.
    public var isReal: Bool {
        if case .real = self { return true }
        return false
    }

    /// Whether this token is a string (literal or hex).
    public var isString: Bool {
        if case .string = self { return true }
        if case .hexString = self { return true }
        return false
    }

    /// Whether this token is a name.
    public var isName: Bool {
        if case .name = self { return true }
        return false
    }

    /// Whether this token is a comment.
    public var isComment: Bool {
        if case .comment = self { return true }
        return false
    }

    /// Whether this token marks the start of an array.
    public var isArrayStart: Bool {
        if case .arrayStart = self { return true }
        return false
    }

    /// Whether this token marks the end of an array.
    public var isArrayEnd: Bool {
        if case .arrayEnd = self { return true }
        return false
    }

    /// Whether this token marks the start of a dictionary.
    public var isDictionaryStart: Bool {
        if case .dictionaryStart = self { return true }
        return false
    }

    /// Whether this token marks the end of a dictionary.
    public var isDictionaryEnd: Bool {
        if case .dictionaryEnd = self { return true }
        return false
    }

    /// Whether this token is the end-of-file marker.
    public var isEndOfFile: Bool {
        if case .endOfFile = self { return true }
        return false
    }

    /// Extracts the keyword value if this is a keyword token.
    public var keywordValue: PDFKeyword? {
        if case .keyword(let kw) = self { return kw }
        return nil
    }

    /// Extracts the integer value if this is an integer token.
    public var integerValue: Int64? {
        if case .integer(let val) = self { return val }
        return nil
    }

    /// Extracts the real value if this is a real token.
    public var realValue: Double? {
        if case .real(let val) = self { return val }
        return nil
    }

    /// Extracts the string data if this is a string or hex string token.
    public var stringData: Data? {
        switch self {
        case .string(let data), .hexString(let data):
            return data
        default:
            return nil
        }
    }

    /// Extracts the name if this is a name token.
    public var nameValue: ASAtom? {
        if case .name(let atom) = self { return atom }
        return nil
    }

    /// Extracts the comment text if this is a comment token.
    public var commentValue: String? {
        if case .comment(let text) = self { return text }
        return nil
    }

    // MARK: - Numeric Conversion

    /// Returns the numeric value as an `Int64`, converting from real if necessary.
    ///
    /// This is useful when a token could be either an integer or a real number,
    /// and you want to treat both as integers (e.g., object numbers).
    public var asInteger: Int64? {
        switch self {
        case .integer(let val):
            return val
        case .real(let val):
            return Int64(val)
        default:
            return nil
        }
    }

    /// Returns the numeric value as a `Double`, converting from integer if necessary.
    public var asReal: Double? {
        switch self {
        case .integer(let val):
            return Double(val)
        case .real(let val):
            return val
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension PDFToken: CustomStringConvertible {
    public var description: String {
        switch self {
        case .keyword(let kw):
            return "keyword(\(kw.rawValue))"
        case .integer(let val):
            return "integer(\(val))"
        case .real(let val):
            return "real(\(val))"
        case .string(let data):
            if let str = String(data: data, encoding: .utf8) {
                return "string(\"\(str)\")"
            } else {
                return "string(\(data.count) bytes)"
            }
        case .hexString(let data):
            return "hexString(\(data.map { String(format: "%02x", $0) }.joined()))"
        case .name(let atom):
            return "name(\(atom.description))"
        case .arrayStart:
            return "["
        case .arrayEnd:
            return "]"
        case .dictionaryStart:
            return "<<"
        case .dictionaryEnd:
            return ">>"
        case .comment(let text):
            return "comment(\"\(text)\")"
        case .endOfFile:
            return "%%EOF"
        }
    }
}
