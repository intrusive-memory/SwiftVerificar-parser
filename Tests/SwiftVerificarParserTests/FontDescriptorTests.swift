import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the FontDescriptor struct.
@Suite("FontDescriptor Tests")
struct FontDescriptorTests {

    @Test("Create valid font descriptor")
    func testValidDescriptor() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Helvetica")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(-100), .integer(-200), .integer(1000), .integer(900)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.fontName == ASAtom("Helvetica"))
        #expect(descriptor.flags == 32)
        #expect(descriptor.italicAngle == 0.0)
        #expect(descriptor.ascent == 750.0)
        #expect(descriptor.descent == -250.0)
        #expect(descriptor.capHeight == 700.0)
        #expect(descriptor.stemV == 70.0)
    }

    @Test("Font bounding box extraction")
    func testFontBBox() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(-100), .integer(-200), .integer(1000), .integer(900)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        let bbox = descriptor.fontBBox
        #expect(bbox.count == 4)
        #expect(bbox[0] == -100.0)
        #expect(bbox[1] == -200.0)
        #expect(bbox[2] == 1000.0)
        #expect(bbox[3] == 900.0)
    }

    @Test("Font bounding box with real numbers")
    func testFontBBoxWithReals() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.real(-100.5), .real(-200.5), .real(1000.5), .real(900.5)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        let bbox = descriptor.fontBBox
        #expect(bbox.count == 4)
        #expect(bbox[0] == -100.5)
        #expect(bbox[1] == -200.5)
        #expect(bbox[2] == 1000.5)
        #expect(bbox[3] == 900.5)
    }

    @Test("Default font bounding box")
    func testDefaultBBox() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        let bbox = descriptor.fontBBox
        #expect(bbox == [0, 0, 1000, 1000])  // Default bounding box
    }

    @Test("Italic angle - integer")
    func testItalicAngleInteger() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(-12),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.italicAngle == -12.0)
    }

    @Test("Italic angle - real")
    func testItalicAngleReal() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .real(-12.5),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.italicAngle == -12.5)
    }

    @Test("Optional properties - XHeight")
    func testXHeight() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70),
            ASAtom("XHeight"): .integer(500)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.xHeight == 500.0)
    }

    @Test("Optional properties - missing")
    func testMissingOptionalProperties() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.xHeight == nil)
        #expect(descriptor.avgWidth == nil)
        #expect(descriptor.maxWidth == nil)
        #expect(descriptor.missingWidth == nil)
        #expect(descriptor.leading == nil)
        #expect(descriptor.stemH == nil)
    }

    @Test("Font flags - fixed pitch")
    func testFixedPitchFlag() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Courier")),
            ASAtom("Flags"): .integer(0x1),  // Fixed pitch
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.isFixedPitch == true)
        #expect(descriptor.isSerif == false)
    }

    @Test("Font flags - serif")
    func testSerifFlag() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Times")),
            ASAtom("Flags"): .integer(0x2),  // Serif
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.isSerif == true)
        #expect(descriptor.isFixedPitch == false)
    }

    @Test("Font flags - symbolic")
    func testSymbolicFlag() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Symbol")),
            ASAtom("Flags"): .integer(0x4),  // Symbolic
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.isSymbolic == true)
        #expect(descriptor.isNonsymbolic == false)
    }

    @Test("Font flags - nonsymbolic")
    func testNonsymbolicFlag() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Helvetica")),
            ASAtom("Flags"): .integer(0x20),  // Nonsymbolic
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.isNonsymbolic == true)
        #expect(descriptor.isSymbolic == false)
    }

    @Test("Font flags - italic")
    func testItalicFlag() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Helvetica-Oblique")),
            ASAtom("Flags"): .integer(0x40),  // Italic
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(-12),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.isItalic == true)
    }

    @Test("Font file entries")
    func testFontFileEntries() throws {
        let fontFileDict: [ASAtom: COSValue] = [.length: .integer(1000)]
        let fontFile2Dict: [ASAtom: COSValue] = [.length: .integer(2000)]
        let fontFile3Dict: [ASAtom: COSValue] = [
            .length: .integer(3000),
            .subtype: .name(ASAtom("OpenType"))
        ]

        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70),
            ASAtom("FontFile"): .dictionary(fontFileDict),
            ASAtom("FontFile2"): .dictionary(fontFile2Dict),
            ASAtom("FontFile3"): .dictionary(fontFile3Dict)
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.fontFile != nil)
        #expect(descriptor.fontFile2 != nil)
        #expect(descriptor.fontFile3 != nil)
        #expect(descriptor.fontFile3Subtype == ASAtom("OpenType"))
    }

    @Test("Error - not a dictionary")
    func testNotADictionary() throws {
        #expect(throws: PDError.notADictionary) {
            _ = try FontDescriptor(cosObject: .name(ASAtom("NotADict")))
        }
    }

    @Test("Default values for missing required fields")
    func testDefaultValues() throws {
        // Minimal descriptor with missing fields
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont"))
        ]

        let descriptor = try FontDescriptor(cosObject: .dictionary(descriptorDict))
        #expect(descriptor.flags == 0)
        #expect(descriptor.italicAngle == 0.0)
        #expect(descriptor.ascent == 750.0)
        #expect(descriptor.descent == -250.0)
        #expect(descriptor.capHeight == 700.0)
        #expect(descriptor.stemV == 70.0)
    }
}
