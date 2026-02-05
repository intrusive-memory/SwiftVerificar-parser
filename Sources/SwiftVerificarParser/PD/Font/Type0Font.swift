import Foundation

/// Type 0 composite font (CID-keyed font).
///
/// This struct corresponds to the Java `PDType0Font` class from veraPDF-parser.
/// Type 0 fonts are composite fonts that can contain thousands of glyphs,
/// making them suitable for complex scripts (Chinese, Japanese, Korean, etc.).
///
/// ## Type 0 Font Dictionary
/// - `/Type` → `/Font` (required)
/// - `/Subtype` → `/Type0` (required)
/// - `/BaseFont` → Composite font name (required)
/// - `/Encoding` → CMap name or stream (required)
/// - `/DescendantFonts` → Array containing one CIDFont (required)
/// - `/ToUnicode` → Unicode mapping CMap (optional but recommended)
///
/// ## Architecture
/// A Type 0 font is a composite of:
/// 1. **Type 0 Font**: The outer font that defines the CMap for character code → CID mapping
/// 2. **CIDFont**: The descendant font that defines CID → glyph mapping and metrics
/// 3. **CMap**: The mapping from multi-byte character codes to CIDs
/// 4. **Font Program**: The actual glyph data (CFF or TrueType)
///
/// ## Character Code → Glyph Process
/// 1. Character code → CID (via CMap specified in `/Encoding`)
/// 2. CID → glyph index (via CIDFont)
/// 3. Glyph index → glyph outline (via font program in CIDFont descriptor)
/// 4. Optional: Character code → Unicode (via `/ToUnicode` CMap)
public struct Type0Font: PDFFont {

    // MARK: - PDObject Conformance

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }

        // Verify this is a Type0 font
        guard let dict = cosObject.dictionaryValue,
              let subtypeValue = dict[.subtype],
              let subtypeName = subtypeValue.nameValue,
              subtypeName == .type0 else {
            throw PDError.incorrectType(
                key: "Subtype",
                expected: "Type0",
                actual: String(describing: cosObject)
            )
        }

        self.cosObject = cosObject
    }

    // MARK: - Type0-Specific Properties

    /// The encoding CMap name or stream.
    ///
    /// This can be:
    /// - A predefined CMap name (e.g., "Identity-H", "Identity-V")
    /// - A custom CMap stream
    ///
    /// The CMap maps multi-byte character codes to CIDs.
    public var encodingCMap: COSValue? {
        optionalEntry(.encoding)
    }

    /// The encoding CMap name, if the encoding is specified as a name.
    public var encodingCMapName: ASAtom? {
        encodingCMap?.nameValue
    }

    /// The descendant CIDFont array.
    ///
    /// The array must contain exactly one CIDFont.
    public var descendantFonts: [COSValue]? {
        optionalArray(.descendantFonts)
    }

    /// The first (and only) descendant CIDFont.
    public var descendantFont: CIDFont? {
        guard let fonts = descendantFonts,
              let first = fonts.first else {
            return nil
        }
        return try? CIDFont(cosObject: first)
    }

    /// Whether the encoding is Identity-H (horizontal identity mapping).
    public var isIdentityH: Bool {
        encodingCMapName == .identityH
    }

    /// Whether the encoding is Identity-V (vertical identity mapping).
    public var isIdentityV: Bool {
        encodingCMapName == .identityV
    }

    // MARK: - PDFFont Conformance

    /// Type0 fonts do not use simple encodings (they use CMaps).
    public var encoding: FontEncoding? {
        nil
    }

    /// Returns the width of a character code by delegating to the descendant CIDFont.
    ///
    /// - Parameter code: The character code (potentially multi-byte).
    /// - Returns: The width in glyph space units.
    public func width(for code: Int) -> Double {
        descendantFont?.width(for: code) ?? 250.0
    }
}
