import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `ASCIIHexFilter`.
@Suite("ASCIIHexFilter Tests")
struct ASCIIHexFilterTests {

    // MARK: - Basic Tests

    @Test("Empty data returns end marker only")
    func emptyData() throws {
        let filter = ASCIIHexFilter()
        let encoded = try filter.encode(Data())
        #expect(encoded == Data([0x3E]))  // ">"
    }

    @Test("Decode empty with just end marker")
    func decodeEmpty() throws {
        let filter = ASCIIHexFilter()
        let result = try filter.decode(Data([0x3E]))  // ">"
        #expect(result.isEmpty)
    }

    @Test("Roundtrip encode and decode")
    func roundtrip() throws {
        let filter = ASCIIHexFilter()
        let original = Data("Hello, World!".utf8)

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Known Test Vectors

    @Test("Encode 0x00 produces '00'")
    func encodeZero() throws {
        let filter = ASCIIHexFilter()
        let encoded = try filter.encode(Data([0x00]))
        #expect(encoded == Data("00>".utf8))
    }

    @Test("Encode 0xFF produces 'FF'")
    func encodeFF() throws {
        let filter = ASCIIHexFilter()
        let encoded = try filter.encode(Data([0xFF]))
        #expect(encoded == Data("FF>".utf8))
    }

    @Test("Encode 0xAB produces 'AB'")
    func encodeAB() throws {
        let filter = ASCIIHexFilter()
        let encoded = try filter.encode(Data([0xAB]))
        #expect(encoded == Data("AB>".utf8))
    }

    @Test("Decode '48656C6C6F>' as 'Hello'")
    func decodeHello() throws {
        let filter = ASCIIHexFilter()
        let decoded = try filter.decode(Data("48656C6C6F>".utf8))
        #expect(decoded == Data("Hello".utf8))
    }

    // MARK: - Case Insensitivity

    @Test("Decode lowercase hex digits")
    func decodeLowercase() throws {
        let filter = ASCIIHexFilter()
        let decoded = try filter.decode(Data("48656c6c6f>".utf8))
        #expect(decoded == Data("Hello".utf8))
    }

    @Test("Decode mixed case hex digits")
    func decodeMixedCase() throws {
        let filter = ASCIIHexFilter()
        let decoded = try filter.decode(Data("48656C6c6F>".utf8))
        #expect(decoded == Data("Hello".utf8))
    }

    // MARK: - Whitespace Handling

    @Test("Whitespace is ignored during decoding")
    func whitespaceIgnored() throws {
        let filter = ASCIIHexFilter()
        let decoded = try filter.decode(Data("48 65 6C 6C 6F>".utf8))
        #expect(decoded == Data("Hello".utf8))
    }

    @Test("Newlines are ignored during decoding")
    func newlinesIgnored() throws {
        let filter = ASCIIHexFilter()
        let decoded = try filter.decode(Data("48\n65\r\n6C\t6C\r6F>".utf8))
        #expect(decoded == Data("Hello".utf8))
    }

    // MARK: - Trailing Single Digit

    @Test("Trailing single digit gets zero-padded")
    func trailingSingleDigit() throws {
        let filter = ASCIIHexFilter()
        // "A>" should decode to 0xA0
        let decoded = try filter.decode(Data("A>".utf8))
        #expect(decoded == Data([0xA0]))
    }

    @Test("Odd number of digits gets zero-padded")
    func oddNumberOfDigits() throws {
        let filter = ASCIIHexFilter()
        // "ABC>" should decode to 0xAB 0xC0
        let decoded = try filter.decode(Data("ABC>".utf8))
        #expect(decoded == Data([0xAB, 0xC0]))
    }

    // MARK: - Missing End Marker

    @Test("Missing end marker is tolerated")
    func missingEndMarker() throws {
        let filter = ASCIIHexFilter()
        // Some PDFs omit the end marker
        let decoded = try filter.decode(Data("48656C6C6F".utf8))
        #expect(decoded == Data("Hello".utf8))
    }

    // MARK: - Error Cases

    @Test("Invalid character throws error")
    func invalidCharacterThrows() throws {
        let filter = ASCIIHexFilter()
        // 'G' is not a valid hex digit
        let invalid = Data("4G>".utf8)

        #expect(throws: PDFStreamError.self) {
            _ = try filter.decode(invalid)
        }
    }

    // MARK: - Larger Data

    @Test("Roundtrip larger data")
    func roundtripLargerData() throws {
        let filter = ASCIIHexFilter()
        var original = Data()
        for i in 0..<256 {
            original.append(UInt8(i))
        }

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
        // Encoded should be approximately 2x original size + end marker
        #expect(encoded.count == original.count * 2 + 1)
    }

    // MARK: - Sendable and Hashable

    @Test("ASCIIHexFilter is Sendable")
    func sendable() {
        let filter = ASCIIHexFilter()
        let _: any Sendable = filter
    }

    @Test("ASCIIHexFilter is Hashable")
    func hashable() {
        let filter1 = ASCIIHexFilter()
        let filter2 = ASCIIHexFilter()
        #expect(filter1 == filter2)
    }
}
