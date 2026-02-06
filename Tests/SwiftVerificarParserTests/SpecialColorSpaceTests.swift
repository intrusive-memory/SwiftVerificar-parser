import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for special color spaces (ICCBased, Indexed, Separation, DeviceN, Pattern).
@Suite("Special Color Space Tests")
struct SpecialColorSpaceTests {

    // MARK: - ICCBased Tests

    @Test("ICCBased with 3 components and alternate")
    func iccBasedRGB() throws {
        let streamDict: COSValue = [
            .n: .integer(3),
            .alternate: .name(.deviceRGB)
        ]
        let array: COSValue = [.name(.iccBased), streamDict]

        let iccBased = try ICCBasedColorSpace(cosObject: array)

        #expect(iccBased.name == .iccBased)
        #expect(iccBased.numberOfComponents == 3)
        #expect(iccBased.alternateColorSpace is DeviceRGBColorSpace)
    }

    @Test("ICCBased with 1 component")
    func iccBasedGray() throws {
        let streamDict: COSValue = [
            .n: .integer(1),
            .alternate: .name(.deviceGray)
        ]
        let array: COSValue = [.name(.iccBased), streamDict]

        let iccBased = try ICCBasedColorSpace(cosObject: array)

        #expect(iccBased.numberOfComponents == 1)
    }

    @Test("ICCBased with 4 components")
    func iccBasedCMYK() throws {
        let streamDict: COSValue = [
            .n: .integer(4),
            .alternate: .name(.deviceCMYK)
        ]
        let array: COSValue = [.name(.iccBased), streamDict]

        let iccBased = try ICCBasedColorSpace(cosObject: array)

        #expect(iccBased.numberOfComponents == 4)
    }

    @Test("ICCBased converts through alternate space")
    func iccBasedConvertsToRGB() throws {
        let streamDict: COSValue = [
            .n: .integer(3),
            .alternate: .name(.deviceRGB)
        ]
        let array: COSValue = [.name(.iccBased), streamDict]

        let iccBased = try ICCBasedColorSpace(cosObject: array)
        let rgb = try iccBased.toRGB([1.0, 0.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("ICCBased missing N throws")
    func iccBasedMissingN() {
        let streamDict: COSValue = [
            .alternate: .name(.deviceRGB)
        ]
        let array: COSValue = [.name(.iccBased), streamDict]

        #expect(throws: PDError.missingRequiredEntry(key: "N")) {
            _ = try ICCBasedColorSpace(cosObject: array)
        }
    }

    @Test("ICCBased invalid N value throws")
    func iccBasedInvalidN() {
        let streamDict: COSValue = [
            .n: .integer(5)  // Invalid - must be 1, 3, or 4
        ]
        let array: COSValue = [.name(.iccBased), streamDict]

        #expect(throws: PDError.missingRequiredEntry(key: "N")) {
            _ = try ICCBasedColorSpace(cosObject: array)
        }
    }

    // MARK: - Indexed Tests

    @Test("Indexed color space with RGB base")
    func indexedRGB() throws {
        let lookupData = Data([
            0xFF, 0x00, 0x00,  // Red
            0x00, 0xFF, 0x00,  // Green
            0x00, 0x00, 0xFF   // Blue
        ])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceRGB),
            .integer(2),
            .string(COSString(data: lookupData))
        ]

        let indexed = try IndexedColorSpace(cosObject: array)

        #expect(indexed.name == .indexed)
        #expect(indexed.numberOfComponents == 1)
        #expect(indexed.highValue == 2)
        #expect(indexed.baseColorSpace is DeviceRGBColorSpace)
    }

    @Test("Indexed converts index 0 to red")
    func indexedIndex0() throws {
        let lookupData = Data([
            0xFF, 0x00, 0x00,  // Red
            0x00, 0xFF, 0x00,  // Green
            0x00, 0x00, 0xFF   // Blue
        ])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceRGB),
            .integer(2),
            .string(COSString(data: lookupData))
        ]

        let indexed = try IndexedColorSpace(cosObject: array)
        let rgb = try indexed.toRGB([0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("Indexed converts index 1 to green")
    func indexedIndex1() throws {
        let lookupData = Data([
            0xFF, 0x00, 0x00,  // Red
            0x00, 0xFF, 0x00,  // Green
            0x00, 0x00, 0xFF   // Blue
        ])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceRGB),
            .integer(2),
            .string(COSString(data: lookupData))
        ]

        let indexed = try IndexedColorSpace(cosObject: array)
        let rgb = try indexed.toRGB([1.0])

        #expect(rgb.r == 0.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 0.0)
    }

    @Test("Indexed clamps out-of-range index")
    func indexedClampsIndex() throws {
        let lookupData = Data([
            0xFF, 0x00, 0x00,  // Red
            0x00, 0xFF, 0x00,  // Green
            0x00, 0x00, 0xFF   // Blue
        ])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceRGB),
            .integer(2),
            .string(COSString(data: lookupData))
        ]

        let indexed = try IndexedColorSpace(cosObject: array)

        // Index 5 should be clamped to 2 (max)
        let rgb = try indexed.toRGB([5.0])
        #expect(rgb.b == 1.0)
    }

    @Test("Indexed with Gray base")
    func indexedGray() throws {
        let lookupData = Data([0x00, 0x80, 0xFF])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceGray),
            .integer(2),
            .string(COSString(data: lookupData))
        ]

        let indexed = try IndexedColorSpace(cosObject: array)

        #expect(indexed.numberOfComponents == 1)
        #expect(indexed.baseColorSpace is DeviceGrayColorSpace)
    }

    @Test("Indexed has CGColorSpace")
    func indexedHasCGColorSpace() throws {
        let lookupData = Data([0xFF, 0x00, 0x00])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceRGB),
            .integer(0),
            .string(COSString(data: lookupData))
        ]

        let indexed = try IndexedColorSpace(cosObject: array)

        #expect(indexed.cgColorSpace != nil)
    }

    // MARK: - Separation Tests

    @Test("Separation color space")
    func separation() throws {
        let array: COSValue = [
            .name(.separation),
            .name(ASAtom("PANTONE 185 CV"),
            .name(.deviceCMYK),
            .reference(COSReference(objectNumber: 10, generation: 0))
        ]

        let separation = try SeparationColorSpace(cosObject: array)

        #expect(separation.name == .separation)
        #expect(separation.numberOfComponents == 1)
        #expect(separation.colorantName == ..name(ASAtom("PANTONE 185 CV"))
        #expect(separation.alternateColorSpace is DeviceCMYKColorSpace)
    }

    @Test("Separation with /All colorant")
    func separationAll() throws {
        let array: COSValue = [
            .name(.separation),
            .name(ASAtom("All"),
            .name(.deviceGray),
            .reference(COSReference(objectNumber: 10, generation: 0))
        ]

        let separation = try SeparationColorSpace(cosObject: array)

        #expect(separation.colorantName == ..name(ASAtom("All"))

        // Tint 1.0 should produce black
        let rgb = try separation.toRGB([1.0])
        #expect(rgb.r == 0.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("Separation with /None colorant")
    func separationNone() throws {
        let array: COSValue = [
            .name(.separation),
            .name(ASAtom("None"),
            .name(.deviceGray),
            .reference(COSReference(objectNumber: 10, generation: 0))
        ]

        let separation = try SeparationColorSpace(cosObject: array)

        // /None colorant produces white (no output)
        let rgb = try separation.toRGB([1.0])
        #expect(rgb.r == 1.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("Separation approximates tint conversion")
    func separationTint() throws {
        let array: COSValue = [
            .name(.separation),
            .name(ASAtom("MyColor"),
            .name(.deviceRGB),
            .reference(COSReference(objectNumber: 10, generation: 0))
        ]

        let separation = try SeparationColorSpace(cosObject: array)

        // Tint 0.0 should be white
        let rgb0 = try separation.toRGB([0.0])
        #expect(rgb0.r == 1.0)
        #expect(rgb0.g == 1.0)
        #expect(rgb0.b == 1.0)

        // Tint 1.0 should be black (or darker)
        let rgb1 = try separation.toRGB([1.0])
        #expect(rgb1.r < rgb0.r)
    }

    // MARK: - DeviceN Tests

    @Test("DeviceN color space")
    func deviceN() throws {
        let array: COSValue = [
            .name(.deviceN),
            [.name(ASAtom("Cyan"), .name(ASAtom("Magenta")],
            .name(.deviceCMYK),
            .reference(COSReference(objectNumber: 11, generation: 0))
        ]

        let deviceN = try DeviceNColorSpace(cosObject: array)

        #expect(deviceN.name == .deviceN)
        #expect(deviceN.numberOfComponents == 2)
        #expect(deviceN.colorantNames.count == 2)
        #expect(deviceN.colorantNames[0] == ..name(ASAtom("Cyan"))
        #expect(deviceN.colorantNames[1] == ..name(ASAtom("Magenta"))
    }

    @Test("DeviceN with CMYK colorants")
    func deviceNCMYK() throws {
        let array: COSValue = [
            .name(.deviceN),
            [.name(ASAtom("Cyan"), .name(ASAtom("Magenta"), .name(ASAtom("Yellow"), .name(ASAtom("Black")],
            .name(.deviceCMYK),
            .reference(COSReference(objectNumber: 11, generation: 0))
        ]

        let deviceN = try DeviceNColorSpace(cosObject: array)

        #expect(deviceN.numberOfComponents == 4)

        // CMYK emulation: C=1, M=0, Y=0, K=0 should give cyan
        let rgb = try deviceN.toRGB([1.0, 0.0, 0.0, 0.0])
        #expect(rgb.r == 0.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("DeviceN with attributes")
    func deviceNWithAttributes() throws {
        let attrs: COSValue = [
            .name(ASAtom("Subtype"): .name(ASAtom("DeviceN")
        ]
        let array: COSValue = [
            .name(.deviceN),
            [.name(ASAtom("Orange"), .name(ASAtom("Green")],
            .name(.deviceRGB),
            .reference(COSReference(objectNumber: 11, generation: 0)),
            attrs
        ]

        let deviceN = try DeviceNColorSpace(cosObject: array)

        #expect(deviceN.attributes != nil)
    }

    @Test("DeviceN approximates tint conversion")
    func deviceNTint() throws {
        let array: COSValue = [
            .name(.deviceN),
            [.name(ASAtom("Color1"), .name(ASAtom("Color2")],
            .name(.deviceRGB),
            .reference(COSReference(objectNumber: 11, generation: 0))
        ]

        let deviceN = try DeviceNColorSpace(cosObject: array)

        // Should not throw
        let rgb = try deviceN.toRGB([0.5, 0.5])
        #expect(rgb.r >= 0.0 && rgb.r <= 1.0)
    }

    @Test("DeviceN throws for empty colorant list")
    func deviceNEmptyColorants() {
        let array: COSValue = [
            .name(.deviceN),
            [],  // Empty colorant list
            .name(.deviceRGB),
            .reference(COSReference(objectNumber: 11, generation: 0))
        ]

        #expect(throws: PDError.invalidColorSpace) {
            _ = try DeviceNColorSpace(cosObject: array)
        }
    }

    // MARK: - Pattern Tests

    @Test("Pattern color space (colored)")
    func patternColored() {
        let pattern = PatternColorSpace(cosObject: .name(.pattern))

        #expect(pattern.name == .pattern)
        #expect(pattern.numberOfComponents == 0)
        #expect(pattern.underlyingColorSpace == nil)
    }

    @Test("Pattern with underlying color space (uncolored)")
    func patternUncolored() {
        let array: COSValue = [.name(.pattern), .name(.deviceRGB)]

        let pattern = PatternColorSpace(cosObject: array)

        #expect(pattern.numberOfComponents == 3)
        #expect(pattern.underlyingColorSpace != nil)
        #expect(pattern.underlyingColorSpace is DeviceRGBColorSpace)
    }

    @Test("Pattern converts through underlying space")
    func patternConvertsToRGB() throws {
        let array: COSValue = [.name(.pattern), .name(.deviceRGB)]

        let pattern = PatternColorSpace(cosObject: array)
        let rgb = try pattern.toRGB([1.0, 0.0, 0.0])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 0.0)
        #expect(rgb.b == 0.0)
    }

    @Test("Pattern colored returns white by default")
    func patternColoredDefaultWhite() throws {
        let pattern = PatternColorSpace(cosObject: .name(.pattern))

        let rgb = try pattern.toRGB([])

        #expect(rgb.r == 1.0)
        #expect(rgb.g == 1.0)
        #expect(rgb.b == 1.0)
    }

    @Test("Pattern is Hashable")
    func patternHashable() {
        let pattern1 = PatternColorSpace(cosObject: .name(.pattern))
        let pattern2 = PatternColorSpace(cosObject: .name(.pattern))

        #expect(pattern1 == pattern2)
    }
}
