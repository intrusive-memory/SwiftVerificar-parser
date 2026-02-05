import Testing
@testable import SwiftVerificarParser

@Suite("PDDocument Tests")
struct PDDocumentTests {

    // MARK: - Helper Functions

    func createMinimalDocument() throws -> PDDocument {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        return try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )
    }

    // MARK: - Initialization Tests

    @Test("PDDocument initializes with valid components")
    func initializesWithValidComponents() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.header.major == 1)
        #expect(document.header.minor == 7)
        #expect(document.trailer.size == 10)
    }

    @Test("PDDocument throws for invalid catalog")
    func throwsForInvalidCatalog() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )

        #expect(throws: PDError.notADictionary) {
            try PDDocument(
                header: header,
                trailer: trailer,
                catalog: .null,
                xrefTable: nil
            )
        }
    }

    // MARK: - Version Tests

    @Test("version returns header version")
    func versionReturnsHeaderVersion() throws {
        let document = try createMinimalDocument()
        #expect(document.version.major == 1)
        #expect(document.version.minor == 7)
    }

    @Test("versionString formats version correctly")
    func versionStringFormatsCorrectly() throws {
        let document = try createMinimalDocument()
        #expect(document.versionString == "1.7")
    }

    @Test("catalogVersion returns catalog version when present")
    func catalogVersionWhenPresent() throws {
        let header = PDFHeader(major: 1, minor: 4)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            "Version": .name(ASAtom("1.7"))
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.catalogVersion == "1.7")
    }

    @Test("catalogVersion returns nil when not present")
    func catalogVersionNil() throws {
        let document = try createMinimalDocument()
        #expect(document.catalogVersion == nil)
    }

    @Test("effectiveVersion prefers catalog version")
    func effectiveVersionPrefersCatalog() throws {
        let header = PDFHeader(major: 1, minor: 4)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            "Version": .name(ASAtom("1.7"))
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.effectiveVersion == "1.7")
    }

    @Test("effectiveVersion falls back to header version")
    func effectiveVersionFallsBack() throws {
        let document = try createMinimalDocument()
        #expect(document.effectiveVersion == "1.7")
    }

    @Test("language returns lang from catalog")
    func languageFromCatalog() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            .lang: .string(COSString(string: "en-US"))
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.language == "en-US")
    }

    // MARK: - Page Access Tests

    @Test("pageTree returns page tree")
    func pageTreeReturns() throws {
        let document = try createMinimalDocument()
        let pageTree = try document.pageTree()
        #expect(pageTree.cosObject[.type]?.nameValue == .pages)
    }

    @Test("pageCount returns correct count")
    func pageCountReturnsCorrect() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(3),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(try document.pageCount() == 3)
    }

    @Test("page at index returns page")
    func pageAtIndexReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(1),
            .kids: .array([pageDict])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        let page = try document.page(at: 0)
        #expect(page.cosObject[.type]?.nameValue == .page)
    }

    @Test("allPages returns all pages")
    func allPagesReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let page1: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]
        let page2: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(2),
            .kids: .array([page1, page2])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        let pages = try document.allPages()
        #expect(pages.count == 2)
    }

    // MARK: - Metadata Tests

    @Test("metadata returns metadata stream")
    func metadataReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let metadataRef: COSValue = .reference(COSReference(objectNumber: 5))
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            .metadata: metadataRef
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.metadata != nil)
        #expect(document.metadata?.referenceValue?.objectNumber == 5)
    }

    @Test("info returns info dictionary")
    func infoReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let infoRef = COSReference(objectNumber: 2)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            infoReference: infoRef,
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.info != nil)
        #expect(document.info?.referenceValue?.objectNumber == 2)
    }

    // MARK: - Structure and Accessibility Tests

    @Test("structTreeRoot returns structure tree")
    func structTreeRootReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let structRef: COSValue = .reference(COSReference(objectNumber: 6))
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            .structTreeRoot: structRef
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.structTreeRoot != nil)
    }

    @Test("isTagged returns true when marked")
    func isTaggedTrue() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let markInfoDict: COSValue = ["Marked": .boolean(true)]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            .markInfo: markInfoDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.isTagged == true)
    }

    @Test("isTagged returns false when not marked")
    func isTaggedFalse() throws {
        let document = try createMinimalDocument()
        #expect(document.isTagged == false)
    }

    @Test("markInfo returns mark info dictionary")
    func markInfoReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let markInfoDict: COSValue = ["Marked": .boolean(true)]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            .markInfo: markInfoDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.markInfo != nil)
    }

    // MARK: - Encryption Tests

    @Test("isEncrypted returns true when encrypted")
    func isEncryptedTrue() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let encryptRef = COSReference(objectNumber: 3)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            encryptReference: encryptRef,
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.isEncrypted == true)
    }

    @Test("isEncrypted returns false when not encrypted")
    func isEncryptedFalse() throws {
        let document = try createMinimalDocument()
        #expect(document.isEncrypted == false)
    }

    @Test("encryptionDict returns encryption dictionary")
    func encryptionDictReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let encryptRef = COSReference(objectNumber: 3)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            encryptReference: encryptRef,
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.encryptionDict != nil)
        #expect(document.encryptionDict?.referenceValue?.objectNumber == 3)
    }

    // MARK: - Navigation and Viewing Tests

    @Test("outlines returns outlines dictionary")
    func outlinesReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let outlinesDict: COSValue = [.type: .name("Outlines")]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            "Outlines": outlinesDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.outlines != nil)
    }

    @Test("pageMode returns page mode")
    func pageModeReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            "PageMode": .name("UseOutlines")
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.pageMode?.stringValue == "UseOutlines")
    }

    @Test("pageLayout returns page layout")
    func pageLayoutReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            "PageLayout": .name("TwoColumnLeft")
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.pageLayout?.stringValue == "TwoColumnLeft")
    }

    @Test("viewerPreferences returns viewer preferences")
    func viewerPreferencesReturns() throws {
        let header = PDFHeader(major: 1, minor: 7)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 10
        )
        let vpDict: COSValue = ["HideToolbar": .boolean(true)]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let catalogDict: COSValue = [
            .type: .name(.catalog),
            .pages: pagesDict,
            "ViewerPreferences": vpDict
        ]

        let document = try PDDocument(
            header: header,
            trailer: trailer,
            catalog: catalogDict,
            xrefTable: nil
        )

        #expect(document.viewerPreferences != nil)
    }

    // MARK: - Description Tests

    @Test("description includes version and page count")
    func descriptionFormat() throws {
        let document = try createMinimalDocument()
        let description = document.description
        #expect(description.contains("1.7"))
        #expect(description.contains("0 pages"))
    }
}
