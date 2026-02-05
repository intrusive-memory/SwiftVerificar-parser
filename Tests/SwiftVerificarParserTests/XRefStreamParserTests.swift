import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("XRefStreamParser Tests")
struct XRefStreamParserTests {

    // MARK: - Error Tests

    @Test("ParseError descriptions")
    func parseErrorDescriptions() {
        let errors: [XRefStreamParser.ParseError] = [
            .notXRefStream,
            .missingOrInvalidWidthArray,
            .missingSize,
            .truncatedStreamData,
            .invalidEntryType(5)
        ]

        for error in errors {
            let desc = error.description
            #expect(!desc.isEmpty)
        }
    }

    @Test("Invalid entry type error contains type value")
    func invalidEntryTypeContainsValue() {
        let error = XRefStreamParser.ParseError.invalidEntryType(99)
        let desc = error.description
        #expect(desc.contains("99"))
    }

    @Test("Not XRef stream error message")
    func notXRefStreamMessage() {
        let error = XRefStreamParser.ParseError.notXRefStream
        let desc = error.description
        #expect(desc.contains("XRef") || desc.contains("cross-reference"))
    }

    // MARK: - Parser Structure Tests

    @Test("Can create parser with stream")
    func createParser() {
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("XRef")),
            .size: .integer(100)
        ]
        let stream = COSStream(dictionary: dict, encodedData: Data())
        let parser = XRefStreamParser(stream: stream)

        // Parser created successfully
        #expect(true)
    }

    @Test("Parser validates XRef type")
    func parserValidatesType() async throws {
        // Stream without /Type /XRef should fail
        let dict: [ASAtom: COSValue] = [
            .size: .integer(100)
        ]
        let stream = COSStream(dictionary: dict, encodedData: Data())
        let parser = XRefStreamParser(stream: stream)

        #expect(throws: XRefStreamParser.ParseError.self) {
            try parser.parse()
        }
    }

    @Test("Parser requires size entry")
    func parserRequiresSize() async throws {
        // Stream with /Type /XRef but no /Size should fail
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("XRef"))
        ]
        let stream = COSStream(dictionary: dict, encodedData: Data())
        let parser = XRefStreamParser(stream: stream)

        #expect(throws: XRefStreamParser.ParseError.self) {
            try parser.parse()
        }
    }

    @Test("Parser requires W array")
    func parserRequiresWidthArray() async throws {
        // Stream with /Type /XRef and /Size but no /W should fail
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("XRef")),
            .size: .integer(1)
        ]
        let stream = COSStream(dictionary: dict, encodedData: Data())
        let parser = XRefStreamParser(stream: stream)

        #expect(throws: XRefStreamParser.ParseError.self) {
            try parser.parse()
        }
    }

    @Test("Parser validates W array has three elements")
    func parserValidatesWidthArrayLength() async throws {
        // /W array must have exactly 3 elements
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("XRef")),
            .size: .integer(1),
            ASAtom("W"): .array([.integer(1), .integer(2)]) // Only 2 elements
        ]
        let stream = COSStream(dictionary: dict, encodedData: Data())
        let parser = XRefStreamParser(stream: stream)

        #expect(throws: XRefStreamParser.ParseError.self) {
            try parser.parse()
        }
    }

    // Note: Full integration tests with valid xref stream data would require
    // implementing stream decoding and creating properly encoded binary data.
    // These tests verify the parser structure and error handling.
}
