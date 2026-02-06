import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for calibrated color spaces (CalGray, CalRGB, Lab).
@Suite("Calibrated Color Space Tests")
struct CalibratedColorSpaceTests {

    // MARK: - CalGray Tests

    @Test("CalGray with minimal parameters")
    func calGrayMinimal() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calGray), dict]

        let calGray = try CalGrayColorSpace(cosObject: array)

        #expect(calGray.name == .calGray)
        #expect(calGray.numberOfComponents == 1)
        #expect(calGray.whitePoint.x == 0.95)
        #expect(calGray.whitePoint.y == 1.0)
        #expect(calGray.whitePoint.z == 1.09)
        #expect(calGray.blackPoint.x == 0.0)
        #expect(calGray.blackPoint.y == 0.0)
        #expect(calGray.blackPoint.z == 0.0)
        #expect(calGray.gamma == 1.0)
    }

    @Test("CalGray with all parameters")
    func calGrayFull() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)],
            .blackPoint: [.real(0.1), .real(0.1), .real(0.1)],
            .gamma: .real(2.2)
        ]
        let array: COSValue = [.name(.calGray), dict]

        let calGray = try CalGrayColorSpace(cosObject: array)

        #expect(calGray.whitePoint.x == 0.95)
        #expect(calGray.blackPoint.x == 0.1)
        #expect(calGray.blackPoint.y == 0.1)
        #expect(calGray.blackPoint.z == 0.1)
        #expect(calGray.gamma == 2.2)
    }

    @Test("CalGray has CGColorSpace")
    func calGrayHasCGColorSpace() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calGray), dict]

        let calGray = try CalGrayColorSpace(cosObject: array)

        #expect(calGray.cgColorSpace != nil)
    }

    @Test("CalGray converts with gamma 1.0")
    func calGrayGamma1() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calGray), dict]

        let calGray = try CalGrayColorSpace(cosObject: array)
        let rgb = try calGray.toRGB([0.5])

        #expect(rgb.r == 0.5)
        #expect(rgb.g == 0.5)
        #expect(rgb.b == 0.5)
    }

    @Test("CalGray converts with gamma 2.2")
    func calGrayGamma2_2() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)],
            .gamma: .real(2.2)
        ]
        let array: COSValue = [.name(.calGray), dict]

        let calGray = try CalGrayColorSpace(cosObject: array)
        let rgb = try calGray.toRGB([0.5])

        let expected = pow(0.5, 2.2)
        #expect(abs(rgb.r - expected) < 0.0001)
    }

    @Test("CalGray missing white point throws")
    func calGrayMissingWhitePoint() {
        let dict: COSValue = [:]
        let array: COSValue = [.name(.calGray), dict]

        #expect(throws: PDError.missingRequiredEntry("WhitePoint")) {
            _ = try CalGrayColorSpace(cosObject: array)
        }
    }

    @Test("CalGray invalid array format throws")
    func calGrayInvalidArray() {
        let array: COSValue = [.name(.calGray)]  // Missing dict

        #expect(throws: PDError.invalidColorSpace) {
            _ = try CalGrayColorSpace(cosObject: array)
        }
    }

    // MARK: - CalRGB Tests

    @Test("CalRGB with minimal parameters")
    func calRGBMinimal() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calRGB), dict]

        let calRGB = try CalRGBColorSpace(cosObject: array)

        #expect(calRGB.name == .calRGB)
        #expect(calRGB.numberOfComponents == 3)
        #expect(calRGB.whitePoint.x == 0.95)
        #expect(calRGB.gamma.r == 1.0)
        #expect(calRGB.gamma.g == 1.0)
        #expect(calRGB.gamma.b == 1.0)
        #expect(calRGB.matrix == [1, 0, 0, 0, 1, 0, 0, 0, 1])
    }

    @Test("CalRGB with all parameters")
    func calRGBFull() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)],
            .blackPoint: [.real(0.1), .real(0.1), .real(0.1)],
            .gamma: [.real(2.2), .real(2.2), .real(2.2)],
            .matrix: [
                .real(0.4), .real(0.2), .real(0.1),
                .real(0.3), .real(0.6), .real(0.1),
                .real(0.1), .real(0.2), .real(0.9)
            ]
        ]
        let array: COSValue = [.name(.calRGB), dict]

        let calRGB = try CalRGBColorSpace(cosObject: array)

        #expect(calRGB.gamma.r == 2.2)
        #expect(calRGB.gamma.g == 2.2)
        #expect(calRGB.gamma.b == 2.2)
        #expect(calRGB.matrix.count == 9)
        #expect(calRGB.matrix[0] == 0.4)
    }

    @Test("CalRGB has CGColorSpace")
    func calRGBHasCGColorSpace() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calRGB), dict]

        let calRGB = try CalRGBColorSpace(cosObject: array)

        #expect(calRGB.cgColorSpace != nil)
    }

    @Test("CalRGB converts with identity matrix and gamma 1.0")
    func calRGBIdentity() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calRGB), dict]

        let calRGB = try CalRGBColorSpace(cosObject: array)
        let rgb = try calRGB.toRGB([1.0, 0.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    // MARK: - Lab Tests

    @Test("Lab with minimal parameters")
    func labMinimal() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)

        #expect(lab.name == .lab)
        #expect(lab.numberOfComponents == 3)
        #expect(lab.whitePoint.x == 0.95)
        #expect(lab.range.aMin == -100)
        #expect(lab.range.aMax == 100)
        #expect(lab.range.bMin == -100)
        #expect(lab.range.bMax == 100)
    }

    @Test("Lab with all parameters")
    func labFull() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)],
            .blackPoint: [.real(0.05), .real(0.05), .real(0.05)],
            .range: [.real(-128), .real(127), .real(-128), .real(127)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)

        #expect(lab.blackPoint.x == 0.05)
        #expect(lab.range.aMin == -128)
        #expect(lab.range.aMax == 127)
        #expect(lab.range.bMin == -128)
        #expect(lab.range.bMax == 127)
    }

    @Test("Lab has CGColorSpace")
    func labHasCGColorSpace() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)

        #expect(lab.cgColorSpace != nil)
    }

    @Test("Lab converts neutral gray (L=50, a=0, b=0)")
    func labNeutralGray() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)
        let rgb = try lab.toRGB([50, 0, 0])

        // Neutral gray should have equal R, G, B components
        #expect(abs(rgb.r - rgb.g) < 0.1)
        #expect(abs(rgb.g - rgb.b) < 0.1)
    }

    @Test("Lab converts white (L=100, a=0, b=0)")
    func labWhite() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)
        let rgb = try lab.toRGB([100, 0, 0])

        // White should be close to (1, 1, 1)
        #expect(rgb.r > 0.9)
        #expect(rgb.g > 0.9)
        #expect(rgb.b > 0.9)
    }

    @Test("Lab converts black (L=0, a=0, b=0)")
    func labBlack() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)
        let rgb = try lab.toRGB([0, 0, 0])

        // Black should be close to (0, 0, 0)
        #expect(rgb.r < 0.1)
        #expect(rgb.g < 0.1)
        #expect(rgb.b < 0.1)
    }

    @Test("Lab clamps L* to 0-100 range")
    func labClampsL() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let lab = try LabColorSpace(cosObject: array)

        // L* = -50 should be clamped to 0
        let rgb1 = try lab.toRGB([-50, 0, 0])
        #expect(rgb1.r < 0.1)

        // L* = 150 should be clamped to 100
        let rgb2 = try lab.toRGB([150, 0, 0])
        #expect(rgb2.r > 0.9)
    }

    @Test("Lab missing white point throws")
    func labMissingWhitePoint() {
        let dict: COSValue = [:]
        let array: COSValue = [.name(.lab), dict]

        #expect(throws: PDError.missingRequiredEntry("WhitePoint")) {
            _ = try LabColorSpace(cosObject: array)
        }
    }
}
