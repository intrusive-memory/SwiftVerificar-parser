import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for PDFPattern protocol and factory.
@Suite("PDFPattern Tests")
struct PDFPatternTests {

    // MARK: - Pattern Error Tests

    @Test("PatternError descriptions are correct")
    func testErrorDescriptions() {
        let errors: [PatternError] = [
            .missingPatternType,
            .invalidPatternType(5),
            .missingRequiredEntry(key: "BBox"),
            .invalidPaintType(3),
            .invalidPaintType(nil),
            .invalidTilingType(5),
            .invalidTilingType(nil),
            .invalidBBox,
            .invalidShading
        ]

        for error in errors {
            #expect(!error.description.isEmpty)
        }
    }

    @Test("PatternError equality works correctly")
    func testErrorEquality() {
        let error1 = PatternError.missingPatternType
        let error2 = PatternError.missingPatternType
        let error3 = PatternError.invalidPatternType(1)

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    // MARK: - Factory Tests

    @Test("PDFPatternFactory creates TilingPattern")
    func testFactoryCreatesTilingPattern() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        let pattern = try PDFPatternFactory.create(from: dict)
        #expect(pattern is TilingPattern)
        #expect(pattern.patternType == 1)
    }

    @Test("PDFPatternFactory creates ShadingPattern")
    func testFactoryCreatesShadingPattern() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("Shading"): .dictionary([
                ASAtom("ShadingType"): .integer(2),
                .colorSpace: .name(.deviceRGB),
                ASAtom("Coords"): .array([.real(0), .real(0), .real(100), .real(0)]),
                ASAtom("Function"): .dictionary([:])
            ])
        ])

        let pattern = try PDFPatternFactory.create(from: dict)
        #expect(pattern is ShadingPattern)
        #expect(pattern.patternType == 2)
    }

    @Test("PDFPatternFactory throws for missing pattern type")
    func testFactoryThrowsForMissingType() {
        let dict: COSValue = .dictionary([
            ASAtom("PaintType"): .integer(1)
        ])

        #expect(throws: PatternError.self) {
            _ = try PDFPatternFactory.create(from: dict)
        }
    }

    @Test("PDFPatternFactory throws for invalid pattern type")
    func testFactoryThrowsForInvalidType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(3)
        ])

        #expect(throws: PatternError.self) {
            _ = try PDFPatternFactory.create(from: dict)
        }
    }
}
