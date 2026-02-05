import Foundation

/// Errors that can occur during PDF stream I/O operations.
///
/// This error type consolidates I/O-related exceptions from the Java
/// `ASInputStream` and `ASOutputStream` class hierarchy into a single
/// Swift error enum.
public enum PDFStreamError: Error, Sendable, Hashable, CustomStringConvertible {
    /// The stream has been closed and cannot be read from or written to.
    case streamClosed

    /// An attempt was made to read past the end of the stream.
    case endOfStream

    /// An attempt was made to seek to an invalid position.
    ///
    /// - Parameter position: The invalid position that was requested.
    case invalidSeekPosition(Int64)

    /// The stream does not support the requested operation.
    ///
    /// - Parameter operation: A description of the unsupported operation.
    case unsupportedOperation(String)

    /// A general I/O error occurred.
    ///
    /// - Parameter message: A description of the error.
    case ioError(String)

    /// An unknown or unrecognized filter name was encountered.
    ///
    /// - Parameter name: The unrecognized filter name.
    case unknownFilter(String)

    /// A filter decoding or encoding operation failed.
    ///
    /// - Parameter message: A description of the failure.
    case filterError(String)

    public var description: String {
        switch self {
        case .streamClosed:
            return "Stream is closed"
        case .endOfStream:
            return "End of stream reached"
        case .invalidSeekPosition(let pos):
            return "Invalid seek position: \(pos)"
        case .unsupportedOperation(let op):
            return "Unsupported operation: \(op)"
        case .ioError(let msg):
            return "I/O error: \(msg)"
        case .unknownFilter(let name):
            return "Unknown filter: \(name)"
        case .filterError(let msg):
            return "Filter error: \(msg)"
        }
    }
}

/// An asynchronous protocol for reading PDF data from a stream.
///
/// `PDFInputStream` corresponds to the Java `ASInputStream` abstract class
/// from veraPDF-parser. It provides an async interface for reading bytes
/// from a PDF data source (file, memory, network, etc.).
///
/// The protocol supports:
/// - Reading individual bytes or buffers of bytes.
/// - Tracking the current read position.
/// - Querying the total number of available bytes.
/// - Closing the stream to release resources.
///
/// Implementations must be `Sendable` for safe use in concurrent contexts.
///
/// ## Usage
/// ```swift
/// var stream: some PDFInputStream = DataInputStream(data: someData)
/// let byte = try stream.readByte()
/// var buffer = [UInt8](repeating: 0, count: 1024)
/// let bytesRead = try stream.read(&buffer, maxLength: 1024)
/// ```
///
/// ## Conformance
/// Implement `readByte()` and `read(_:maxLength:)` at minimum. Default
/// implementations are provided for `readAllBytes()`, `skip(_:)`, and
/// `peek()`.
public protocol PDFInputStream: Sendable {

    /// The current byte offset within the stream.
    ///
    /// Starts at 0 and advances with each read operation. For seekable
    /// streams, this may also be set via seeking.
    var position: Int64 { get }

    /// The total number of bytes available in the stream, if known.
    ///
    /// Returns `nil` if the total length is not known in advance
    /// (e.g., for network streams or concatenated streams whose
    /// inner streams have unknown lengths).
    var availableBytes: Int64? { get }

    /// Whether the stream has been closed.
    var isClosed: Bool { get }

    /// Reads a single byte from the stream.
    ///
    /// - Returns: The next byte, or `nil` if the end of stream has been reached.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func readByte() throws -> UInt8?

    /// Reads up to `maxLength` bytes into the provided buffer.
    ///
    /// - Parameters:
    ///   - buffer: The buffer to fill with data. Must have at least
    ///     `maxLength` capacity.
    ///   - maxLength: The maximum number of bytes to read.
    /// - Returns: The actual number of bytes read, or 0 if the end of stream
    ///   has been reached.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func read(_ buffer: inout [UInt8], maxLength: Int) throws -> Int

    /// Reads all remaining bytes from the stream.
    ///
    /// - Returns: A `Data` instance containing all remaining bytes.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func readAllBytes() throws -> Data

    /// Skips over the specified number of bytes in the stream.
    ///
    /// If fewer bytes remain than `count`, skips to the end of the stream.
    ///
    /// - Parameter count: The number of bytes to skip.
    /// - Returns: The actual number of bytes skipped.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    @discardableResult
    mutating func skip(_ count: Int64) throws -> Int64

    /// Reads the next byte without advancing the stream position.
    ///
    /// - Returns: The next byte, or `nil` if the end of stream has been reached.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func peek() throws -> UInt8?

    /// Closes the stream, releasing any associated resources.
    ///
    /// After calling `close()`, any further read operations will throw
    /// `PDFStreamError.streamClosed`.
    mutating func close()
}

// MARK: - Default Implementations

extension PDFInputStream {

    /// Default implementation that reads all remaining bytes by repeatedly
    /// calling `read(_:maxLength:)`.
    public mutating func readAllBytes() throws -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let bytesRead = try read(&buffer, maxLength: buffer.count)
            if bytesRead == 0 {
                break
            }
            result.append(contentsOf: buffer[0..<bytesRead])
        }
        return result
    }

    /// Default implementation that skips bytes by reading and discarding them.
    @discardableResult
    public mutating func skip(_ count: Int64) throws -> Int64 {
        var remaining = count
        var buffer = [UInt8](repeating: 0, count: min(Int(count), 4096))
        while remaining > 0 {
            let toRead = min(Int(remaining), buffer.count)
            let bytesRead = try read(&buffer, maxLength: toRead)
            if bytesRead == 0 {
                break
            }
            remaining -= Int64(bytesRead)
        }
        return count - remaining
    }

    /// Default implementation that reads a byte and then seeks back.
    ///
    /// For streams that do not support seeking, this default implementation
    /// returns `nil` (indicating peek is not supported without seeking).
    /// Concrete types should override this if they can support peeking.
    public mutating func peek() throws -> UInt8? {
        // Default: not supported without seeking capability.
        // Concrete types like DataInputStream override this.
        return nil
    }
}
