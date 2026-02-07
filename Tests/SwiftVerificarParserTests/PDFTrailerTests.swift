import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFTrailer Tests")
struct PDFTrailerTests {

    // MARK: - Initialization from Dictionary

    @Test("Init with dictionary")
    func initFromDictionary() {
        let dict: [ASAtom: COSValue] = [
            .root: .integer(1),
            .size: .integer(100),
        ]
        let trailer = PDFTrailer(dictionary: dict)
        #expect(trailer.dictionary.count == 2)
    }

    @Test("Init with empty dictionary")
    func initEmptyDictionary() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(trailer.dictionary.isEmpty)
        #expect(trailer.rootValue == nil)
        #expect(trailer.size == nil)
    }

    // MARK: - Initialization with Explicit Values

    @Test("Init with root reference and size")
    func initWithRootAndSize() {
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 100
        )
        #expect(trailer.rootValue != nil)
        #expect(trailer.size == 100)
    }

    @Test("Init with all optional parameters")
    func initWithAllParams() {
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            infoReference: COSReference(objectNumber: 2),
            encryptReference: COSReference(objectNumber: 3),
            size: 100,
            previousXRefOffset: 5000,
            documentID: (COSString(string: "ID1"), COSString(string: "ID2"))
        )
        #expect(trailer.rootValue != nil)
        #expect(trailer.infoValue != nil)
        #expect(trailer.encryptValue != nil)
        #expect(trailer.size == 100)
        #expect(trailer.previousXRefOffset == 5000)
        #expect(trailer.isEncrypted)
        #expect(trailer.hasIncrementalUpdate)
    }

    @Test("Init without optional parameters")
    func initWithoutOptionals() {
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 50
        )
        #expect(trailer.infoValue == nil)
        #expect(trailer.encryptValue == nil)
        #expect(trailer.previousXRefOffset == nil)
        #expect(trailer.documentID == nil)
        #expect(!trailer.isEncrypted)
        #expect(!trailer.hasIncrementalUpdate)
    }

    // MARK: - Dictionary Access

    @Test("Subscript by ASAtom key")
    func subscriptAtom() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(100),
        ])
        #expect(trailer[.root]?.integerValue == 1)
        #expect(trailer[.size]?.integerValue == 100)
    }

    @Test("Subscript by string key")
    func subscriptString() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
        ])
        #expect(trailer["Root"]?.integerValue == 1)
    }

    @Test("Subscript returns nil for missing key")
    func subscriptMissing() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(trailer[.root] == nil)
        #expect(trailer["Info"] == nil)
    }

    // MARK: - Standard Trailer Entries

    @Test("Root value")
    func rootValue() {
        let trailer = PDFTrailer(dictionary: [.root: .integer(1)])
        #expect(trailer.rootValue?.integerValue == 1)
    }

    @Test("Info value")
    func infoValue() {
        let trailer = PDFTrailer(dictionary: [.info: .integer(2)])
        #expect(trailer.infoValue?.integerValue == 2)
    }

    @Test("Encrypt value")
    func encryptValue() {
        let trailer = PDFTrailer(dictionary: [.encrypt: .integer(3)])
        #expect(trailer.encryptValue?.integerValue == 3)
    }

    @Test("Size value")
    func sizeValue() {
        let trailer = PDFTrailer(dictionary: [.size: .integer(100)])
        #expect(trailer.size == 100)
    }

    @Test("Size returns nil for non-integer")
    func sizeNonInteger() {
        let trailer = PDFTrailer(dictionary: [.size: .name(ASAtom("big"))])
        #expect(trailer.size == nil)
    }

    @Test("Previous XRef offset")
    func previousXRefOffset() {
        let trailer = PDFTrailer(dictionary: [.prev: .integer(5000)])
        #expect(trailer.previousXRefOffset == 5000)
    }

    @Test("Previous XRef offset returns nil when missing")
    func previousXRefOffsetMissing() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(trailer.previousXRefOffset == nil)
    }

    // MARK: - Document ID

    @Test("Document ID present")
    func documentIDPresent() {
        let id1 = COSString(string: "FirstID")
        let id2 = COSString(string: "SecondID")
        let trailer = PDFTrailer(dictionary: [
            .id: .array([.string(id1), .string(id2)])
        ])
        let docID = trailer.documentID
        #expect(docID != nil)
        #expect(docID?.0 == id1)
        #expect(docID?.1 == id2)
    }

    @Test("Document ID missing")
    func documentIDMissing() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(trailer.documentID == nil)
    }

    @Test("Document ID with wrong type")
    func documentIDWrongType() {
        let trailer = PDFTrailer(dictionary: [.id: .integer(42)])
        #expect(trailer.documentID == nil)
    }

    @Test("Document ID with too few elements")
    func documentIDTooFew() {
        let trailer = PDFTrailer(dictionary: [
            .id: .array([.string(COSString(string: "OnlyOne"))])
        ])
        #expect(trailer.documentID == nil)
    }

    @Test("Document ID with non-string elements")
    func documentIDNonString() {
        let trailer = PDFTrailer(dictionary: [
            .id: .array([.integer(1), .integer(2)])
        ])
        #expect(trailer.documentID == nil)
    }

    // MARK: - Boolean Properties

    @Test("isEncrypted when encrypt present")
    func isEncryptedTrue() {
        let trailer = PDFTrailer(dictionary: [.encrypt: .integer(3)])
        #expect(trailer.isEncrypted)
    }

    @Test("isEncrypted when encrypt absent")
    func isEncryptedFalse() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(!trailer.isEncrypted)
    }

    @Test("hasIncrementalUpdate when prev present")
    func hasIncrementalUpdateTrue() {
        let trailer = PDFTrailer(dictionary: [.prev: .integer(5000)])
        #expect(trailer.hasIncrementalUpdate)
    }

    @Test("hasIncrementalUpdate when prev absent")
    func hasIncrementalUpdateFalse() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(!trailer.hasIncrementalUpdate)
    }

    // MARK: - Entry Count

    @Test("Entry count")
    func entryCount() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(100),
            .info: .integer(2),
        ])
        #expect(trailer.entryCount == 3)
    }

    @Test("Entry count for empty trailer")
    func entryCountEmpty() {
        let trailer = PDFTrailer(dictionary: [:])
        #expect(trailer.entryCount == 0)
    }

    // MARK: - Equality

    @Test("Equal trailers")
    func equalTrailers() {
        let dict: [ASAtom: COSValue] = [.root: .integer(1), .size: .integer(100)]
        let a = PDFTrailer(dictionary: dict)
        let b = PDFTrailer(dictionary: dict)
        #expect(a == b)
    }

    @Test("Different dictionaries are not equal")
    func differentDictionaries() {
        let a = PDFTrailer(dictionary: [.root: .integer(1)])
        let b = PDFTrailer(dictionary: [.root: .integer(2)])
        #expect(a != b)
    }

    @Test("Different entry counts are not equal")
    func differentEntryCounts() {
        let a = PDFTrailer(dictionary: [.root: .integer(1)])
        let b = PDFTrailer(dictionary: [.root: .integer(1), .size: .integer(50)])
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Equal trailers have same hash")
    func equalHashValues() {
        let dict: [ASAtom: COSValue] = [.root: .integer(1), .size: .integer(100)]
        let a = PDFTrailer(dictionary: dict)
        let b = PDFTrailer(dictionary: dict)
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Description

    @Test("Description includes size and root")
    func descriptionBasic() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(100),
        ])
        let desc = trailer.description
        #expect(desc.contains("trailer"))
        #expect(desc.contains("size: 100"))
        #expect(desc.contains("root:"))
    }

    @Test("Description indicates encryption")
    func descriptionEncrypted() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(100),
            .encrypt: .integer(3),
        ])
        let desc = trailer.description
        #expect(desc.contains("encrypted: yes"))
    }

    @Test("Description indicates incremental update")
    func descriptionIncremental() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(100),
            .prev: .integer(5000),
        ])
        let desc = trailer.description
        #expect(desc.contains("prev: 5000"))
    }

    @Test("Description indicates info present")
    func descriptionInfo() {
        let trailer = PDFTrailer(dictionary: [
            .root: .integer(1),
            .info: .integer(2),
        ])
        let desc = trailer.description
        #expect(desc.contains("info: present"))
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(100),
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFTrailer.self, from: data)
        #expect(original == decoded)
    }

    @Test("Encode and decode with document ID")
    func codableWithDocumentID() throws {
        let original = PDFTrailer(dictionary: [
            .root: .integer(1),
            .size: .integer(50),
            .id: .array([
                .string(COSString(string: "ID1")),
                .string(COSString(string: "ID2")),
            ]),
        ])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFTrailer.self, from: data)
        #expect(decoded.documentID != nil)
    }

    @Test("Encode and decode empty trailer")
    func codableEmptyTrailer() throws {
        let original = PDFTrailer(dictionary: [:])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFTrailer.self, from: data)
        #expect(decoded.dictionary.isEmpty)
    }

    // MARK: - Sendable

    @Test("PDFTrailer is Sendable")
    func sendable() async {
        let trailer = PDFTrailer(dictionary: [.root: .integer(1), .size: .integer(100)])
        let task = Task { trailer }
        let result = await task.value
        #expect(result == trailer)
    }

    // MARK: - Edge Cases

    @Test("Trailer with many entries")
    func manyEntries() {
        var dict: [ASAtom: COSValue] = [:]
        for i in 0..<20 {
            dict[ASAtom("Key\(i)")] = .integer(Int64(i))
        }
        let trailer = PDFTrailer(dictionary: dict)
        #expect(trailer.entryCount == 20)
    }

    @Test("Large size value")
    func largeSizeValue() {
        let trailer = PDFTrailer(dictionary: [.size: .integer(Int64.max)])
        #expect(trailer.size == Int64.max)
    }

    @Test("Large previous offset")
    func largePreviousOffset() {
        let trailer = PDFTrailer(dictionary: [.prev: .integer(999_999_999)])
        #expect(trailer.previousXRefOffset == 999_999_999)
    }
}
