import Foundation

/// TrueType font.
///
/// This struct corresponds to the Java `PDTrueTypeFont` class from veraPDF-parser.
/// TrueType fonts use quadratic Bézier curves for glyph outlines and are widely
/// supported across platforms.
///
/// ## TrueType Font Dictionary
/// - `/Type` → `/Font` (required)
/// - `/Subtype` → `/TrueType` (required)
/// - `/BaseFont` → PostScript font name (required)
/// - `/FirstChar` → First character code in Widths array (required)
/// - `/LastChar` → Last character code in Widths array (required)
/// - `/Widths` → Array of glyph widths (required)
/// - `/FontDescriptor` → Font descriptor (required)
/// - `/Encoding` → Encoding (optional, defaults to WinAnsiEncoding)
/// - `/ToUnicode` → Unicode mapping CMap (optional)
///
/// ## TrueType Font Programs
/// The TrueType font program is embedded in the FontDescriptor's `/FontFile2` entry.
/// The font program is a TrueType font file (.ttf) containing:
/// - Glyph outlines (quadratic Bézier curves)
/// - Character-to-glyph mapping tables (cmap)
/// - Glyph metrics (hmtx, vmtx)
/// - Font metrics (head, hhea, vhea, maxp)
/// - And many other tables
///
/// ## Design Notes
/// This implementation provides access to the embedded font program but does not
/// parse TrueType tables directly. For full TrueType parsing, see the TODO.md
/// Phase 5.5 (Font Parsing) section which describes TrueType table parsing.
public struct TrueTypeFont: SimpleFont {

    // MARK: - PDObject Conformance

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }

        // Verify this is a TrueType font
        guard let dict = cosObject.dictionaryValue,
              let subtypeValue = dict[.subtype],
              let subtypeName = subtypeValue.nameValue,
              subtypeName == .trueType else {
            throw PDError.incorrectType(
                key: "Subtype",
                expected: "TrueType",
                actual: String(describing: cosObject)
            )
        }

        self.cosObject = cosObject
    }

    // MARK: - TrueType-Specific Properties

    /// The embedded TrueType font program stream, if present.
    ///
    /// This is the `/FontFile2` entry in the font descriptor.
    /// The stream contains a TrueType font file (.ttf).
    public var fontProgram: COSValue? {
        fontDescriptor?.fontFile2
    }

    /// The length of the TrueType font program in bytes.
    public var fontProgramLength: Int? {
        guard let stream = fontProgram,
              let dict = stream.dictionaryValue,
              let lengthValue = dict[.length],
              let length = lengthValue.integerValue else {
            return nil
        }
        return Int(length)
    }

    /// Whether this font has an embedded TrueType program.
    public var isEmbedded: Bool {
        fontProgram != nil
    }
}
