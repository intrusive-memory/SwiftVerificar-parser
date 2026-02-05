import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `FlateDecodeFilter`.
@Suite("FlateDecodeFilter Tests")
struct FlateDecodeFilterTests {

    // MARK: - Basic Tests

    @Test("Empty data returns empty result")
    func emptyData() throws {
        let filter = FlateDecodeFilter()
        let result = try filter.decode(Data())
        #expect(result.isEmpty)
    }

    @Test("Roundtrip encode and decode")
    func roundtrip() throws {
        let filter = FlateDecodeFilter()
        let original = Data("Hello, World! This is a test of Flate compression.".utf8)

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    @Test("Roundtrip with larger data")
    func roundtripLargeData() throws {
        let filter = FlateDecodeFilter()
        // Create a larger data set with some repetition for better compression
        var original = Data()
        for i in 0..<1000 {
            original.append(contentsOf: "Line \(i): This is repeated text for compression testing.\n".utf8)
        }

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
        #expect(compressed.count < original.count)  // Should actually compress
    }

    @Test("Roundtrip with binary data")
    func roundtripBinaryData() throws {
        let filter = FlateDecodeFilter()
        var original = Data(count: 1000)
        for i in 0..<original.count {
            original[i] = UInt8(i % 256)
        }

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    @Test("Decode with parameters (parameters ignored)")
    func decodeWithParameters() throws {
        let filter = FlateDecodeFilter()
        let original = Data("Test data".utf8)
        let compressed = try filter.encode(original)

        // Parameters should be ignored (predictor handled separately)
        let decompressed = try filter.decode(compressed, parameters: .dictionary([.predictor: .integer(1)]))
        #expect(decompressed == original)
    }

    // MARK: - Sendable and Hashable

    @Test("FlateDecodeFilter is Sendable")
    func sendable() {
        let filter = FlateDecodeFilter()
        let _: any Sendable = filter
    }

    @Test("FlateDecodeFilter is Hashable")
    func hashable() {
        let filter1 = FlateDecodeFilter()
        let filter2 = FlateDecodeFilter()
        #expect(filter1 == filter2)
        #expect(filter1.hashValue == filter2.hashValue)
    }
}
