import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

/// Tests for device color spaces (DeviceGray, DeviceRGB, DeviceCMYK).
@Suite("Device Color Space Tests")
struct DeviceColorSpaceTests {

    // MARK: - DeviceGray Tests

    @Test("DeviceGray creation")
    func deviceGrayCreation() {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        #expect(gray.name == .deviceGray)
        #expect(gray.numberOfComponents == 1)
        #expect(gray.cosObject == .name(.deviceGray))
    }

    @Test("DeviceGray has CGColorSpace")
    func deviceGrayHasCGColorSpace() {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        #expect(gray.cgColorSpace != nil)
    }

    @Test("DeviceGray converts black to RGB")
    func deviceGrayBlackToRGB() throws {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        let rgb = try gray.toRGB([0.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceGray converts white to RGB")
    func deviceGrayWhiteToRGB() throws {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        let rgb = try gray.toRGB([1.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceGray converts mid-gray to RGB")
    func deviceGrayMidGrayToRGB() throws {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        let rgb = try gray.toRGB([0.5])

        #expect(rgb.r == 0.5)
        #expect(rgb.g == 0.5)
        #expect(rgb.b == 0.5)
    }

    @Test("DeviceGray clamps out-of-range values")
    func deviceGrayClampValues() throws {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        let rgb1 = try gray.toRGB([-0.5])
        #expect(rgb1.r == 0.0)

        let rgb2 = try gray.toRGB([1.5])
        #expect(rgb2.r == 1.0)
    }

    @Test("DeviceGray throws for wrong component count")
    func deviceGrayWrongComponentCount() {
        let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        #expect(throws: PDError.invalidColorComponents(expected: 1, got: 2)) {
            _ = try gray.toRGB([0.5, 0.5])
        }
    }

    @Test("DeviceGray is Hashable and Equatable")
    func deviceGrayHashable() {
        let gray1 = DeviceGrayColorSpace(cosObject: .name(.deviceGray))
        let gray2 = DeviceGrayColorSpace(cosObject: .name(.deviceGray))

        #expect(gray1 == gray2)
        #expect(gray1.hashValue == gray2.hashValue)
    }

    // MARK: - DeviceRGB Tests

    @Test("DeviceRGB creation")
    func deviceRGBCreation() {
        let rgb = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        #expect(rgb.name == .deviceRGB)
        #expect(rgb.numberOfComponents == 3)
        #expect(rgb.cosObject == .name(.deviceRGB))
    }

    @Test("DeviceRGB has CGColorSpace")
    func deviceRGBHasCGColorSpace() {
        let rgb = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        #expect(rgb.cgColorSpace != nil)
    }

    @Test("DeviceRGB converts red")
    func deviceRGBRed() throws {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        let rgb = try colorSpace.toRGB([1.0, 0.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceRGB converts green")
    func deviceRGBGreen() throws {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        let rgb = try colorSpace.toRGB([0.0, 1.0, 0.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceRGB converts blue")
    func deviceRGBBlue() throws {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        let rgb = try colorSpace.toRGB([0.0, 0.0, 1.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceRGB converts white")
    func deviceRGBWhite() throws {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        let rgb = try colorSpace.toRGB([1.0, 1.0, 1.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceRGB converts black")
    func deviceRGBBlack() throws {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        let rgb = try colorSpace.toRGB([0.0, 0.0, 0.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceRGB clamps out-of-range values")
    func deviceRGBClampValues() throws {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        let rgb = try colorSpace.toRGB([-0.5, 1.5, 0.5])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 0.5)
    }

    @Test("DeviceRGB throws for wrong component count")
    func deviceRGBWrongComponentCount() {
        let colorSpace = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))

        #expect(throws: PDError.invalidColorComponents(expected: 3, got: 2)) {
            _ = try colorSpace.toRGB([0.5, 0.5])
        }
    }

    // MARK: - DeviceCMYK Tests

    @Test("DeviceCMYK creation")
    func deviceCMYKCreation() {
        let cmyk = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        #expect(cmyk.name == .deviceCMYK)
        #expect(cmyk.numberOfComponents == 4)
        #expect(cmyk.cosObject == .name(.deviceCMYK))
    }

    @Test("DeviceCMYK has CGColorSpace")
    func deviceCMYKHasCGColorSpace() {
        let cmyk = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        #expect(cmyk.cgColorSpace != nil)
    }

    @Test("DeviceCMYK converts white (no ink)")
    func deviceCMYKWhite() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([0.0, 0.0, 0.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceCMYK converts black")
    func deviceCMYKBlack() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([0.0, 0.0, 0.0, 1.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceCMYK converts red (magenta + yellow)")
    func deviceCMYKRed() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([0.0, 1.0, 1.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceCMYK converts green (cyan + yellow)")
    func deviceCMYKGreen() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([1.0, 0.0, 1.0, 0.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceCMYK converts blue (cyan + magenta)")
    func deviceCMYKBlue() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([1.0, 1.0, 0.0, 0.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceCMYK converts cyan")
    func deviceCMYKCyan() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([1.0, 0.0, 0.0, 0.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceCMYK converts magenta")
    func deviceCMYKMagenta() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([0.0, 1.0, 0.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceCMYK converts yellow")
    func deviceCMYKYellow() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([0.0, 0.0, 1.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 0.0)
    }

    @Test("DeviceCMYK clamps out-of-range values")
    func deviceCMYKClampValues() throws {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        let rgb = try colorSpace.toRGB([-0.5, 1.5, 0.5, 0.5])

        // C=0, M=1, Y=0.5, K=0.5
        // R = (1-0) * (1-0.5) = 0.5
        // G = (1-1) * (1-0.5) = 0.0
        // B = (1-0.5) * (1-0.5) = 0.25
        #expect(rgb.r == 0.5)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.25)
    }

    @Test("DeviceCMYK throws for wrong component count")
    func deviceCMYKWrongComponentCount() {
        let colorSpace = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))

        #expect(throws: PDError.invalidColorComponents(expected: 4, got: 3)) {
            _ = try colorSpace.toRGB([0.5, 0.5, 0.5])
        }
    }
}
