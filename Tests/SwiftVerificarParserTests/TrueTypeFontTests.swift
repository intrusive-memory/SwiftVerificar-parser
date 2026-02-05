import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the TrueTypeFont struct.
@Suite("TrueTypeFont Tests")
struct TrueTypeFontTests {

    @Test("Create valid TrueType font")
    func testValidTrueTypeFont() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(255),
            ASAtom("Widths"): .array(Array(repeating: .integer(500), count: 224))
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.subtype == .trueType)
        #expect(font.baseFontName == ASAtom("Arial"))
    }

    @Test("Error - wrong subtype")
    func testWrongSubtype() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica"))
        ]

        #expect(throws: PDError.self) {
            _ = try TrueTypeFont(cosObject: .dictionary(fontDict))
        }
    }

    @Test("Error - not a dictionary")
    func testNotADictionary() throws {
        #expect(throws: PDError.notADictionary) {
            _ = try TrueTypeFont(cosObject: .name(ASAtom("NotADict")))
        }
    }

    @Test("TrueType with embedded font program")
    func testEmbeddedFontProgram() throws {
        let fontFile2Dict: [ASAtom: COSValue] = [
            .length: .integer(12000),
            ASAtom("Length1"): .integer(12000)
        ]

        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Arial")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(-100), .integer(-200), .integer(1000), .integer(900)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70),
            ASAtom("FontFile2"): .dictionary( fontFile2Dict)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(255),
            ASAtom("Widths"): .array(Array(repeating: .integer(500), count: 224)),
            .fontDescriptor: .dictionary(descriptorDict)
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.fontProgram != nil)
        #expect(font.isEmbedded == true)
        #expect(font.fontProgramLength == 12000)
    }

    @Test("TrueType without embedded font program")
    func testNoEmbeddedFontProgram() throws {
        let descriptorDict: [ASAtom: COSValue] = [
            ASAtom("FontName"): .name(ASAtom("Arial")),
            ASAtom("Flags"): .integer(32),
            ASAtom("FontBBox"): .array([.integer(-100), .integer(-200), .integer(1000), .integer(900)]),
            ASAtom("ItalicAngle"): .integer(0),
            ASAtom("Ascent"): .integer(750),
            ASAtom("Descent"): .integer(-250),
            ASAtom("CapHeight"): .integer(700),
            ASAtom("StemV"): .integer(70)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(255),
            ASAtom("Widths"): .array(Array(repeating: .integer(500), count: 224)),
            .fontDescriptor: .dictionary(descriptorDict)
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.fontProgram == nil)
        #expect(font.isEmbedded == false)
        #expect(font.fontProgramLength == nil)
    }

    @Test("TrueType with widths array")
    func testWidthsArray() throws {
        let widths = Array(stride(from: 200, through: 600, by: 50)).map { COSValue.integer(Int64($0)) }

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(65),  // 'A'
            ASAtom("LastChar"): .integer(73),   // 'I'
            ASAtom("Widths"): .array(widths)
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.firstChar == 65)
        #expect(font.lastChar == 73)
        #expect(font.widths?.count == 9)
    }

    @Test("TrueType width lookup")
    func testWidthLookup() throws {
        let widths = [250.0, 300.0, 350.0, 400.0, 450.0]
        let widthsValues = widths.map { COSValue.integer(Int64($0)) }

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(65),  // 'A'
            ASAtom("LastChar"): .integer(69),   // 'E'
            ASAtom("Widths"): .array(widthsValues)
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))

        // Test width lookup
        #expect(font.width(for: 65) == 250.0)  // 'A'
        #expect(font.width(for: 67) == 350.0)  // 'C'
        #expect(font.width(for: 69) == 450.0)  // 'E'

        // Outside range - should return default
        #expect(font.width(for: 32) == 250.0)  // Default
    }

    @Test("TrueType with encoding")
    func testTrueTypeWithEncoding() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(255),
            ASAtom("Widths"): .array(Array(repeating: .integer(500), count: 224)),
            .encoding: .name(.winAnsiEncoding)
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.encoding != nil)
        #expect(font.encoding?.encodingName == .winAnsiEncoding)
    }

    @Test("TrueType with ToUnicode")
    func testTrueTypeWithToUnicode() throws {
        let toUnicodeDict: [ASAtom: COSValue] = [
            .length: .integer(500)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial")),
            ASAtom("FirstChar"): .integer(32),
            ASAtom("LastChar"): .integer(255),
            ASAtom("Widths"): .array(Array(repeating: .integer(500), count: 224)),
            .toUnicode: .dictionary( toUnicodeDict)
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.toUnicodeCMap != nil)
    }

    @Test("TrueType is not composite")
    func testIsNotComposite() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial"))
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.isComposite == false)
    }

    @Test("TrueType minimal dictionary")
    func testMinimalDictionary() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.trueType),
            .baseFont: .name(ASAtom("Arial"))
        ]

        let font = try TrueTypeFont(cosObject: .dictionary(fontDict))
        #expect(font.baseFontName == ASAtom("Arial"))
        #expect(font.firstChar == nil)
        #expect(font.lastChar == nil)
        #expect(font.widths == nil)
        #expect(font.fontDescriptor == nil)
    }
}
