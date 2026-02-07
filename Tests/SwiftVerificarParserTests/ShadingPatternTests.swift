import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for ShadingPattern.
@Suite("ShadingPattern Tests")
struct ShadingPatternTests {

    // MARK: - Helper Methods

    private func createAxialShadingDict() -> COSValue {
        .dictionary([
            ASAtom("ShadingType"): .integer(2),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
            ASAtom("Function"): .dictionary([:])
        ])
    }

    // MARK: - Initialization Tests

    @Test("ShadingPattern creates with valid dictionary")
    func testValidInitialization() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict()
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.patternType == 2)
    }

    @Test("ShadingPattern defaults pattern type to 2")
    func testDefaultPatternType() throws {
        let dict: COSValue = .dictionary([
            ASAtom("Shading"): createAxialShadingDict()
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.patternType == 2)
    }

    @Test("ShadingPattern throws for invalid pattern type")
    func testThrowsForInvalidPatternType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("Shading"): createAxialShadingDict()
        ])

        #expect(throws: PatternError.self) {
            _ = try ShadingPattern(cosObject: dict)
        }
    }

    @Test("ShadingPattern throws for missing Shading")
    func testThrowsForMissingShading() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2)
        ])

        #expect(throws: PatternError.self) {
            _ = try ShadingPattern(cosObject: dict)
        }
    }

    // MARK: - Property Tests

    @Test("ShadingPattern reads matrix")
    func testMatrix() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict(),
            .matrix: .array([.real(1.5), .real(0), .real(0), .real(1.5), .real(50), .real(50)])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.matrix.a == 1.5)
        #expect(pattern.matrix.e == 50)
    }

    @Test("ShadingPattern defaults to identity matrix")
    func testDefaultMatrix() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict()
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.matrix.isIdentity == true)
    }

    @Test("ShadingPattern reads shading value")
    func testShadingValue() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict()
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.shadingValue != nil)
    }

    @Test("ShadingPattern creates shading object")
    func testShadingObject() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict()
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        let shading = try pattern.shading()
        #expect(shading.shadingType == 2)
    }

    @Test("ShadingPattern reads ExtGState")
    func testExtGState() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict(),
            .extGState: .dictionary([
                ASAtom("CA"): .real(0.5),
                ASAtom("ca"): .real(0.5)
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.extGState != nil)
    }

    // MARK: - Convenience Property Tests

    @Test("ShadingPattern reads shading type")
    func testShadingType() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(3),
                .colorSpace: .name(.deviceRGB),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(10), .real(100), .real(0), .real(50)]),
                ASAtom("Function"): .dictionary([:])
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.shadingType == 3)
    }

    @Test("ShadingPattern reads color space")
    func testColorSpace() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(2),
                .colorSpace: .name(.deviceCMYK),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
                ASAtom("Function"): .dictionary([:])
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.colorSpaceName == .deviceCMYK)
    }

    @Test("ShadingPattern reads array color space")
    func testArrayColorSpace() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(2),
                .colorSpace: .array([.name(.iccBased), .reference(COSReference(objectNumber: 1, generation: 0))]),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
                ASAtom("Function"): .dictionary([:])
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.colorSpaceName == .iccBased)
    }

    @Test("ShadingPattern reads background")
    func testBackground() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(2),
                .colorSpace: .name(.deviceRGB),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
                ASAtom("Function"): .dictionary([:]),
                ASAtom("Background"): .array([.real(1), .real(1), .real(1)])
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.background?.count == 3)
        #expect(pattern.background?[0] == 1)
    }

    @Test("ShadingPattern reads BBox")
    func testBBox() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(2),
                .colorSpace: .name(.deviceRGB),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
                ASAtom("Function"): .dictionary([:]),
                .bbox: .array([.real(0), .real(0), .real(200), .real(200)])
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.bBox != nil)
        #expect(pattern.bBox?.width == 200)
    }

    @Test("ShadingPattern reads antiAlias")
    func testAntiAlias() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(2),
                .colorSpace: .name(.deviceRGB),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
                ASAtom("Function"): .dictionary([:]),
                ASAtom("AntiAlias"): .boolean(true)
            ])
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.antiAlias == true)
    }

    @Test("ShadingPattern defaults antiAlias to false")
    func testDefaultAntiAlias() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): createAxialShadingDict()
        ])

        let pattern = try ShadingPattern(cosObject: dict)
        #expect(pattern.antiAlias == false)
    }
}
