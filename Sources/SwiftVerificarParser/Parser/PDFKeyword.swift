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

    // MARK: - Content Stream Operators (Graphics State)

    /// Save graphics state (`q`).
    case q

    /// Restore graphics state (`Q`).
    case Q

    /// Concatenate matrix (`cm`).
    case cm

    /// Set line width (`w`).
    case w

    /// Set line cap (`J`).
    case J

    /// Set line join (`j`).
    case j

    /// Set miter limit (`M`).
    case M

    /// Set dash pattern (`d`).
    case d

    /// Set rendering intent (`ri`).
    case ri

    /// Set flatness (`i`).
    case i

    /// Set extended graphics state (`gs`).
    case gs

    // MARK: - Content Stream Operators (Path Construction)

    /// Move to (`m`).
    case m

    /// Line to (`l`).
    case l

    /// Curve to (`c`).
    case c

    /// Curve to V (`v`).
    case v

    /// Curve to Y (`y`).
    case y

    /// Close path (`h`).
    case h

    /// Rectangle (`re`).
    case re

    // MARK: - Content Stream Operators (Path Painting)

    /// Stroke (`S`).
    case S

    /// Close and stroke (`s`).
    case s

    /// Fill (`f`).
    case f

    /// Fill (alternative) (`F`).
    case F

    /// Fill even-odd (`f*`).
    case fStar = "f*"

    /// Fill and stroke (`B`).
    case B

    /// Fill and stroke even-odd (`B*`).
    case BStar = "B*"

    /// Close, fill and stroke (`b`).
    case b

    /// Close, fill and stroke even-odd (`b*`).
    case bStar = "b*"

    /// End path (`n`).
    case n

    // MARK: - Content Stream Operators (Clipping)

    /// Clip (`W`).
    case W

    /// Clip even-odd (`W*`).
    case WStar = "W*"

    // MARK: - Content Stream Operators (Text Objects)

    /// Begin text (`BT`).
    case BT

    /// End text (`ET`).
    case ET

    // MARK: - Content Stream Operators (Text State)

    /// Set character spacing (`Tc`).
    case Tc

    /// Set word spacing (`Tw`).
    case Tw

    /// Set horizontal scaling (`Tz`).
    case Tz

    /// Set text leading (`TL`).
    case TL

    /// Set font (`Tf`).
    case Tf

    /// Set text rendering mode (`Tr`).
    case Tr

    /// Set text rise (`Ts`).
    case Ts

    // MARK: - Content Stream Operators (Text Positioning)

    /// Move text (`Td`).
    case Td

    /// Move text and set leading (`TD`).
    case TD

    /// Set text matrix (`Tm`).
    case Tm

    /// Move to next line (`T*`).
    case TStar = "T*"

    // MARK: - Content Stream Operators (Text Showing)

    /// Show text (`Tj`).
    case Tj

    /// Show text array (`TJ`).
    case TJ

    /// Move to next line and show text (`'`).
    case quote = "'"

    /// Set spacing, move to next line and show text (`"`).
    case doubleQuote = "\""

    // MARK: - Content Stream Operators (Color)

    /// Set stroking color space (`CS`).
    case CS

    /// Set nonstroking color space (`cs`).
    case cs

    /// Set stroking color (`SC`).
    case SC

    /// Set stroking color with pattern (`SCN`).
    case SCN

    /// Set nonstroking color (`sc`).
    case sc

    /// Set nonstroking color with pattern (`scn`).
    case scn

    /// Set stroking gray (`G`).
    case G

    /// Set nonstroking gray (`g`).
    case g

    /// Set stroking RGB (`RG`).
    case RG

    /// Set nonstroking RGB (`rg`).
    case rg

    /// Set stroking CMYK (`K`).
    case K

    /// Set nonstroking CMYK (`k`).
    case k

    // MARK: - Content Stream Operators (Shading)

    /// Paint shading (`sh`).
    case sh

    // MARK: - Content Stream Operators (Inline Images)

    /// Begin inline image (`BI`).
    case BI

    /// Inline image data (`ID`).
    case ID

    /// End inline image (`EI`).
    case EI

    // MARK: - Content Stream Operators (XObjects)

    /// Invoke XObject (`Do`).
    case Do

    // MARK: - Content Stream Operators (Marked Content)

    /// Marked content point (`MP`).
    case MP

    /// Marked content point with properties (`DP`).
    case DP

    /// Begin marked content (`BMC`).
    case BMC

    /// Begin marked content with properties (`BDC`).
    case BDC

    /// End marked content (`EMC`).
    case EMC

    // MARK: - Content Stream Operators (Compatibility)

    /// Begin compatibility section (`BX`).
    case BX

    /// End compatibility section (`EX`).
    case EX

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
