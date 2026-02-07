import Foundation

/// Represents a PDF string object, storing raw bytes and encoding information.
///
/// PDF strings come in two flavors:
/// - **Literal strings**: Enclosed in parentheses `(Hello World)`
/// - **Hex strings**: Enclosed in angle brackets `<48656C6C6F>`
///
/// `COSString` preserves the raw byte representation and tracks whether the
/// string was originally hex-encoded. It provides methods to decode the bytes
/// as text using PDFDocEncoding or UTF-16BE (as per the PDF specification).
///
/// This type consolidates the Java `COSString` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let literal = COSString(data: Data("Hello".utf8), isHex: false)
/// let hex = COSString(hexString: "48656C6C6F")
/// ```
public struct COSString: Sendable, Hashable, Codable, CustomStringConvertible {

    // MARK: - Properties

    /// The raw bytes of the string.
    public let data: Data

    /// Whether this string was originally encoded as a hex string.
    public let isHex: Bool

    // MARK: - Initialization

    /// Creates a `COSString` from raw data bytes.
    ///
    /// - Parameters:
    ///   - data: The raw bytes of the string.
    ///   - isHex: Whether this string uses hex encoding. Defaults to `false`.
    public init(data: Data, isHex: Bool = false) {
        self.data = data
        self.isHex = isHex
    }

    /// Creates a `COSString` from a Swift string using UTF-8 encoding.
    ///
    /// - Parameters:
    ///   - string: The string value to encode.
    ///   - isHex: Whether this string should be treated as hex-encoded. Defaults to `false`.
    public init(string: String, isHex: Bool = false) {
        self.data = Data(string.utf8)
        self.isHex = isHex
    }

    /// Creates a `COSString` from a hex-encoded string.
    ///
    /// Each pair of hex digits represents one byte. If the hex string has an odd
    /// number of characters, a trailing `0` is assumed (per PDF specification).
    ///
    /// - Parameter hexString: A string of hex digit characters (0-9, a-f, A-F).
    ///   Whitespace is ignored.
    /// - Returns: `nil` if the hex string contains invalid characters.
    public init?(hexString: String) {
        // Remove whitespace
        let cleaned = hexString.filter { !$0.isWhitespace }

        // Pad odd-length strings with trailing 0
        let padded = cleaned.count.isMultiple(of: 2) ? cleaned : cleaned + "0"

        var bytes = Data()
        bytes.reserveCapacity(padded.count / 2)

        var index = padded.startIndex
        while index < padded.endIndex {
            let nextIndex = padded.index(index, offsetBy: 2)
            let byteString = padded[index..<nextIndex]

            guard let byte = UInt8(byteString, radix: 16) else {
                return nil
            }
            bytes.append(byte)
            index = nextIndex
        }

        self.data = bytes
        self.isHex = true
    }

    // MARK: - Text Decoding

    /// Decodes the string bytes as text.
    ///
    /// Per the PDF specification, strings are decoded as follows:
    /// 1. If the bytes begin with a UTF-16BE BOM (0xFE 0xFF), decode as UTF-16BE.
    /// 2. If the bytes begin with a UTF-8 BOM (0xEF 0xBB 0xBF), decode as UTF-8.
    /// 3. Otherwise, decode as PDFDocEncoding (a superset of ISO Latin-1 for
    ///    bytes 0x00-0xFF).
    ///
    /// - Returns: The decoded string, or `nil` if decoding fails.
    public var stringValue: String? {
        if hasUTF16BOM {
            return decodeUTF16BE()
        } else if hasUTF8BOM {
            return decodeUTF8(skipBOM: true)
        } else {
            return decodePDFDocEncoding()
        }
    }

    /// Whether the data starts with a UTF-16BE Byte Order Mark (0xFE 0xFF).
    public var hasUTF16BOM: Bool {
        data.count >= 2 && data[data.startIndex] == 0xFE && data[data.startIndex + 1] == 0xFF
    }

    /// Whether the data starts with a UTF-8 Byte Order Mark (0xEF 0xBB 0xBF).
    public var hasUTF8BOM: Bool {
        data.count >= 3
            && data[data.startIndex] == 0xEF
            && data[data.startIndex + 1] == 0xBB
            && data[data.startIndex + 2] == 0xBF
    }

    /// The number of bytes in the string.
    public var count: Int {
        data.count
    }

    /// Whether the string is empty.
    public var isEmpty: Bool {
        data.isEmpty
    }

    // MARK: - Hex Encoding

    /// Returns the hex-encoded representation of the string bytes.
    ///
    /// - Parameter uppercase: Whether to use uppercase hex digits. Defaults to `false`.
    /// - Returns: A string of hex digits representing the raw bytes.
    public func hexEncoded(uppercase: Bool = false) -> String {
        data.map { String(format: uppercase ? "%02X" : "%02x", $0) }.joined()
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        if isHex {
            return "<\(hexEncoded())>"
        } else {
            return "(\(stringValue ?? data.map { String(format: "\\%03o", $0) }.joined()))"
        }
    }

    // MARK: - Private Helpers

    /// Decodes the data as UTF-16BE, skipping the BOM if present.
    private func decodeUTF16BE() -> String? {
        let startOffset = hasUTF16BOM ? 2 : 0
        let relevantData = data.dropFirst(startOffset)

        // UTF-16BE requires an even number of bytes
        guard relevantData.count.isMultiple(of: 2) else { return nil }

        var utf16Units: [UInt16] = []
        utf16Units.reserveCapacity(relevantData.count / 2)

        var iterator = relevantData.makeIterator()
        while let high = iterator.next(), let low = iterator.next() {
            utf16Units.append(UInt16(high) << 8 | UInt16(low))
        }

        return String(utf16CodeUnits: utf16Units, count: utf16Units.count)
    }

    /// Decodes the data as UTF-8, optionally skipping the BOM.
    private func decodeUTF8(skipBOM: Bool) -> String? {
        let startOffset = skipBOM && hasUTF8BOM ? 3 : 0
        let relevantData = data.dropFirst(startOffset)
        return String(data: Data(relevantData), encoding: .utf8)
    }

    /// Decodes the data using PDFDocEncoding.
    ///
    /// PDFDocEncoding is identical to ISO Latin-1 (ISO 8859-1) for byte values
    /// 0x20-0x7E and 0xA1-0xFF. Bytes 0x80-0x9F have special mappings to
    /// Unicode code points. Bytes 0x00-0x1F are mostly control characters,
    /// with some mapped to Unicode.
    private func decodePDFDocEncoding() -> String? {
        var result = ""
        result.reserveCapacity(data.count)

        for byte in data {
            if let scalar = Self.pdfDocEncodingToUnicode(byte) {
                result.append(Character(scalar))
            } else {
                // Undefined bytes map to Unicode replacement character
                result.append("\u{FFFD}")
            }
        }

        return result
    }

    /// Maps a PDFDocEncoding byte to its Unicode scalar value.
    ///
    /// - Parameter byte: The byte value to map.
    /// - Returns: The corresponding Unicode scalar, or `nil` if the byte is undefined.
    private static func pdfDocEncodingToUnicode(_ byte: UInt8) -> Unicode.Scalar? {
        // 0x00-0x07: Mostly undefined or control
        // 0x08: BS (backspace)
        // 0x09: HT (tab)
        // 0x0A: LF (line feed)
        // 0x0B: VT
        // 0x0C: FF (form feed)
        // 0x0D: CR (carriage return)
        // 0x0E-0x0F: undefined
        // 0x10-0x17: undefined
        // 0x18-0x1F: special mappings
        // 0x20-0x7E: ASCII
        // 0x7F: undefined
        // 0x80-0x9F: special mappings
        // 0xA0: non-breaking space (U+00A0) - but note: 0xAD is special
        // 0xA1-0xFF: same as ISO Latin-1

        switch byte {
        // Standard ASCII range
        case 0x08: return Unicode.Scalar(0x0008)  // BS
        case 0x09: return Unicode.Scalar(0x0009)  // HT
        case 0x0A: return Unicode.Scalar(0x000A)  // LF
        case 0x0B: return Unicode.Scalar(0x000B)  // VT
        case 0x0C: return Unicode.Scalar(0x000C)  // FF
        case 0x0D: return Unicode.Scalar(0x000D)  // CR

        // PDFDocEncoding special mappings (0x18-0x1F)
        case 0x18: return Unicode.Scalar(0x02D8)  // BREVE
        case 0x19: return Unicode.Scalar(0x02C7)  // CARON
        case 0x1A: return Unicode.Scalar(0x02C6)  // MODIFIER LETTER CIRCUMFLEX ACCENT
        case 0x1B: return Unicode.Scalar(0x02D9)  // DOT ABOVE
        case 0x1C: return Unicode.Scalar(0x02DD)  // DOUBLE ACUTE ACCENT
        case 0x1D: return Unicode.Scalar(0x02DB)  // OGONEK
        case 0x1E: return Unicode.Scalar(0x02DA)  // RING ABOVE
        case 0x1F: return Unicode.Scalar(0x02DC)  // SMALL TILDE

        // Standard ASCII printable range (0x20-0x7E)
        case 0x20...0x7E: return Unicode.Scalar(UInt32(byte))

        // PDFDocEncoding special mappings (0x80-0x9F)
        case 0x80: return Unicode.Scalar(0x2022)  // BULLET
        case 0x81: return Unicode.Scalar(0x2020)  // DAGGER
        case 0x82: return Unicode.Scalar(0x2021)  // DOUBLE DAGGER
        case 0x83: return Unicode.Scalar(0x2026)  // HORIZONTAL ELLIPSIS
        case 0x84: return Unicode.Scalar(0x2014)  // EM DASH
        case 0x85: return Unicode.Scalar(0x2013)  // EN DASH
        case 0x86: return Unicode.Scalar(0x0192)  // LATIN SMALL LETTER F WITH HOOK
        case 0x87: return Unicode.Scalar(0x2044)  // FRACTION SLASH
        case 0x88: return Unicode.Scalar(0x2039)  // SINGLE LEFT-POINTING ANGLE QUOTATION MARK
        case 0x89: return Unicode.Scalar(0x203A)  // SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
        case 0x8A: return Unicode.Scalar(0x2212)  // MINUS SIGN
        case 0x8B: return Unicode.Scalar(0x2030)  // PER MILLE SIGN
        case 0x8C: return Unicode.Scalar(0x201E)  // DOUBLE LOW-9 QUOTATION MARK
        case 0x8D: return Unicode.Scalar(0x201C)  // LEFT DOUBLE QUOTATION MARK
        case 0x8E: return Unicode.Scalar(0x201D)  // RIGHT DOUBLE QUOTATION MARK
        case 0x8F: return Unicode.Scalar(0x2018)  // LEFT SINGLE QUOTATION MARK
        case 0x90: return Unicode.Scalar(0x2019)  // RIGHT SINGLE QUOTATION MARK
        case 0x91: return Unicode.Scalar(0x201A)  // SINGLE LOW-9 QUOTATION MARK
        case 0x92: return Unicode.Scalar(0x2122)  // TRADE MARK SIGN
        case 0x93: return Unicode.Scalar(0xFB01)  // LATIN SMALL LIGATURE FI
        case 0x94: return Unicode.Scalar(0xFB02)  // LATIN SMALL LIGATURE FL
        case 0x95: return Unicode.Scalar(0x0141)  // LATIN CAPITAL LETTER L WITH STROKE
        case 0x96: return Unicode.Scalar(0x0152)  // LATIN CAPITAL LIGATURE OE
        case 0x97: return Unicode.Scalar(0x0160)  // LATIN CAPITAL LETTER S WITH CARON
        case 0x98: return Unicode.Scalar(0x0178)  // LATIN CAPITAL LETTER Y WITH DIAERESIS
        case 0x99: return Unicode.Scalar(0x017D)  // LATIN CAPITAL LETTER Z WITH CARON
        case 0x9A: return Unicode.Scalar(0x0131)  // LATIN SMALL LETTER DOTLESS I
        case 0x9B: return Unicode.Scalar(0x0142)  // LATIN SMALL LETTER L WITH STROKE
        case 0x9C: return Unicode.Scalar(0x0153)  // LATIN SMALL LIGATURE OE
        case 0x9D: return Unicode.Scalar(0x0161)  // LATIN SMALL LETTER S WITH CARON
        case 0x9E: return Unicode.Scalar(0x017E)  // LATIN SMALL LETTER Z WITH CARON
        case 0xA0...0xFF: return Unicode.Scalar(UInt32(byte))  // ISO Latin-1
        case 0xAD: return Unicode.Scalar(0x00AD)  // SOFT HYPHEN (same mapping)

        default:
            // Undefined code points (0x00-0x07, 0x0E-0x17, 0x7F, 0x9F)
            return nil
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension COSString: ExpressibleByStringLiteral {
    /// Creates a `COSString` from a string literal using UTF-8 encoding.
    public init(stringLiteral value: String) {
        self.init(string: value)
    }
}

// MARK: - Empty Constant

extension COSString {
    /// An empty `COSString` with no data.
    public static let empty = COSString(data: Data())
}
