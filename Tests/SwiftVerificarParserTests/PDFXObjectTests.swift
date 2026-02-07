import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for PDFXObject protocol and XObject error handling.
@Suite("PDFXObject Tests")
struct PDFXObjectTests {

    // MARK: - XObject Error Tests

    @Test("XObjectError descriptions are correct")
    func testErrorDescriptions() {
        let errors: [XObjectError] = [
            .missingRequiredEntry(key: "Width"),
            .invalidSubtype("Unknown"),
            .invalidSubtype(nil),
            .streamDecodingFailed("test reason"),
            .invalidImageDimensions(width: -1, height: 0),
            .invalidBitsPerComponent(3),
            .invalidColorSpace("missing"),
            .malformedInlineImage("bad data"),
            .invalidBBox,
            .invalidPatternType(5),
            .invalidPatternType(nil),
            .invalidShadingType(10),
            .invalidShadingType(nil)
        ]

        for error in errors {
            #expect(!error.description.isEmpty)
        }
    }

    @Test("XObjectError equality works correctly")
    func testErrorEquality() {
        let error1 = XObjectError.missingRequiredEntry(key: "Width")
        let error2 = XObjectError.missingRequiredEntry(key: "Width")
        let error3 = XObjectError.missingRequiredEntry(key: "Height")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    // MARK: - Factory Tests

    @Test("PDFXObjectFactory creates ImageXObject")
    func testFactoryCreatesImageXObject() throws {
        let imageDict: COSValue = .dictionary([
            .subtype: .name(.image),
            .width: .integer(100),
            .height: .integer(50),
            .bitsPerComponent: .integer(8),
            .colorSpace: .name(.deviceRGB)
        ])

        let xObject = try PDFXObjectFactory.create(from: imageDict)
        #expect(xObject is ImageXObject)
        #expect(xObject.subtype == .image)
    }

    @Test("PDFXObjectFactory creates FormXObject")
    func testFactoryCreatesFormXObject() throws {
        let formDict: COSValue = .dictionary([
            .subtype: .name(.form),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)])
        ])

        let xObject = try PDFXObjectFactory.create(from: formDict)
        #expect(xObject is FormXObject)
        #expect(xObject.subtype == .form)
    }

    @Test("PDFXObjectFactory creates PostScriptXObject")
    func testFactoryCreatesPostScriptXObject() throws {
        let psDict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS"))
        ])

        let xObject = try PDFXObjectFactory.create(from: psDict)
        #expect(xObject is PostScriptXObject)
        #expect(xObject.subtype == ASAtom("PS"))
    }

    @Test("PDFXObjectFactory throws for missing subtype")
    func testFactoryThrowsForMissingSubtype() {
        let dict: COSValue = .dictionary([
            .width: .integer(100)
        ])

        #expect(throws: XObjectError.self) {
            _ = try PDFXObjectFactory.create(from: dict)
        }
    }

    @Test("PDFXObjectFactory throws for invalid subtype")
    func testFactoryThrowsForInvalidSubtype() {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("Unknown"))
        ])

        #expect(throws: XObjectError.self) {
            _ = try PDFXObjectFactory.create(from: dict)
        }
    }

    @Test("PDFXObjectFactory throws for non-name subtype")
    func testFactoryThrowsForNonNameSubtype() {
        let dict: COSValue = .dictionary([
            .subtype: .integer(1)
        ])

        #expect(throws: XObjectError.self) {
            _ = try PDFXObjectFactory.create(from: dict)
        }
    }
}
