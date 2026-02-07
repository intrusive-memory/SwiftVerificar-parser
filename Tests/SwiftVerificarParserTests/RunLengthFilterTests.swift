import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `RunLengthFilter`.
@Suite("RunLengthFilter Tests")
struct RunLengthFilterTests {

    // MARK: - Basic Tests

    @Test("Empty data returns end marker only when encoding")
    func emptyDataEncode() throws {
        let filter = RunLengthFilter()
        let encoded = try filter.encode(Data())
        #expect(encoded == Data([128]))  // EOD marker
    }

    @Test("Decode EOD marker only")
    func decodeEODOnly() throws {
        let filter = RunLengthFilter()
        let result = try filter.decode(Data([128]))
        #expect(result.isEmpty)
    }

    @Test("Roundtrip encode and decode")
    func roundtrip() throws {
        let filter = RunLengthFilter()
        let original = Data("Hello, World!".utf8)

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Literal Runs

    @Test("Literal run of 1 byte")
    func literalRun1() throws {
        let filter = RunLengthFilter()
        // Length byte 0 means copy 1 byte
        let encoded = Data([0, 0x41, 128])  // Copy 1 byte (A), EOD

        let decoded = try filter.decode(encoded)
        #expect(decoded == Data([0x41]))
    }

    @Test("Literal run of 3 bytes")
    func literalRun3() throws {
        let filter = RunLengthFilter()
        // Length byte 2 means copy 3 bytes
        let encoded = Data([2, 0x41, 0x42, 0x43, 128])  // Copy 3 bytes (ABC), EOD

        let decoded = try filter.decode(encoded)
        #expect(decoded == Data([0x41, 0x42, 0x43]))
    }

    @Test("Maximum literal run (128 bytes)")
    func maxLiteralRun() throws {
        let filter = RunLengthFilter()
        var original = Data()
        // Create non-repeating data
        for i in 0..<128 {
            original.append(UInt8(i))
        }

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Repeat Runs

    @Test("Repeat run of 3 bytes")
    func repeatRun3() throws {
        let filter = RunLengthFilter()
        // Length byte 254 (257 - 3) means repeat 3 times
        let encoded = Data([254, 0x41, 128])  // Repeat A 3 times, EOD

        let decoded = try filter.decode(encoded)
        #expect(decoded == Data([0x41, 0x41, 0x41]))
    }

    @Test("Repeat run of 128 bytes")
    func repeatRun128() throws {
        let filter = RunLengthFilter()
        // Length byte 129 (257 - 128) means repeat 128 times
        let encoded = Data([129, 0x42, 128])  // Repeat B 128 times, EOD

        let decoded = try filter.decode(encoded)
        #expect(decoded == Data(repeating: 0x42, count: 128))
    }

    @Test("Encoding compresses repeated bytes")
    func encodingCompressesRepeats() throws {
        let filter = RunLengthFilter()
        let original = Data(repeating: 0x41, count: 100)

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
        #expect(encoded.count < original.count)  // Should compress
    }

    // MARK: - Mixed Runs

    @Test("Mixed literal and repeat runs")
    func mixedRuns() throws {
        let filter = RunLengthFilter()
        // "ABCCCCCDEF"
        let original = Data([0x41, 0x42, 0x43, 0x43, 0x43, 0x43, 0x43, 0x44, 0x45, 0x46])

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    @Test("Alternating runs")
    func alternatingRuns() throws {
        let filter = RunLengthFilter()
        // "AAABBBCCC"
        let original = Data([0x41, 0x41, 0x41, 0x42, 0x42, 0x42, 0x43, 0x43, 0x43])

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Edge Cases

    @Test("Single byte")
    func singleByte() throws {
        let filter = RunLengthFilter()
        let original = Data([0x42])

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    @Test("Two identical bytes")
    func twoIdenticalBytes() throws {
        let filter = RunLengthFilter()
        let original = Data([0x42, 0x42])

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    @Test("Two different bytes")
    func twoDifferentBytes() throws {
        let filter = RunLengthFilter()
        let original = Data([0x41, 0x42])

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    @Test("All same bytes")
    func allSameBytes() throws {
        let filter = RunLengthFilter()
        let original = Data(repeating: 0xFF, count: 500)

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
        // Should compress: 500 bytes -> multiple repeat runs
        #expect(encoded.count < original.count)
    }

    @Test("All different bytes")
    func allDifferentBytes() throws {
        let filter = RunLengthFilter()
        var original = Data()
        for i in 0..<256 {
            original.append(UInt8(i))
        }

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Larger Data

    @Test("Roundtrip larger data")
    func roundtripLargerData() throws {
        let filter = RunLengthFilter()
        var original = Data()
        // Create data with some repetition
        for _ in 0..<100 {
            original.append(contentsOf: [0x41, 0x41, 0x41, 0x42, 0x43])
        }

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Error Cases

    @Test("Truncated literal run throws error")
    func truncatedLiteralRun() throws {
        let filter = RunLengthFilter()
        // Claims 3 bytes but only provides 2
        let invalid = Data([2, 0x41, 0x42])

        #expect(throws: PDFStreamError.self) {
            _ = try filter.decode(invalid)
        }
    }

    @Test("Truncated repeat run throws error")
    func truncatedRepeatRun() throws {
        let filter = RunLengthFilter()
        // Claims to repeat but missing the byte to repeat
        let invalid = Data([254])

        #expect(throws: PDFStreamError.self) {
            _ = try filter.decode(invalid)
        }
    }

    // MARK: - Sendable and Hashable

    @Test("RunLengthFilter is Sendable")
    func sendable() {
        let filter = RunLengthFilter()
        let _: any Sendable = filter
    }

    @Test("RunLengthFilter is Hashable")
    func hashable() {
        let filter1 = RunLengthFilter()
        let filter2 = RunLengthFilter()
        #expect(filter1 == filter2)
        #expect(filter1.hashValue == filter2.hashValue)
    }
}
