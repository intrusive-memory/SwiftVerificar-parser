import Foundation

/// The name of a PDF stream filter, used to identify decode/encode algorithms.
///
/// This enum provides type-safe access to the standard PDF filter names
/// defined in the PDF specification (ISO 32000). Each case corresponds
/// to a `/Filter` value that can appear in a stream dictionary.
public enum PDFFilterName: Sendable, Hashable, CustomStringConvertible {

    /// Flate (zlib/deflate) compression (`/FlateDecode`).
    case flateDecode

    /// LZW compression (`/LZWDecode`).
    case lzwDecode

    /// ASCII base-85 encoding (`/ASCII85Decode`).
    case ascii85Decode

    /// ASCII hexadecimal encoding (`/ASCIIHexDecode`).
    case asciiHexDecode

    /// Run-length encoding (`/RunLengthDecode`).
    case runLengthDecode

    /// DCT (JPEG) compression (`/DCTDecode`).
    case dctDecode

    /// JPEG 2000 compression (`/JPXDecode`).
    case jpxDecode

    /// CCITT facsimile compression (`/CCITTFaxDecode`).
    case ccittFaxDecode

    /// Crypt filter (`/Crypt`).
    case crypt

    /// A custom or non-standard filter name.
    ///
    /// - Parameter name: The raw filter name string.
    case custom(String)

    // MARK: - Initialization from ASAtom

    /// Creates a filter name from an `ASAtom`.
    ///
    /// - Parameter atom: The atom representing the filter name.
    public init(atom: ASAtom) {
        switch atom {
        case .flateDecode:
            self = .flateDecode
        case .lzwDecode:
            self = .lzwDecode
        case .ascii85Decode:
            self = .ascii85Decode
        case .asciiHexDecode:
            self = .asciiHexDecode
        case .runLengthDecode:
            self = .runLengthDecode
        case .dctDecode:
            self = .dctDecode
        case .jpxDecode:
            self = .jpxDecode
        case .ccittFaxDecode:
            self = .ccittFaxDecode
        case .crypt:
            self = .crypt
        default:
            self = .custom(atom.stringValue)
        }
    }

    /// Returns the corresponding `ASAtom` for this filter name.
    public var atom: ASAtom {
        switch self {
        case .flateDecode: return .flateDecode
        case .lzwDecode: return .lzwDecode
        case .ascii85Decode: return .ascii85Decode
        case .asciiHexDecode: return .asciiHexDecode
        case .runLengthDecode: return .runLengthDecode
        case .dctDecode: return .dctDecode
        case .jpxDecode: return .jpxDecode
        case .ccittFaxDecode: return .ccittFaxDecode
        case .crypt: return .crypt
        case .custom(let name): return ASAtom(name)
        }
    }

    public var description: String {
        atom.stringValue
    }
}

/// A protocol for creating PDF stream decode and encode filters.
///
/// `PDFFilterFactory` corresponds to the Java `IASFilterFactory` interface
/// from veraPDF-parser. Implementations create filter objects that can
/// decode (decompress/decrypt) or encode (compress/encrypt) PDF stream data.
///
/// The factory pattern allows for pluggable filter implementations. The
/// `DefaultFilterFactory` provides the standard PDF filters, while custom
/// factories can add support for proprietary or extended filters.
///
/// ## Usage
/// ```swift
/// let factory: some PDFFilterFactory = DefaultFilterFactory()
/// let decoded = try factory.decode(
///     data: compressedData,
///     filterName: .flateDecode,
///     parameters: nil
/// )
/// ```
///
/// ## Thread Safety
/// Implementations must be `Sendable`. Stateless factories (like
/// `DefaultFilterFactory`) are inherently thread-safe. Stateful factories
/// should use actors or other synchronization mechanisms.
public protocol PDFFilterFactory: Sendable {

    /// Decodes (decompresses/decrypts) data using the specified filter.
    ///
    /// - Parameters:
    ///   - data: The encoded data to decode.
    ///   - filterName: The name of the filter to apply.
    ///   - parameters: Optional decode parameters from the stream's
    ///     `/DecodeParms` entry. May be `nil` if no parameters are specified.
    /// - Returns: The decoded data.
    /// - Throws: `PDFStreamError.unknownFilter` if the filter is not supported.
    ///   `PDFStreamError.filterError` if decoding fails.
    func decode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data

    /// Encodes (compresses/encrypts) data using the specified filter.
    ///
    /// - Parameters:
    ///   - data: The raw data to encode.
    ///   - filterName: The name of the filter to apply.
    ///   - parameters: Optional encode parameters.
    /// - Returns: The encoded data.
    /// - Throws: `PDFStreamError.unknownFilter` if the filter is not supported.
    ///   `PDFStreamError.filterError` if encoding fails.
    func encode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data

    /// Returns whether this factory supports the given filter.
    ///
    /// - Parameter filterName: The filter name to check.
    /// - Returns: `true` if this factory can decode/encode with the given filter.
    func supportsFilter(_ filterName: PDFFilterName) -> Bool

    /// Decodes data through a pipeline of filters.
    ///
    /// Filters are applied in order (first filter in the array is applied first).
    /// This matches the PDF specification: the `/Filter` array lists filters
    /// in the order they were applied during encoding, so decoding applies
    /// them in the same order.
    ///
    /// - Parameters:
    ///   - data: The encoded data.
    ///   - filters: The ordered array of filter names to apply.
    ///   - parameterSets: Optional array of decode parameters, one per filter.
    ///     May be `nil` or shorter than `filters`; missing parameters default
    ///     to `nil`.
    /// - Returns: The fully decoded data.
    /// - Throws: `PDFStreamError` if any filter application fails.
    func decodePipeline(data: Data, filters: [PDFFilterName], parameterSets: [COSValue?]?) throws -> Data
}

// MARK: - Default Pipeline Implementation

extension PDFFilterFactory {

    /// Default implementation that applies each filter sequentially.
    public func decodePipeline(data: Data, filters: [PDFFilterName], parameterSets: [COSValue?]?) throws -> Data {
        var result = data
        for (index, filterName) in filters.enumerated() {
            let params: COSValue? = parameterSets.flatMap { index < $0.count ? $0[index] : nil }
            result = try decode(data: result, filterName: filterName, parameters: params)
        }
        return result
    }
}
