import Foundation

/// An input stream that concatenates multiple input streams sequentially.
///
/// `ConcatenatedInputStream` corresponds to the Java
/// `ASConcatenatedInputStream` class from veraPDF-parser. It reads from
/// the first stream until it is exhausted, then seamlessly transitions to
/// the next stream, and so on, presenting a unified sequential view of
/// all the underlying streams.
///
/// This is commonly used in PDF parsing when:
/// - Multiple content streams need to be treated as a single stream
///   (e.g., page content streams specified as an array).
/// - Stream data is fragmented across multiple sources.
///
/// ## Usage
/// ```swift
/// let stream1 = DataInputStream(data: Data([0x01, 0x02]))
/// let stream2 = DataInputStream(data: Data([0x03, 0x04]))
/// var concat = ConcatenatedInputStream(streams: [stream1, stream2])
/// let all = try concat.readAllBytes()  // Data([0x01, 0x02, 0x03, 0x04])
/// ```
///
/// ## Note on Seeking
/// `ConcatenatedInputStream` does not conform to `SeekableStream` because
/// seeking across concatenated streams with potentially unknown lengths
/// is not generally feasible. If random access is needed, read all data
/// into a `DataInputStream` first.
public struct ConcatenatedInputStream<Stream: PDFInputStream>: PDFInputStream, Sendable where Stream: Sendable {

    // MARK: - Storage

    /// The ordered list of underlying streams to read from.
    private var streams: [Stream]

    /// The index of the currently active stream.
    private var currentStreamIndex: Int

    /// The cumulative byte offset across all streams.
    private var currentPosition: Int64

    /// Whether this concatenated stream has been closed.
    private var closed: Bool

    // MARK: - Initialization

    /// Creates a concatenated stream from an array of input streams.
    ///
    /// The streams will be read in order. When one stream is exhausted,
    /// reading continues from the next.
    ///
    /// - Parameter streams: The ordered array of streams to concatenate.
    ///   May be empty, in which case all reads return end-of-stream.
    public init(streams: [Stream]) {
        self.streams = streams
        self.currentStreamIndex = 0
        self.currentPosition = 0
        self.closed = false
    }

    // MARK: - PDFInputStream

    /// The cumulative byte offset across all concatenated streams.
    public var position: Int64 {
        currentPosition
    }

    /// The total number of bytes available across all streams, if known.
    ///
    /// Returns `nil` if any stream has an unknown length.
    public var availableBytes: Int64? {
        var total: Int64 = 0
        for stream in streams {
            guard let available = stream.availableBytes else {
                return nil
            }
            total += available
        }
        return total
    }

    /// Whether this concatenated stream has been closed.
    public var isClosed: Bool {
        closed
    }

    /// The number of underlying streams in this concatenated stream.
    public var streamCount: Int {
        streams.count
    }

    /// The index of the currently active underlying stream.
    ///
    /// Returns `streams.count` if all streams have been exhausted.
    public var activeStreamIndex: Int {
        currentStreamIndex
    }

    /// Reads a single byte from the current stream, advancing to the next
    /// stream if the current one is exhausted.
    ///
    /// - Returns: The next byte, or `nil` if all streams are exhausted.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func readByte() throws -> UInt8? {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        while currentStreamIndex < streams.count {
            if let byte = try streams[currentStreamIndex].readByte() {
                currentPosition += 1
                return byte
            }
            currentStreamIndex += 1
        }
        return nil
    }

    /// Reads up to `maxLength` bytes into the buffer, reading across stream
    /// boundaries as needed.
    ///
    /// - Parameters:
    ///   - buffer: The buffer to fill with data.
    ///   - maxLength: The maximum number of bytes to read.
    /// - Returns: The actual number of bytes read, or 0 if all streams
    ///   are exhausted.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func read(_ buffer: inout [UInt8], maxLength: Int) throws -> Int {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        var totalRead = 0
        while totalRead < maxLength, currentStreamIndex < streams.count {
            var remaining = maxLength - totalRead
            var tempBuffer = [UInt8](repeating: 0, count: remaining)
            let bytesRead = try streams[currentStreamIndex].read(&tempBuffer, maxLength: remaining)
            if bytesRead > 0 {
                for i in 0..<bytesRead {
                    buffer[totalRead + i] = tempBuffer[i]
                }
                totalRead += bytesRead
                currentPosition += Int64(bytesRead)
            }
            if bytesRead == 0 || bytesRead < remaining {
                // Current stream is exhausted if we got 0 bytes
                if bytesRead == 0 {
                    currentStreamIndex += 1
                }
            }
        }
        return totalRead
    }

    /// Reads all remaining bytes from all concatenated streams.
    ///
    /// - Returns: A `Data` instance containing all remaining bytes.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func readAllBytes() throws -> Data {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        var result = Data()
        while currentStreamIndex < streams.count {
            let data = try streams[currentStreamIndex].readAllBytes()
            result.append(data)
            currentPosition += Int64(data.count)
            currentStreamIndex += 1
        }
        return result
    }

    /// Skips the specified number of bytes across stream boundaries.
    ///
    /// - Parameter count: The number of bytes to skip.
    /// - Returns: The actual number of bytes skipped.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    @discardableResult
    public mutating func skip(_ count: Int64) throws -> Int64 {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        var remaining = count
        while remaining > 0, currentStreamIndex < streams.count {
            let skipped = try streams[currentStreamIndex].skip(remaining)
            remaining -= skipped
            currentPosition += skipped
            if skipped == 0 {
                currentStreamIndex += 1
            }
        }
        return count - remaining
    }

    /// Closes all underlying streams and this concatenated stream.
    public mutating func close() {
        for i in streams.indices {
            streams[i].close()
        }
        closed = true
    }
}

// MARK: - Convenience Initializers

extension ConcatenatedInputStream where Stream == DataInputStream {

    /// Creates a concatenated stream from an array of `Data` instances.
    ///
    /// Each `Data` is wrapped in a `DataInputStream`.
    ///
    /// - Parameter dataArray: The array of data chunks to concatenate.
    public init(dataArray: [Data]) {
        self.init(streams: dataArray.map { DataInputStream(data: $0) })
    }
}
