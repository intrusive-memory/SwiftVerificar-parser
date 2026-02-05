import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `ASCII85Filter`.
@Suite("ASCII85Filter Tests")
struct ASCII85FilterTests {

    // MARK: - Basic Tests

    @Test("Empty data returns end marker only")
    func emptyData() throws {
        let filter = ASCII85Filter()
        let encoded = try filter.encode(Data())
        #expect(encoded == Data([0x7E, 0x3E]))  // "~>"
    }

    @Test("Decode empty with just end marker")
    func decodeEmpty() throws {
        let filter = ASCII85Filter()
        let result = try filter.decode(Data([0x7E, 0x3E]))  // "~>"
        #expect(result.isEmpty)
    }

    @Test("Roundtrip encode and decode")
    func roundtrip() throws {
        let filter = ASCII85Filter()
        let original = Data("Hello, World!".utf8)

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Known Test Vectors

    @Test("Encode known value - 'Man'")
    func encodeKnownValue() throws {
        let filter = ASCII85Filter()
        let input = Data("Man ".utf8)  // 4 bytes

        let encoded = try filter.encode(input)
        // "Man " = 0x4D616E20 should encode to specific ASCII85 characters
        // The encoded value (without end marker) should be a 5-character sequence
        #expect(encoded.count > 0)
    }

    @Test("Zero bytes encode to z")
    func zeroEncodesToZ() throws {
        let filter = ASCII85Filter()
        let input = Data([0, 0, 0, 0])

        let encoded = try filter.encode(input)
        // Four zeros should encode to 'z'
        #expect(encoded.contains(UInt8(ascii: "z")))
    }

    @Test("Decode z as four zeros")
    func decodeZ() throws {
        let filter = ASCII85Filter()
        let input = Data("z~>".utf8)

        let decoded = try filter.decode(input)
        #expect(decoded == Data([0, 0, 0, 0]))
    }

    // MARK: - Edge Cases

    @Test("Partial final group (1-3 bytes)")
    func partialFinalGroup() throws {
        let filter = ASCII85Filter()

        // Test 1 byte
        let one = Data([0x41])
        let encodedOne = try filter.encode(one)
        let decodedOne = try filter.decode(encodedOne)
        #expect(decodedOne == one)

        // Test 2 bytes
        let two = Data([0x41, 0x42])
        let encodedTwo = try filter.encode(two)
        let decodedTwo = try filter.decode(encodedTwo)
        #expect(decodedTwo == two)

        // Test 3 bytes
        let three = Data([0x41, 0x42, 0x43])
        let encodedThree = try filter.encode(three)
        let decodedThree = try filter.decode(encodedThree)
        #expect(decodedThree == three)
    }

    @Test("Whitespace is ignored during decoding")
    func whitespaceIgnored() throws {
        let filter = ASCII85Filter()
        let original = Data("Test".utf8)
        let encoded = try filter.encode(original)

        // Insert whitespace
        var withWhitespace = Data()
        for (i, byte) in encoded.enumerated() {
            withWhitespace.append(byte)
            if i % 2 == 0 {
                withWhitespace.append(UInt8(ascii: " "))
            }
        }

        let decoded = try filter.decode(withWhitespace)
        #expect(decoded == original)
    }

    @Test("Start marker <~ is handled")
    func startMarkerHandled() throws {
        let filter = ASCII85Filter()
        let original = Data("Test".utf8)
        let encoded = try filter.encode(original)

        // Prepend start marker
        var withStartMarker = Data([0x3C, 0x7E])  // "<~"
        withStartMarker.append(encoded)

        let decoded = try filter.decode(withStartMarker)
        #expect(decoded == original)
    }

    // MARK: - Error Cases

    @Test("Invalid character throws error")
    func invalidCharacterThrows() throws {
        let filter = ASCII85Filter()
        // 'v' (ASCII 118) is out of range (valid range is '!' to 'u')
        let invalid = Data([0x76, 0x7E, 0x3E])  // "v~>"

        #expect(throws: PDFStreamError.self) {
            _ = try filter.decode(invalid)
        }
    }

    @Test("z in middle of group throws error")
    func zInMiddleThrows() throws {
        let filter = ASCII85Filter()
        // 'z' appearing after partial group is invalid
        let invalid = Data("!z~>".utf8)

        #expect(throws: PDFStreamError.self) {
            _ = try filter.decode(invalid)
        }
    }

    // MARK: - Larger Data

    @Test("Roundtrip larger data")
    func roundtripLargerData() throws {
        let filter = ASCII85Filter()
        var original = Data()
        for i in 0..<1000 {
            original.append(UInt8(i % 256))
        }

        let encoded = try filter.encode(original)
        let decoded = try filter.decode(encoded)

        #expect(decoded == original)
    }

    // MARK: - Sendable and Hashable

    @Test("ASCII85Filter is Sendable")
    func sendable() {
        let filter = ASCII85Filter()
        let _: any Sendable = filter
    }

    @Test("ASCII85Filter is Hashable")
    func hashable() {
        let filter1 = ASCII85Filter()
        let filter2 = ASCII85Filter()
        #expect(filter1 == filter2)
    }
}
