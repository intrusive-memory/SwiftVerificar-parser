import Foundation

/// PostScript Type 1 font.
///
/// This struct corresponds to the Java `PDType1Font` class from veraPDF-parser.
/// Type 1 fonts are PostScript fonts using cubic Bézier curves for glyph outlines.
///
/// ## Type 1 Font Dictionary
/// - `/Type` → `/Font` (required)
/// - `/Subtype` → `/Type1` or `/MMType1` (required)
/// - `/BaseFont` → PostScript font name (required)
/// - `/FirstChar` → First character code in Widths array (required except for standard 14)
/// - `/LastChar` → Last character code in Widths array (required except for standard 14)
/// - `/Widths` → Array of glyph widths (required except for standard 14)
/// - `/FontDescriptor` → Font descriptor (required for embedded fonts)
/// - `/Encoding` → Encoding (optional, defaults to font's built-in encoding)
/// - `/ToUnicode` → Unicode mapping CMap (optional)
///
/// ## Standard 14 Fonts
/// PDF viewers are required to support 14 standard Type 1 fonts without embedding:
/// - Times-Roman, Times-Bold, Times-Italic, Times-BoldItalic
/// - Helvetica, Helvetica-Bold, Helvetica-Oblique, Helvetica-BoldOblique
/// - Courier, Courier-Bold, Courier-Oblique, Courier-BoldOblique
/// - Symbol, ZapfDingbats
///
/// For these fonts, FirstChar/LastChar/Widths/FontDescriptor may be omitted.
public struct Type1Font: SimpleFont {

    // MARK: - PDObject Conformance

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }

        // Verify this is a Type1 or MMType1 font
        guard let dict = cosObject.dictionaryValue,
              let subtypeValue = dict[.subtype],
              let subtypeName = subtypeValue.nameValue,
              (subtypeName == .type1 || subtypeName == .mmType1) else {
            throw PDError.incorrectType(
                key: "Subtype",
                expected: "Type1 or MMType1",
                actual: String(describing: cosObject)
            )
        }

        self.cosObject = cosObject
    }

    // MARK: - Type1-Specific Properties

    /// Whether this is a Multiple Master Type 1 font.
    public var isMultipleMaster: Bool {
        subtype == .mmType1
    }

    /// Whether this is one of the standard 14 fonts.
    public var isStandard14: Bool {
        guard let name = baseFontName else {
            return false
        }
        return Standard14Fonts.isStandard14(name)
    }

    /// The embedded Type 1 font program stream, if present.
    ///
    /// This is the `/FontFile` entry in the font descriptor.
    public var fontProgram: COSValue? {
        fontDescriptor?.fontFile
    }
}

// MARK: - Standard 14 Fonts

/// Helper for identifying the PDF standard 14 fonts.
enum Standard14Fonts {

    /// The names of the 14 standard PDF fonts.
    static let standard14Names: Set<String> = [
        "Times-Roman", "Times-Bold", "Times-Italic", "Times-BoldItalic",
        "Helvetica", "Helvetica-Bold", "Helvetica-Oblique", "Helvetica-BoldOblique",
        "Courier", "Courier-Bold", "Courier-Oblique", "Courier-BoldOblique",
        "Symbol", "ZapfDingbats"
    ]

    /// Checks if the given font name is one of the standard 14.
    ///
    /// - Parameter name: The font name atom.
    /// - Returns: True if this is a standard 14 font name.
    static func isStandard14(_ name: ASAtom) -> Bool {
        standard14Names.contains(name.stringValue)
    }
}
