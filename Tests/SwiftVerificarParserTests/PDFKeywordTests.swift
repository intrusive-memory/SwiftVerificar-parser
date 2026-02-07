import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFKeyword Tests")
struct PDFKeywordTests {

    // MARK: - Initialization

    @Test("Init from raw value - valid keywords")
    func initFromRawValue() {
        #expect(PDFKeyword(rawValue: "obj") == .obj)
        #expect(PDFKeyword(rawValue: "endobj") == .endobj)
        #expect(PDFKeyword(rawValue: "stream") == .stream)
        #expect(PDFKeyword(rawValue: "endstream") == .endstream)
        #expect(PDFKeyword(rawValue: "xref") == .xref)
        #expect(PDFKeyword(rawValue: "trailer") == .trailer)
        #expect(PDFKeyword(rawValue: "startxref") == .startxref)
        #expect(PDFKeyword(rawValue: "true") == .true)
        #expect(PDFKeyword(rawValue: "false") == .false)
        #expect(PDFKeyword(rawValue: "null") == .null)
        #expect(PDFKeyword(rawValue: "R") == .R)
    }

    @Test("Init from raw value - invalid keyword")
    func initFromInvalidRawValue() {
        #expect(PDFKeyword(rawValue: "invalid") == nil)
        #expect(PDFKeyword(rawValue: "OBJ") == nil)
        #expect(PDFKeyword(rawValue: "True") == nil)
        #expect(PDFKeyword(rawValue: "") == nil)
    }

    // MARK: - String Value

    @Test("String value property")
    func stringValueProperty() {
        #expect(PDFKeyword.obj.stringValue == "obj")
        #expect(PDFKeyword.endobj.stringValue == "endobj")
        #expect(PDFKeyword.stream.stringValue == "stream")
        #expect(PDFKeyword.endstream.stringValue == "endstream")
        #expect(PDFKeyword.xref.stringValue == "xref")
        #expect(PDFKeyword.trailer.stringValue == "trailer")
        #expect(PDFKeyword.startxref.stringValue == "startxref")
        #expect(PDFKeyword.true.stringValue == "true")
        #expect(PDFKeyword.false.stringValue == "false")
        #expect(PDFKeyword.null.stringValue == "null")
        #expect(PDFKeyword.R.stringValue == "R")
    }

    // MARK: - Equality

    @Test("Keywords are equal to themselves")
    func keywordsEqualToThemselves() {
        #expect(PDFKeyword.obj == .obj)
        #expect(PDFKeyword.endobj == .endobj)
        #expect(PDFKeyword.stream == .stream)
        #expect(PDFKeyword.true == .true)
        #expect(PDFKeyword.false == .false)
        #expect(PDFKeyword.null == .null)
    }

    @Test("Different keywords are not equal")
    func differentKeywordsNotEqual() {
        #expect(PDFKeyword.obj != .endobj)
        #expect(PDFKeyword.stream != .endstream)
        #expect(PDFKeyword.xref != .trailer)
        #expect(PDFKeyword.true != .false)
        #expect(PDFKeyword.true != .null)
    }

    // MARK: - Hashable

    @Test("Equal keywords have same hash")
    func equalKeywordsHaveSameHash() {
        #expect(PDFKeyword.obj.hashValue == PDFKeyword.obj.hashValue)
        #expect(PDFKeyword.true.hashValue == PDFKeyword.true.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        var dict: [PDFKeyword: String] = [:]
        dict[.obj] = "object"
        dict[.stream] = "stream"
        dict[.true] = "true"
        #expect(dict[.obj] == "object")
        #expect(dict[.stream] == "stream")
        #expect(dict[.true] == "true")
        #expect(dict.count == 3)
    }

    @Test("Can be stored in a Set")
    func storedInSet() {
        let set: Set<PDFKeyword> = [.obj, .endobj, .obj, .stream]
        #expect(set.count == 3)
        #expect(set.contains(.obj))
        #expect(set.contains(.endobj))
        #expect(set.contains(.stream))
        #expect(!set.contains(.xref))
    }

    // MARK: - Object Markers

    @Test("isObjectStart property")
    func isObjectStart() {
        #expect(PDFKeyword.obj.isObjectStart)
        #expect(!PDFKeyword.endobj.isObjectStart)
        #expect(!PDFKeyword.stream.isObjectStart)
        #expect(!PDFKeyword.xref.isObjectStart)
        #expect(!PDFKeyword.true.isObjectStart)
    }

    @Test("isObjectEnd property")
    func isObjectEnd() {
        #expect(PDFKeyword.endobj.isObjectEnd)
        #expect(!PDFKeyword.obj.isObjectEnd)
        #expect(!PDFKeyword.endstream.isObjectEnd)
        #expect(!PDFKeyword.trailer.isObjectEnd)
        #expect(!PDFKeyword.false.isObjectEnd)
    }

    // MARK: - Stream Markers

    @Test("isStreamStart property")
    func isStreamStart() {
        #expect(PDFKeyword.stream.isStreamStart)
        #expect(!PDFKeyword.endstream.isStreamStart)
        #expect(!PDFKeyword.obj.isStreamStart)
        #expect(!PDFKeyword.xref.isStreamStart)
    }

    @Test("isStreamEnd property")
    func isStreamEnd() {
        #expect(PDFKeyword.endstream.isStreamEnd)
        #expect(!PDFKeyword.stream.isStreamEnd)
        #expect(!PDFKeyword.endobj.isStreamEnd)
        #expect(!PDFKeyword.startxref.isStreamEnd)
    }

    // MARK: - Boolean Properties

    @Test("isBoolean property")
    func isBoolean() {
        #expect(PDFKeyword.true.isBoolean)
        #expect(PDFKeyword.false.isBoolean)
        #expect(!PDFKeyword.null.isBoolean)
        #expect(!PDFKeyword.obj.isBoolean)
        #expect(!PDFKeyword.stream.isBoolean)
    }

    @Test("booleanValue property")
    func booleanValue() {
        #expect(PDFKeyword.true.booleanValue == true)
        #expect(PDFKeyword.false.booleanValue == false)
        #expect(PDFKeyword.null.booleanValue == nil)
        #expect(PDFKeyword.obj.booleanValue == nil)
        #expect(PDFKeyword.stream.booleanValue == nil)
    }

    // MARK: - Case Iteration

    @Test("All cases are present")
    func allCasesPresent() {
        let allCases = PDFKeyword.allCases
        #expect(allCases.contains(.true))
        #expect(allCases.contains(.false))
        #expect(allCases.contains(.null))
        #expect(allCases.contains(.obj))
        #expect(allCases.contains(.endobj))
        #expect(allCases.contains(.stream))
        #expect(allCases.contains(.endstream))
        #expect(allCases.contains(.xref))
        #expect(allCases.contains(.trailer))
        #expect(allCases.contains(.startxref))
        #expect(allCases.contains(.R))
        #expect(allCases.count == PDFKeyword.allCases.count)
    }

    // MARK: - CustomStringConvertible

    @Test("Description matches raw value")
    func descriptionMatchesRawValue() {
        #expect(PDFKeyword.obj.description == "obj")
        #expect(PDFKeyword.endobj.description == "endobj")
        #expect(PDFKeyword.stream.description == "stream")
        #expect(PDFKeyword.endstream.description == "endstream")
        #expect(PDFKeyword.xref.description == "xref")
        #expect(PDFKeyword.trailer.description == "trailer")
        #expect(PDFKeyword.startxref.description == "startxref")
        #expect(PDFKeyword.true.description == "true")
        #expect(PDFKeyword.false.description == "false")
        #expect(PDFKeyword.null.description == "null")
        #expect(PDFKeyword.R.description == "R")
    }

    // MARK: - Codable

    @Test("Encode and decode keyword")
    func encodeDecodeKeyword() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let keyword = PDFKeyword.obj
        let encoded = try encoder.encode(keyword)
        let decoded = try decoder.decode(PDFKeyword.self, from: encoded)
        #expect(decoded == keyword)
    }

    @Test("Encode all keywords")
    func encodeAllKeywords() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for keyword in PDFKeyword.allCases {
            let encoded = try encoder.encode(keyword)
            let decoded = try decoder.decode(PDFKeyword.self, from: encoded)
            #expect(decoded == keyword)
        }
    }

    @Test("Encode keyword array")
    func encodeKeywordArray() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let keywords: [PDFKeyword] = [.obj, .stream, .endstream, .endobj]
        let encoded = try encoder.encode(keywords)
        let decoded = try decoder.decode([PDFKeyword].self, from: encoded)
        #expect(decoded == keywords)
    }

    // MARK: - Sendable

    @Test("PDFKeyword is Sendable")
    func keywordIsSendable() {
        // This test verifies that PDFKeyword conforms to Sendable
        // by attempting to send it across concurrency boundaries
        let keyword = PDFKeyword.obj
        Task {
            let _ = keyword
        }
    }

    // MARK: - Raw Value Round Trip

    @Test("Raw value round trip")
    func rawValueRoundTrip() {
        for keyword in PDFKeyword.allCases {
            let rawValue = keyword.rawValue
            let reconstructed = PDFKeyword(rawValue: rawValue)
            #expect(reconstructed == keyword)
        }
    }

    // MARK: - Edge Cases

    @Test("Case sensitivity")
    func caseSensitivity() {
        // PDF keywords are case-sensitive
        #expect(PDFKeyword(rawValue: "OBJ") == nil)
        #expect(PDFKeyword(rawValue: "Obj") == nil)
        #expect(PDFKeyword(rawValue: "TRUE") == nil)
        #expect(PDFKeyword(rawValue: "False") == nil)
        #expect(PDFKeyword(rawValue: "NULL") == nil)
        #expect(PDFKeyword(rawValue: "r") == nil)
    }

    @Test("Empty string is not a keyword")
    func emptyStringNotKeyword() {
        #expect(PDFKeyword(rawValue: "") == nil)
    }

    @Test("Whitespace in keywords")
    func whitespaceInKeywords() {
        #expect(PDFKeyword(rawValue: " obj") == nil)
        #expect(PDFKeyword(rawValue: "obj ") == nil)
        #expect(PDFKeyword(rawValue: " obj ") == nil)
    }
}
