import Foundation

/// CID-keyed font (Character Identifier font).
///
/// This struct corresponds to the Java `PDCIDFont` class from veraPDF-parser.
/// A CIDFont is a font that uses CIDs (Character Identifiers) instead of character codes.
/// CIDFonts are always used as descendant fonts within Type 0 composite fonts.
///
/// ## CIDFont Dictionary
/// - `/Type` → `/Font` (required)
/// - `/Subtype` → `/CIDFontType0` or `/CIDFontType2` (required)
/// - `/BaseFont` → PostScript font name (required)
/// - `/CIDSystemInfo` → Dictionary identifying character collection (required)
/// - `/FontDescriptor` → Font descriptor (required)
/// - `/DW` → Default width for CIDs (optional, default 1000)
/// - `/W` → Array specifying widths for CID ranges (optional)
/// - `/DW2` → Default vertical metrics (optional)
/// - `/W2` → Array specifying vertical metrics for CID ranges (optional)
/// - `/CIDToGIDMap` → CID-to-GID mapping (optional for TrueType CIDFonts)
///
/// ## CIDFont Types
/// - **CIDFontType0**: Based on CFF (Compact Font Format) font programs
/// - **CIDFontType2**: Based on TrueType font programs
///
/// ## CID System Info
/// The CIDSystemInfo dictionary identifies the character collection:
/// - `/Registry` → Issuer of the character collection (e.g., "Adobe")
/// - `/Ordering` → Character collection name (e.g., "Japan1", "Korea1", "GB1")
/// - `/Supplement` → Supplement number (version)
///
/// Example: Adobe-Japan1-6 = {Registry: "Adobe", Ordering: "Japan1", Supplement: 6}
public struct CIDFont: PDFFont {

    // MARK: - PDObject Conformance

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }

        // Verify this is a CIDFont
        guard let dict = cosObject.dictionaryValue,
              let subtypeValue = dict[.subtype],
              let subtypeName = subtypeValue.nameValue,
              (subtypeName == .cidFontType0 || subtypeName == .cidFontType2) else {
            throw PDError.incorrectType(
                key: "Subtype",
                expected: "CIDFontType0 or CIDFontType2",
                actual: String(describing: cosObject)
            )
        }

        self.cosObject = cosObject
    }

    // MARK: - CIDFont-Specific Properties

    /// Whether this is a CIDFontType0 (CFF-based).
    public var isCIDFontType0: Bool {
        subtype == .cidFontType0
    }

    /// Whether this is a CIDFontType2 (TrueType-based).
    public var isCIDFontType2: Bool {
        subtype == .cidFontType2
    }

    /// The CIDSystemInfo dictionary.
    public var cidSystemInfo: CIDSystemInfo? {
        guard let infoDict = optionalDictionary(ASAtom("CIDSystemInfo")) else {
            return nil
        }
        return try? CIDSystemInfo(cosObject: .dictionary(infoDict))
    }

    /// The default width for all CIDs.
    ///
    /// Defaults to 1000 if not specified.
    public var defaultWidth: Double {
        if let int = optionalInteger(ASAtom("DW")) {
            return Double(int)
        }
        return optionalEntry(ASAtom("DW"))?.realValue ?? 1000.0
    }

    /// The width array defining widths for CID ranges.
    ///
    /// Format: `[c1 [w1 w2 ... wn] c2 [w1 w2 ... wm] ...]` or
    ///         `[c1 c2 w ...]` for ranges with uniform width
    public var widthArray: [COSValue]? {
        optionalArray(ASAtom("W"))
    }

    /// The CIDToGIDMap for TrueType CIDFonts.
    ///
    /// Maps CIDs to glyph indices in the embedded TrueType font.
    /// Can be:
    /// - The name `/Identity` (CID = GID)
    /// - A stream containing the mapping
    public var cidToGIDMap: COSValue? {
        optionalEntry(ASAtom("CIDToGIDMap"))
    }

    /// Whether the CIDToGIDMap is the identity mapping.
    public var isIdentityCIDToGID: Bool {
        guard let map = cidToGIDMap,
              let name = map.nameValue else {
            return false
        }
        return name.stringValue == "Identity"
    }

    // MARK: - PDFFont Conformance

    /// CIDFonts do not use simple encodings.
    public var encoding: FontEncoding? {
        nil
    }

    /// Returns the width for a CID.
    ///
    /// This checks the W array first, then falls back to the default width.
    ///
    /// - Parameter code: The CID (character identifier).
    /// - Returns: The width in glyph space units.
    public func width(for code: Int) -> Double {
        // Check the width array
        if let width = widthFromArray(for: code) {
            return width
        }

        // Fall back to default width
        return defaultWidth
    }

    /// Looks up the width for a CID from the W array.
    ///
    /// - Parameter cid: The CID.
    /// - Returns: The width if found, or nil.
    private func widthFromArray(for cid: Int) -> Double? {
        guard let w = widthArray, !w.isEmpty else {
            return nil
        }

        // The W array has two formats:
        // 1. c1 [w1 w2 ... wn] - individual widths starting at c1
        // 2. c1 c2 w - uniform width for range [c1, c2]

        var i = 0
        while i < w.count {
            guard let c1 = w[i].integerValue else {
                i += 1
                continue
            }

            if i + 1 < w.count {
                // Check for format 1: array of widths
                if let widthsArray = w[i + 1].arrayValue {
                    let startCID = Int(c1)
                    for (offset, widthValue) in widthsArray.enumerated() {
                        if startCID + offset == cid {
                            if let int = widthValue.integerValue {
                                return Double(int)
                            }
                            return widthValue.realValue
                        }
                    }
                    i += 2
                    continue
                }

                // Check for format 2: range with uniform width
                if i + 2 < w.count,
                   let c2 = w[i + 1].integerValue {
                    let startCID = Int(c1)
                    let endCID = Int(c2)
                    if cid >= startCID && cid <= endCID {
                        if let int = w[i + 2].integerValue {
                            return Double(int)
                        }
                        return w[i + 2].realValue
                    }
                    i += 3
                    continue
                }
            }

            i += 1
        }

        return nil
    }
}

// MARK: - CIDSystemInfo

/// CID System Info identifying a character collection.
public struct CIDSystemInfo: PDObject {

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    /// The registry identifying the issuer of the character collection.
    ///
    /// Common values: "Adobe"
    public var registry: String? {
        optionalEntry(ASAtom("Registry"))?.textValue
    }

    /// The ordering identifying the character collection.
    ///
    /// Common values: "Japan1", "Korea1", "GB1", "CNS1", "Identity"
    public var ordering: String? {
        optionalEntry(ASAtom("Ordering"))?.textValue
    }

    /// The supplement number (version) of the character collection.
    public var supplement: Int? {
        optionalInteger(ASAtom("Supplement")).map { Int($0) }
    }

    /// The full character collection name (e.g., "Adobe-Japan1-6").
    public var fullName: String {
        let r = registry ?? "Unknown"
        let o = ordering ?? "Unknown"
        let s = supplement.map { String($0) } ?? "0"
        return "\(r)-\(o)-\(s)"
    }
}
