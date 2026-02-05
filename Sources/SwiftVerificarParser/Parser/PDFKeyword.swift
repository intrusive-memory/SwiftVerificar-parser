import Foundation

/// PDF keywords used in the PDF file structure.
///
/// `PDFKeyword` represents the special keyword tokens that appear in PDF files
/// and have specific structural meaning in the PDF syntax. These keywords are
/// distinct from PDF names (which use the `/` prefix) and from PDF operators
/// (which appear in content streams).
///
/// This enum corresponds to the Java `Token.Keyword` enum from veraPDF-parser.
///
/// ## PDF Structural Keywords
///
/// - **Object definition**: `obj`, `endobj` delimit indirect objects
/// - **Streams**: `stream`, `endstream` delimit stream data
/// - **Cross-reference**: `xref`, `trailer`, `startxref` mark xref structures
/// - **Boolean and null**: `true`, `false`, `null` are literal values
/// - **Indirect references**: `R` marks an indirect reference (e.g., `1 0 R`)
///
/// ## Usage
/// ```swift
/// let keyword = PDFKeyword.obj
/// print(keyword.rawValue)  // "obj"
///
/// if let parsed = PDFKeyword(rawValue: "stream") {
///     print("Found stream keyword")
/// }
/// ```
///
/// ## Thread Safety
/// This enum is `Sendable` and safe to use across concurrency boundaries.
public enum PDFKeyword: String, CaseIterable, Sendable, Equatable, Hashable, Codable {

    // MARK: - Boolean and Null Literals

    /// The `true` boolean literal.
    case `true`

    /// The `false` boolean literal.
    case `false`

    /// The `null` literal.
    case null

    // MARK: - Object Definition

    /// Begins an indirect object definition (e.g., `1 0 obj`).
    case obj

    /// Ends an indirect object definition.
    case endobj

    // MARK: - Stream Delimiters

    /// Begins a stream object's data section.
    case stream

    /// Ends a stream object's data section.
    case endstream

    // MARK: - Cross-Reference Structure

    /// Marks the beginning of a cross-reference table.
    case xref

    /// Marks the beginning of a trailer dictionary.
    case trailer

    /// Marks the byte offset of the cross-reference table (followed by the offset value).
    case startxref

    // MARK: - Indirect Reference

    /// Marks an indirect reference (e.g., `1 0 R` references object 1, generation 0).
    case R

    // MARK: - Properties

    /// The string representation of this keyword as it appears in PDF files.
    public var stringValue: String {
        rawValue
    }

    /// Whether this keyword marks the start of an object definition.
    public var isObjectStart: Bool {
        self == .obj
    }

    /// Whether this keyword marks the end of an object definition.
    public var isObjectEnd: Bool {
        self == .endobj
    }

    /// Whether this keyword marks the start of stream data.
    public var isStreamStart: Bool {
        self == .stream
    }

    /// Whether this keyword marks the end of stream data.
    public var isStreamEnd: Bool {
        self == .endstream
    }

    /// Whether this keyword is a boolean literal (`true` or `false`).
    public var isBoolean: Bool {
        self == .true || self == .false
    }

    /// Returns the boolean value if this is a boolean keyword, otherwise `nil`.
    public var booleanValue: Bool? {
        switch self {
        case .true: return true
        case .false: return false
        default: return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension PDFKeyword: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}
