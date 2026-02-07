import Foundation

/// An asynchronous protocol for writing PDF data to a stream.
///
/// `PDFOutputStream` corresponds to the Java `ASOutputStream` abstract class
/// from veraPDF-parser. It provides an interface for writing bytes to a PDF
/// data destination (file, memory buffer, network, etc.).
///
/// The protocol supports:
/// - Writing individual bytes or buffers of bytes.
/// - Tracking the current write position (total bytes written).
/// - Flushing buffered data to the underlying destination.
/// - Closing the stream to release resources.
///
/// Implementations must be `Sendable` for safe use in concurrent contexts.
///
/// ## Usage
/// ```swift
/// var stream: some PDFOutputStream = DataOutputStream()
/// try stream.writeByte(0x25)  // '%'
/// try stream.write([0x50, 0x44, 0x46])  // "PDF"
/// try stream.flush()
/// stream.close()
/// ```
public protocol PDFOutputStream: Sendable {

    /// The total number of bytes written to this stream so far.
    var bytesWritten: Int64 { get }

    /// Whether the stream has been closed.
    var isClosed: Bool { get }

    /// Writes a single byte to the stream.
    ///
    /// - Parameter byte: The byte value to write.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func writeByte(_ byte: UInt8) throws

    /// Writes a sequence of bytes to the stream.
    ///
    /// - Parameter bytes: The bytes to write.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func write(_ bytes: [UInt8]) throws

    /// Writes a portion of a byte buffer to the stream.
    ///
    /// - Parameters:
    ///   - bytes: The byte buffer to write from.
    ///   - offset: The starting offset in the buffer.
    ///   - length: The number of bytes to write.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func write(_ bytes: [UInt8], offset: Int, length: Int) throws

    /// Writes the contents of a `Data` instance to the stream.
    ///
    /// - Parameter data: The data to write.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func write(_ data: Data) throws

    /// Flushes any buffered data to the underlying destination.
    ///
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func flush() throws

    /// Closes the stream, flushing any remaining data and releasing resources.
    ///
    /// After calling `close()`, any further write operations will throw
    /// `PDFStreamError.streamClosed`.
    mutating func close()
}

// MARK: - Default Implementations

extension PDFOutputStream {

    /// Default implementation that writes each byte individually.
    public mutating func write(_ bytes: [UInt8]) throws {
        for byte in bytes {
            try writeByte(byte)
        }
    }

    /// Default implementation that writes a slice of the buffer.
    public mutating func write(_ bytes: [UInt8], offset: Int, length: Int) throws {
        let slice = Array(bytes[offset..<(offset + length)])
        try write(slice)
    }

    /// Default implementation that converts `Data` to an array and writes it.
    public mutating func write(_ data: Data) throws {
        try write(Array(data))
    }

    /// Default implementation that does nothing (no buffering by default).
    public mutating func flush() throws {
        guard !isClosed else {
            throw PDFStreamError.streamClosed
        }
    }
}

// MARK: - DataOutputStream

/// An in-memory output stream that collects written bytes into a `Data` buffer.
///
/// This struct is the write counterpart of `DataInputStream`. It buffers all
/// written bytes in memory and provides access to the accumulated data via
/// the `data` property.
///
/// ## Usage
/// ```swift
/// var output = DataOutputStream()
/// try output.writeByte(0x25)
/// try output.write([0x50, 0x44, 0x46])
/// let result = output.data  // Data containing [0x25, 0x50, 0x44, 0x46]
/// ```
public struct DataOutputStream: PDFOutputStream, Sendable {

    // MARK: - Storage

    /// The accumulated output data.
    private var buffer: Data

    /// Whether this stream has been closed.
    private var closed: Bool

    // MARK: - Initialization

    /// Creates a new empty output stream.
    ///
    /// - Parameter capacity: An optional initial capacity hint for the buffer.
    ///   Defaults to 0.
    public init(capacity: Int = 0) {
        self.buffer = Data()
        if capacity > 0 {
            self.buffer.reserveCapacity(capacity)
        }
        self.closed = false
    }

    // MARK: - PDFOutputStream

    /// The total number of bytes written so far.
    public var bytesWritten: Int64 {
        Int64(buffer.count)
    }

    /// Whether the stream has been closed.
    public var isClosed: Bool {
        closed
    }

    /// The accumulated output data.
    ///
    /// This property is available even after the stream is closed.
    public var data: Data {
        buffer
    }

    /// Writes a single byte to the buffer.
    public mutating func writeByte(_ byte: UInt8) throws {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        buffer.append(byte)
    }

    /// Writes an array of bytes to the buffer.
    public mutating func write(_ bytes: [UInt8]) throws {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        buffer.append(contentsOf: bytes)
    }

    /// Writes a slice of a byte buffer to the stream.
    public mutating func write(_ bytes: [UInt8], offset: Int, length: Int) throws {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        buffer.append(contentsOf: bytes[offset..<(offset + length)])
    }

    /// Writes the contents of a `Data` instance to the buffer.
    public mutating func write(_ data: Data) throws {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        buffer.append(data)
    }

    /// Flushes the output stream. For in-memory streams, this is a no-op.
    public mutating func flush() throws {
        guard !closed else {
            throw PDFStreamError.streamClosed
        }
        // No-op for in-memory buffer
    }

    /// Closes the output stream.
    public mutating func close() {
        closed = true
    }

    /// Resets the output stream, clearing all buffered data and reopening
    /// the stream if it was closed.
    public mutating func reset() {
        buffer = Data()
        closed = false
    }
}
