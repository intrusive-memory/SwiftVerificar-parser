import Testing
@testable import SwiftVerificarParser

@Suite("PDFPageTree Tests")
struct PDFPageTreeTests {

    // MARK: - Initialization Tests

    @Test("PDFPageTree requires dictionary")
    func requiresDictionary() throws {
        #expect(throws: PDError.notADictionary) {
            try PDFPageTree(cosObject: .null)
        }

        #expect(throws: PDError.notADictionary) {
            try PDFPageTree(cosObject: .array([]))
        }
    }

    @Test("PDFPageTree accepts valid dictionary")
    func acceptsValidDictionary() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.cosObject.isDictionary)
    }

    // MARK: - Required Entry Tests

    @Test("count returns integer value")
    func count() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(5),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        let count = try pageTree.count()
        #expect(count == 5)
    }

    @Test("count throws when missing")
    func countMissing() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(throws: PDError.missingRequiredEntry(key: "Count")) {
            try pageTree.count()
        }
    }

    @Test("kids returns array")
    func kids() throws {
        let kid1: COSValue = .reference(COSReference(objectNumber: 10))
        let kid2: COSValue = .reference(COSReference(objectNumber: 11))
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(2),
            .kids: .array([kid1, kid2])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        let kids = try pageTree.kids()
        #expect(kids.count == 2)
    }

    @Test("kids throws when missing")
    func kidsMissing() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0)
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(throws: PDError.missingRequiredEntry(key: "Kids")) {
            try pageTree.kids()
        }
    }

    // MARK: - Optional Entry Tests

    @Test("parent returns optional value")
    func parent() throws {
        let parentRef: COSValue = .reference(COSReference(objectNumber: 1))
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([]),
            .parent: parentRef
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.parent != nil)
        #expect(pageTree.parent?.referenceValue?.objectNumber == 1)
    }

    @Test("parent returns nil for root")
    func parentNilForRoot() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.parent == nil)
    }

    // MARK: - Page Access Tests

    @Test("page at index returns page for single leaf")
    func pageAtIndexSingleLeaf() throws {
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

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        let page = try pageTree.page(at: 0)
        #expect(page.cosObject[.type]?.nameValue == .page)
    }

    @Test("page at index throws for out of bounds")
    func pageAtIndexOutOfBounds() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(1),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(throws: PDError.pageIndexOutOfBounds(index: 5, count: 1)) {
            try pageTree.page(at: 5)
        }
    }

    @Test("page at index throws for negative index")
    func pageAtIndexNegative() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(1),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(throws: PDError.pageIndexOutOfBounds(index: -1, count: 1)) {
            try pageTree.page(at: -1)
        }
    }

    @Test("page at index handles multiple pages")
    func pageAtIndexMultiple() throws {
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

        let pageTree = try PDFPageTree(cosObject: pagesDict)

        let firstPage = try pageTree.page(at: 0)
        #expect(firstPage.cosObject[.type]?.nameValue == .page)

        let secondPage = try pageTree.page(at: 1)
        #expect(secondPage.cosObject[.type]?.nameValue == .page)
    }

    @Test("page at index handles nested page trees")
    func pageAtIndexNested() throws {
        let page1: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 2)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]
        let page2: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 2)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let childTree: COSValue = [
            .type: .name(.pages),
            .count: .integer(2),
            .kids: .array([page1, page2]),
            .parent: .reference(COSReference(objectNumber: 1))
        ]

        let rootTree: COSValue = [
            .type: .name(.pages),
            .count: .integer(2),
            .kids: .array([childTree])
        ]

        let pageTree = try PDFPageTree(cosObject: rootTree)

        let firstPage = try pageTree.page(at: 0)
        #expect(firstPage.cosObject[.type]?.nameValue == .page)

        let secondPage = try pageTree.page(at: 1)
        #expect(secondPage.cosObject[.type]?.nameValue == .page)
    }

    @Test("allPages returns all pages")
    func allPages() throws {
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
        let page3: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(3),
            .kids: .array([page1, page2, page3])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        let pages = try pageTree.allPages()
        #expect(pages.count == 3)
    }

    @Test("allPages returns empty array for no pages")
    func allPagesEmpty() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        let pages = try pageTree.allPages()
        #expect(pages.isEmpty)
    }

    // MARK: - Inherited Attributes Tests

    @Test("resources returns optional dictionary")
    func resources() throws {
        let resourcesDict: COSValue = [
            .font: [ASAtom("F1"): .reference(COSReference(objectNumber: 10))]
        ]
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([]),
            .resources: resourcesDict
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.resources != nil)
    }

    @Test("mediaBox returns optional array")
    func mediaBox() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([]),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.mediaBox != nil)
        #expect(pageTree.mediaBox?.count == 4)
    }

    @Test("cropBox returns optional array")
    func cropBox() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([]),
            .cropBox: .array([.real(10), .real(10), .real(602), .real(782)])
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.cropBox != nil)
        #expect(pageTree.cropBox?.count == 4)
    }

    @Test("rotate returns optional integer")
    func rotate() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([]),
            "Rotate": .integer(90)
        ]

        let pageTree = try PDFPageTree(cosObject: pagesDict)
        #expect(pageTree.rotate == 90)
    }

    // MARK: - Hashable Tests

    @Test("PDFPageTree is hashable")
    func hashable() throws {
        let pagesDict: COSValue = [
            .type: .name(.pages),
            .count: .integer(0),
            .kids: .array([])
        ]
        let pageTree1 = try PDFPageTree(cosObject: pagesDict)
        let pageTree2 = try PDFPageTree(cosObject: pagesDict)

        #expect(pageTree1 == pageTree2)
        #expect(pageTree1.hashValue == pageTree2.hashValue)
    }
}
