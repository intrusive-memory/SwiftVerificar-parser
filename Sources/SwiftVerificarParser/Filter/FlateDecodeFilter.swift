import Foundation
import Compression

/// A filter that decompresses/compresses data using the Flate (zlib/deflate) algorithm.
///
/// `FlateDecodeFilter` corresponds to the Java `COSFilterFlateDecode` class from
/// veraPDF-parser. It implements the `/FlateDecode` filter specified in PDF
/// (ISO 32000). This filter uses the zlib compression format defined in RFC 1950.
///
/// This implementation uses Apple's `Compression` framework for hardware-accelerated
/// compression/decompression when available.
///
/// ## PDF Specification
/// The FlateDecode filter decodes data encoded using the zlib/deflate compression
/// method. The `/DecodeParms` dictionary may contain:
/// - `/Predictor` -- Predictor function (1=none, 2=TIFF, 10-15=PNG)
/// - `/Colors` -- Number of color components per sample (default: 1)
/// - `/BitsPerComponent` -- Bits per component (default: 8)
/// - `/Columns` -- Number of samples per row (default: 1)
///
/// ## Usage
/// ```swift
/// let filter = FlateDecodeFilter()
/// let decompressed = try filter.decode(compressedData)
/// let compressed = try filter.encode(rawData)
/// ```
///
/// ## Note on Predictors
/// Predictor processing is handled separately by `PredictorFilter`. When decoding
/// a stream with predictors, first apply `FlateDecodeFilter`, then apply
/// `PredictorFilter` if the `/Predictor` parameter is greater than 1.
public struct FlateDecodeFilter: Sendable, Hashable {

    // MARK: - Constants

    /// The default buffer size for compression/decompression operations.
    private static let bufferSize = 65536

    // MARK: - Initialization

    /// Creates a new Flate decode filter.
    public init() {}

    // MARK: - Decoding

    /// Decodes (decompresses) data using the zlib/deflate algorithm.
    ///
    /// - Parameter data: The compressed data to decode.
    /// - Returns: The decompressed data.
    /// - Throws: `PDFStreamError.filterError` if decompression fails.
    public func decode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        // Use compression_decode_buffer for zlib decompression
        // The data includes zlib header (2 bytes) and Adler-32 checksum (4 bytes)
        return try decompressZlib(data)
    }

    /// Decodes data with the given decode parameters.
    ///
    /// - Parameters:
    ///   - data: The compressed data to decode.
    ///   - parameters: Optional decode parameters (ignored; predictor handling is separate).
    /// - Returns: The decompressed data.
    /// - Throws: `PDFStreamError.filterError` if decompression fails.
    public func decode(_ data: Data, parameters: COSValue?) throws -> Data {
        // Note: Predictor parameters are handled by PredictorFilter, not here.
        // The DefaultFilterFactory will chain filters appropriately.
        return try decode(data)
    }

    // MARK: - Encoding

    /// Encodes (compresses) data using the zlib/deflate algorithm.
    ///
    /// - Parameter data: The raw data to compress.
    /// - Returns: The compressed data.
    /// - Throws: `PDFStreamError.filterError` if compression fails.
    public func encode(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        return try compressZlib(data)
    }

    /// Encodes data with the given encode parameters.
    ///
    /// - Parameters:
    ///   - data: The raw data to compress.
    ///   - parameters: Optional encode parameters (ignored for compression).
    /// - Returns: The compressed data.
    /// - Throws: `PDFStreamError.filterError` if compression fails.
    public func encode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try encode(data)
    }

    // MARK: - Private Implementation

    /// Decompresses zlib-formatted data using the Compression framework.
    private func decompressZlib(_ data: Data) throws -> Data {
        // The Compression framework's COMPRESSION_ZLIB algorithm expects raw deflate data
        // without the zlib header. PDF FlateDecode uses raw deflate.
        //
        // However, some PDFs include the zlib header (0x78 0x9C for default compression).
        // We need to handle both cases.

        let sourceData: Data
        if data.count >= 2 {
            let firstByte = data[data.startIndex]
            let secondByte = data[data.startIndex + 1]

            // Check for zlib header: first byte is typically 0x78
            // (CMF = 8 for deflate, CINFO = 7 for 32K window)
            // Second byte's lower nibble combined with first byte must be divisible by 31
            if firstByte == 0x78 && ((Int(firstByte) * 256 + Int(secondByte)) % 31 == 0) {
                // Strip the 2-byte zlib header
                // Also strip the 4-byte Adler-32 checksum at the end if present
                let headerSize = 2
                let checksumSize = 4
                if data.count > headerSize + checksumSize {
                    sourceData = data.dropFirst(headerSize).dropLast(checksumSize)
                } else if data.count > headerSize {
                    sourceData = data.dropFirst(headerSize)
                } else {
                    sourceData = data
                }
            } else {
                // Raw deflate data (no zlib header)
                sourceData = data
            }
        } else {
            sourceData = data
        }

        return try decompressDeflate(sourceData)
    }

    /// Decompresses raw deflate data.
    private func decompressDeflate(_ data: Data) throws -> Data {
        var result = Data()
        let bufferSize = Self.bufferSize

        try data.withUnsafeBytes { sourceBuffer in
            guard let sourcePointer = sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw PDFStreamError.filterError("FlateDecodeFilter: Unable to access source data")
            }

            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { destinationBuffer.deallocate() }

            let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
            defer { streamPtr.deallocate() }

            var status = compression_stream_init(
                streamPtr,
                COMPRESSION_STREAM_DECODE,
                COMPRESSION_ZLIB
            )

            guard status == COMPRESSION_STATUS_OK else {
                throw PDFStreamError.filterError("FlateDecodeFilter: Failed to initialize decompression stream")
            }

            defer { compression_stream_destroy(streamPtr) }

            streamPtr.pointee.src_ptr = sourcePointer
            streamPtr.pointee.src_size = data.count
            streamPtr.pointee.dst_ptr = destinationBuffer
            streamPtr.pointee.dst_size = bufferSize

            repeat {
                status = compression_stream_process(streamPtr, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))

                switch status {
                case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                    let outputCount = bufferSize - streamPtr.pointee.dst_size
                    if outputCount > 0 {
                        result.append(destinationBuffer, count: outputCount)
                    }
                    streamPtr.pointee.dst_ptr = destinationBuffer
                    streamPtr.pointee.dst_size = bufferSize

                case COMPRESSION_STATUS_ERROR:
                    throw PDFStreamError.filterError("FlateDecodeFilter: Decompression error")

                default:
                    break
                }
            } while status == COMPRESSION_STATUS_OK

            if status != COMPRESSION_STATUS_END && streamPtr.pointee.src_size > 0 {
                // Some data was not processed; this might be okay for truncated streams
                // but we should report it as an error for strict compliance
                throw PDFStreamError.filterError("FlateDecodeFilter: Incomplete decompression - \(streamPtr.pointee.src_size) bytes remaining")
            }
        }

        return result
    }

    /// Compresses data using zlib deflate.
    private func compressZlib(_ data: Data) throws -> Data {
        var result = Data()
        let bufferSize = Self.bufferSize

        try data.withUnsafeBytes { sourceBuffer in
            guard let sourcePointer = sourceBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw PDFStreamError.filterError("FlateDecodeFilter: Unable to access source data")
            }

            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { destinationBuffer.deallocate() }

            let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
            defer { streamPtr.deallocate() }

            var status = compression_stream_init(
                streamPtr,
                COMPRESSION_STREAM_ENCODE,
                COMPRESSION_ZLIB
            )

            guard status == COMPRESSION_STATUS_OK else {
                throw PDFStreamError.filterError("FlateDecodeFilter: Failed to initialize compression stream")
            }

            defer { compression_stream_destroy(streamPtr) }

            streamPtr.pointee.src_ptr = sourcePointer
            streamPtr.pointee.src_size = data.count
            streamPtr.pointee.dst_ptr = destinationBuffer
            streamPtr.pointee.dst_size = bufferSize

            repeat {
                status = compression_stream_process(streamPtr, Int32(COMPRESSION_STREAM_FINALIZE.rawValue))

                switch status {
                case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                    let outputCount = bufferSize - streamPtr.pointee.dst_size
                    if outputCount > 0 {
                        result.append(destinationBuffer, count: outputCount)
                    }
                    streamPtr.pointee.dst_ptr = destinationBuffer
                    streamPtr.pointee.dst_size = bufferSize

                case COMPRESSION_STATUS_ERROR:
                    throw PDFStreamError.filterError("FlateDecodeFilter: Compression error")

                default:
                    break
                }
            } while status == COMPRESSION_STATUS_OK
        }

        return result
    }
}
