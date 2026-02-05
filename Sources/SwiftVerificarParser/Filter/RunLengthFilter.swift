import Foundation

/// A filter that encodes/decodes data using run-length encoding.
///
/// `RunLengthFilter` corresponds to the Java `RunLengthDecode` class from
/// veraPDF-parser. It implements the `/RunLengthDecode` filter specified in PDF
/// (ISO 32000).
///
/// Run-length encoding compresses sequences of identical bytes (runs) by storing
/// the byte value and a count. It works well for data with many repeated bytes
/// (like simple images) but can actually increase the size of random data.
///
/// ## PDF Specification
/// The format uses a length byte followed by data:
/// - Length 0-127: Copy the following (length + 1) bytes literally.
/// - Length 129-255: Repeat the following byte (257 - length) times.
/// - Length 128 (0x80): End of data marker.
///
/// ## Usage
/// ```swift
/// let filter = RunLengthFilter()
/// let decoded = try filter.decode(encodedData)
/// let encoded = try filter.encode(rawData)
/// ```
public struct RunLengthFilter: Sendable, Hashable {

    // MARK: - Constants

    /// End of data marker.
    private static let eodMarker: UInt8 = 128

    /// Maximum literal run length.
    private static let maxLiteralRun = 128

    /// Maximum repeat count.
    private static let maxRepeatCount = 128

    // MARK: - Initialization

    /// Creates a new run-length filter.
    public init() {}

    // MARK: - Decoding

    /// Decodes run-length encoded data.
    ///
    /// - Parameter data: The run-length encoded data.
    /// - Returns: The decoded data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        var result = Data()
        var index = data.startIndex

        while index < data.endIndex {
            let length = data[index]
            index += 1

            if length == Self.eodMarker {
                // End of data
                break
            } else if length < 128 {
                // Literal run: copy (length + 1) bytes
                let copyCount = Int(length) + 1

                guard index + copyCount <= data.endIndex else {
                    throw PDFStreamError.filterError("RunLengthFilter: Unexpected end of data during literal run")
                }

                result.append(contentsOf: data[index..<(index + copyCount)])
                index += copyCount
            } else {
                // Repeat run: repeat next byte (257 - length) times
                let repeatCount = 257 - Int(length)

                guard index < data.endIndex else {
                    throw PDFStreamError.filterError("RunLengthFilter: Unexpected end of data during repeat run")
                }

                let repeatByte = data[index]
                index += 1

                result.append(contentsOf: [UInt8](repeating: repeatByte, count: repeatCount))
            }
        }

        return result
    }

    /// Decodes run-length encoded data with parameters.
    ///
    /// - Parameters:
    ///   - data: The run-length encoded data.
    ///   - parameters: Optional decode parameters (ignored for run-length).
    /// - Returns: The decoded data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try decode(data)
    }

    // MARK: - Encoding

    /// Encodes data using run-length encoding.
    ///
    /// - Parameter data: The raw data to encode.
    /// - Returns: The run-length encoded data.
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data([Self.eodMarker])
        }

        var result = Data()
        var index = data.startIndex

        while index < data.endIndex {
            // Look ahead to find runs
            let currentByte = data[index]
            var runLength = 1

            // Count consecutive identical bytes
            while index + runLength < data.endIndex &&
                    runLength < Self.maxRepeatCount &&
                    data[index + runLength] == currentByte {
                runLength += 1
            }

            if runLength >= 3 {
                // Worth encoding as a repeat run (3+ bytes become 2 bytes)
                result.append(UInt8(257 - runLength))
                result.append(currentByte)
                index += runLength
            } else {
                // Collect literal bytes (non-repeating or short runs)
                let literalStart = index
                var literalCount = 0

                while index < data.endIndex && literalCount < Self.maxLiteralRun {
                    // Check if we should switch to a repeat run
                    let byte = data[index]
                    var repeatAhead = 1

                    while index + repeatAhead < data.endIndex &&
                            repeatAhead < 3 &&
                            data[index + repeatAhead] == byte {
                        repeatAhead += 1
                    }

                    if repeatAhead >= 3 {
                        // Found a good repeat run, stop literal collection
                        break
                    }

                    literalCount += 1
                    index += 1
                }

                if literalCount > 0 {
                    result.append(UInt8(literalCount - 1))
                    result.append(contentsOf: data[literalStart..<(literalStart + literalCount)])
                }
            }
        }

        // Append end of data marker
        result.append(Self.eodMarker)

        return result
    }

    /// Encodes data with parameters.
    ///
    /// - Parameters:
    ///   - data: The raw data to encode.
    ///   - parameters: Optional encode parameters (ignored for run-length).
    /// - Returns: The run-length encoded data.
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try encode(data)
    }
}
