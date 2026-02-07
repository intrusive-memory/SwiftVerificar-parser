import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for InlineImage.
@Suite("InlineImage Tests")
struct InlineImageTests {

    // MARK: - Initialization Tests

    @Test("InlineImage creates with explicit properties")
    func testExplicitInitialization() {
        let data = Data([0xFF, 0x00, 0x80])
        let image = InlineImage(
            width: 100,
            height: 50,
            bitsPerComponent: 8,
            colorSpace: .name(.deviceRGB),
            data: data
        )

        #expect(image.width == 100)
        #expect(image.height == 50)
        #expect(image.bitsPerComponent == 8)
        #expect(image.colorSpaceName == .deviceRGB)
        #expect(image.dataSize == 3)
    }

    @Test("InlineImage creates image mask")
    func testImageMaskInitialization() {
        let data = Data([0xFF])
        let image = InlineImage(
            width: 8,
            height: 8,
            isImageMask: true,
            data: data
        )

        #expect(image.isImageMask == true)
        #expect(image.bitsPerComponent == 1)
        #expect(image.numberOfComponents == 1)
    }

    @Test("InlineImage creates from abbreviated dictionary")
    func testAbbreviatedDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(100),
            ASAtom("H"): .integer(50),
            ASAtom("BPC"): .integer(8),
            ASAtom("CS"): .name(.deviceRGB)
        ]
        let data = Data(repeating: 0xFF, count: 100)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.width == 100)
        #expect(image.height == 50)
        #expect(image.bitsPerComponent == 8)
    }

    @Test("InlineImage creates from full dictionary keys")
    func testFullDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            .width: .integer(200),
            .height: .integer(100),
            .bitsPerComponent: .integer(4),
            .colorSpace: .name(.deviceGray)
        ]
        let data = Data(repeating: 0x00, count: 50)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.width == 200)
        #expect(image.height == 100)
        #expect(image.bitsPerComponent == 4)
    }

    @Test("InlineImage throws for missing width")
    func testThrowsForMissingWidth() {
        let dict: [ASAtom: COSValue] = [
            ASAtom("H"): .integer(50)
        ]
        let data = Data()

        #expect(throws: XObjectError.self) {
            _ = try InlineImage(dictionary: dict, data: data)
        }
    }

    @Test("InlineImage throws for missing height")
    func testThrowsForMissingHeight() {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(100)
        ]
        let data = Data()

        #expect(throws: XObjectError.self) {
            _ = try InlineImage(dictionary: dict, data: data)
        }
    }

    @Test("InlineImage throws for invalid dimensions")
    func testThrowsForInvalidDimensions() {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(0),
            ASAtom("H"): .integer(100)
        ]
        let data = Data()

        #expect(throws: XObjectError.self) {
            _ = try InlineImage(dictionary: dict, data: data)
        }
    }

    // MARK: - Color Space Tests

    @Test("InlineImage expands abbreviated color space names")
    func testAbbreviatedColorSpaces() throws {
        let testCases: [(String, ASAtom)] = [
            ("G", .deviceGray),
            ("RGB", .deviceRGB),
            ("CMYK", .deviceCMYK),
            ("I", .indexed)
        ]

        for (abbreviated, expected) in testCases {
            let dict: [ASAtom: COSValue] = [
                ASAtom("W"): .integer(10),
                ASAtom("H"): .integer(10),
                ASAtom("CS"): .name(ASAtom(abbreviated))
            ]
            let data = Data(repeating: 0, count: 10)

            let image = try InlineImage(dictionary: dict, data: data)
            #expect(image.colorSpaceName == expected,
                   "Expected \(expected.stringValue) for abbreviated \(abbreviated)")
        }
    }

    @Test("InlineImage reads array color space")
    func testArrayColorSpace() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10),
            ASAtom("CS"): .array([.name(ASAtom("I")), .name(.deviceRGB), .integer(255)])
        ]
        let data = Data(repeating: 0, count: 10)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.colorSpaceName == .indexed)
    }

    @Test("InlineImage calculates component count")
    func testComponentCount() throws {
        let testCases: [(ASAtom, Int)] = [
            (ASAtom("G"), 1),
            (ASAtom("RGB"), 3),
            (ASAtom("CMYK"), 4),
            (.deviceGray, 1),
            (.deviceRGB, 3),
            (.deviceCMYK, 4)
        ]

        for (colorSpace, expectedComponents) in testCases {
            let dict: [ASAtom: COSValue] = [
                ASAtom("W"): .integer(10),
                ASAtom("H"): .integer(10),
                ASAtom("CS"): .name(colorSpace)
            ]
            let data = Data(repeating: 0, count: 10)

            let image = try InlineImage(dictionary: dict, data: data)
            #expect(image.numberOfComponents == expectedComponents,
                   "Expected \(expectedComponents) for \(colorSpace.stringValue)")
        }
    }

    // MARK: - Filter Tests

    @Test("InlineImage reads abbreviated filter names")
    func testAbbreviatedFilters() throws {
        let testCases: [(String, ASAtom)] = [
            ("AHx", .asciiHexDecode),
            ("A85", .ascii85Decode),
            ("LZW", .lzwDecode),
            ("Fl", .flateDecode),
            ("RL", .runLengthDecode),
            ("CCF", .ccittFaxDecode),
            ("DCT", .dctDecode)
        ]

        for (abbreviated, expected) in testCases {
            let dict: [ASAtom: COSValue] = [
                ASAtom("W"): .integer(10),
                ASAtom("H"): .integer(10),
                ASAtom("F"): .name(ASAtom(abbreviated))
            ]
            let data = Data(repeating: 0, count: 10)

            let image = try InlineImage(dictionary: dict, data: data)
            #expect(image.expandedFilterName == expected,
                   "Expected \(expected.stringValue) for \(abbreviated)")
        }
    }

    @Test("InlineImage detects compression")
    func testIsCompressed() throws {
        let compressedDict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10),
            ASAtom("F"): .name(.flateDecode)
        ]
        let uncompressedDict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10)
        ]
        let data = Data(repeating: 0, count: 10)

        let compressed = try InlineImage(dictionary: compressedDict, data: data)
        let uncompressed = try InlineImage(dictionary: uncompressedDict, data: data)

        #expect(compressed.isCompressed == true)
        #expect(uncompressed.isCompressed == false)
    }

    // MARK: - Property Tests

    @Test("InlineImage reads interpolate flag")
    func testInterpolateFlag() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10),
            ASAtom("I"): .boolean(true)
        ]
        let data = Data(repeating: 0, count: 10)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.interpolate == true)
    }

    @Test("InlineImage reads decode array")
    func testDecodeArray() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10),
            ASAtom("D"): .array([.real(0), .real(1)])
        ]
        let data = Data(repeating: 0, count: 10)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.decode?.count == 2)
        #expect(image.decode?[0] == 0)
        #expect(image.decode?[1] == 1)
    }

    @Test("InlineImage reads decode params")
    func testDecodeParams() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10),
            ASAtom("DP"): .dictionary([.columns: .integer(10)])
        ]
        let data = Data(repeating: 0, count: 10)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.decodeParms != nil)
    }

    @Test("InlineImage stores additional entries")
    func testAdditionalEntries() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10),
            ASAtom("CustomKey"): .string(COSString(string: "custom value"))
        ]
        let data = Data(repeating: 0, count: 10)

        let image = try InlineImage(dictionary: dict, data: data)
        #expect(image.additionalEntries[ASAtom("CustomKey")] != nil)
    }

    // MARK: - Data Size Tests

    @Test("InlineImage reports data size")
    func testDataSize() {
        let data = Data(repeating: 0xFF, count: 1024)
        let image = InlineImage(width: 100, height: 100, data: data)

        #expect(image.dataSize == 1024)
    }

    @Test("InlineImage estimates uncompressed size")
    func testEstimatedUncompressedSize() {
        let data = Data()
        let image = InlineImage(
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            colorSpace: .name(.deviceRGB),
            data: data
        )

        // 100 * 100 * 3 components * 8 bits / 8 = 30000 bytes
        #expect(image.estimatedUncompressedSize == 30000)
    }

    @Test("InlineImage estimates size for image mask")
    func testEstimatedSizeForMask() {
        let data = Data()
        let image = InlineImage(
            width: 64,
            height: 64,
            isImageMask: true,
            data: data
        )

        // 64 * 64 * 1 component * 1 bit / 8 = 512 bytes
        #expect(image.estimatedUncompressedSize == 512)
    }

    // MARK: - Description Tests

    @Test("InlineImage has description")
    func testDescription() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(100),
            ASAtom("H"): .integer(50),
            ASAtom("CS"): .name(.deviceRGB),
            ASAtom("F"): .name(.flateDecode)
        ]
        let data = Data(repeating: 0, count: 100)

        let image = try InlineImage(dictionary: dict, data: data)
        let desc = image.description

        #expect(desc.contains("100x50"))
        #expect(desc.contains("DeviceRGB"))
        #expect(desc.contains("FlateDecode"))
        #expect(desc.contains("100 bytes"))
    }

    @Test("InlineImage description shows mask")
    func testDescriptionForMask() {
        let data = Data(repeating: 0, count: 8)
        let image = InlineImage(width: 8, height: 8, isImageMask: true, data: data)
        let desc = image.description

        #expect(desc.contains("mask"))
    }

    // MARK: - Equality and Hashing Tests

    @Test("InlineImage equality")
    func testEquality() {
        let data1 = Data([0x00, 0xFF])
        let data2 = Data([0x00, 0xFF])
        let data3 = Data([0xFF, 0x00])

        let image1 = InlineImage(width: 10, height: 10, data: data1)
        let image2 = InlineImage(width: 10, height: 10, data: data2)
        let image3 = InlineImage(width: 10, height: 10, data: data3)

        #expect(image1 == image2)
        #expect(image1 != image3)
    }

    @Test("InlineImage hashing")
    func testHashing() {
        let data = Data([0x00, 0xFF])
        let image1 = InlineImage(width: 10, height: 10, data: data)
        let image2 = InlineImage(width: 10, height: 10, data: data)

        var set = Set<InlineImage>()
        set.insert(image1)
        set.insert(image2)

        #expect(set.count == 1)
    }
}
