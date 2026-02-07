import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for ImageXObject.
@Suite("ImageXObject Tests")
struct ImageXObjectTests {

    // MARK: - Initialization Tests

    @Test("ImageXObject creates with valid dictionary")
    func testValidInitialization() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .width: .integer(100),
            .height: .integer(50),
            .bitsPerComponent: .integer(8),
            .colorSpace: .name(.deviceRGB)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.width == 100)
        #expect(image.height == 50)
        #expect(image.bitsPerComponent == 8)
        #expect(image.colorSpaceName == .deviceRGB)
    }

    @Test("ImageXObject creates image mask without color space")
    func testImageMaskInitialization() throws {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .width: .integer(64),
            .height: .integer(64),
            ASAtom("ImageMask"): .boolean(true)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.isImageMask == true)
        #expect(image.bitsPerComponent == 1)
        #expect(image.width == 64)
    }

    @Test("ImageXObject throws for missing width")
    func testThrowsForMissingWidth() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB)
        ])

        #expect(throws: XObjectError.self) {
            _ = try ImageXObject(cosObject: dict)
        }
    }

    @Test("ImageXObject throws for missing height")
    func testThrowsForMissingHeight() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .width: .integer(100),
            .colorSpace: .name(.deviceRGB)
        ])

        #expect(throws: XObjectError.self) {
            _ = try ImageXObject(cosObject: dict)
        }
    }

    @Test("ImageXObject throws for invalid dimensions")
    func testThrowsForInvalidDimensions() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .width: .integer(0),
            .height: .integer(100),
            .colorSpace: .name(.deviceRGB)
        ])

        #expect(throws: XObjectError.self) {
            _ = try ImageXObject(cosObject: dict)
        }
    }

    @Test("ImageXObject throws for missing color space on non-mask")
    func testThrowsForMissingColorSpace() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.image),
            .width: .integer(100),
            .height: .integer(50),
            .bitsPerComponent: .integer(8)
        ])

        #expect(throws: XObjectError.self) {
            _ = try ImageXObject(cosObject: dict)
        }
    }

    @Test("ImageXObject throws for invalid subtype")
    func testThrowsForInvalidSubtype() {
        let dict: COSValue = .dictionary([
            .subtype: .name(.form),
            .width: .integer(100),
            .height: .integer(50)
        ])

        #expect(throws: XObjectError.self) {
            _ = try ImageXObject(cosObject: dict)
        }
    }

    // MARK: - Property Tests

    @Test("ImageXObject subtype is Image")
    func testSubtype() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.subtype == .image)
    }

    @Test("ImageXObject reads color space name")
    func testColorSpaceName() throws {
        let grayscaleDict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceGray)
        ])

        let image = try ImageXObject(cosObject: grayscaleDict)
        #expect(image.colorSpaceName == .deviceGray)
        #expect(image.numberOfComponents == 1)
    }

    @Test("ImageXObject reads array-based color space")
    func testArrayColorSpace() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .array([.name(.iccBased), .reference(COSReference(objectNumber: 1, generation: 0))])
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.colorSpaceName == .iccBased)
    }

    @Test("ImageXObject component counts for different color spaces")
    func testComponentCounts() throws {
        let testCases: [(ASAtom, Int)] = [
            (.deviceGray, 1),
            (.calGray, 1),
            (.deviceRGB, 3),
            (.calRGB, 3),
            (.lab, 3),
            (.deviceCMYK, 4),
            (.indexed, 1)
        ]

        for (colorSpace, expectedComponents) in testCases {
            let dict: COSValue = .dictionary([
                .width: .integer(100),
                .height: .integer(50),
                .colorSpace: .name(colorSpace)
            ])

            let image = try ImageXObject(cosObject: dict)
            #expect(image.numberOfComponents == expectedComponents,
                   "Expected \(expectedComponents) components for \(colorSpace)")
        }
    }

    @Test("ImageXObject reads mask property")
    func testMaskProperty() throws {
        let maskRef = COSReference(objectNumber: 5, generation: 0)
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Mask"): .reference(maskRef)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.mask != nil)
        #expect(image.mask?.referenceValue == maskRef)
    }

    @Test("ImageXObject reads soft mask property")
    func testSoftMaskProperty() throws {
        let smaskRef = COSReference(objectNumber: 6, generation: 0)
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            ASAtom("SMask"): .reference(smaskRef)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.softMask != nil)
    }

    @Test("ImageXObject reads interpolate property")
    func testInterpolateProperty() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Interpolate"): .boolean(true)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.interpolate == true)
    }

    @Test("ImageXObject reads decode array")
    func testDecodeArray() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Decode"): .array([.real(0), .real(1), .real(0), .real(1), .real(0), .real(1)])
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.decode?.count == 6)
        #expect(image.decode?[0] == 0)
        #expect(image.decode?[1] == 1)
    }

    @Test("ImageXObject reads intent property")
    func testIntentProperty() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            ASAtom("Intent"): .name(ASAtom("Perceptual"))
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.intent == ASAtom("Perceptual"))
    }

    @Test("ImageXObject reads filter property")
    func testFilterProperty() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            .filter: .name(.dctDecode)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.filterName == .dctDecode)
        #expect(image.isJPEG == true)
    }

    @Test("ImageXObject detects JPEG2000")
    func testJPEG2000Detection() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            .filter: .name(.jpxDecode)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.isJPEG2000 == true)
        #expect(image.isJPEG == false)
    }

    @Test("ImageXObject detects CCITT")
    func testCCITTDetection() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceGray),
            .filter: .name(.ccittFaxDecode)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.isCCITT == true)
    }

    @Test("ImageXObject calculates sample count")
    func testSampleCount() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.sampleCount == 5000)
    }

    @Test("ImageXObject estimates data size")
    func testEstimatedDataSize() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(100),
            .bitsPerComponent: .integer(8),
            .colorSpace: .name(.deviceRGB)
        ])

        let image = try ImageXObject(cosObject: dict)
        // 100 * 100 * 3 components * 8 bits / 8 = 30000 bytes
        #expect(image.estimatedDataSize == 30000)
    }

    @Test("ImageXObject reads metadata")
    func testMetadataProperty() throws {
        let metadataRef = COSReference(objectNumber: 10, generation: 0)
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            .metadata: .reference(metadataRef)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.metadata != nil)
    }

    @Test("ImageXObject reads struct parent")
    func testStructParent() throws {
        let dict: COSValue = .dictionary([
            .width: .integer(100),
            .height: .integer(50),
            .colorSpace: .name(.deviceRGB),
            ASAtom("StructParent"): .integer(5)
        ])

        let image = try ImageXObject(cosObject: dict)
        #expect(image.structParent == 5)
    }
}
