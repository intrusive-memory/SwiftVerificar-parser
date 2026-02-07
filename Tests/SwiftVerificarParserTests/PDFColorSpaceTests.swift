import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the PDFColorSpace protocol and factory method.
@Suite("PDFColorSpace Tests")
struct PDFColorSpaceTests {

    // MARK: - Factory Method Tests

    @Test("Create DeviceGray from name")
    func createDeviceGrayFromName() throws {
        let colorSpace = try PDFColorSpaceFactory.create(from: .name(.deviceGray))

        #expect(colorSpace.name == .deviceGray)
        #expect(colorSpace.numberOfComponents == 1)
        #expect(colorSpace is DeviceGrayColorSpace)
    }

    @Test("Create DeviceRGB from name")
    func createDeviceRGBFromName() throws {
        let colorSpace = try PDFColorSpaceFactory.create(from: .name(.deviceRGB))

        #expect(colorSpace.name == .deviceRGB)
        #expect(colorSpace.numberOfComponents == 3)
        #expect(colorSpace is DeviceRGBColorSpace)
    }

    @Test("Create DeviceCMYK from name")
    func createDeviceCMYKFromName() throws {
        let colorSpace = try PDFColorSpaceFactory.create(from: .name(.deviceCMYK))

        #expect(colorSpace.name == .deviceCMYK)
        #expect(colorSpace.numberOfComponents == 4)
        #expect(colorSpace is DeviceCMYKColorSpace)
    }

    @Test("Create Pattern from name")
    func createPatternFromName() throws {
        let colorSpace = try PDFColorSpaceFactory.create(from: .name(.pattern))

        #expect(colorSpace.name == .pattern)
        #expect(colorSpace is PatternColorSpace)
    }

    @Test("Create CalGray from array")
    func createCalGrayFromArray() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calGray), dict]

        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .calGray)
        #expect(colorSpace.numberOfComponents == 1)
        #expect(colorSpace is CalGrayColorSpace)
    }

    @Test("Create CalRGB from array")
    func createCalRGBFromArray() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.calRGB), dict]

        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .calRGB)
        #expect(colorSpace.numberOfComponents == 3)
        #expect(colorSpace is CalRGBColorSpace)
    }

    @Test("Create Lab from array")
    func createLabFromArray() throws {
        let dict: COSValue = [
            .whitePoint: [.real(0.95), .real(1.0), .real(1.09)]
        ]
        let array: COSValue = [.name(.lab), dict]

        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .lab)
        #expect(colorSpace.numberOfComponents == 3)
        #expect(colorSpace is LabColorSpace)
    }

    @Test("Create ICCBased from array", .disabled("ICCBased from reference not implemented in v0.1.0"))
    func createICCBasedFromArray() throws {
        // ICCBased color spaces in PDFs typically use a reference to a stream
        // For testing, we'll use a dictionary that represents the stream's properties
        let streamRef = COSReference(objectNumber: 5, generation: 0)
        let array: COSValue = [.name(.iccBased), .reference(streamRef)]

        // This test verifies the factory can create an ICCBased color space
        // In real usage, the stream would be resolved and parsed
        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .iccBased)
        #expect(colorSpace is ICCBasedColorSpace)
    }

    @Test("Create Indexed from array")
    func createIndexedFromArray() throws {
        let lookupData = Data([
            0xFF, 0x00, 0x00,  // Red
            0x00, 0xFF, 0x00,  // Green
            0x00, 0x00, 0xFF   // Blue
        ])
        let array: COSValue = [
            .name(.indexed),
            .name(.deviceRGB),
            .integer(2),  // hival = 2 (3 colors)
            .string(COSString(data: lookupData))
        ]

        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .indexed)
        #expect(colorSpace.numberOfComponents == 1)
        #expect(colorSpace is IndexedColorSpace)
    }

    @Test("Create Separation from array")
    func createSeparationFromArray() throws {
        let array: COSValue = [
            .name(.separation),
            .name(ASAtom("PANTONE 185 CV")),
            .name(.deviceCMYK),
            .reference(COSReference(objectNumber: 10, generation: 0))  // Function
        ]

        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .separation)
        #expect(colorSpace.numberOfComponents == 1)
        #expect(colorSpace is SeparationColorSpace)
    }

    @Test("Create DeviceN from array")
    func createDeviceNFromArray() throws {
        let array: COSValue = .array([
            .name(.deviceN),
            .array([.name(ASAtom("Cyan")), .name(ASAtom("Magenta")), .name(ASAtom("Yellow")), .name(ASAtom("Black"))]),
            .name(.deviceCMYK),
            .reference(COSReference(objectNumber: 11, generation: 0))  // Function
        ])

        let colorSpace = try PDFColorSpaceFactory.create(from: array)

        #expect(colorSpace.name == .deviceN)
        #expect(colorSpace.numberOfComponents == 4)
        #expect(colorSpace is DeviceNColorSpace)
    }

    @Test("Unsupported color space throws error")
    func unsupportedColorSpace() throws {
        let unknownName = ASAtom("UnknownColorSpace")

        #expect(throws: PDError.unsupportedColorSpace(unknownName.stringValue)) {
            _ = try PDFColorSpaceFactory.create(from: .name(unknownName))
        }
    }

    @Test("Invalid color space array throws error")
    func invalidColorSpaceArray() throws {
        let emptyArray: COSValue = []

        #expect(throws: PDError.invalidColorSpace) {
            _ = try PDFColorSpaceFactory.create(from: emptyArray)
        }
    }

    @Test("Array with non-name first element throws error")
    func arrayWithNonNameFirstElement() throws {
        let array: COSValue = [.integer(123), .null]

        #expect(throws: PDError.invalidColorSpace) {
            _ = try PDFColorSpaceFactory.create(from: array)
        }
    }
}
