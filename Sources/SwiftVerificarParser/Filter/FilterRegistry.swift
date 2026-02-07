import Foundation

/// A thread-safe registry for managing PDF filter factories.
///
/// `FilterRegistry` corresponds to the Java `COSFilterRegistry` class from
/// veraPDF-parser. It uses Swift's `actor` model to provide thread-safe
/// registration and lookup of filter factories, replacing Java's synchronized
/// static singleton pattern.
///
/// The registry maintains:
/// - A **default factory** used for standard PDF filters.
/// - A set of **custom factories** that can override or extend the default
///   filter behavior.
///
/// When decoding or encoding, the registry checks custom factories first
/// (in registration order) and falls back to the default factory.
///
/// ## Usage
/// ```swift
/// let registry = FilterRegistry()
/// let decoded = try await registry.decode(
///     data: compressedData,
///     filterName: .flateDecode,
///     parameters: nil
/// )
///
/// // Register a custom factory for proprietary filters:
/// await registry.registerFactory(myCustomFactory)
/// ```
///
/// ## Thread Safety
/// All operations on `FilterRegistry` are isolated to the actor and are
/// safe to call from any concurrency context.
public actor FilterRegistry {

    // MARK: - Storage

    /// The default filter factory, used as a fallback when no custom factory
    /// handles a given filter.
    private var defaultFactory: any PDFFilterFactory

    /// Custom filter factories, checked in order before the default factory.
    private var customFactories: [any PDFFilterFactory]

    // MARK: - Initialization

    /// Creates a new filter registry with the given default factory.
    ///
    /// - Parameter defaultFactory: The factory to use as the default fallback.
    ///   Defaults to `DefaultFilterFactory()`.
    public init(defaultFactory: any PDFFilterFactory = DefaultFilterFactory()) {
        self.defaultFactory = defaultFactory
        self.customFactories = []
    }

    // MARK: - Factory Management

    /// Registers a custom filter factory.
    ///
    /// Custom factories are checked in registration order before the default
    /// factory when looking up filter support.
    ///
    /// - Parameter factory: The factory to register.
    public func registerFactory(_ factory: any PDFFilterFactory) {
        customFactories.append(factory)
    }

    /// Removes all custom factories, reverting to the default factory only.
    public func removeAllCustomFactories() {
        customFactories.removeAll()
    }

    /// Replaces the default filter factory.
    ///
    /// - Parameter factory: The new default factory.
    public func setDefaultFactory(_ factory: any PDFFilterFactory) {
        defaultFactory = factory
    }

    /// Returns the current default filter factory.
    public func getDefaultFactory() -> any PDFFilterFactory {
        defaultFactory
    }

    /// Returns the number of registered custom factories.
    public var customFactoryCount: Int {
        customFactories.count
    }

    // MARK: - Filter Lookup

    /// Finds the first factory that supports the given filter name.
    ///
    /// Custom factories are checked first (in registration order), then the
    /// default factory.
    ///
    /// - Parameter filterName: The filter to look up.
    /// - Returns: The first factory that supports the filter, or `nil` if
    ///   no factory supports it.
    public func factoryForFilter(_ filterName: PDFFilterName) -> (any PDFFilterFactory)? {
        for factory in customFactories {
            if factory.supportsFilter(filterName) {
                return factory
            }
        }
        if defaultFactory.supportsFilter(filterName) {
            return defaultFactory
        }
        return nil
    }

    /// Returns whether any registered factory supports the given filter.
    ///
    /// - Parameter filterName: The filter to check.
    /// - Returns: `true` if at least one factory (custom or default) supports
    ///   the filter.
    public func supportsFilter(_ filterName: PDFFilterName) -> Bool {
        factoryForFilter(filterName) != nil
    }

    // MARK: - Decode / Encode

    /// Decodes data using the appropriate factory for the specified filter.
    ///
    /// Custom factories are checked first. If no custom factory supports the
    /// filter, the default factory is used.
    ///
    /// - Parameters:
    ///   - data: The encoded data to decode.
    ///   - filterName: The filter to apply.
    ///   - parameters: Optional decode parameters.
    /// - Returns: The decoded data.
    /// - Throws: `PDFStreamError.unknownFilter` if no factory supports the filter.
    ///   `PDFStreamError.filterError` if decoding fails.
    public func decode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard let factory = factoryForFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }
        return try factory.decode(data: data, filterName: filterName, parameters: parameters)
    }

    /// Encodes data using the appropriate factory for the specified filter.
    ///
    /// Custom factories are checked first. If no custom factory supports the
    /// filter, the default factory is used.
    ///
    /// - Parameters:
    ///   - data: The raw data to encode.
    ///   - filterName: The filter to apply.
    ///   - parameters: Optional encode parameters.
    /// - Returns: The encoded data.
    /// - Throws: `PDFStreamError.unknownFilter` if no factory supports the filter.
    ///   `PDFStreamError.filterError` if encoding fails.
    public func encode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard let factory = factoryForFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }
        return try factory.encode(data: data, filterName: filterName, parameters: parameters)
    }

    /// Decodes data through a pipeline of filters using the appropriate
    /// factories.
    ///
    /// Each filter in the pipeline is resolved independently, so different
    /// filters may use different factories.
    ///
    /// - Parameters:
    ///   - data: The encoded data.
    ///   - filters: The ordered array of filter names.
    ///   - parameterSets: Optional array of decode parameters per filter.
    /// - Returns: The fully decoded data.
    /// - Throws: `PDFStreamError` if any filter in the pipeline fails.
    public func decodePipeline(data: Data, filters: [PDFFilterName], parameterSets: [COSValue?]?) throws -> Data {
        var result = data
        for (index, filterName) in filters.enumerated() {
            let params: COSValue? = parameterSets.flatMap { index < $0.count ? $0[index] : nil }
            result = try decode(data: result, filterName: filterName, parameters: params)
        }
        return result
    }

    /// Decodes data from a `COSStream` using its declared filters.
    ///
    /// Reads the `/Filter` and `/DecodeParms` entries from the stream
    /// dictionary and applies the appropriate decode pipeline.
    ///
    /// - Parameter stream: The COS stream to decode.
    /// - Returns: The decoded stream data.
    /// - Throws: `PDFStreamError` if decoding fails.
    public func decodeStream(_ stream: COSStream) throws -> Data {
        let filterAtoms = stream.filters
        guard !filterAtoms.isEmpty else {
            // No filters: return encoded data as-is
            return stream.encodedData
        }

        let filterNames = filterAtoms.map { PDFFilterName(atom: $0) }

        // Extract decode parameters
        let parameterSets: [COSValue?]?
        if let decodeParams = stream.decodeParameters {
            switch decodeParams {
            case .dictionary:
                // Single filter with single parameter dict
                parameterSets = [decodeParams]
            case .array(let arr):
                // Array of parameters, one per filter
                parameterSets = arr.map { $0.isNull ? nil : $0 }
            default:
                parameterSets = nil
            }
        } else {
            parameterSets = nil
        }

        return try decodePipeline(
            data: stream.encodedData,
            filters: filterNames,
            parameterSets: parameterSets
        )
    }
}
