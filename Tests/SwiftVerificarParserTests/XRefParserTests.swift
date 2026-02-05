import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("XRefParser Tests")
struct XRefParserTests {

    // MARK: - Error Tests

    @Test("ParseError descriptions")
    func parseErrorDescriptions() {
        let errors: [XRefParser.ParseError] = [
            .missingXRefKeyword,
            .invalidSubsectionHeader,
            .invalidEntryFormat(line: "invalid line"),
            .invalidTrailer,
            .unexpectedEndOfStream,
            .invalidInteger("abc")
        ]

        for error in errors {
            let desc = error.description
            #expect(!desc.isEmpty)
        }
    }

    @Test("Invalid entry format error contains line")
    func invalidEntryFormatContainsLine() {
        let error = XRefParser.ParseError.invalidEntryFormat(line: "bad line")
        let desc = error.description
        #expect(desc.contains("bad line"))
    }

    @Test("Invalid integer error contains value")
    func invalidIntegerErrorContainsValue() {
        let error = XRefParser.ParseError.invalidInteger("xyz")
        let desc = error.description
        #expect(desc.contains("xyz"))
    }

    // Note: Full parser tests would require implementing a complete COS dictionary parser
    // and creating valid PDF xref table data. These tests verify the error types and
    // structure. Integration tests with real PDF data would go in separate test files.
}
