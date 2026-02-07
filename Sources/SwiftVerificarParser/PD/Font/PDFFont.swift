import Foundation

/// Protocol for all PDF font types.
///
/// This protocol corresponds to the Java `PDFont` abstract class from veraPDF-parser.
/// Fonts in PDF can be simple (Type1, TrueType, Type3) or composite (Type0/CID).
///
/// ## Font Types
/// - **Simple fonts**: Map single byte codes to glyphs (Type1, TrueType, Type3)
/// - **Composite fonts**: Map multi-byte codes to glyphs (Type0 with CIDFont)
///
/// ## Common Font Dictionary Keys
/// - `/Type` → `/Font` (required)
/// - `/Subtype` → `/Type1`, `/TrueType`, `/Type0`, etc. (required)
/// - `/BaseFont` → Name of the font (required for most types)
/// - `/Encoding` → Character encoding (optional, varies by font type)
/// - `/ToUnicode` → CMap for Unicode mapping (optional)
/// - `/FontDescriptor` → Font metrics and attributes (required for embedded fonts)
///
/// ## Design Notes
/// Following Swift conventions, font types are value types (structs) conforming
/// to this protocol. Each font wraps a COS dictionary containing the font data.
public protocol PDFFont: PDObject {

    /// The font subtype name (Type1, TrueType, Type0, etc.).
    var subtype: ASAtom { get }

    /// The base font name.
    ///
    /// For Type1/TrueType: the PostScript name (e.g., "Helvetica-Bold")
    /// For Type0: the composite font name
    var baseFontName: ASAtom? { get }

    /// The font encoding, if present.
    ///
    /// Simple fonts may have a `/Encoding` entry specifying character mapping.
    /// Type0 fonts do not use this field.
    var encoding: FontEncoding? { get }

    /// The ToUnicode CMap for mapping character codes to Unicode.
    ///
    /// Optional but recommended for text extraction. Returns the COS stream
    /// containing the CMap program.
    var toUnicodeCMap: COSValue? { get }

    /// The font descriptor containing font metrics and attributes.
    ///
    /// Required for embedded fonts, optional for standard 14 fonts.
    var fontDescriptor: FontDescriptor? { get }

    /// Returns the width of a character code in glyph space units.
    ///
    /// - Parameter code: The character code (single or multi-byte depending on font type).
    /// - Returns: The width in 1/1000 glyph space units, or a default value if not found.
    func width(for code: Int) -> Double

    /// Whether this is a composite font (Type0).
    var isComposite: Bool { get }
}

// MARK: - Default Implementations

extension PDFFont {

    public var subtype: ASAtom {
        (try? requireName(.subtype)) ?? ASAtom("")
    }

    public var baseFontName: ASAtom? {
        optionalName(.baseFont)
    }

    public var encoding: FontEncoding? {
        guard let encodingValue = optionalEntry(.encoding) else {
            return nil
        }
        return try? FontEncoding(cosObject: encodingValue)
    }

    public var toUnicodeCMap: COSValue? {
        optionalEntry(.toUnicode)
    }

    public var fontDescriptor: FontDescriptor? {
        guard let descriptorDict = optionalEntry(.fontDescriptor) else {
            return nil
        }
        return try? FontDescriptor(cosObject: descriptorDict)
    }

    public var isComposite: Bool {
        subtype == .type0
    }

    /// Default width implementation returns 250 (a reasonable fallback).
    public func width(for code: Int) -> Double {
        250.0
    }
}

// MARK: - Font Subtype Constants

extension ASAtom {
    /// Type3 font subtype name.
    public static let type3 = ASAtom("Type3")

    /// MMType1 font subtype name (Multiple Master Type 1).
    public static let mmType1 = ASAtom("MMType1")
}
