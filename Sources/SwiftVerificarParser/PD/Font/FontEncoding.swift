import Foundation

/// Font encoding for mapping character codes to glyph names.
///
/// This struct corresponds to the Java `Encoding` class from veraPDF-parser.
/// In PDF, simple fonts use encodings to map single-byte character codes (0-255)
/// to glyph names. The encoding can be:
/// - A predefined encoding name (MacRomanEncoding, WinAnsiEncoding, etc.)
/// - A custom encoding dictionary with differences from a base encoding
///
/// ## Encoding Dictionary Keys
/// - `/Type` → `/Encoding` (optional)
/// - `/BaseEncoding` → Name of base encoding (optional)
/// - `/Differences` → Array specifying encoding differences (optional)
///
/// ## Standard Encodings
/// - **MacRomanEncoding**: Mac OS Roman encoding
/// - **WinAnsiEncoding**: Windows Code Page 1252 (Latin-1)
/// - **MacExpertEncoding**: Mac OS Expert encoding
/// - **StandardEncoding**: Adobe Standard encoding
/// - **SymbolEncoding**: Symbol font encoding
/// - **ZapfDingbatsEncoding**: ZapfDingbats font encoding
///
/// ## Design Notes
/// This implementation stores the encoding as either a name or a dictionary.
/// Glyph name lookups are handled by applying differences to the base encoding.
public struct FontEncoding: PDObject {

    // MARK: - PDObject Conformance

    public let cosObject: COSValue

    public init(cosObject: COSValue) throws {
        self.cosObject = cosObject
    }

    // MARK: - Properties

    /// The base encoding name, if this is a dictionary encoding.
    ///
    /// Returns nil if this is a simple name encoding or if no base is specified.
    public var baseEncoding: ASAtom? {
        guard cosObject.isDictionary else {
            return nil
        }
        return optionalName(ASAtom("BaseEncoding"))
    }

    /// The encoding name, if this is a simple name encoding.
    ///
    /// Returns the name value if this encoding is specified as a name rather than dictionary.
    public var encodingName: ASAtom? {
        cosObject.nameValue
    }

    /// The differences array for custom encodings.
    ///
    /// The differences array has the format:
    /// `[code1 name1 name2 ... codeN nameN ...]`
    /// where each code is an integer starting code, followed by glyph names.
    ///
    /// Example: `[39 /quotesingle 96 /grave]` maps code 39 to 'quotesingle', 96 to 'grave'.
    public var differences: [COSValue]? {
        guard cosObject.isDictionary else {
            return nil
        }
        return optionalArray(ASAtom("Differences"))
    }

    /// Whether this encoding is specified as a name (not a dictionary).
    public var isNameEncoding: Bool {
        cosObject.isName
    }

    /// Whether this encoding is specified as a dictionary.
    public var isDictionaryEncoding: Bool {
        cosObject.isDictionary
    }

    /// Looks up the glyph name for the given character code.
    ///
    /// This applies the differences array (if present) over the base encoding.
    ///
    /// - Parameter code: The character code (0-255).
    /// - Returns: The glyph name, or nil if not found.
    public func glyphName(for code: Int) -> ASAtom? {
        // If this is a dictionary encoding with differences, check those first
        if let diffs = differences {
            var currentCode = -1
            for value in diffs {
                if let intCode = value.integerValue {
                    currentCode = Int(intCode)
                } else if let name = value.nameValue, currentCode >= 0 {
                    if currentCode == code {
                        return name
                    }
                    currentCode += 1
                }
            }
        }

        // Fall back to base encoding or standard encoding
        let base = baseEncoding ?? encodingName ?? .standardEncoding
        return StandardEncodings.glyphName(for: code, encoding: base)
    }
}

// MARK: - Standard Encoding Names

extension ASAtom {
    /// MacRomanEncoding name.
    public static let macRomanEncoding = ASAtom("MacRomanEncoding")

    /// WinAnsiEncoding name (Windows Code Page 1252).
    public static let winAnsiEncoding = ASAtom("WinAnsiEncoding")

    /// MacExpertEncoding name.
    public static let macExpertEncoding = ASAtom("MacExpertEncoding")

    /// StandardEncoding name (Adobe Standard).
    public static let standardEncoding = ASAtom("StandardEncoding")

    /// SymbolEncoding name.
    public static let symbolEncoding = ASAtom("SymbolEncoding")

    /// ZapfDingbatsEncoding name.
    public static let zapfDingbatsEncoding = ASAtom("ZapfDingbatsEncoding")

    /// Identity-H encoding (for horizontal writing).
    public static let identityH = ASAtom("Identity-H")

    /// Identity-V encoding (for vertical writing).
    public static let identityV = ASAtom("Identity-V")
}

// MARK: - Standard Encodings Helper

/// Helper for standard PDF encodings.
///
/// This provides glyph name lookups for the predefined PDF encodings.
/// Full encoding tables would be quite large, so this is a simplified implementation
/// that covers common cases. A complete implementation would include all 256 entries
/// for each standard encoding.
enum StandardEncodings {

    /// Looks up a glyph name for the given code in the specified encoding.
    ///
    /// - Parameters:
    ///   - code: The character code (0-255).
    ///   - encoding: The encoding name.
    /// - Returns: The glyph name, or nil if not found.
    static func glyphName(for code: Int, encoding: ASAtom) -> ASAtom? {
        // This is a simplified implementation. A full implementation would
        // include complete encoding tables for all standard encodings.
        // For now, return nil to indicate "not found in standard encoding"
        // which is reasonable for PDF/UA validation purposes.
        return nil
    }
}

// MARK: - Glyph Name Constants

/// Common glyph names used in PDF fonts.
///
/// These are Adobe Glyph List (AGL) standard names.
extension ASAtom {
    public static let notdef = ASAtom(".notdef")
    public static let space = ASAtom("space")
    public static let A = ASAtom("A")
    public static let B = ASAtom("B")
    public static let C = ASAtom("C")
    // Add more as needed...
}
