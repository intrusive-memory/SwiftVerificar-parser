import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the Type1Font struct and SimpleFont protocol.
@Suite("Type1Font Tests")
struct Type1FontTests {

    @Test("Create valid Type1 font")
    func testValidType1Font() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(255),
            ASAtom("Widths"): .array(Array(repeating: .integer(500), count: 224))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.subtype == .type1)
        #expect(font.baseFontName == ASAtom("Helvetica"))
    }

    @Test("Create MMType1 font")
    func testMMType1Font() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.mmType1),
            .baseFont: .name(ASAtom("MyMMFont"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.subtype == .mmType1)
        #expect(font.isMultipleMaster == true)
    }

    @Test("Error - wrong subtype")
    func testWrongSubtype() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial"))
        ]

        #expect(throws: PDError.self) {
            _ = try Type1Font(cosObject: .dictionary(fontDict))
        }
    }

    @Test("Error - not a dictionary")
    func testNotADictionary() throws {
        #expect(throws: PDError.notADictionary) {
            _ = try Type1Font(cosObject: .name(ASAtom("NotADict")))
        }
    }

    @Test("Standard 14 fonts - Helvetica")
    func testStandard14Helvetica() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isStandard14 == true)
    }

    @Test("Standard 14 fonts - Times-Roman")
    func testStandard14TimesRoman() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Times-Roman"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isStandard14 == true)
    }

    @Test("Standard 14 fonts - Courier")
    func testStandard14Courier() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Courier"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isStandard14 == true)
    }

    @Test("Standard 14 fonts - Symbol")
    func testStandard14Symbol() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Symbol"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isStandard14 == true)
    }

    @Test("Not standard 14 font")
    func testNotStandard14() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyCustomFont"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isStandard14 == false)
    }

    @Test("FirstChar and LastChar")
    func testFirstLastChar() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(126)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.firstChar == 32)
        #expect(font.lastChar == 126)
    }

    @Test("Widths array")
    func testWidthsArray() throws {
        let widths = [250.0, 300.0, 350.0, 400.0, 450.0]
        let widthsValues = widths.map { COSValue.integer(Int64($0)) }

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            ASAtom("FirstChar"): .integer(65),  // 'A'
            ASAtom("LastChar"): .integer(69),   // 'E'
            ASAtom("Widths"): .array(widthsValues)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        let widthsArray = font.widths
        #expect(widthsArray?.count == 5)
        #expect(widthsArray?[0] == 250.0)
        #expect(widthsArray?[4] == 450.0)
    }

    @Test("Width lookup from widths array")
    func testWidthLookup() throws {
        let widths = [250.0, 300.0, 350.0, 400.0, 450.0]
        let widthsValues = widths.map { COSValue.integer(Int64($0)) }

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            ASAtom("FirstChar"): .integer(65),  // 'A'
            ASAtom("LastChar"): .integer(69),   // 'E'
            ASAtom("Widths"): .array(widthsValues)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))

        // Character code 65 ('A') should have width 250
        #expect(font.width(for: 65) == 250.0)

        // Character code 67 ('C') should have width 350
        #expect(font.width(for: 67) == 350.0)

        // Character code 69 ('E') should have width 450
        #expect(font.width(for: 69) == 450.0)
    }

    @Test("Width lookup outside range - returns default")
    func testWidthLookupOutsideRange() throws {
        let widths = [250.0, 300.0, 350.0]
        let widthsValues = widths.map { COSValue.integer(Int64($0)) }

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            ASAtom("FirstChar"): .integer(65),
            ASAtom("LastChar"): .integer(67),
            ASAtom("Widths"): .array(widthsValues)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))

        // Character code 32 (space) is outside the range, should return default
        #expect(font.width(for: 32) == 250.0)  // Default width

        // Character code 100 is outside the range
        #expect(font.width(for: 100) == 250.0)  // Default width
    }

    @Test("Width lookup with missing width - uses descriptor")
    func testWidthLookupWithMissingWidth() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("MyFont")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(0), .integer(0), .integer(1000), .integer(1000)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70),
            ASAtom("MissingWidth"): .integer(600)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            ASAtom("FirstChar"): .integer(65),
            ASAtom("LastChar"): .integer(67),
            ASAtom("Widths"): .array([.integer(250), .integer(300), .integer(350)]),
            .fontDescriptor: .dictionary(descriptorDict)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))

        // Character code outside range should use MissingWidth from descriptor
        #expect(font.width(for: 100) == 600.0)
    }

    @Test("Font program access")
    func testFontProgram() throws {
        let fontFileDict: [ASAtom: COSValue] = [
            .length: .integer(5000)
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
            ASAtom("FontFile"): .dictionary( fontFileDict)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            .fontDescriptor: .dictionary(descriptorDict)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.fontProgram != nil)
    }

    @Test("Is not composite")
    func testIsNotComposite() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isComposite == false)
    }

    @Test("All standard 14 font names")
    func testAllStandard14Names() {
        let standard14 = [
            "Times-Roman", "Times-Bold", "Times-Italic", "Times-BoldItalic",
            "Helvetica", "Helvetica-Bold", "Helvetica-Oblique", "Helvetica-BoldOblique",
            "Courier", "Courier-Bold", "Courier-Oblique", "Courier-BoldOblique",
            "Symbol", "ZapfDingbats"
        ]

        for name in standard14 {
            #expect(Standard14Fonts.isStandard14(ASAtom(name)) == true)
        }

        // Non-standard font
        #expect(Standard14Fonts.isStandard14(ASAtom("Arial")) == false)
    }
}
