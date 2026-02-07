import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the CIDFont struct.
@Suite("CIDFont Tests")
struct CIDFontTests {

    @Test("Create valid CIDFontType0")
    func testValidCIDFontType0() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ])
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.subtype == .cidFontType0)
        #expect(font.isCIDFontType0 == true)
        #expect(font.isCIDFontType2 == false)
    }

    @Test("Create valid CIDFontType2")
    func testValidCIDFontType2() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType2),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Korea1")),
                ASAtom("Supplement"): .integer(2)
            ])
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.subtype == .cidFontType2)
        #expect(font.isCIDFontType0 == false)
        #expect(font.isCIDFontType2 == true)
    }

    @Test("Error - wrong subtype")
    func testWrongSubtype() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("NotACIDFont"))
        ]

        #expect(throws: PDError.self) {
            _ = try CIDFont(cosObject: .dictionary(cidFontDict))
        }
    }

    @Test("Error - not a dictionary")
    func testNotADictionary() throws {
        #expect(throws: PDError.notADictionary) {
            _ = try CIDFont(cosObject: .name(ASAtom("NotADict")))
        }
    }

    @Test("CIDSystemInfo access")
    func testCIDSystemInfo() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ])
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        let info = font.cidSystemInfo
        #expect(info != nil)
        #expect(info?.registry == "Adobe")
        #expect(info?.ordering == "Japan1")
        #expect(info?.supplement == 6)
        #expect(info?.fullName == "Adobe-Japan1-6")
    }

    @Test("Default width - explicit")
    func testDefaultWidthExplicit() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("DW"): .integer(500)
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.defaultWidth == 500.0)
    }

    @Test("Default width - default value")
    func testDefaultWidthDefault() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ])
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.defaultWidth == 1000.0)
    }

    @Test("Width array - individual widths format")
    func testWidthArrayIndividualWidths() throws {
        let widthArray: [COSValue] = [
            .integer(1),  // Start CID
            .array([.integer(500), .integer(600), .integer(700)])
        ]

        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("DW"): .integer(1000),
            ASAtom("W"): .array(widthArray)
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.width(for: 1) == 500.0)
        #expect(font.width(for: 2) == 600.0)
        #expect(font.width(for: 3) == 700.0)
        #expect(font.width(for: 4) == 1000.0)  // Default
    }

    @Test("Width array - range format")
    func testWidthArrayRangeFormat() throws {
        let widthArray: [COSValue] = [
            .integer(100),  // Start CID
            .integer(200),  // End CID
            .integer(800)   // Width for entire range
        ]

        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("DW"): .integer(1000),
            ASAtom("W"): .array(widthArray)
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.width(for: 100) == 800.0)
        #expect(font.width(for: 150) == 800.0)
        #expect(font.width(for: 200) == 800.0)
        #expect(font.width(for: 99) == 1000.0)   // Before range
        #expect(font.width(for: 201) == 1000.0)  // After range
    }

    @Test("Width array - mixed format")
    func testWidthArrayMixedFormat() throws {
        let widthArray: [COSValue] = [
            .integer(1),
            .array([.integer(500), .integer(600)]),
            .integer(10),
            .integer(20),
            .integer(750)
        ]

        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("DW"): .integer(1000),
            ASAtom("W"): .array(widthArray)
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.width(for: 1) == 500.0)
        #expect(font.width(for: 2) == 600.0)
        #expect(font.width(for: 15) == 750.0)  // In range [10, 20]
        #expect(font.width(for: 100) == 1000.0)  // Default
    }

    @Test("CIDToGIDMap - Identity")
    func testCIDToGIDMapIdentity() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType2),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("CIDToGIDMap"): .name(ASAtom("Identity"))
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.isIdentityCIDToGID == true)
        #expect(font.cidToGIDMap != nil)
    }

    @Test("CIDToGIDMap - stream")
    func testCIDToGIDMapStream() throws {
        let mapDict: [ASAtom: COSValue] = [
            .length: .integer(1000)
        ]

        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType2),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("CIDToGIDMap"): .dictionary( mapDict)
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.isIdentityCIDToGID == false)
        #expect(font.cidToGIDMap != nil)
    }

    @Test("CIDFont does not have simple encoding")
    func testNoSimpleEncoding() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ])
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.encoding == nil)
    }

    @Test("Width with real numbers")
    func testWidthWithRealNumbers() throws {
        let widthArray: [COSValue] = [
            .integer(1),
            .array([.real(500.5), .real(600.5)])
        ]

        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType0),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Japan1")),
                ASAtom("Supplement"): .integer(6)
            ]),
            ASAtom("DW"): .real(1000.5),
            ASAtom("W"): .array(widthArray)
        ]

        let font = try CIDFont(cosObject: .dictionary(cidFontDict))
        #expect(font.defaultWidth == 1000.5)
        #expect(font.width(for: 1) == 500.5)
        #expect(font.width(for: 2) == 600.5)
    }
}

/// Tests for the CIDSystemInfo struct.
@Suite("CIDSystemInfo Tests")
struct CIDSystemInfoTests {

    @Test("Create valid CIDSystemInfo")
    func testValidCIDSystemInfo() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Registry"): .string(COSString(string: "Adobe")),
            ASAtom("Ordering"): .string(COSString(string: "Japan1")),
            ASAtom("Supplement"): .integer(6)
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.registry == "Adobe")
        #expect(info.ordering == "Japan1")
        #expect(info.supplement == 6)
    }

    @Test("Full name generation")
    func testFullName() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Registry"): .string(COSString(string: "Adobe")),
            ASAtom("Ordering"): .string(COSString(string: "Korea1")),
            ASAtom("Supplement"): .integer(2)
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.fullName == "Adobe-Korea1-2")
    }

    @Test("Full name - GB1")
    func testFullNameGB1() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Registry"): .string(COSString(string: "Adobe")),
            ASAtom("Ordering"): .string(COSString(string: "GB1")),
            ASAtom("Supplement"): .integer(5)
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.fullName == "Adobe-GB1-5")
    }

    @Test("Full name - CNS1")
    func testFullNameCNS1() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Registry"): .string(COSString(string: "Adobe")),
            ASAtom("Ordering"): .string(COSString(string: "CNS1")),
            ASAtom("Supplement"): .integer(7)
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.fullName == "Adobe-CNS1-7")
    }

    @Test("Missing registry")
    func testMissingRegistry() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Ordering"): .string(COSString(string: "Japan1")),
            ASAtom("Supplement"): .integer(6)
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.registry == nil)
        #expect(info.fullName == "Unknown-Japan1-6")
    }

    @Test("Missing ordering")
    func testMissingOrdering() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Registry"): .string(COSString(string: "Adobe")),
            ASAtom("Supplement"): .integer(6)
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.ordering == nil)
        #expect(info.fullName == "Adobe-Unknown-6")
    }

    @Test("Missing supplement")
    func testMissingSupplement() throws {
        let infoDict: [ASAtom: COSValue] = [
            ASAtom("Registry"): .string(COSString(string: "Adobe")),
            ASAtom("Ordering"): .string(COSString(string: "Japan1"))
        ]

        let info = try CIDSystemInfo(cosObject: .dictionary(infoDict))
        #expect(info.supplement == nil)
        #expect(info.fullName == "Adobe-Japan1-0")
    }

    @Test("Error - not a dictionary")
    func testNotADictionary() throws {
        #expect(throws: PDError.notADictionary) {
            _ = try CIDSystemInfo(cosObject: .name(ASAtom("NotADict")))
        }
    }
}
