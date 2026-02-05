import Foundation

/// Font descriptor containing font metrics and attributes.
///
/// This struct corresponds to the Java `PDFontDescriptor` class from veraPDF-parser.
/// A font descriptor provides detailed metrics and attributes for a font, such as
/// ascent, descent, cap height, flags, bounding box, and embedded font data.
///
/// ## Font Descriptor Dictionary Keys
/// - `/Type` → `/FontDescriptor` (required)
/// - `/FontName` → PostScript font name (required)
/// - `/Flags` → Font flags indicating properties (required)
/// - `/FontBBox` → Font bounding box [llx lly urx ury] (required)
/// - `/ItalicAngle` → Italic angle in degrees (required)
/// - `/Ascent` → Maximum height above baseline (required)
/// - `/Descent` → Maximum depth below baseline (required)
/// - `/CapHeight` → Height of capital letters (required for symbolic fonts)
/// - `/StemV` → Vertical stem width (required)
/// - `/FontFile`, `/FontFile2`, `/FontFile3` → Embedded font program (optional)
/// - `/XHeight` → Height of lowercase 'x' (optional)
/// - `/AvgWidth` → Average glyph width (optional)
/// - `/MaxWidth` → Maximum glyph width (optional)
/// - `/MissingWidth` → Width for missing glyphs (optional)
/// - `/Leading` → Spacing between lines (optional)
/// - `/StemH` → Horizontal stem width (optional)
///
/// ## Design Notes
/// - All required fields have sensible defaults to handle malformed PDFs
/// - The struct is a value type for immutability
public struct FontDescriptor: PDObject {

    // MARK: - PDObject Conformance

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Required Properties

    /// The PostScript name of the font.
    public var fontName: ASAtom? {
        optionalName(ASAtom("FontName"))
    }

    /// Font flags indicating various properties.
    ///
    /// The flags are a bit field with the following meanings:
    /// - Bit 1: FixedPitch
    /// - Bit 2: Serif
    /// - Bit 3: Symbolic
    /// - Bit 4: Script
    /// - Bit 6: Nonsymbolic
    /// - Bit 7: Italic
    /// - Bit 17: AllCap
    /// - Bit 18: SmallCap
    /// - Bit 19: ForceBold
    public var flags: Int {
        Int(optionalInteger(ASAtom("Flags")) ?? 0)
    }

    /// Font bounding box [llx, lly, urx, ury] in glyph space units.
    public var fontBBox: [Double] {
        guard let array = optionalArray(ASAtom("FontBBox")), array.count >= 4 else {
            return [0, 0, 1000, 1000]  // Default bounding box
        }
        return array.prefix(4).compactMap { value -> Double? in
            if let int = value.integerValue {
                return Double(int)
            }
            return value.realValue
        }
    }

    /// Italic angle in degrees counterclockwise from vertical.
    ///
    /// 0 for upright fonts, negative for fonts that lean to the right.
    public var italicAngle: Double {
        if let int = optionalInteger(ASAtom("ItalicAngle")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("ItalicAngle"))?.realValue ?? 0.0
    }

    /// Maximum height above the baseline reached by glyphs.
    public var ascent: Double {
        if let int = optionalInteger(ASAtom("Ascent")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("Ascent"))?.realValue ?? 750.0
    }

    /// Maximum depth below the baseline reached by glyphs.
    ///
    /// Typically a negative number.
    public var descent: Double {
        if let int = optionalInteger(ASAtom("Descent")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("Descent"))?.realValue ?? -250.0
    }

    /// Height of capital letters, measured from the baseline.
    public var capHeight: Double {
        if let int = optionalInteger(ASAtom("CapHeight")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("CapHeight"))?.realValue ?? 700.0
    }

    /// Thickness of vertical stems, in glyph space units.
    public var stemV: Double {
        if let int = optionalInteger(ASAtom("StemV")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("StemV"))?.realValue ?? 70.0
    }

    // MARK: - Optional Properties

    /// Height of lowercase letters (e.g., 'x'), measured from the baseline.
    public var xHeight: Double? {
        if let int = optionalInteger(ASAtom("XHeight")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("XHeight"))?.realValue
    }

    /// Average width of all glyphs in the font.
    public var avgWidth: Double? {
        if let int = optionalInteger(ASAtom("AvgWidth")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("AvgWidth"))?.realValue
    }

    /// Maximum width of all glyphs in the font.
    public var maxWidth: Double? {
        if let int = optionalInteger(ASAtom("MaxWidth")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("MaxWidth"))?.realValue
    }

    /// Width to use for character codes that are missing from the font.
    public var missingWidth: Double? {
        if let int = optionalInteger(ASAtom("MissingWidth")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("MissingWidth"))?.realValue
    }

    /// Spacing between baselines of consecutive lines of text.
    public var leading: Double? {
        if let int = optionalInteger(ASAtom("Leading")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("Leading"))?.realValue
    }

    /// Thickness of horizontal stems, in glyph space units.
    public var stemH: Double? {
        if let int = optionalInteger(ASAtom("StemH")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("StemH"))?.realValue
    }

    // MARK: - Embedded Font Programs

    /// Type 1 font program stream (FontFile).
    public var fontFile: COSValue? {
        optionalEntry(ASAtom("FontFile"))
    }

    /// TrueType font program stream (FontFile2).
    public var fontFile2: COSValue? {
        optionalEntry(ASAtom("FontFile2"))
    }

    /// Type 1C (CFF), CIDFont Type 0C, or OpenType font program stream (FontFile3).
    public var fontFile3: COSValue? {
        optionalEntry(ASAtom("FontFile3"))
    }

    /// The subtype of the FontFile3 stream, if present.
    ///
    /// Common values: "Type1C", "CIDFontType0C", "OpenType"
    public var fontFile3Subtype: ASAtom? {
        guard let file3 = fontFile3?.dictionaryValue else {
            return nil
        }
        return file3[.subtype]?.nameValue
    }

    // MARK: - Font Flags

    /// Whether the font is fixed-pitch (monospaced).
    public var isFixedPitch: Bool {
        (flags & 0x1) != 0
    }

    /// Whether the font is serif.
    public var isSerif: Bool {
        (flags & 0x2) != 0
    }

    /// Whether the font is symbolic (uses non-standard encoding).
    public var isSymbolic: Bool {
        (flags & 0x4) != 0
    }

    /// Whether the font is script.
    public var isScript: Bool {
        (flags & 0x8) != 0
    }

    /// Whether the font is nonsymbolic (uses standard encoding).
    public var isNonsymbolic: Bool {
        (flags & 0x20) != 0
    }

    /// Whether the font is italic.
    public var isItalic: Bool {
        (flags & 0x40) != 0
    }

    /// Whether all glyphs have their tops at CapHeight.
    public var isAllCap: Bool {
        (flags & 0x10000) != 0
    }

    /// Whether all glyphs have their tops at CapHeight for lowercase.
    public var isSmallCap: Bool {
        (flags & 0x20000) != 0
    }

    /// Whether bold glyphs should be painted with extra pixels.
    public var isForceBold: Bool {
        (flags & 0x40000) != 0
    }
}
