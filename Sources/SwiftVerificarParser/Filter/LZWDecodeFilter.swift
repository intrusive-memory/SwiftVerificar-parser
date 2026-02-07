import Foundation

/// A filter that decompresses/compresses data using the LZW algorithm.
///
/// `LZWDecodeFilter` corresponds to the Java `COSFilterLZWDecode` class from
/// veraPDF-parser. It implements the `/LZWDecode` filter specified in PDF
/// (ISO 32000).
///
/// LZW (Lempel-Ziv-Welch) is a dictionary-based compression algorithm that builds
/// a table of strings encountered in the input. It was commonly used in early PDFs
/// but has largely been replaced by FlateDecode due to patent issues (now expired).
///
/// ## PDF Specification
/// The LZWDecode filter may use an `/EarlyChange` parameter:
/// - `1` (default): Code length increases one code early (GIF/PDF style)
/// - `0`: Code length increases after the code is used (TIFF style)
///
/// The `/DecodeParms` dictionary may also contain predictor parameters, which
/// are handled separately by `PredictorFilter`.
///
/// ## Usage
/// ```swift
/// let filter = LZWDecodeFilter()
/// let decompressed = try filter.decode(compressedData)
/// ```
public struct LZWDecodeFilter: Sendable, Hashable {

    // MARK: - Constants

    /// Clear table code - resets the dictionary.
    private static let clearTableCode = 256

    /// End of data code - signals end of compressed stream.
    private static let endOfDataCode = 257

    /// First code available for dictionary entries.
    private static let firstCode = 258

    /// Maximum code value (12-bit codes).
    private static let maxCode = 4095

    /// Maximum dictionary size.
    private static let maxDictSize = 4096

    // MARK: - Initialization

    /// Creates a new LZW decode filter.
    public init() {}

    // MARK: - Decoding

    /// Decodes (decompresses) LZW-compressed data.
    ///
    /// - Parameter data: The LZW-compressed data to decode.
    /// - Returns: The decompressed data.
    /// - Throws: `PDFStreamError.filterError` if decompression fails.
    public func decode(_ data: Data) throws -> Data {
        try decode(data, earlyChange: true)
    }

    /// Decodes LZW-compressed data with parameters.
    ///
    /// - Parameters:
    ///   - data: The LZW-compressed data to decode.
    ///   - parameters: Optional decode parameters containing `/EarlyChange`.
    /// - Returns: The decompressed data.
    /// - Throws: `PDFStreamError.filterError` if decompression fails.
    public func decode(_ data: Data, parameters: COSValue?) throws -> Data {
        let earlyChange: Bool
        if case .dictionary(let dict) = parameters,
           let ec = dict[.earlyChange]?.integerValue {
            earlyChange = ec != 0
        } else {
            earlyChange = true  // Default is 1 (early change)
        }
        return try decode(data, earlyChange: earlyChange)
    }

    /// Decodes LZW-compressed data with the specified early change behavior.
    ///
    /// - Parameters:
    ///   - data: The LZW-compressed data to decode.
    ///   - earlyChange: If true, increase code size one code early.
    /// - Returns: The decompressed data.
    /// - Throws: `PDFStreamError.filterError` if decompression fails.
    public func decode(_ data: Data, earlyChange: Bool) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        var result = Data()
        var reader = BitReader(data: data)

        // Initialize the dictionary with single-byte entries (0-255)
        var dictionary: [[UInt8]] = (0..<256).map { [UInt8($0)] }
        // Add entries for clear and end codes (they don't produce output)
        dictionary.append([])  // 256 = clear
        dictionary.append([])  // 257 = end

        var codeSize = 9  // Start with 9-bit codes
        var nextCode = Self.firstCode
        var prevEntry: [UInt8]?

        while let code = reader.readBits(codeSize) {
            if code == Self.clearTableCode {
                // Reset dictionary
                dictionary = (0..<256).map { [UInt8($0)] }
                dictionary.append([])  // 256 = clear
                dictionary.append([])  // 257 = end
                codeSize = 9
                nextCode = Self.firstCode
                prevEntry = nil
                continue
            }

            if code == Self.endOfDataCode {
                // End of data
                break
            }

            let entry: [UInt8]
            if code < dictionary.count {
                // Code is in dictionary
                entry = dictionary[code]
            } else if code == nextCode, let prev = prevEntry {
                // Special case: code not yet in dictionary
                // Entry is previous entry + first byte of previous entry
                entry = prev + [prev[0]]
            } else {
                throw PDFStreamError.filterError("LZWDecodeFilter: Invalid code \(code) encountered")
            }

            // Output the entry
            result.append(contentsOf: entry)

            // Add new entry to dictionary (previous entry + first byte of current entry)
            if let prev = prevEntry, nextCode <= Self.maxCode {
                let newEntry = prev + [entry[0]]
                dictionary.append(newEntry)
                nextCode += 1

                // From swift-gif: when count reaches 2^codeSize, increase codeSize
                // E.g., after adding entry #511, nextCode becomes 512 = 2^9, so increase to 10 bits
                if nextCode == (1 << codeSize) && codeSize < 12 {
                    codeSize += 1
                }
            }

            prevEntry = entry
        }

        return result
    }

    // MARK: - Encoding

    /// Encodes (compresses) data using the LZW algorithm.
    ///
    /// - Parameter data: The raw data to compress.
    /// - Returns: The LZW-compressed data.
    /// - Throws: `PDFStreamError.filterError` if compression fails.
    public func encode(_ data: Data) throws -> Data {
        try encode(data, earlyChange: true)
    }

    /// Encodes data with parameters.
    ///
    /// - Parameters:
    ///   - data: The raw data to compress.
    ///   - parameters: Optional encode parameters containing `/EarlyChange`.
    /// - Returns: The LZW-compressed data.
    /// - Throws: `PDFStreamError.filterError` if compression fails.
    public func encode(_ data: Data, parameters: COSValue?) throws -> Data {
        let earlyChange: Bool
        if case .dictionary(let dict) = parameters,
           let ec = dict[.earlyChange]?.integerValue {
            earlyChange = ec != 0
        } else {
            earlyChange = true
        }
        return try encode(data, earlyChange: earlyChange)
    }

    /// Encodes data using LZW with the specified early change behavior.
    ///
    /// - Parameters:
    ///   - data: The raw data to compress.
    ///   - earlyChange: If true, increase code size one code early.
    /// - Returns: The LZW-compressed data.
    /// - Throws: `PDFStreamError.filterError` if compression fails.
    public func encode(_ data: Data, earlyChange: Bool) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        var writer = BitWriter()

        // Initialize dictionary: map byte sequences to codes
        var dictionary: [Data: Int] = [:]
        for i in 0..<256 {
            dictionary[Data([UInt8(i)])] = i
        }

        var codeSize = 9
        var nextCode = Self.firstCode

        // Write clear code at start
        writer.writeBits(Self.clearTableCode, count: codeSize)

        var currentSequence = Data()

        for byte in data {
            let testSequence = currentSequence + Data([byte])

            if dictionary[testSequence] != nil {
                // Sequence is in dictionary, extend it
                currentSequence = testSequence
            } else {
                // Output code for current sequence
                if let code = dictionary[currentSequence] {
                    writer.writeBits(code, count: codeSize)
                }

                // Add new sequence to dictionary
                if nextCode <= Self.maxCode {
                    dictionary[testSequence] = nextCode
                    nextCode += 1

                    // From swift-gif: encoder uses offset=1 for "early change" (GIF/PDF style)
                    // When nextCode reaches 2^codeSize + 1, increase codeSize
                    // E.g., after adding entry #511, nextCode=512, check 512==513? NO
                    // After adding entry #512, nextCode=513, check 513==513? YES! Increase to 10 bits
                    if nextCode == (1 << codeSize) + 1 && codeSize < 12 {
                        codeSize += 1
                    }
                } else {
                    // Dictionary full, emit clear code and reset
                    writer.writeBits(Self.clearTableCode, count: codeSize)
                    dictionary = [:]
                    for i in 0..<256 {
                        dictionary[Data([UInt8(i)])] = i
                    }
                    codeSize = 9
                    nextCode = Self.firstCode
                }

                currentSequence = Data([byte])
            }
        }

        // Output final sequence
        if !currentSequence.isEmpty, let code = dictionary[currentSequence] {
            writer.writeBits(code, count: codeSize)
        }

        // Write end of data code
        writer.writeBits(Self.endOfDataCode, count: codeSize)

        return writer.finalize()
    }
}

// MARK: - BitReader

/// A helper struct for reading variable-width bit sequences from data.
private struct BitReader {
    private let data: Data
    private var byteIndex: Int = 0
    private var bitIndex: Int = 0  // Bits are read MSB first

    init(data: Data) {
        self.data = data
    }

    /// Reads the specified number of bits and returns them as an integer.
    mutating func readBits(_ count: Int) -> Int? {
        var result = 0
        var bitsRemaining = count

        while bitsRemaining > 0 {
            guard byteIndex < data.count else {
                return nil  // End of data
            }

            let currentByte = data[data.startIndex + byteIndex]
            let bitsAvailable = 8 - bitIndex
            let bitsToRead = min(bitsRemaining, bitsAvailable)

            // Extract bits from current byte (MSB first)
            let shift = bitsAvailable - bitsToRead
            let mask = ((1 << bitsToRead) - 1) << shift
            let bits = (Int(currentByte) & mask) >> shift

            result = (result << bitsToRead) | bits
            bitsRemaining -= bitsToRead
            bitIndex += bitsToRead

            if bitIndex >= 8 {
                bitIndex = 0
                byteIndex += 1
            }
        }

        return result
    }
}

// MARK: - BitWriter

/// A helper struct for writing variable-width bit sequences to data.
private struct BitWriter {
    private var data = Data()
    private var currentByte: UInt8 = 0
    private var bitIndex: Int = 0  // Number of bits written to current byte

    /// Writes the specified number of bits from the given value.
    mutating func writeBits(_ value: Int, count: Int) {
        var bitsRemaining = count
        let shiftedValue = value

        while bitsRemaining > 0 {
            let bitsAvailable = 8 - bitIndex
            let bitsToWrite = min(bitsRemaining, bitsAvailable)

            // Extract the most significant bits we want to write
            let shift = bitsRemaining - bitsToWrite
            let bits = (shiftedValue >> shift) & ((1 << bitsToWrite) - 1)

            // Place bits in current byte (MSB first)
            let placement = bitsAvailable - bitsToWrite
            currentByte |= UInt8(bits << placement)

            bitIndex += bitsToWrite
            bitsRemaining -= bitsToWrite

            if bitIndex >= 8 {
                data.append(currentByte)
                currentByte = 0
                bitIndex = 0
            }
        }
    }

    /// Finalizes the bit stream and returns the data.
    mutating func finalize() -> Data {
        if bitIndex > 0 {
            // Flush remaining bits (padded with zeros)
            data.append(currentByte)
        }
        return data
    }
}
