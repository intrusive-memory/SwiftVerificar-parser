import Foundation

/// An in-memory input stream that reads from a `Data` buffer.
///
/// `DataInputStream` corresponds to the Java `ASMemoryInStream` class from
/// veraPDF-parser. It wraps a `Data` instance and provides the `PDFInputStream`
/// and `SeekableStream` protocols for sequential and random-access reading.
///
/// This is the primary way to create an input stream from in-memory data,
/// such as decoded stream content, embedded resources, or test data.
///
/// ## Usage
/// ```swift
/// let data = Data([0x25, 0x50, 0x44, 0x46])
/// var stream = DataInputStream(data: data)
/// let byte = try stream.readByte()  // 0x25
/// try stream.seek(to: 2)
/// let byte2 = try stream.readByte()  // 0x44
/// ```
public struct DataInputStream: PDFInputStream, SeekableStream, Sendable {

    // MARK: - Storage

    /// The underlying data buffer.
    private let data: Data

    /// The current read position within the data buffer.
    private var currentPosition: Int

    /// Whether this stream has been closed.
    private var closed: Bool

    // MARK: - Initialization

    /// Creates a new input stream wrapping the given data.
    ///
    /// - Parameter data: The data to read from. The stream starts at position 0.
    public init(data: Data) {
        self.data = data
        self.currentPosition = 0
        self.closed = false
    }

    /// Creates a new input stream from a byte array.
    ///
    /// - Parameter bytes: The bytes to read from.
    public init(bytes: [UInt8]) {
        self.init(data: Data(bytes))
    }

    // MARK: - PDFInputStream

    /// The current byte offset within the data buffer.
    public var position: Int64 {
        Int64(currentPosition)
    }

    /// The total number of bytes in the data buffer.
    public var availableBytes: Int64? {
        Int64(data.count)
    }

    /// The number of bytes remaining from the current position to the end.
    public var remainingBytes: Int {
        max(0, data.count - currentPosition)
    }

    /// Whether the stream has been closed.
    public var isClosed: Bool {
        closed
    }

    /// Whether the current position is at or past the end of the data.
    public var isAtEnd: Bool {
        currentPosition >= data.count
    }

    /// Reads a single byte from the data buffer.
    ///
    /// - Returns: The next byte, or `nil` if the end of data has been reached.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func readByte() throws -> UInt8? {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        guard currentPosition < data.count else {
            return nil
        }
        let byte = data[data.startIndex + currentPosition]
        currentPosition += 1
        return byte
    }

    /// Reads up to `maxLength` bytes into the provided buffer.
    ///
    /// - Parameters:
    ///   - buffer: The buffer to fill with data.
    ///   - maxLength: The maximum number of bytes to read.
    /// - Returns: The actual number of bytes read, or 0 if at the end of data.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func read(_ buffer: inout [UInt8], maxLength: Int) throws -> Int {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        guard currentPosition < data.count else {
            return 0
        }
        let bytesToRead = min(maxLength, data.count - currentPosition)
        let startIndex = data.startIndex + currentPosition
        let endIndex = startIndex + bytesToRead
        data.copyBytes(to: &buffer, from: startIndex..<endIndex)
        currentPosition += bytesToRead
        return bytesToRead
    }

    /// Reads all remaining bytes from the current position.
    ///
    /// - Returns: A `Data` instance containing all remaining bytes.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func readAllBytes() throws -> Data {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        guard currentPosition < data.count else {
            return Data()
        }
        let startIndex = data.startIndex + currentPosition
        let result = data[startIndex...]
        currentPosition = data.count
        return Data(result)
    }

    /// Skips over the specified number of bytes.
    ///
    /// - Parameter count: The number of bytes to skip.
    /// - Returns: The actual number of bytes skipped.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    @discardableResult
    public mutating func skip(_ count: Int64) throws -> Int64 {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        let bytesToSkip = min(Int(count), data.count - currentPosition)
        let actualSkipped = max(0, bytesToSkip)
        currentPosition += actualSkipped
        return Int64(actualSkipped)
    }

    /// Reads the next byte without advancing the stream position.
    ///
    /// - Returns: The next byte, or `nil` if the end of data has been reached.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func peek() throws -> UInt8? {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        guard currentPosition < data.count else {
            return nil
        }
        return data[data.startIndex + currentPosition]
    }

    /// Closes the stream.
    public mutating func close() {
        closed = true
    }

    // MARK: - SeekableStream

    /// The total length of the underlying data.
    public var length: Int64 {
        Int64(data.count)
    }

    /// Seeks to the specified byte position within the data buffer.
    ///
    /// - Parameter position: The byte offset to seek to. Must be between
    ///   0 and the data length (inclusive).
    /// - Throws: `PDFStreamError.invalidSeekPosition` if the position is
    ///   out of range. `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func seek(to position: Int64) throws {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        guard position >= 0, position <= Int64(data.count) else {
            throw PDFStreamError.invalidSeekPosition(position)
        }
        currentPosition = Int(position)
    }

    /// Resets the stream position to the beginning.
    ///
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func reset() throws {
        try seek(to: 0)
    }
}
