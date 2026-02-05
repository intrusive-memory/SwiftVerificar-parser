import Testing
import Foundation
@testable import SwiftVerificarParser

/// Test suite for COSParser protocol default implementations.
@Suite("COSParser Tests")
struct COSParserTests {

    // MARK: - Mock Parser Implementation

    /// A mock parser for testing the default protocol implementations.
    struct MockCOSParser: COSParser {
        let header: PDFHeader
        let xrefTable: XRefTable
        let trailer: PDFTrailer

        private var objects: [COSObjectKey: COSValue]

        init(
            header: PDFHeader = PDFHeader(major: 1, minor: 7),
            xrefTable: XRefTable,
            trailer: PDFTrailer,
            objects: [COSObjectKey: COSValue] = [:]
        ) {
            self.header = header
            self.xrefTable = xrefTable
            self.trailer = trailer
            self.objects = objects
        }

        func getObject(key: COSObjectKey) async throws -> COSValue? {
            objects[key]
        }
    }

    // MARK: - Default Implementation Tests

    @Test("getObject by number uses generation 0")
    func getObjectByNumberUsesGeneration0() async throws {
        let key = COSObjectKey(objectNumber: 42, generation: 0)
        let value = COSValue.integer(123)

        let subsection = XRefSubsection(startObjectNumber: 42, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [key: value]
        )

        let result = try await parser.getObject(objectNumber: 42)
        #expect(result == value)
    }

    @Test("getCatalog returns catalog object")
    func getCatalogReturnsCatalogObject() async throws {
        let catalogKey = COSObjectKey(objectNumber: 1, generation: 0)
        let catalogValue = COSValue.dictionary([.type: .name(.catalog)])

        let subsection = XRefSubsection(startObjectNumber: 1, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        // Store the reference in the trailer
        let trailerDict: [ASAtom: COSValue] = [
            .root: .reference(COSReference(key: catalogKey))
        ]
        let trailer = PDFTrailer(dictionary: trailerDict)
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [catalogKey: catalogValue]
        )

        let catalog = try await parser.getCatalog()
        #expect(catalog?.isDictionary == true)
        #expect(catalog?[.type]?.nameValue == .catalog)
    }

    @Test("getCatalog returns nil when no root reference")
    func getCatalogReturnsNilWhenNoRoot() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let catalog = try await parser.getCatalog()
        #expect(catalog == nil)
    }

    @Test("getInfo returns info dictionary")
    func getInfoReturnsInfoDictionary() async throws {
        let infoKey = COSObjectKey(objectNumber: 2, generation: 0)
        let infoValue = COSValue.dictionary([
            ASAtom("Title"): .string(COSString(string: "Test Document")),
            ASAtom("Author"): .string(COSString(string: "Test Author"))
        ])

        let subsection = XRefSubsection(startObjectNumber: 2, entries: [
            .inUse(offset: 200, generation: 0)
        ])
        let trailerDict: [ASAtom: COSValue] = [
            .info: .reference(COSReference(key: infoKey))
        ]
        let trailer = PDFTrailer(dictionary: trailerDict)
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [infoKey: infoValue]
        )

        let info = try await parser.getInfo()
        #expect(info?.isDictionary == true)
        #expect(info?[ASAtom("Title")]?.isString == true)
    }

    @Test("getInfo returns nil when no info reference")
    func getInfoReturnsNilWhenNoInfo() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let info = try await parser.getInfo()
        #expect(info == nil)
    }

    // MARK: - Reference Resolution

    @Test("resolve returns value as-is for non-reference")
    func resolveReturnsValueForNonReference() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let value = COSValue.integer(42)
        let resolved = try await parser.resolve(value)
        #expect(resolved == value)
    }

    @Test("resolve follows reference")
    func resolveFollowsReference() async throws {
        let key = COSObjectKey(objectNumber: 10, generation: 0)
        let targetValue = COSValue.string(COSString(string: "Referenced Value"))

        let subsection = XRefSubsection(startObjectNumber: 10, entries: [
            .inUse(offset: 300, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [key: targetValue]
        )

        let reference = COSValue.reference(COSReference(key: key))
        let resolved = try await parser.resolve(reference)
        #expect(resolved == targetValue)
    }

    @Test("resolve returns null for missing reference")
    func resolveReturnsNullForMissingReference() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let reference = COSValue.reference(COSReference(objectNumber: 999))
        let resolved = try await parser.resolve(reference)
        #expect(resolved == .null)
    }

    // MARK: - Full Resolution (Transitive)

    @Test("fullyResolve follows chain of references")
    func fullyResolveFollowsChain() async throws {
        let key1 = COSObjectKey(objectNumber: 1, generation: 0)
        let key2 = COSObjectKey(objectNumber: 2, generation: 0)
        let key3 = COSObjectKey(objectNumber: 3, generation: 0)

        let finalValue = COSValue.integer(42)
        let ref2 = COSValue.reference(COSReference(key: key3))
        let ref1 = COSValue.reference(COSReference(key: key2))

        let subsection = XRefSubsection(startObjectNumber: 1, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [
                key1: ref1,
                key2: ref2,
                key3: finalValue
            ]
        )

        let resolved = try await parser.fullyResolve(ref1)
        #expect(resolved == finalValue)
    }

    @Test("fullyResolve detects circular references")
    func fullyResolveDetectsCircularReferences() async throws {
        let key1 = COSObjectKey(objectNumber: 1, generation: 0)
        let key2 = COSObjectKey(objectNumber: 2, generation: 0)

        let ref1 = COSValue.reference(COSReference(key: key2))
        let ref2 = COSValue.reference(COSReference(key: key1))

        let subsection = XRefSubsection(startObjectNumber: 1, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [
                key1: ref1,
                key2: ref2
            ]
        )

        let resolved = try await parser.fullyResolve(ref1)
        #expect(resolved == .null)
    }

    @Test("fullyResolve returns value for non-reference")
    func fullyResolveReturnsValueForNonReference() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let value = COSValue.array([.integer(1), .integer(2)])
        let resolved = try await parser.fullyResolve(value)
        #expect(resolved == value)
    }

    // MARK: - Dictionary Resolution

    @Test("resolveDictionary resolves reference to dictionary")
    func resolveDictionaryResolvesReference() async throws {
        let key = COSObjectKey(objectNumber: 5, generation: 0)
        let dictValue = COSValue.dictionary([.type: .name(.page)])

        let subsection = XRefSubsection(startObjectNumber: 5, entries: [
            .inUse(offset: 500, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [key: dictValue]
        )

        let reference = COSValue.reference(COSReference(key: key))
        let dict = try await parser.resolveDictionary(reference)
        #expect(dict != nil)
        #expect(dict?[.type]?.nameValue == .page)
    }

    @Test("resolveDictionary returns nil for non-dictionary")
    func resolveDictionaryReturnsNilForNonDictionary() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let value = COSValue.integer(42)
        let dict = try await parser.resolveDictionary(value)
        #expect(dict == nil)
    }

    // MARK: - Array Resolution

    @Test("resolveArray resolves reference to array")
    func resolveArrayResolvesReference() async throws {
        let key = COSObjectKey(objectNumber: 7, generation: 0)
        let arrayValue = COSValue.array([.integer(1), .integer(2), .integer(3)])

        let subsection = XRefSubsection(startObjectNumber: 7, entries: [
            .inUse(offset: 700, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [key: arrayValue]
        )

        let reference = COSValue.reference(COSReference(key: key))
        let array = try await parser.resolveArray(reference)
        #expect(array?.count == 3)
    }

    @Test("resolveArray returns nil for non-array")
    func resolveArrayReturnsNilForNonArray() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let value = COSValue.dictionary([:])
        let array = try await parser.resolveArray(value)
        #expect(array == nil)
    }

    // MARK: - Entry Resolution

    @Test("resolveEntry finds and resolves dictionary entry")
    func resolveEntryFindsAndResolves() async throws {
        let key = COSObjectKey(objectNumber: 8, generation: 0)
        let targetValue = COSValue.string(COSString(string: "Target"))

        let subsection = XRefSubsection(startObjectNumber: 8, entries: [
            .inUse(offset: 800, generation: 0)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(
            xrefTable: xref,
            trailer: trailer,
            objects: [key: targetValue]
        )

        let dict: [ASAtom: COSValue] = [
            ASAtom("Key"): .reference(COSReference(key: key))
        ]

        let resolved = try await parser.resolveEntry(dict, key: ASAtom("Key"))
        #expect(resolved == targetValue)
    }

    @Test("resolveEntry returns nil for missing key")
    func resolveEntryReturnsNilForMissingKey() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let dict: [ASAtom: COSValue] = [:]
        let resolved = try await parser.resolveEntry(dict, key: ASAtom("Missing"))
        #expect(resolved == nil)
    }

    @Test("resolveEntry resolves non-reference values")
    func resolveEntryResolvesNonReferenceValues() async throws {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535)
        ])
        let trailer = PDFTrailer(dictionary: [:])
        let xref = XRefTable(subsections: [subsection], trailer: trailer)

        let parser = MockCOSParser(xrefTable: xref, trailer: trailer)

        let dict: [ASAtom: COSValue] = [
            ASAtom("Direct"): .integer(123)
        ]

        let resolved = try await parser.resolveEntry(dict, key: ASAtom("Direct"))
        #expect(resolved == .integer(123))
    }
}
