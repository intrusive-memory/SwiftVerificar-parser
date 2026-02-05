import Foundation

/// Represents a PDF content stream.
///
/// Content streams contain sequences of PDF operators and operands that describe
/// the graphics and text to be painted on a page or in a form XObject.
///
/// This type corresponds to the Java `PDContentStream` class from veraPDF-parser.
///
/// ## PDF Specification
/// Content streams can appear in several contexts:
/// - As the `/Contents` entry of a page dictionary (single stream or array of streams)
/// - As the stream data of a form XObject
/// - As the glyph description of a Type 3 font
/// - As the appearance stream of an annotation
///
/// ## Usage
/// ```swift
/// let contentStream = try PDFContentStream(cosObject: contentsValue)
/// let streamData = try contentStream.streamData()
/// ```
public struct PDFContentStream: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS object for this content stream.
    ///
    /// This can be either:
    /// - A single stream object (`.reference` pointing to a stream, or embedded stream data)
    /// - An array of stream objects (for pages with multiple content streams)
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a content stream from a COS object.
    ///
    /// - Parameter cosObject: The COS object (can be a reference, array, or dictionary).
    /// - Throws: `PDError` if the object cannot be interpreted as a content stream.
    public init(cosObject: COSValue) throws {
        // Content streams can be:
        // 1. A reference to a stream object
        // 2. An array of references to stream objects
        // 3. A stream dictionary directly (rare, but allowed)
        // We store the COS object as-is and handle resolution later
        self.cosObject = cosObject
    }

    // MARK: - Content Stream Properties

    /// Whether this content stream is a single stream or an array of streams.
    public var isArray: Bool {
        cosObject.isArray
    }

    /// Whether this content stream is a single stream reference.
    public var isReference: Bool {
        cosObject.isReference
    }

    /// Whether this content stream is a dictionary (stream with inline data).
    public var isDictionary: Bool {
        cosObject.isDictionary
    }

    /// Returns the number of stream objects.
    ///
    /// - Returns: 1 for a single stream, or the array length for multiple streams.
    public var streamCount: Int {
        if cosObject.isArray {
            return cosObject.count ?? 0
        }
        return 1
    }

    /// Returns the stream at the specified index.
    ///
    /// - Parameter index: The zero-based stream index.
    /// - Returns: The COSValue for the stream (typically a reference).
    /// - Throws: `PDError` if the index is out of bounds.
    public func stream(at index: Int) throws -> COSValue {
        if cosObject.isArray {
            guard let streams = cosObject.arrayValue, streams.indices.contains(index) else {
                throw PDError.pageIndexOutOfBounds(index: index, count: streamCount)
            }
            return streams[index]
        } else if index == 0 {
            return cosObject
        } else {
            throw PDError.pageIndexOutOfBounds(index: index, count: 1)
        }
    }

    /// Returns all stream references as an array.
    ///
    /// - Returns: An array of COSValues representing the streams.
    public func allStreams() -> [COSValue] {
        if let streams = cosObject.arrayValue {
            return streams
        }
        return [cosObject]
    }

    // MARK: - Stream Data Access

    /// Returns the raw stream data for a single stream.
    ///
    /// This method is only valid when the content stream is a single stream object.
    /// For arrays of streams, use `allStreams()` to access individual streams.
    ///
    /// - Returns: The stream data as `Data`.
    /// - Throws: `PDError.invalidDocument` if this is an array of streams,
    ///   or if the stream data cannot be accessed.
    ///
    /// - Note: This method returns the underlying COS object and does not decode
    ///   the stream data. Use `COSStream` or a content stream parser to decode.
    public func singleStreamObject() throws -> COSValue {
        guard !isArray else {
            throw PDError.invalidDocument(reason: "Content stream is an array; use allStreams() instead")
        }
        return cosObject
    }

    // MARK: - Convenience Accessors

    /// Whether this content stream is empty.
    ///
    /// - Returns: `true` if the stream count is zero, `false` otherwise.
    public var isEmpty: Bool {
        streamCount == 0
    }
}
