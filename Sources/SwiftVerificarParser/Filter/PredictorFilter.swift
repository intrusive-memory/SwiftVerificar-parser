import Foundation

/// A filter that applies or removes predictor functions for decompressed data.
///
/// `PredictorFilter` corresponds to the Java `COSPredictorDecode` class from
/// veraPDF-parser. It implements predictor processing as specified in PDF
/// (ISO 32000) for the `/FlateDecode` and `/LZWDecode` filters.
///
/// Predictors improve compression ratios by transforming data before compression.
/// Each row of image data is filtered to highlight differences rather than
/// absolute values, which compresses better.
///
/// ## PDF Specification
/// The `/DecodeParms` dictionary may contain:
/// - `/Predictor` -- The predictor function:
///   - 1 = None (no prediction, default)
///   - 2 = TIFF Predictor 2 (horizontal differencing)
///   - 10 = PNG None
///   - 11 = PNG Sub
///   - 12 = PNG Up
///   - 13 = PNG Average
///   - 14 = PNG Paeth
///   - 15 = PNG Optimum (per-row selection)
/// - `/Colors` -- Number of color components per sample (default: 1)
/// - `/BitsPerComponent` -- Bits per component (default: 8)
/// - `/Columns` -- Number of samples per row (default: 1)
///
/// ## Usage
/// ```swift
/// let filter = PredictorFilter(
///     predictor: 12,  // PNG Up
///     colors: 3,
///     bitsPerComponent: 8,
///     columns: 640
/// )
/// let unpredicted = try filter.decode(predictedData)
/// ```
public struct PredictorFilter: Sendable, Hashable {

    // MARK: - Predictor Types

    /// The predictor function to apply.
    public enum Predictor: Int, Sendable, Hashable {
        /// No prediction (identity).
        case none = 1

        /// TIFF Predictor 2 (horizontal differencing).
        case tiff2 = 2

        /// PNG None filter.
        case pngNone = 10

        /// PNG Sub filter (difference from left pixel).
        case pngSub = 11

        /// PNG Up filter (difference from above pixel).
        case pngUp = 12

        /// PNG Average filter (average of left and above).
        case pngAverage = 13

        /// PNG Paeth filter (Paeth prediction).
        case pngPaeth = 14

        /// PNG Optimum (each row specifies its own filter).
        case pngOptimum = 15
    }

    // MARK: - Properties

    /// The predictor function.
    public let predictor: Predictor

    /// Number of color components per sample.
    public let colors: Int

    /// Bits per color component.
    public let bitsPerComponent: Int

    /// Number of samples (pixels) per row.
    public let columns: Int

    /// Calculated bytes per pixel (rounded up for sub-byte components).
    private var bytesPerPixel: Int {
        max(1, (colors * bitsPerComponent + 7) / 8)
    }

    /// Calculated bytes per row (including filter byte for PNG).
    private var bytesPerRow: Int {
        (columns * colors * bitsPerComponent + 7) / 8
    }

    // MARK: - Initialization

    /// Creates a predictor filter with the given parameters.
    ///
    /// - Parameters:
    ///   - predictor: The predictor function (default: .none).
    ///   - colors: Number of color components (default: 1).
    ///   - bitsPerComponent: Bits per component (default: 8).
    ///   - columns: Samples per row (default: 1).
    public init(
        predictor: Predictor = .none,
        colors: Int = 1,
        bitsPerComponent: Int = 8,
        columns: Int = 1
    ) {
        self.predictor = predictor
        self.colors = max(1, colors)
        self.bitsPerComponent = max(1, bitsPerComponent)
        self.columns = max(1, columns)
    }

    /// Creates a predictor filter from a decode parameters dictionary.
    ///
    /// - Parameter parameters: The `/DecodeParms` dictionary value.
    public init(parameters: COSValue?) {
        guard case .dictionary(let dict) = parameters else {
            self = PredictorFilter()
            return
        }

        let predictorValue = dict[.predictor]?.integerValue ?? 1
        let colors = dict[.colors]?.integerValue ?? 1
        let bpc = dict[.bitsPerComponent]?.integerValue ?? 8
        let columns = dict[.columns]?.integerValue ?? 1

        self.predictor = Predictor(rawValue: Int(predictorValue)) ?? .none
        self.colors = max(1, Int(colors))
        self.bitsPerComponent = max(1, Int(bpc))
        self.columns = max(1, Int(columns))
    }

    // MARK: - Decoding

    /// Decodes (unpredicts) data by reversing the predictor function.
    ///
    /// - Parameter data: The predicted data.
    /// - Returns: The original unpredicted data.
    /// - Throws: `PDFStreamError.filterError` if decoding fails.
    public func decode(_ data: Data) throws -> Data {
        guard predictor != .none else {
            return data  // No prediction
        }

        if predictor == .tiff2 {
            return try decodeTIFF2(data)
        } else {
            return try decodePNG(data)
        }
    }

    /// Decodes data with parameters (parameters are used in initialization).
    ///
    /// - Parameters:
    ///   - data: The predicted data.
    ///   - parameters: Ignored (parameters were used in init).
    /// - Returns: The unpredicted data.
    public func decode(_ data: Data, parameters: COSValue?) throws -> Data {
        return try decode(data)
    }

    // MARK: - Encoding

    /// Encodes (predicts) data by applying the predictor function.
    ///
    /// - Parameter data: The original data.
    /// - Returns: The predicted data.
    /// - Throws: `PDFStreamError.filterError` if encoding fails.
    public func encode(_ data: Data) throws -> Data {
        guard predictor != .none else {
            return data  // No prediction
        }

        if predictor == .tiff2 {
            return try encodeTIFF2(data)
        } else {
            return try encodePNG(data)
        }
    }

    // MARK: - TIFF Predictor 2

    /// Decodes TIFF Predictor 2 (horizontal differencing).
    private func decodeTIFF2(_ data: Data) throws -> Data {
        let rowLength = bytesPerRow
        guard rowLength > 0 else {
            return data
        }

        var result = Data(count: data.count)

        var offset = 0
        while offset < data.count {
            let rowEnd = min(offset + rowLength, data.count)

            // First sample in row is unchanged
            for i in 0..<min(bytesPerPixel, rowEnd - offset) {
                result[offset + i] = data[offset + i]
            }

            // Subsequent samples: add previous sample value
            for i in bytesPerPixel..<(rowEnd - offset) {
                let previous = result[offset + i - bytesPerPixel]
                let current = data[offset + i]
                result[offset + i] = current &+ previous
            }

            offset = rowEnd
        }

        return result
    }

    /// Encodes TIFF Predictor 2 (horizontal differencing).
    private func encodeTIFF2(_ data: Data) throws -> Data {
        let rowLength = bytesPerRow
        guard rowLength > 0 else {
            return data
        }

        var result = Data(count: data.count)

        var offset = 0
        while offset < data.count {
            let rowEnd = min(offset + rowLength, data.count)

            // First sample in row is unchanged
            for i in 0..<min(bytesPerPixel, rowEnd - offset) {
                result[offset + i] = data[offset + i]
            }

            // Subsequent samples: subtract previous sample value
            for i in bytesPerPixel..<(rowEnd - offset) {
                let previous = data[offset + i - bytesPerPixel]
                let current = data[offset + i]
                result[offset + i] = current &- previous
            }

            offset = rowEnd
        }

        return result
    }

    // MARK: - PNG Predictors

    /// Decodes PNG-style predictors.
    private func decodePNG(_ data: Data) throws -> Data {
        let rowLength = bytesPerRow
        guard rowLength > 0 else {
            return data
        }

        // PNG format: each row has a filter type byte followed by row data
        let pngRowLength = rowLength + 1
        var result = Data()
        result.reserveCapacity(data.count - (data.count / pngRowLength))

        var previousRow = [UInt8](repeating: 0, count: rowLength)
        var currentRow = [UInt8](repeating: 0, count: rowLength)

        var offset = 0
        while offset < data.count {
            guard offset + 1 <= data.count else {
                break
            }

            // Read filter type byte
            let filterType = data[offset]
            offset += 1

            // Read row data
            let rowDataEnd = min(offset + rowLength, data.count)
            let rowDataLength = rowDataEnd - offset

            // Decode the row
            for i in 0..<rowDataLength {
                let filtered = data[offset + i]
                let a = i >= bytesPerPixel ? currentRow[i - bytesPerPixel] : 0  // Left
                let b = previousRow[i]  // Above
                let c = i >= bytesPerPixel ? previousRow[i - bytesPerPixel] : 0  // Upper-left

                let decoded: UInt8
                switch filterType {
                case 0:  // None
                    decoded = filtered
                case 1:  // Sub
                    decoded = filtered &+ a
                case 2:  // Up
                    decoded = filtered &+ b
                case 3:  // Average
                    decoded = filtered &+ UInt8((Int(a) + Int(b)) / 2)
                case 4:  // Paeth
                    decoded = filtered &+ paethPredictor(a: a, b: b, c: c)
                default:
                    // Unknown filter type, treat as None
                    decoded = filtered
                }

                currentRow[i] = decoded
            }

            // Append decoded row to result
            result.append(contentsOf: currentRow.prefix(rowDataLength))

            // Swap rows
            swap(&previousRow, &currentRow)
            currentRow = [UInt8](repeating: 0, count: rowLength)

            offset = rowDataEnd
        }

        return result
    }

    /// Encodes PNG-style predictors.
    private func encodePNG(_ data: Data) throws -> Data {
        let rowLength = bytesPerRow
        guard rowLength > 0 else {
            return data
        }

        var result = Data()
        result.reserveCapacity(data.count + (data.count / rowLength) + 1)

        var previousRow = [UInt8](repeating: 0, count: rowLength)
        var currentRow = [UInt8](repeating: 0, count: rowLength)

        let filterType: UInt8
        switch predictor {
        case .pngNone: filterType = 0
        case .pngSub: filterType = 1
        case .pngUp: filterType = 2
        case .pngAverage: filterType = 3
        case .pngPaeth: filterType = 4
        case .pngOptimum: filterType = 0  // Default to None for encoding
        default: filterType = 0
        }

        var offset = 0
        while offset < data.count {
            let rowEnd = min(offset + rowLength, data.count)
            let rowDataLength = rowEnd - offset

            // Copy current row data
            for i in 0..<rowDataLength {
                currentRow[i] = data[offset + i]
            }

            // Write filter type byte
            result.append(filterType)

            // Encode the row
            for i in 0..<rowDataLength {
                let original = currentRow[i]
                let a = i >= bytesPerPixel ? currentRow[i - bytesPerPixel] : 0  // Left
                let b = previousRow[i]  // Above
                let c = i >= bytesPerPixel ? previousRow[i - bytesPerPixel] : 0  // Upper-left

                let encoded: UInt8
                switch filterType {
                case 0:  // None
                    encoded = original
                case 1:  // Sub
                    encoded = original &- a
                case 2:  // Up
                    encoded = original &- b
                case 3:  // Average
                    encoded = original &- UInt8((Int(a) + Int(b)) / 2)
                case 4:  // Paeth
                    encoded = original &- paethPredictor(a: a, b: b, c: c)
                default:
                    encoded = original
                }

                result.append(encoded)
            }

            // Swap rows
            swap(&previousRow, &currentRow)
            currentRow = [UInt8](repeating: 0, count: rowLength)

            offset = rowEnd
        }

        return result
    }

    /// Paeth predictor function as defined in PNG specification.
    private func paethPredictor(a: UInt8, b: UInt8, c: UInt8) -> UInt8 {
        let ia = Int(a)
        let ib = Int(b)
        let ic = Int(c)

        let p = ia + ib - ic
        let pa = abs(p - ia)
        let pb = abs(p - ib)
        let pc = abs(p - ic)

        if pa <= pb && pa <= pc {
            return a
        } else if pb <= pc {
            return b
        } else {
            return c
        }
    }
}

