import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `PredictorFilter`.
@Suite("PredictorFilter Tests")
struct PredictorFilterTests {

    // MARK: - Initialization Tests

    @Test("Default initialization")
    func defaultInit() {
        let filter = PredictorFilter()
        #expect(filter.predictor == .none)
        #expect(filter.colors == 1)
        #expect(filter.bitsPerComponent == 8)
        #expect(filter.columns == 1)
    }

    @Test("Initialization with custom values")
    func customInit() {
        let filter = PredictorFilter(
            predictor: .pngUp,
            colors: 3,
            bitsPerComponent: 8,
            columns: 640
        )
        #expect(filter.predictor == .pngUp)
        #expect(filter.colors == 3)
        #expect(filter.bitsPerComponent == 8)
        #expect(filter.columns == 640)
    }

    @Test("Initialization from parameters dictionary")
    func initFromParameters() {
        let params: COSValue = .dictionary([
            .predictor: .integer(12),  // PNG Up
            .colors: .integer(3),
            .bitsPerComponent: .integer(8),
            .columns: .integer(100)
        ])
        let filter = PredictorFilter(parameters: params)
        #expect(filter.predictor == .pngUp)
        #expect(filter.colors == 3)
        #expect(filter.bitsPerComponent == 8)
        #expect(filter.columns == 100)
    }

    @Test("Initialization from nil parameters")
    func initFromNilParameters() {
        let filter = PredictorFilter(parameters: nil)
        #expect(filter.predictor == .none)
    }

    // MARK: - No Predictor

    @Test("Predictor none passes data through unchanged")
    func predictorNone() throws {
        let filter = PredictorFilter(predictor: .none)
        let data = Data([1, 2, 3, 4, 5])

        let encoded = try filter.encode(data)
        let decoded = try filter.decode(data)

        #expect(encoded == data)
        #expect(decoded == data)
    }

    // MARK: - TIFF Predictor 2

    @Test("TIFF Predictor 2 roundtrip")
    func tiff2Roundtrip() throws {
        let filter = PredictorFilter(
            predictor: .tiff2,
            colors: 1,
            bitsPerComponent: 8,
            columns: 5
        )
        // Simple row of increasing values
        let original = Data([1, 2, 3, 4, 5])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    @Test("TIFF Predictor 2 with multiple rows")
    func tiff2MultipleRows() throws {
        let filter = PredictorFilter(
            predictor: .tiff2,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        // Two rows of 4 bytes each
        let original = Data([10, 20, 30, 40, 100, 110, 120, 130])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    @Test("TIFF Predictor 2 with RGB data")
    func tiff2RGB() throws {
        let filter = PredictorFilter(
            predictor: .tiff2,
            colors: 3,
            bitsPerComponent: 8,
            columns: 2
        )
        // 2 pixels, 3 colors each = 6 bytes per row
        let original = Data([255, 0, 0, 0, 255, 0])  // Red, Green

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    // MARK: - PNG Predictors

    @Test("PNG None roundtrip")
    func pngNoneRoundtrip() throws {
        let filter = PredictorFilter(
            predictor: .pngNone,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        let original = Data([10, 20, 30, 40])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    @Test("PNG Sub roundtrip")
    func pngSubRoundtrip() throws {
        let filter = PredictorFilter(
            predictor: .pngSub,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        let original = Data([10, 20, 30, 40])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    @Test("PNG Up roundtrip")
    func pngUpRoundtrip() throws {
        let filter = PredictorFilter(
            predictor: .pngUp,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        // Two rows
        let original = Data([10, 20, 30, 40, 15, 25, 35, 45])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    @Test("PNG Average roundtrip")
    func pngAverageRoundtrip() throws {
        let filter = PredictorFilter(
            predictor: .pngAverage,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        let original = Data([10, 20, 30, 40, 15, 25, 35, 45])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    @Test("PNG Paeth roundtrip")
    func pngPaethRoundtrip() throws {
        let filter = PredictorFilter(
            predictor: .pngPaeth,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        let original = Data([10, 20, 30, 40, 15, 25, 35, 45])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    // MARK: - Multi-channel Data

    @Test("RGB image data roundtrip with PNG Up")
    func rgbPngUp() throws {
        let filter = PredictorFilter(
            predictor: .pngUp,
            colors: 3,
            bitsPerComponent: 8,
            columns: 4
        )
        // 4 pixels x 3 channels x 2 rows = 24 bytes
        var original = Data()
        for row in 0..<2 {
            for pixel in 0..<4 {
                original.append(UInt8(row * 50 + pixel * 10))  // R
                original.append(UInt8(row * 50 + pixel * 10 + 1))  // G
                original.append(UInt8(row * 50 + pixel * 10 + 2))  // B
            }
        }

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    // MARK: - Edge Cases

    @Test("Empty data")
    func emptyData() throws {
        let filter = PredictorFilter(predictor: .pngUp, columns: 4)
        let result = try filter.decode(Data())
        #expect(result.isEmpty)
    }

    @Test("Single row")
    func singleRow() throws {
        let filter = PredictorFilter(
            predictor: .pngUp,
            colors: 1,
            bitsPerComponent: 8,
            columns: 4
        )
        let original = Data([10, 20, 30, 40])

        let predicted = try filter.encode(original)
        let unpredicted = try filter.decode(predicted)

        #expect(unpredicted == original)
    }

    // MARK: - Sendable and Hashable

    @Test("PredictorFilter is Sendable")
    func sendable() {
        let filter = PredictorFilter()
        let _: any Sendable = filter
    }

    @Test("PredictorFilter is Hashable")
    func hashable() {
        let filter1 = PredictorFilter(predictor: .pngUp, columns: 100)
        let filter2 = PredictorFilter(predictor: .pngUp, columns: 100)
        #expect(filter1 == filter2)
        #expect(filter1.hashValue == filter2.hashValue)

        let filter3 = PredictorFilter(predictor: .pngSub, columns: 100)
        #expect(filter1 != filter3)
    }
}
