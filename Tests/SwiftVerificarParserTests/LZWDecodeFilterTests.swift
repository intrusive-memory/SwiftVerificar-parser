import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `LZWDecodeFilter`.
@Suite("LZWDecodeFilter Tests")
struct LZWDecodeFilterTests {

    // MARK: - Basic Tests

    @Test("Empty data returns empty result")
    func emptyData() throws {
        let filter = LZWDecodeFilter()
        let result = try filter.decode(Data())
        #expect(result.isEmpty)
    }

    @Test("Roundtrip encode and decode")
    func roundtrip() throws {
        let filter = LZWDecodeFilter()
        let original = Data("Hello, World! This is a test of LZW compression.".utf8)

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    @Test("Roundtrip with repetitive data")
    func roundtripRepetitiveData() throws {
        let filter = LZWDecodeFilter()
        // LZW works well with repetitive data
        let original = Data(repeating: UInt8(ascii: "A"), count: 100)

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
        #expect(compressed.count < original.count)  // Should compress
    }

    @Test("Roundtrip with larger data")
    func roundtripLargeData() throws {
        let filter = LZWDecodeFilter()
        var original = Data()
        for i in 0..<500 {
            original.append(contentsOf: "Line \(i % 10): Repeated text.\n".utf8)
        }

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    // MARK: - Early Change Parameter

    @Test("Decode with early change parameter")
    func decodeWithEarlyChange() throws {
        let filter = LZWDecodeFilter()
        let original = Data("Test with early change parameter.".utf8)

        // Encode with early change = true (default)
        let compressed = try filter.encode(original, earlyChange: true)
        let decompressed = try filter.decode(compressed, earlyChange: true)

        #expect(decompressed == original)
    }

    @Test("Decode with parameters dictionary")
    func decodeWithParametersDictionary() throws {
        let filter = LZWDecodeFilter()
        let original = Data("Test with parameters.".utf8)
        let compressed = try filter.encode(original)

        // Pass parameters as dictionary
        let params: COSValue = .dictionary([.earlyChange: .integer(1)])
        let decompressed = try filter.decode(compressed, parameters: params)

        #expect(decompressed == original)
    }

    // MARK: - Edge Cases

    @Test("Single byte data")
    func singleByte() throws {
        let filter = LZWDecodeFilter()
        let original = Data([42])

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    @Test("All same bytes")
    func allSameBytes() throws {
        let filter = LZWDecodeFilter()
        let original = Data(repeating: 0xFF, count: 256)

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    @Test("All different bytes")
    func allDifferentBytes() throws {
        let filter = LZWDecodeFilter()
        var original = Data()
        for i in 0..<256 {
            original.append(UInt8(i))
        }

        let compressed = try filter.encode(original)
        let decompressed = try filter.decode(compressed)

        #expect(decompressed == original)
    }

    // MARK: - Sendable and Hashable

    @Test("LZWDecodeFilter is Sendable")
    func sendable() {
        let filter = LZWDecodeFilter()
        let _: any Sendable = filter
    }

    @Test("LZWDecodeFilter is Hashable")
    func hashable() {
        let filter1 = LZWDecodeFilter()
        let filter2 = LZWDecodeFilter()
        #expect(filter1 == filter2)
    }
}
