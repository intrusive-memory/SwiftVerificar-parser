import Foundation

/// Protocol for simple PDF fonts (Type1, TrueType, Type3).
///
/// This protocol corresponds to the Java `PDSimpleFont` abstract class from veraPDF-parser.
/// Simple fonts use single-byte character codes (0-255) and have an encoding that maps
/// codes to glyph names.
///
/// ## Simple Font Types
/// - **Type1**: PostScript Type 1 fonts
/// - **TrueType**: TrueType fonts
/// - **Type3**: User-defined fonts with glyph descriptions as PDF content streams
///
/// ## Common Dictionary Keys
/// - `/Type` → `/Font` (required)
/// - `/Subtype` → `/Type1`, `/TrueType`, or `/Type3` (required)
/// - `/BaseFont` → Font name (required)
/// - `/FirstChar` → First character code in Widths array (required except Type3)
/// - `/LastChar` → Last character code in Widths array (required except Type3)
/// - `/Widths` → Array of glyph widths (required except Type3)
/// - `/FontDescriptor` → Font descriptor (required for embedded fonts)
/// - `/Encoding` → Encoding (optional, defaults vary by font type)
/// - `/ToUnicode` → Unicode mapping CMap (optional)
public protocol SimpleFont: PDFFont {

    /// The first character code defined in the Widths array.
    var firstChar: Int? { get }

    /// The last character code defined in the Widths array.
    var lastChar: Int? { get }

    /// Array of glyph widths for character codes from firstChar to lastChar.
    ///
    /// The array has (lastChar - firstChar + 1) entries.
    var widths: [Double]? { get }

    /// Returns the width for a character code using the Widths array.
    ///
    /// - Parameter code: The character code (0-255).
    /// - Returns: The width in glyph space units, or the default width if not found.
    func widthFromWidthsArray(for code: Int) -> Double?
}

// MARK: - Default Implementations

extension SimpleFont {

    public var firstChar: Int? {
        optionalInteger(ASAtom("FirstChar")).map { Int($0) }
    }

    public var lastChar: Int? {
        optionalInteger(ASAtom("LastChar")).map { Int($0) }
    }

    public var widths: [Double]? {
        guard let widthsArray = optionalArray(ASAtom("Widths")) else {
            return nil
        }
        return widthsArray.compactMap { value -> Double? in
            if let int = value.integerValue {
                return Double(int)
            }
            return value.realValue
        }
    }

    public func widthFromWidthsArray(for code: Int) -> Double? {
        guard let first = firstChar,
              let last = lastChar,
              let widthsArray = widths,
              code >= first,
              code <= last else {
            return nil
        }

        let index = code - first
        guard index >= 0 && index < widthsArray.count else {
            return nil
        }

        return widthsArray[index]
    }

    public var isComposite: Bool {
        false  // Simple fonts are never composite
    }

    public func width(for code: Int) -> Double {
        // Try widths array first
        if let width = widthFromWidthsArray(for: code) {
            return width
        }

        // Fall back to font descriptor's missing width
        if let missingWidth = fontDescriptor?.missingWidth {
            return missingWidth
        }

        // Final fallback
        return 250.0
    }
}
