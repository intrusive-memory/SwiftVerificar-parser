import Foundation

/// A filter that encodes/decodes data using ASCII hexadecimal encoding.
///
/// `ASCIIHexFilter` corresponds to the Java `COSFilterASCIIHexDecode` class from
/// veraPDF-parser. It implements the `/ASCIIHexDecode` filter specified in PDF
/// (ISO 32000).
///
/// ASCII hexadecimal encoding represents each byte as two hexadecimal digits
/// (0-9, A-F, a-f). This doubles the data size but produces printable ASCII output.
///
/// ## PDF Specification
/// The encoded data:
/// - Uses characters 0-9, A-F (or a-f) for hexadecimal digits.
/// - Ends with the '>' character (0x3E).
/// - May contain whitespace anywhere (which is ignored during decoding).
/// - If the final byte has only one hex digit, a trailing zero is assumed.
///
/// ## Usage
/// ```swift
/// let filter = ASCIIHexFilter()
/// let decoded = try filter.decode(encodedData)
/// let encoded = try filter.encode(binaryData)
/// ```
public struct ASCIIHexFilter: Sendable, Hashable {

    // MARK: - Constants

    /// The end-of-data marker.
    private static let endMarker: UInt8 = 0x3E  // '>'

    /// Hex digit characters for encoding (uppercase).
    private static let hexChars: [UInt8] = [
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,  // 0-7
        0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46   // 8-9, A-F
    ]

    // MARK: - Initialization

    /// Creates a new ASCII hex filter.
    public init() {}

    // MARK: - Decoding

    /// Decodes ASCII hex-encoded data.
    ///
    /// - Parameter data: The ASCII hex-encoded data.
    /// - Returns: The decoded binary data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        var result = Data()
        result.reserveCapacity(data.count / 2)

        var highNibble: UInt8?
        var foundEnd = false

        for byte in data {
            // Check for end marker
            if byte == Self.endMarker {
                foundEnd = true
                break
            }

            // Skip whitespace
            if isWhitespace(byte) {
                continue
            }

            // Get hex digit value
            guard let nibble = hexValue(of: byte) else {
                throw PDFStreamError.filterError("ASCIIHexFilter: Invalid hex character '\(Character(UnicodeScalar(byte)))' (0x\(String(byte, radix: 16)))")
            }

            if let high = highNibble {
                // Second nibble - combine and output byte
                result.append((high << 4) | nibble)
                highNibble = nil
            } else {
                // First nibble - store for next iteration
                highNibble = nibble
            }
        }

        // Handle trailing single hex digit (assume zero for low nibble)
        if let high = highNibble {
            result.append(high << 4)
        }

        // It's okay if we didn't find the end marker (some PDFs omit it)
        _ = foundEnd

        return result
    }

    /// Decodes ASCII hex-encoded data with parameters.
    ///
    /// - Parameters:
    ///   - data: The ASCII hex-encoded data.
    ///   - parameters: Optional decode parameters (ignored for ASCII hex).
    /// - Returns: The decoded binary data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try decode(data)
    }

    // MARK: - Encoding

    /// Encodes binary data using ASCII hexadecimal encoding.
    ///
    /// - Parameter data: The binary data to encode.
    /// - Returns: The ASCII hex-encoded data (with end marker).
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data) throws -> Data {
        var result = Data()
        result.reserveCapacity(data.count * 2 + 1)

        for byte in data {
            let highNibble = Int((byte >> 4) & 0x0F)
            let lowNibble = Int(byte & 0x0F)
            result.append(Self.hexChars[highNibble])
            result.append(Self.hexChars[lowNibble])
        }

        // Append end marker
        result.append(Self.endMarker)

        return result
    }

    /// Encodes binary data with parameters.
    ///
    /// - Parameters:
    ///   - data: The binary data to encode.
    ///   - parameters: Optional encode parameters (ignored for ASCII hex).
    /// - Returns: The ASCII hex-encoded data.
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try encode(data)
    }

    // MARK: - Private Helpers

    /// Returns the numeric value of a hexadecimal digit character.
    ///
    /// - Parameter byte: The ASCII byte to convert.
    /// - Returns: The hex value (0-15), or `nil` if not a valid hex digit.
    private func hexValue(of byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39:  // '0'-'9'
            return byte - 0x30
        case 0x41...0x46:  // 'A'-'F'
            return byte - 0x41 + 10
        case 0x61...0x66:  // 'a'-'f'
            return byte - 0x61 + 10
        default:
            return nil
        }
    }

    /// Returns true if the byte is a whitespace character that should be ignored.
    private func isWhitespace(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x00,  // NUL (PDF spec allows NUL as whitespace)
             0x09,  // HT (horizontal tab)
             0x0A,  // LF (line feed)
             0x0C,  // FF (form feed)
             0x0D,  // CR (carriage return)
             0x20:  // Space
            return true
        default:
            return false
        }
    }
}
