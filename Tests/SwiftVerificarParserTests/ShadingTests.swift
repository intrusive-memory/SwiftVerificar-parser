import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for Shading.
@Suite("Shading Tests")
struct ShadingTests {

    // MARK: - ShadingType Enum Tests

    @Test("ShadingType enum values")
    func testShadingTypeEnum() {
        #expect(Shading.ShadingType.functionBased.rawValue == 1)
        #expect(Shading.ShadingType.axial.rawValue == 2)
        #expect(Shading.ShadingType.radial.rawValue == 3)
        #expect(Shading.ShadingType.freeFormGouraud.rawValue == 4)
        #expect(Shading.ShadingType.latticeFormGouraud.rawValue == 5)
        #expect(Shading.ShadingType.coonsPatch.rawValue == 6)
        #expect(Shading.ShadingType.tensorProductPatch.rawValue == 7)
        #expect(Shading.ShadingType.allCases.count == 7)
    }

    @Test("ShadingType descriptions")
    func testShadingTypeDescriptions() {
        for type in Shading.ShadingType.allCases {
            #expect(!type.description.isEmpty)
        }
    }

    @Test("ShadingType requiresStream")
    func testShadingTypeRequiresStream() {
        #expect(Shading.ShadingType.functionBased.requiresStream == false)
        #expect(Shading.ShadingType.axial.requiresStream == false)
        #expect(Shading.ShadingType.radial.requiresStream == false)
        #expect(Shading.ShadingType.freeFormGouraud.requiresStream == true)
        #expect(Shading.ShadingType.latticeFormGouraud.requiresStream == true)
        #expect(Shading.ShadingType.coonsPatch.requiresStream == true)
        #expect(Shading.ShadingType.tensorProductPatch.requiresStream == true)
    }

    // MARK: - Initialization Tests

    @Test("Shading creates with valid axial shading")
    func testValidAxialShading() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.shadingType == 2)
        #expect(shading.type == .axial)
    }

    @Test("Shading creates with valid radial shading")
    func testValidRadialShading() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(3),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(50), .real(50), .real(0), .real(50), .real(50), .real(100)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.shadingType == 3)
        #expect(shading.type == .radial)
    }

    @Test("Shading throws for missing ShadingType")
    func testThrowsForMissingShadingType() {
        let dict: COSValue = .dictionary([
            .colorSpace: .name(.deviceRGB)
        ])

        #expect(throws: XObjectError.self) {
            _ = try Shading(cosObject: dict)
        }
    }

    @Test("Shading throws for invalid ShadingType")
    func testThrowsForInvalidShadingType() {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(8),
            .colorSpace: .name(.deviceRGB)
        ])

        #expect(throws: XObjectError.self) {
            _ = try Shading(cosObject: dict)
        }
    }

    @Test("Shading throws for missing ColorSpace")
    func testThrowsForMissingColorSpace() {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2)
        ])

        #expect(throws: XObjectError.self) {
            _ = try Shading(cosObject: dict)
        }
    }

    // MARK: - Common Property Tests

    @Test("Shading reads color space name")
    func testColorSpaceName() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceCMYK),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.colorSpaceName == .deviceCMYK)
    }

    @Test("Shading reads array color space")
    func testArrayColorSpace() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .array([.name(.calRGB), .dictionary([:])]),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.colorSpaceName == .calRGB)
    }

    @Test("Shading reads background")
    func testBackground() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:]),
            ASAtom("Background"): .array([.real(0.5), .real(0.5), .real(0.5)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.background?.count == 3)
        #expect(shading.background?[0] == 0.5)
    }

    @Test("Shading reads BBox")
    func testBBox() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:]),
            .bbox: .array([.real(0), .real(0), .real(200), .real(100)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.bBox != nil)
        #expect(shading.bBox?.width == 200)
        #expect(shading.bBox?.height == 100)
    }

    @Test("Shading reads antiAlias")
    func testAntiAlias() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:]),
            ASAtom("AntiAlias"): .boolean(true)
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.antiAlias == true)
    }

    @Test("Shading defaults antiAlias to false")
    func testDefaultAntiAlias() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.antiAlias == false)
    }

    // MARK: - Function-Based Shading (Type 1) Tests

    @Test("Shading type 1 reads domain")
    func testType1Domain() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(1),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Function"): .dictionary([:]),
            ASAtom("Domain"): .array([.real(0), .real(1), .real(0), .real(1)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.domain?.count == 4)
        #expect(shading.domain?[0] == 0)
    }

    @Test("Shading type 1 defaults domain to [0 1 0 1]")
    func testType1DefaultDomain() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(1),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.domain == [0, 1, 0, 1])
    }

    @Test("Shading type 1 reads matrix")
    func testType1Matrix() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(1),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Function"): .dictionary([:]),
            .matrix: .array([.real(2), .real(0), .real(0), .real(2), .real(0), .real(0)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.shadingMatrix?.a == 2)
    }

    @Test("Shading type 1 reads function")
    func testType1Function() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(1),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Function"): .dictionary([
                ASAtom("FunctionType"): .integer(2)
            ])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.function != nil)
    }

    // MARK: - Axial Shading (Type 2) Tests

    @Test("Shading type 2 reads axial coords")
    func testType2Coords() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(10), .real(20), .real(110), .real(120)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        let coords = shading.axialCoords

        #expect(coords?.start.x == 10)
        #expect(coords?.start.y == 20)
        #expect(coords?.end.x == 110)
        #expect(coords?.end.y == 120)
    }

    @Test("Shading type 2 reads parameter domain")
    func testType2Domain() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:]),
            ASAtom("Domain"): .array([.real(0.25), .real(0.75)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.parameterDomain?.t0 == 0.25)
        #expect(shading.parameterDomain?.t1 == 0.75)
    }

    @Test("Shading type 2 defaults domain to [0 1]")
    func testType2DefaultDomain() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.parameterDomain?.t0 == 0)
        #expect(shading.parameterDomain?.t1 == 1)
    }

    @Test("Shading type 2 reads extend flags")
    func testType2Extend() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:]),
            ASAtom("Extend"): .array([.boolean(true), .boolean(false)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.extend?.extendStart == true)
        #expect(shading.extend?.extendEnd == false)
    }

    @Test("Shading type 2 defaults extend to [false false]")
    func testType2DefaultExtend() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.extend?.extendStart == false)
        #expect(shading.extend?.extendEnd == false)
    }

    // MARK: - Radial Shading (Type 3) Tests

    @Test("Shading type 3 reads radial coords")
    func testType3Coords() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(3),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(50), .real(50), .real(10), .real(50), .real(50), .real(100)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        let coords = shading.radialCoords

        #expect(coords?.startCenter.x == 50)
        #expect(coords?.startCenter.y == 50)
        #expect(coords?.startRadius == 10)
        #expect(coords?.endCenter.x == 50)
        #expect(coords?.endCenter.y == 50)
        #expect(coords?.endRadius == 100)
    }

    @Test("Shading type 3 reads parameter domain and extend")
    func testType3DomainAndExtend() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(3),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(50), .real(50), .real(0), .real(50), .real(50), .real(100)]),
            ASAtom("Function"): .dictionary([:]),
            ASAtom("Domain"): .array([.real(0), .real(0.5)]),
            ASAtom("Extend"): .array([.boolean(false), .boolean(true)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.parameterDomain?.t0 == 0)
        #expect(shading.parameterDomain?.t1 == 0.5)
        #expect(shading.extend?.extendStart == false)
        #expect(shading.extend?.extendEnd == true)
    }

    // MARK: - Mesh Shading (Types 4-7) Tests

    @Test("Shading type 4 reads mesh properties")
    func testType4Properties() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(4),
            .colorSpace: .name(.deviceRGB),
            ASAtom("BitsPerCoordinate"): .integer(16),
            .bitsPerComponent: .integer(8),
            ASAtom("BitsPerFlag"): .integer(2),
            ASAtom("Decode"): .array([.real(0), .real(100), .real(0), .real(100), .real(0), .real(1), .real(0), .real(1), .real(0), .real(1)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.bitsPerCoordinate == 16)
        #expect(shading.bitsPerComponent == 8)
        #expect(shading.bitsPerFlag == 2)
        #expect(shading.decode?.count == 10)
    }

    @Test("Shading type 5 reads vertices per row")
    func testType5VerticesPerRow() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(5),
            .colorSpace: .name(.deviceRGB),
            ASAtom("BitsPerCoordinate"): .integer(16),
            .bitsPerComponent: .integer(8),
            ASAtom("VerticesPerRow"): .integer(10),
            ASAtom("Decode"): .array([.real(0), .real(100), .real(0), .real(100), .real(0), .real(1)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.verticesPerRow == 10)
    }

    @Test("Shading type 6 reads Coons patch properties")
    func testType6Properties() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(6),
            .colorSpace: .name(.deviceRGB),
            ASAtom("BitsPerCoordinate"): .integer(24),
            .bitsPerComponent: .integer(8),
            ASAtom("BitsPerFlag"): .integer(8),
            ASAtom("Decode"): .array([.real(0), .real(100), .real(0), .real(100)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.bitsPerCoordinate == 24)
        #expect(shading.bitsPerFlag == 8)
    }

    @Test("Shading type 7 reads tensor-product patch properties")
    func testType7Properties() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(7),
            .colorSpace: .name(.deviceRGB),
            ASAtom("BitsPerCoordinate"): .integer(32),
            .bitsPerComponent: .integer(16),
            ASAtom("BitsPerFlag"): .integer(8),
            ASAtom("Decode"): .array([.real(0), .real(200), .real(0), .real(200)])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.bitsPerCoordinate == 32)
        #expect(shading.bitsPerComponent == 16)
    }

    // MARK: - Non-Applicable Property Tests

    @Test("Type 2 shading returns nil for type 1 properties")
    func testType2ReturnsNilForType1() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.domain == nil)
        #expect(shading.shadingMatrix == nil)
    }

    @Test("Type 2 shading returns nil for type 3 properties")
    func testType2ReturnsNilForType3() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.radialCoords == nil)
    }

    @Test("Type 2 shading returns nil for mesh properties")
    func testType2ReturnsNilForMesh() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let shading = try Shading(cosObject: dict)
        #expect(shading.bitsPerCoordinate == nil)
        #expect(shading.bitsPerComponent == nil)
        #expect(shading.bitsPerFlag == nil)
        #expect(shading.decode == nil)
        #expect(shading.verticesPerRow == nil)
    }

    // MARK: - Validation Tests

    @Test("Shading validates type 2 completeness")
    func testType2Validation() throws {
        // Valid axial shading
        let validDict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])

        let validShading = try Shading(cosObject: validDict)
        #expect(validShading.isValid == true)

        // Invalid (missing coords)
        let invalidDict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Function"): .dictionary([:])
        ])

        let invalidShading = try Shading(cosObject: invalidDict)
        #expect(invalidShading.isValid == false)
    }

    @Test("Shading validates type 4 completeness")
    func testType4Validation() throws {
        // Valid
        let validDict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(4),
            .colorSpace: .name(.deviceRGB),
            ASAtom("BitsPerCoordinate"): .integer(16),
            .bitsPerComponent: .integer(8),
            ASAtom("BitsPerFlag"): .integer(2),
            ASAtom("Decode"): .array([.real(0), .real(100)])
        ])

        let validShading = try Shading(cosObject: validDict)
        #expect(validShading.isValid == true)

        // Invalid (missing BitsPerFlag)
        let invalidDict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(4),
            .colorSpace: .name(.deviceRGB),
            ASAtom("BitsPerCoordinate"): .integer(16),
            .bitsPerComponent: .integer(8),
            ASAtom("Decode"): .array([.real(0), .real(100)])
        ])

        let invalidShading = try Shading(cosObject: invalidDict)
        #expect(invalidShading.isValid == false)
    }

    // MARK: - Description Tests

    @Test("Shading has description")
    func testDescription() throws {
        let dict: COSValue = .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:]),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("AntiAlias"): .boolean(true)
        ])

        let shading = try Shading(cosObject: dict)
        let desc = shading.description

        #expect(desc.contains("Axial"))
        #expect(desc.contains("DeviceRGB"))
        #expect(desc.contains("antiAlias"))
    }
}
