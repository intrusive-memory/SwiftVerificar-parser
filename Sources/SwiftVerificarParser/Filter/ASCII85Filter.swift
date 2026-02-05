import Foundation

/// A filter that encodes/decodes data using ASCII base-85 encoding.
///
/// `ASCII85Filter` corresponds to the Java `COSFilterASCII85Decode` class from
/// veraPDF-parser. It implements the `/ASCII85Decode` filter specified in PDF
/// (ISO 32000).
///
/// ASCII85 (also known as btoa) encodes 4 bytes of binary data into 5 ASCII
/// characters using base-85 representation. This is more efficient than
/// hexadecimal encoding (which uses 2 characters per byte).
///
/// ## PDF Specification
/// The encoded data:
/// - Uses characters '!' (33) through 'u' (117) representing values 0-84.
/// - Uses 'z' as a special abbreviation for four zero bytes (0x00000000).
/// - Ends with the '~>' marker.
/// - May contain whitespace anywhere (which is ignored during decoding).
///
/// ## Usage
/// ```swift
/// let filter = ASCII85Filter()
/// let decoded = try filter.decode(encodedData)
/// let encoded = try filter.encode(binaryData)
/// ```
public struct ASCII85Filter: Sendable, Hashable {

    // MARK: - Constants

    /// The base for ASCII85 encoding.
    private static let base: UInt32 = 85

    /// The ASCII value of the first encoding character ('!').
    private static let firstChar: UInt8 = 33  // '!'

    /// The ASCII value of the last encoding character ('u').
    private static let lastChar: UInt8 = 117  // 'u'

    /// The ASCII value of 'z' (special case for all zeros).
    private static let zChar: UInt8 = 122  // 'z'

    /// The end-of-data marker.
    private static let endMarker: [UInt8] = [126, 62]  // "~>"

    /// The start-of-data marker (optional in PDF, used in original btoa).
    private static let startMarker: [UInt8] = [60, 126]  // "<~"

    /// Powers of 85 for encoding/decoding.
    private static let pow85: [UInt32] = [
        85 * 85 * 85 * 85,  // 52200625
        85 * 85 * 85,       // 614125
        85 * 85,            // 7225
        85,                 // 85
        1                   // 1
    ]

    // MARK: - Initialization

    /// Creates a new ASCII85 filter.
    public init() {}

    // MARK: - Decoding

    /// Decodes ASCII85-encoded data.
    ///
    /// - Parameter data: The ASCII85-encoded data.
    /// - Returns: The decoded binary data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        var result = Data()
        var tuple: [UInt8] = []
        tuple.reserveCapacity(5)

        var foundEnd = false
        var index = data.startIndex

        // Skip optional start marker "<~"
        if data.count >= 2 &&
            data[index] == Self.startMarker[0] &&
            data[index + 1] == Self.startMarker[1] {
            index += 2
        }

        while index < data.endIndex {
            let byte = data[index]
            index += 1

            // Check for end marker "~>"
            if byte == Self.endMarker[0] {
                if index < data.endIndex && data[index] == Self.endMarker[1] {
                    foundEnd = true
                    break
                }
                // '~' alone is invalid in the middle of data
                throw PDFStreamError.filterError("ASCII85Filter: Invalid '~' character without '>' in data")
            }

            // Skip whitespace
            if isWhitespace(byte) {
                continue
            }

            // Handle 'z' (four zeros)
            if byte == Self.zChar {
                if !tuple.isEmpty {
                    throw PDFStreamError.filterError("ASCII85Filter: 'z' character in middle of group")
                }
                result.append(contentsOf: [0, 0, 0, 0])
                continue
            }

            // Regular character
            guard byte >= Self.firstChar && byte <= Self.lastChar else {
                throw PDFStreamError.filterError("ASCII85Filter: Invalid character '\(Character(UnicodeScalar(byte)))' (0x\(String(byte, radix: 16)))")
            }

            tuple.append(byte)

            if tuple.count == 5 {
                try decodeTuple(tuple, into: &result, count: 4)
                tuple.removeAll(keepingCapacity: true)
            }
        }

        // Handle partial final group
        if !tuple.isEmpty {
            // We have N chars (1-4), so we output N-1 bytes
            let originalCount = tuple.count
            // Pad with 'u' (84) to make 5 characters
            while tuple.count < 5 {
                tuple.append(Self.lastChar)
            }
            try decodeTuple(tuple, into: &result, count: originalCount - 1)
        }

        // It's okay if we didn't find the end marker (some PDFs omit it)
        _ = foundEnd

        return result
    }

    /// Decodes ASCII85-encoded data with parameters.
    ///
    /// - Parameters:
    ///   - data: The ASCII85-encoded data.
    ///   - parameters: Optional decode parameters (ignored for ASCII85).
    /// - Returns: The decoded binary data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try decode(data)
    }

    // MARK: - Encoding

    /// Encodes binary data using ASCII85 encoding.
    ///
    /// - Parameter data: The binary data to encode.
    /// - Returns: The ASCII85-encoded data (without start marker, with end marker).
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data(Self.endMarker)
        }

        var result = Data()
        result.reserveCapacity((data.count * 5) / 4 + 10)

        var index = data.startIndex

        while index < data.endIndex {
            let remaining = data.endIndex - index

            if remaining >= 4 {
                // Full 4-byte group
                let b0 = UInt32(data[index])
                let b1 = UInt32(data[index + 1])
                let b2 = UInt32(data[index + 2])
                let b3 = UInt32(data[index + 3])
                let value = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3

                if value == 0 {
                    // Special case: four zeros become 'z'
                    result.append(Self.zChar)
                } else {
                    encodeTuple(value, into: &result, count: 5)
                }
                index += 4
            } else {
                // Partial final group (1-3 bytes)
                var value: UInt32 = 0
                let count = remaining

                for i in 0..<count {
                    value |= UInt32(data[index + i]) << (24 - i * 8)
                }

                // Encode and output only count+1 characters
                encodeTuple(value, into: &result, count: count + 1)
                index += count
            }
        }

        // Append end marker
        result.append(contentsOf: Self.endMarker)

        return result
    }

    /// Encodes binary data with parameters.
    ///
    /// - Parameters:
    ///   - data: The binary data to encode.
    ///   - parameters: Optional encode parameters (ignored for ASCII85).
    /// - Returns: The ASCII85-encoded data.
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try encode(data)
    }

    // MARK: - Private Helpers

    /// Decodes a 5-character tuple into binary bytes.
    private func decodeTuple(_ tuple: [UInt8], into result: inout Data, count: Int) throws {
        var value: UInt32 = 0

        for i in 0..<5 {
            let digit = UInt32(tuple[i] - Self.firstChar)
            value += digit * Self.pow85[i]
        }

        // Extract bytes (big-endian)
        if count >= 1 { result.append(UInt8((value >> 24) & 0xFF)) }
        if count >= 2 { result.append(UInt8((value >> 16) & 0xFF)) }
        if count >= 3 { result.append(UInt8((value >> 8) & 0xFF)) }
        if count >= 4 { result.append(UInt8(value & 0xFF)) }
    }

    /// Encodes a 32-bit value into ASCII85 characters.
    private func encodeTuple(_ value: UInt32, into result: inout Data, count: Int) {
        var chars: [UInt8] = [0, 0, 0, 0, 0]
        var v = value

        // Convert to base-85 (least significant digit first)
        for i in stride(from: 4, through: 0, by: -1) {
            chars[i] = UInt8(v % UInt32(Self.base)) + Self.firstChar
            v /= UInt32(Self.base)
        }

        // Output only the requested number of characters
        for i in 0..<count {
            result.append(chars[i])
        }
    }

    /// Returns true if the byte is a whitespace character that should be ignored.
    private func isWhitespace(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x09, 0x0A, 0x0C, 0x0D, 0x20:  // HT, LF, FF, CR, Space
            return true
        default:
            return false
        }
    }
}
