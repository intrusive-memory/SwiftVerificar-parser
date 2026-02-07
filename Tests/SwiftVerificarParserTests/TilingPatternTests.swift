import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for TilingPattern.
@Suite("TilingPattern Tests")
struct TilingPatternTests {

    // MARK: - Enum Tests

    @Test("PaintType enum values")
    func testPaintTypeEnum() {
        #expect(TilingPattern.PaintType.colored.rawValue == 1)
        #expect(TilingPattern.PaintType.uncolored.rawValue == 2)
        #expect(TilingPattern.PaintType.allCases.count == 2)
    }

    @Test("TilingType enum values")
    func testTilingTypeEnum() {
        #expect(TilingPattern.TilingType.constantSpacing.rawValue == 1)
        #expect(TilingPattern.TilingType.noDistortion.rawValue == 2)
        #expect(TilingPattern.TilingType.fasterTiling.rawValue == 3)
        #expect(TilingPattern.TilingType.allCases.count == 3)
    }

    // MARK: - Initialization Tests

    @Test("TilingPattern creates with valid dictionary")
    func testValidInitialization() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.patternType == 1)
        #expect(pattern.paintType == .colored)
        #expect(pattern.tilingType == .constantSpacing)
    }

    @Test("TilingPattern defaults pattern type to 1")
    func testDefaultPatternType() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.patternType == 1)
    }

    @Test("TilingPattern throws for invalid pattern type")
    func testThrowsForInvalidPatternType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(2),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for missing PaintType")
    func testThrowsForMissingPaintType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for invalid PaintType")
    func testThrowsForInvalidPaintType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(3),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for missing TilingType")
    func testThrowsForMissingTilingType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for invalid TilingType")
    func testThrowsForInvalidTilingType() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(5),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for missing BBox")
    func testThrowsForMissingBBox() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for missing XStep")
    func testThrowsForMissingXStep() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("YStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    @Test("TilingPattern throws for missing YStep")
    func testThrowsForMissingYStep() {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100)
        ])

        #expect(throws: PatternError.self) {
            _ = try TilingPattern(cosObject: dict)
        }
    }

    // MARK: - Property Tests

    @Test("TilingPattern reads paint types")
    func testPaintTypes() throws {
        for paintType in TilingPattern.PaintType.allCases {
            let dict: COSValue = .dictionary([
                ASAtom("PatternType"): .integer(1),
                ASAtom("PaintType"): .integer(Int64(paintType.rawValue)),
                ASAtom("TilingType"): .integer(1),
                .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
                ASAtom("XStep"): .real(50),
                ASAtom("YStep"): .real(50)
            ])

            let pattern = try TilingPattern(cosObject: dict)
            #expect(pattern.paintType == paintType)
            #expect(pattern.paintTypeValue == paintType.rawValue)
        }
    }

    @Test("TilingPattern colored and uncolored flags")
    func testColoredFlags() throws {
        let coloredDict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50)
        ])

        let uncoloredDict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(2),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50)
        ])

        let colored = try TilingPattern(cosObject: coloredDict)
        let uncolored = try TilingPattern(cosObject: uncoloredDict)

        #expect(colored.isColored == true)
        #expect(colored.isUncolored == false)
        #expect(uncolored.isColored == false)
        #expect(uncolored.isUncolored == true)
    }

    @Test("TilingPattern reads tiling types")
    func testTilingTypes() throws {
        for tilingType in TilingPattern.TilingType.allCases {
            let dict: COSValue = .dictionary([
                ASAtom("PatternType"): .integer(1),
                ASAtom("PaintType"): .integer(1),
                ASAtom("TilingType"): .integer(Int64(tilingType.rawValue)),
                .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
                ASAtom("XStep"): .real(50),
                ASAtom("YStep"): .real(50)
            ])

            let pattern = try TilingPattern(cosObject: dict)
            #expect(pattern.tilingType == tilingType)
            #expect(pattern.tilingTypeValue == tilingType.rawValue)
        }
    }

    @Test("TilingPattern reads BBox")
    func testBBox() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(10), .real(20), .real(110), .real(120)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.bBox.llx == 10)
        #expect(pattern.bBox.lly == 20)
        #expect(pattern.bBox.urx == 110)
        #expect(pattern.bBox.ury == 120)
    }

    @Test("TilingPattern reads XStep and YStep")
    func testSteps() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(100)]),
            ASAtom("XStep"): .real(60),
            ASAtom("YStep"): .real(120)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.xStep == 60)
        #expect(pattern.yStep == 120)
    }

    @Test("TilingPattern reads matrix")
    func testMatrix() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50),
            .matrix: .array([.real(2), .real(0), .real(0), .real(2), .real(10), .real(20)])
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.matrix.a == 2)
        #expect(pattern.matrix.e == 10)
        #expect(pattern.matrix.isIdentity == false)
    }

    @Test("TilingPattern defaults to identity matrix")
    func testDefaultMatrix() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.matrix.isIdentity == true)
    }

    @Test("TilingPattern reads resources")
    func testResources() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50),
            .resources: .dictionary([
                .font: .dictionary([:])
            ])
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.resources != nil)
        #expect(pattern.resourcesValue != nil)
    }

    // MARK: - Computed Property Tests

    @Test("TilingPattern computes width and height")
    func testWidthHeight() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(50)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(50)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.width == 100)
        #expect(pattern.height == 50)
    }

    @Test("TilingPattern computes cell and step sizes")
    func testCellStepSizes() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(50)]),
            ASAtom("XStep"): .real(120),
            ASAtom("YStep"): .real(60)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.cellSize.width == 100)
        #expect(pattern.cellSize.height == 50)
        #expect(pattern.stepSize.width == 120)
        #expect(pattern.stepSize.height == 60)
    }

    @Test("TilingPattern detects overlap")
    func testOverlapDetection() throws {
        let overlappingDict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(80),  // Less than width
            ASAtom("YStep"): .real(100)
        ])

        let nonOverlappingDict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        let overlapping = try TilingPattern(cosObject: overlappingDict)
        let nonOverlapping = try TilingPattern(cosObject: nonOverlappingDict)

        #expect(overlapping.hasOverlap == true)
        #expect(nonOverlapping.hasOverlap == false)
    }

    @Test("TilingPattern detects gaps")
    func testGapDetection() throws {
        let withGapsDict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(120),  // More than width
            ASAtom("YStep"): .real(100)
        ])

        let noGapsDict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(100), .real(100)]),
            ASAtom("XStep"): .real(100),
            ASAtom("YStep"): .real(100)
        ])

        let withGaps = try TilingPattern(cosObject: withGapsDict)
        let noGaps = try TilingPattern(cosObject: noGapsDict)

        #expect(withGaps.hasGaps == true)
        #expect(noGaps.hasGaps == false)
    }

    @Test("TilingPattern reads stream properties")
    func testStreamProperties() throws {
        let dict: COSValue = .dictionary([
            ASAtom("PatternType"): .integer(1),
            ASAtom("PaintType"): .integer(1),
            ASAtom("TilingType"): .integer(1),
            .bbox: .array([.real(0), .real(0), .real(50), .real(50)]),
            ASAtom("XStep"): .real(50),
            ASAtom("YStep"): .real(50),
            .filter: .name(.flateDecode),
            .length: .integer(512)
        ])

        let pattern = try TilingPattern(cosObject: dict)
        #expect(pattern.filter?.nameValue == .flateDecode)
        #expect(pattern.length == 512)
    }
}
