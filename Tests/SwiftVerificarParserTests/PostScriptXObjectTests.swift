import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for PostScriptXObject.
@Suite("PostScriptXObject Tests")
struct PostScriptXObjectTests {

    // MARK: - Initialization Tests

    @Test("PostScriptXObject creates with valid dictionary")
    func testValidInitialization() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS"))
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.subtype == ASAtom("PS"))
    }

    @Test("PostScriptXObject creates without subtype")
    func testInitializationWithoutSubtype() throws {
        let dict: COSValue = .dictionary([:])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.subtype == ASAtom("PS"))
    }

    @Test("PostScriptXObject throws for invalid subtype")
    func testThrowsForInvalidSubtype() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image)
        ])

        #expect(throws: XObjectError.self) {
            _ = try PostScriptXObject(cosObject: dict)
        }
    }

    // MARK: - Property Tests

    @Test("PostScriptXObject subtype is PS")
    func testSubtype() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS"))
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.subtype == ASAtom("PS"))
    }

    @Test("PostScriptXObject reads Level1 alternative")
    func testLevel1Property() throws {
        let level1Ref = COSReference(objectNumber: 5, generation: 0)
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS")),
            ASAtom("Level1"): .reference(level1Ref)
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.level1 != nil)
        #expect(psXObject.hasLevel1Alternative == true)
    }

    @Test("PostScriptXObject without Level1 alternative")
    func testNoLevel1Alternative() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS"))
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.level1 == nil)
        #expect(psXObject.hasLevel1Alternative == false)
    }

    @Test("PostScriptXObject reads filter")
    func testFilterProperty() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS")),
            .filter: .name(.ascii85Decode)
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.filter?.nameValue == .ascii85Decode)
    }

    @Test("PostScriptXObject reads length")
    func testLengthProperty() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS")),
            .length: .integer(2048)
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.length == 2048)
    }

    @Test("PostScriptXObject reads decode params")
    func testDecodeParmsProperty() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(ASAtom("PS")),
            .decodeParms: .dictionary([
                ASAtom("Columns"): .integer(80)
            ])
        ])

        let psXObject = try PostScriptXObject(cosObject: dict)
        #expect(psXObject.decodeParms != nil)
    }

    // MARK: - Deprecation Tests

    @Test("PostScriptXObject is marked deprecated")
    func testDeprecation() {
        #expect(PostScriptXObject.isDeprecated == true)
        #expect(PostScriptXObject.deprecatedInVersion == "2.0")
    }
}
