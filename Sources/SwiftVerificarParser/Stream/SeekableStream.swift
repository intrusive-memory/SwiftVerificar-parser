import Foundation

/// A protocol that adds seeking capability to a PDF input stream.
///
/// `SeekableStream` corresponds to the Java `SeekableInputStream` interface
/// from veraPDF-parser. Types conforming to this protocol can reposition
/// their read cursor to arbitrary byte offsets within the underlying data.
///
/// This capability is essential for PDF parsing because:
/// - The cross-reference table may be at the end of the file, requiring
///   backward seeking.
/// - Object streams require random access to individual objects.
/// - Incremental updates require revisiting earlier parts of the file.
///
/// ## Conformance
/// A type conforming to `SeekableStream` must also conform to
/// `PDFInputStream`. It must implement `seek(to:)` and provide a `length`
/// property indicating the total stream size.
///
/// ## Usage
/// ```swift
/// var stream: some SeekableStream = DataInputStream(data: fileData)
/// try stream.seek(to: 0)         // Go to beginning
/// try stream.seek(to: stream.length - 5)  // Go near end
/// let byte = try stream.readByte()
/// ```
public protocol SeekableStream: PDFInputStream {

    /// The total length of the stream in bytes.
    ///
    /// This value is always known for seekable streams because random
    /// access requires knowing the bounds.
    var length: Int64 { get }

    /// Repositions the stream to the specified byte offset.
    ///
    /// The next read operation will start from this position.
    ///
    /// - Parameter position: The byte offset to seek to. Must be between
    ///   0 and `length` (inclusive). Seeking to `length` positions the
    ///   stream at the end, so the next read will return end-of-stream.
    /// - Throws: `PDFStreamError.invalidSeekPosition` if `position` is
    ///   negative or greater than `length`.
    ///   `PDFStreamError.streamClosed` if the stream is closed.
    mutating func seek(to position: Int64) throws

    /// Resets the stream position to the beginning (position 0).
    ///
    /// This is equivalent to `seek(to: 0)`.
    ///
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    mutating func reset() throws
}

// MARK: - Default Implementations

extension SeekableStream {

    /// Default implementation that seeks to position 0.
    public mutating func reset() throws {
        try seek(to: 0)
    }

    /// Skips forward by the specified number of bytes using seeking.
    ///
    /// This override of the `PDFInputStream` default implementation uses
    /// seeking for O(1) skip performance.
    ///
    /// - Parameter count: The number of bytes to skip forward.
    /// - Returns: The actual number of bytes skipped.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    @discardableResult
    public mutating func skip(_ count: Int64) throws -> Int64 {
        let newPosition = min(position + count, length)
        let actualSkipped = newPosition - position
        try seek(to: newPosition)
        return actualSkipped
    }

    /// Reads the next byte without advancing the stream position.
    ///
    /// This override uses seeking to restore the position after reading.
    ///
    /// - Returns: The next byte, or `nil` if at end of stream.
    /// - Throws: `PDFStreamError.streamClosed` if the stream is closed.
    public mutating func peek() throws -> UInt8? {
        let savedPosition = position
        let byte = try readByte()
        try seek(to: savedPosition)
        return byte
    }
}
