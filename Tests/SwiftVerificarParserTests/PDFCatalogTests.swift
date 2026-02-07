import Testing
@testable import SwiftVerificarParser

@Suite("PDFCatalog Tests")
struct PDFCatalogTests {

    // MARK: - Initialization Tests

    @Test("PDFCatalog requires dictionary")
    func requiresDictionary() throws {
        #expect(throws: PDError.notADictionary) {
            try PDFCatalog(cosObject: .null)
        }

        #expect(throws: PDError.notADictionary) {
            try PDFCatalog(cosObject: .integer(42))
        }
    }

    @Test("PDFCatalog accepts valid dictionary")
    func acceptsValidDictionary() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(1),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.cosObject.isDictionary)
    }

    // MARK: - Pages Entry Tests

    @Test("pagesObject returns pages dictionary")
    func pagesObject() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(1),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        let pages = try catalog.pagesObject()
        #expect(pages[.type]?.nameValue == .pages)
    }

    @Test("pagesObject throws when missing")
    func pagesObjectMissing() throws {
        let catalogDict: COSValue = [.type: .name(.catalog)]
        let catalog = try PDFCatalog(cosObject: catalogDict)

        #expect(throws: PDError.missingRequiredEntry(key: "Pages")) {
            try catalog.pagesObject()
        }
    }

    @Test("pageTree returns PDFPageTree")
    func pageTree() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(1),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        let pageTree = try catalog.pageTree()
        #expect(pageTree.cosObject[.type]?.nameValue == .pages)
    }

    // MARK: - Optional Entry Tests

    @Test("metadata returns optional value")
    func metadata() throws {
        let metadataRef: COSValue = .reference(COSReference(objectNumber: 10))
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .metadata: metadataRef
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.metadata != nil)
        #expect(catalog.metadata?.referenceValue?.objectNumber == 10)
    }

    @Test("metadata returns nil when missing")
    func metadataMissing() throws {
        let catalogDict: COSValue = [.type: .name(.catalog)]
        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.metadata == nil)
    }

    @Test("structTreeRoot returns optional value")
    func structTreeRoot() throws {
        let structRef: COSValue = .reference(COSReference(objectNumber: 20))
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .structTreeRoot: structRef
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.structTreeRoot != nil)
        #expect(catalog.structTreeRoot?.referenceValue?.objectNumber == 20)
    }

    @Test("markInfo returns optional value")
    func markInfo() throws {
        let markInfoDict: COSValue = ["Marked": .boolean(true)]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .markInfo: markInfoDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.markInfo != nil)
        #expect(catalog.markInfo?["Marked"]?.boolValue == true)
    }

    @Test("lang returns optional string")
    func lang() throws {
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .lang: .string(COSString(string: "en-US"))
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.lang == "en-US")
    }

    @Test("lang returns nil when missing")
    func langMissing() throws {
        let catalogDict: COSValue = [.type: .name(.catalog)]
        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.lang == nil)
    }

    @Test("version returns optional name")
    func version() throws {
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            "Version": .name(ASAtom("1.7"))
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.version?.stringValue == "1.7")
    }

    @Test("outlines returns optional value")
    func outlines() throws {
        let outlinesDict: COSValue = [.type: .name("Outlines")]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            "Outlines": outlinesDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.outlines != nil)
    }

    @Test("dests returns optional value")
    func dests() throws {
        let destsDict: COSValue = ["Dest1": .array([])]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            "Dests": destsDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.dests != nil)
    }

    @Test("viewerPreferences returns optional value")
    func viewerPreferences() throws {
        let vpDict: COSValue = ["HideToolbar": .boolean(true)]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            "ViewerPreferences": vpDict
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.viewerPreferences != nil)
    }

    @Test("pageMode returns optional name")
    func pageMode() throws {
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            "PageMode": .name("UseOutlines")
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.pageMode?.stringValue == "UseOutlines")
    }

    @Test("pageLayout returns optional name")
    func pageLayout() throws {
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            "PageLayout": .name("TwoColumnLeft")
        ]

        let catalog = try PDFCatalog(cosObject: catalogDict)
        #expect(catalog.pageLayout?.stringValue == "TwoColumnLeft")
    }

    // MARK: - Hashable Tests

    @Test("PDFCatalog is hashable")
    func hashable() throws {
        let catalogDict: COSValue = [.type: .name(.catalog)]
        let catalog1 = try PDFCatalog(cosObject: catalogDict)
        let catalog2 = try PDFCatalog(cosObject: catalogDict)

        #expect(catalog1 == catalog2)
        #expect(catalog1.hashValue == catalog2.hashValue)
    }
}
