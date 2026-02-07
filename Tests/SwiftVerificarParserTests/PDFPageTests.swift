import Testing
@testable import SwiftVerificarParser
#if canImport(CoreGraphics)
import CoreGraphics
#endif

@Suite("PDFPage Tests")
struct PDFPageTests {

    // MARK: - Initialization Tests

    @Test("PDFPage requires dictionary")
    func requiresDictionary() throws {
        #expect(throws: PDError.notADictionary) {
            try PDFPage(cosObject: .null)
        }

        #expect(throws: PDError.notADictionary) {
            try PDFPage(cosObject: .array([]))
        }
    }

    @Test("PDFPage accepts valid dictionary")
    func acceptsValidDictionary() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.cosObject.isDictionary)
    }

    // MARK: - Required Entry Tests

    @Test("parent returns parent reference")
    func parent() throws {
        let parentRef: COSValue = .reference(COSReference(objectNumber: 5))
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: parentRef,
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        let parent = try page.parent()
        #expect(parent.referenceValue?.objectNumber == 5)
    }

    @Test("parent throws when missing")
    func parentMissing() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(throws: PDError.missingRequiredEntry(key: "Parent")) {
            try page.parent()
        }
    }

    @Test("mediaBox returns array")
    func mediaBox() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        let mediaBox = try page.mediaBox()
        #expect(mediaBox.count == 4)
        #expect(mediaBox[0].realValue == 0.0)
        #expect(mediaBox[1].realValue == 0.0)
        #expect(mediaBox[2].realValue == 612.0)
        #expect(mediaBox[3].realValue == 792.0)
    }

    @Test("mediaBox throws when missing")
    func mediaBoxMissing() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1))
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(throws: PDError.missingRequiredEntry(key: "MediaBox")) {
            try page.mediaBox()
        }
    }

    #if canImport(CoreGraphics)
    @Test("mediaBoxRect converts to CGRect")
    func mediaBoxRect() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        let rect = try page.mediaBoxRect()
        #expect(rect != nil)
        #expect(rect?.origin.x == 0.0)
        #expect(rect?.origin.y == 0.0)
        #expect(rect?.width == 612.0)
        #expect(rect?.height == 792.0)
    }

    @Test("mediaBoxRect handles malformed arrays")
    func mediaBoxRectMalformed() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .parent: .reference(COSReference(objectNumber: 1)),
            .mediaBox: .array([.real(0), .real(0)])  // Only 2 elements
        ]

        let page = try PDFPage(cosObject: pageDict)
        let rect = try page.mediaBoxRect()
        #expect(rect == nil)
    }
    #endif

    // MARK: - Optional Entry Tests

    @Test("cropBox returns optional array")
    func cropBox() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            .cropBox: .array([.real(10), .real(10), .real(602), .real(782)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.cropBox != nil)
        #expect(page.cropBox?.count == 4)
    }

    @Test("cropBox returns nil when missing")
    func cropBoxMissing() throws {
        let pageDict: COSValue = [.type: .name(.page)]
        let page = try PDFPage(cosObject: pageDict)
        #expect(page.cropBox == nil)
    }

    @Test("resources returns optional dictionary")
    func resources() throws {
        let resourcesDict: COSValue = [
            .font: [ASAtom("F1"): .reference(COSReference(objectNumber: 10))]
        ]
        let pageDict: COSValue = [
            .type: .name(.page),
            .resources: resourcesDict
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.resources != nil)
        #expect(page.resources?.isDictionary == true)
    }

    @Test("resourcesObject returns PDFResources")
    func resourcesObject() throws {
        let resourcesDict: COSValue = [
            .font: [ASAtom("F1"): .reference(COSReference(objectNumber: 10))]
        ]
        let pageDict: COSValue = [
            .type: .name(.page),
            .resources: resourcesDict
        ]

        let page = try PDFPage(cosObject: pageDict)
        let resources = try page.resourcesObject()
        #expect(resources != nil)
        #expect(resources?.fonts != nil)
    }

    @Test("resourcesObject returns nil when resources missing")
    func resourcesObjectMissing() throws {
        let pageDict: COSValue = [.type: .name(.page)]
        let page = try PDFPage(cosObject: pageDict)
        let resources = try page.resourcesObject()
        #expect(resources == nil)
    }

    @Test("contents returns optional value")
    func contents() throws {
        let contentsRef: COSValue = .reference(COSReference(objectNumber: 15))
        let pageDict: COSValue = [
            .type: .name(.page),
            .contents: contentsRef
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.contents != nil)
        #expect(page.contents?.referenceValue?.objectNumber == 15)
    }

    @Test("contents can be an array")
    func contentsArray() throws {
        let contentsArray: COSValue = .array([
            .reference(COSReference(objectNumber: 15)),
            .reference(COSReference(objectNumber: 16))
        ])
        let pageDict: COSValue = [
            .type: .name(.page),
            .contents: contentsArray
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.contents != nil)
        #expect(page.contents?.isArray == true)
    }

    @Test("rotate returns optional integer")
    func rotate() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            "Rotate": .integer(90)
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.rotate == 90)
    }

    @Test("annots returns optional array")
    func annots() throws {
        let annotsArray: COSValue = .array([
            .reference(COSReference(objectNumber: 20)),
            .reference(COSReference(objectNumber: 21))
        ])
        let pageDict: COSValue = [
            .type: .name(.page),
            .annots: annotsArray
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.annots != nil)
        #expect(page.annots?.count == 2)
    }

    @Test("thumb returns optional value")
    func thumb() throws {
        let thumbRef: COSValue = .reference(COSReference(objectNumber: 25))
        let pageDict: COSValue = [
            .type: .name(.page),
            "Thumb": thumbRef
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.thumb != nil)
    }

    @Test("bleedBox returns optional array")
    func bleedBox() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            "BleedBox": .array([.real(0), .real(0), .real(612), .real(792)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.bleedBox != nil)
        #expect(page.bleedBox?.count == 4)
    }

    @Test("trimBox returns optional array")
    func trimBox() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            "TrimBox": .array([.real(5), .real(5), .real(607), .real(787)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.trimBox != nil)
        #expect(page.trimBox?.count == 4)
    }

    @Test("artBox returns optional array")
    func artBox() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            "ArtBox": .array([.real(10), .real(10), .real(602), .real(782)])
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.artBox != nil)
        #expect(page.artBox?.count == 4)
    }

    @Test("userUnit returns optional double")
    func userUnit() throws {
        let pageDict: COSValue = [
            .type: .name(.page),
            "UserUnit": .real(2.0)
        ]

        let page = try PDFPage(cosObject: pageDict)
        #expect(page.userUnit == 2.0)
    }

    @Test("userUnit returns nil when missing")
    func userUnitMissing() throws {
        let pageDict: COSValue = [.type: .name(.page)]
        let page = try PDFPage(cosObject: pageDict)
        #expect(page.userUnit == nil)
    }

    // MARK: - Hashable Tests

    @Test("PDFPage is hashable")
    func hashable() throws {
        let pageDict: COSValue = [.type: .name(.page)]
        let page1 = try PDFPage(cosObject: pageDict)
        let page2 = try PDFPage(cosObject: pageDict)

        #expect(page1 == page2)
        #expect(page1.hashValue == page2.hashValue)
    }
}
