import Foundation

/// The default implementation of `PDFFilterFactory` that provides
/// support for standard PDF stream filters.
///
/// `DefaultFilterFactory` corresponds to the Java `ASFilterFactory` class
/// from veraPDF-parser. It serves as the default filter factory used by
/// the parser when no custom factory is registered.
///
/// ## Supported Filters
/// - `FlateDecode` -- zlib/deflate compression (Apple Compression framework)
/// - `LZWDecode` -- LZW compression
/// - `ASCII85Decode` -- ASCII base-85 encoding
/// - `ASCIIHexDecode` -- ASCII hexadecimal encoding
/// - `RunLengthDecode` -- Run-length encoding
///
/// ## Partially Supported Filters
/// - `DCTDecode` -- JPEG images (passthrough; use CGImage for decoding)
/// - `JPXDecode` -- JPEG 2000 images (passthrough; use ImageIO for decoding)
/// - `CCITTFaxDecode` -- CCITT fax compression (not yet implemented)
/// - `Crypt` -- Encryption filter (requires external key setup)
///
/// ## Usage
/// ```swift
/// let factory = DefaultFilterFactory()
/// let decoded = try factory.decode(data: compressed, filterName: .flateDecode, parameters: nil)
/// ```
public struct DefaultFilterFactory: PDFFilterFactory, Sendable, Hashable {

    // MARK: - Supported Filter Set

    /// The set of filter names that this factory recognizes.
    private static let recognizedFilters: Set<PDFFilterName> = [
        .flateDecode,
        .lzwDecode,
        .ascii85Decode,
        .asciiHexDecode,
        .runLengthDecode,
        .dctDecode,
        .jpxDecode,
        .ccittFaxDecode,
        .crypt,
    ]

    /// Filters that are fully implemented.
    private static let implementedFilters: Set<PDFFilterName> = [
        .flateDecode,
        .lzwDecode,
        .ascii85Decode,
        .asciiHexDecode,
        .runLengthDecode,
    ]

    /// Filters that pass through data unchanged (images handled elsewhere).
    private static let passthroughFilters: Set<PDFFilterName> = [
        .dctDecode,  // JPEG - decoded via CGImage/ImageIO
        .jpxDecode,  // JPEG 2000 - decoded via ImageIO
    ]

    // MARK: - Filter Instances

    /// Reusable filter instances (all are stateless and thread-safe).
    private let flateFilter = FlateDecodeFilter()
    private let lzwFilter = LZWDecodeFilter()
    private let ascii85Filter = ASCII85Filter()
    private let asciiHexFilter = ASCIIHexFilter()
    private let runLengthFilter = RunLengthFilter()

    // MARK: - Initialization

    /// Creates a new default filter factory.
    public init() {}

    // MARK: - PDFFilterFactory

    /// Returns whether this factory recognizes the given filter.
    ///
    /// - Parameter filterName: The filter name to check.
    /// - Returns: `true` if the filter is a standard PDF filter recognized
    ///   by this factory.
    public func supportsFilter(_ filterName: PDFFilterName) -> Bool {
        Self.recognizedFilters.contains(filterName)
    }

    /// Decodes data using the specified filter.
    ///
    /// - Parameters:
    ///   - data: The encoded data to decode.
    ///   - filterName: The filter to apply.
    ///   - parameters: Optional decode parameters.
    /// - Returns: The decoded data.
    /// - Throws: `PDFStreamError.unknownFilter` if the filter is not recognized.
    ///   `PDFStreamError.filterError` if the filter is not implemented or decoding fails.
    public func decode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard supportsFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }

        // Decode based on filter type
        var decoded: Data
        switch filterName {
        case .flateDecode:
            decoded = try flateFilter.decode(data, parameters: parameters)

        case .lzwDecode:
            decoded = try lzwFilter.decode(data, parameters: parameters)

        case .ascii85Decode:
            decoded = try ascii85Filter.decode(data, parameters: parameters)

        case .asciiHexDecode:
            decoded = try asciiHexFilter.decode(data, parameters: parameters)

        case .runLengthDecode:
            decoded = try runLengthFilter.decode(data, parameters: parameters)

        case .dctDecode, .jpxDecode:
            // Image filters - return data as-is; actual decoding is done
            // by CGImage/ImageIO when the image is rendered.
            decoded = data

        case .ccittFaxDecode:
            throw PDFStreamError.filterError(
                "Filter '\(filterName)' decoding not yet implemented"
            )

        case .crypt:
            // Crypt filter requires external key setup via AESDecryptFilter or RC4DecryptFilter.
            // The crypt filter in a filter chain should be handled by the encryption system.
            throw PDFStreamError.filterError(
                "Crypt filter requires encryption context; use AESDecryptFilter or RC4DecryptFilter directly"
            )

        case .custom(let name):
            throw PDFStreamError.filterError(
                "Custom filter '\(name)' is not supported"
            )
        }

        // Apply predictor if specified in parameters
        decoded = try applyPredictorIfNeeded(to: decoded, parameters: parameters, encoding: false)

        return decoded
    }

    /// Encodes data using the specified filter.
    ///
    /// - Parameters:
    ///   - data: The raw data to encode.
    ///   - filterName: The filter to apply.
    ///   - parameters: Optional encode parameters.
    /// - Returns: The encoded data.
    /// - Throws: `PDFStreamError.unknownFilter` if the filter is not recognized.
    ///   `PDFStreamError.filterError` if the filter is not implemented or encoding fails.
    public func encode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard supportsFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }

        // Apply predictor first if encoding
        let toEncode = try applyPredictorIfNeeded(to: data, parameters: parameters, encoding: true)

        // Encode based on filter type
        switch filterName {
        case .flateDecode:
            return try flateFilter.encode(toEncode, parameters: parameters)

        case .lzwDecode:
            return try lzwFilter.encode(toEncode, parameters: parameters)

        case .ascii85Decode:
            return try ascii85Filter.encode(toEncode, parameters: parameters)

        case .asciiHexDecode:
            return try asciiHexFilter.encode(toEncode, parameters: parameters)

        case .runLengthDecode:
            return try runLengthFilter.encode(toEncode, parameters: parameters)

        case .dctDecode, .jpxDecode:
            // Image filters - encoding is typically done by image processing libraries
            return data

        case .ccittFaxDecode:
            throw PDFStreamError.filterError(
                "Filter '\(filterName)' encoding not yet implemented"
            )

        case .crypt:
            throw PDFStreamError.filterError(
                "Crypt filter requires encryption context; use AESDecryptFilter or RC4DecryptFilter directly"
            )

        case .custom(let name):
            throw PDFStreamError.filterError(
                "Custom filter '\(name)' is not supported"
            )
        }
    }

    // MARK: - Predictor Handling

    /// Applies predictor processing if specified in parameters.
    ///
    /// - Parameters:
    ///   - data: The data to process.
    ///   - parameters: The decode/encode parameters dictionary.
    ///   - encoding: `true` if encoding (apply predictor), `false` if decoding (reverse predictor).
    /// - Returns: The processed data.
    private func applyPredictorIfNeeded(to data: Data, parameters: COSValue?, encoding: Bool) throws -> Data {
        guard case .dictionary(let dict) = parameters,
              let predictorValue = dict[.predictor]?.integerValue,
              predictorValue > 1 else {
            return data  // No predictor or predictor == 1 (none)
        }

        let predictorFilter = PredictorFilter(parameters: parameters)

        if encoding {
            return try predictorFilter.encode(data)
        } else {
            return try predictorFilter.decode(data)
        }
    }
}
