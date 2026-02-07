import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for FormXObject.
@Suite("FormXObject Tests")
struct FormXObjectTests {

    // MARK: - Rectangle Tests

    @Test("Rectangle creates from coordinates")
    func testRectangleFromCoordinates() {
        let rect = FormXObject.Rectangle(llx: 10, lly: 20, urx: 110, ury: 120)
        #expect(rect.llx == 10)
        #expect(rect.lly == 20)
        #expect(rect.urx == 110)
        #expect(rect.ury == 120)
        #expect(rect.width == 100)
        #expect(rect.height == 100)
    }

    @Test("Rectangle creates from COSValue")
    func testRectangleFromCOSValue() {
        let cosArray: COSValue = .array([.real(0), .real(0), .real(200), .real(300)])
        let rect = FormXObject.Rectangle(from: cosArray)

        #expect(rect != nil)
        #expect(rect?.llx == 0)
        #expect(rect?.lly == 0)
        #expect(rect?.urx == 200)
        #expect(rect?.ury == 300)
    }

    @Test("Rectangle returns nil for invalid array")
    func testRectangleInvalidArray() {
        let shortArray: COSValue = .array([.real(0), .real(0)])
        #expect(FormXObject.Rectangle(from: shortArray) == nil)

        let nonNumericArray: COSValue = .array([.name(.type), .name(.page), .integer(1), .integer(2)])
        #expect(FormXObject.Rectangle(from: nonNumericArray) == nil)

        let nilValue: COSValue? = nil
        #expect(FormXObject.Rectangle(from: nilValue) == nil)
    }

    @Test("Rectangle converts to CGRect")
    func testRectangleToCGRect() {
        let rect = FormXObject.Rectangle(llx: 10, lly: 20, urx: 60, ury: 70)
        let cgRect = rect.cgRect

        #expect(cgRect.origin.x == 10)
        #expect(cgRect.origin.y == 20)
        #expect(cgRect.width == 50)
        #expect(cgRect.height == 50)
    }

    @Test("Rectangle has description")
    func testRectangleDescription() {
        let rect = FormXObject.Rectangle(llx: 0, lly: 0, urx: 100, ury: 100)
        #expect(rect.description.contains("0"))
        #expect(rect.description.contains("100"))
    }

    // MARK: - Matrix Tests

    @Test("Matrix identity matrix")
    func testIdentityMatrix() {
        let identity = FormXObject.Matrix.identity
        #expect(identity.a == 1)
        #expect(identity.b == 0)
        #expect(identity.c == 0)
        #expect(identity.d == 1)
        #expect(identity.e == 0)
        #expect(identity.f == 0)
        #expect(identity.isIdentity == true)
    }

    @Test("Matrix creates from components")
    func testMatrixFromComponents() {
        let matrix = FormXObject.Matrix(a: 2, b: 0, c: 0, d: 2, e: 10, f: 20)
        #expect(matrix.a == 2)
        #expect(matrix.d == 2)
        #expect(matrix.e == 10)
        #expect(matrix.f == 20)
        #expect(matrix.isIdentity == false)
    }

    @Test("Matrix creates from COSValue")
    func testMatrixFromCOSValue() {
        let cosArray: COSValue = .array([.real(1.5), .real(0), .real(0), .real(1.5), .real(50), .real(100)])
        let matrix = FormXObject.Matrix(from: cosArray)

        #expect(matrix != nil)
        #expect(matrix?.a == 1.5)
        #expect(matrix?.e == 50)
        #expect(matrix?.f == 100)
    }

    @Test("Matrix returns nil for invalid array")
    func testMatrixInvalidArray() {
        let shortArray: COSValue = .array([.real(1), .real(0)])
        #expect(FormXObject.Matrix(from: shortArray) == nil)
    }

    @Test("Matrix converts to CGAffineTransform")
    func testMatrixToCGAffineTransform() {
        let matrix = FormXObject.Matrix(a: 2, b: 0, c: 0, d: 2, e: 10, f: 20)
        let transform = matrix.cgAffineTransform

        #expect(transform.a == 2)
        #expect(transform.tx == 10)
        #expect(transform.ty == 20)
    }

    // MARK: - FormXObject Initialization Tests

    @Test("FormXObject creates with valid dictionary")
    func testValidInitialization() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(.form),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.bBox.width == 100)
        #expect(form.bBox.height == 100)
    }

    @Test("FormXObject throws for missing BBox")
    func testThrowsForMissingBBox() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.form)
        ])

        #expect(throws: XObjectError.self) {
            _ = try FormXObject(cosObject: dict)
        }
    }

    @Test("FormXObject throws for invalid BBox")
    func testThrowsForInvalidBBox() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.form),
            .bbox: .array([.real(0)])  // Too few elements
        ])

        #expect(throws: XObjectError.self) {
            _ = try FormXObject(cosObject: dict)
        }
    }

    @Test("FormXObject throws for invalid subtype")
    func testThrowsForInvalidSubtype() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)])
        ])

        #expect(throws: XObjectError.self) {
            _ = try FormXObject(cosObject: dict)
        }
    }

    // MARK: - Property Tests

    @Test("FormXObject subtype is Form")
    func testSubtype() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.subtype == .form)
    }

    @Test("FormXObject reads matrix")
    func testMatrixProperty() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            .matrix: .array([.real(2), .real(0), .real(0), .real(2), .real(10), .real(20)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.matrix.a == 2)
        #expect(form.matrix.e == 10)
    }

    @Test("FormXObject defaults to identity matrix")
    func testDefaultMatrix() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.matrix.isIdentity == true)
    }

    @Test("FormXObject reads resources")
    func testResourcesProperty() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            .resources: .dictionary([
                .font: .dictionary([:])
            ])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.resources != nil)
        #expect(form.resourcesValue != nil)
    }

    @Test("FormXObject reads transparency group")
    func testTransparencyGroup() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("Group"): .dictionary([
                .type: .name(ASAtom("Group")),
                .s: .name(ASAtom("Transparency")),
                .colorSpace: .name(.deviceRGB),
                ASAtom("I"): .boolean(true),
                ASAtom("K"): .boolean(false)
            ])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.isTransparencyGroup == true)
        #expect(form.isIsolated == true)
        #expect(form.isKnockout == false)
        #expect(form.groupColorSpace != nil)
    }

    @Test("FormXObject reads reference XObject")
    func testReferenceXObject() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("Ref"): .dictionary([
                ASAtom("F"): .dictionary([
                    .type: .name(ASAtom("Filespec")),
                    ASAtom("F"): .string(COSString(string: "external.pdf"))
                ])
            ])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.hasExternalReference == true)
        #expect(form.reference != nil)
    }

    @Test("FormXObject reads optional content")
    func testOptionalContent() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("OC"): .dictionary([
                .type: .name(ASAtom("OCG")),
                ASAtom("Name"): .string(COSString(string: "Layer1"))
            ])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.optionalContent != nil)
    }

    @Test("FormXObject reads metadata")
    func testMetadata() throws {
        let metadataRef = COSReference(objectNumber: 10, generation: 0)
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            .metadata: .reference(metadataRef)
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.metadata != nil)
    }

    @Test("FormXObject reads struct parent")
    func testStructParent() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("StructParent"): .integer(3),
            ASAtom("StructParents"): .integer(5)
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.structParent == 3)
        #expect(form.structParents == 5)
    }

    @Test("FormXObject reads form type")
    func testFormType() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("FormType"): .integer(1)
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.formType == 1)
    }

    @Test("FormXObject defaults form type to 1")
    func testDefaultFormType() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.formType == 1)
    }

    @Test("FormXObject reads filter")
    func testFilterProperty() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            .filter: .name(.flateDecode),
            .length: .integer(1024)
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.filter?.nameValue == .flateDecode)
        #expect(form.length == 1024)
    }

    @Test("FormXObject computes width and height")
    func testWidthHeight() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(10), .real(20), .real(210), .real(170)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.width == 200)
        #expect(form.height == 150)
    }

    @Test("FormXObject computes cell and step sizes")
    func testCellAndStepSizes() throws {
        let dict: COSValue = .dictionary([
            .bbox: .array([.real(0), .real(0), .real(100), .real(50)])
        ])

        let form = try FormXObject(cosObject: dict)
        #expect(form.cellSize.width == 100)
        #expect(form.cellSize.height == 50)
    }
}
