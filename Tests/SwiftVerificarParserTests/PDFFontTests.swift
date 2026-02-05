import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the PDFFont protocol and base font functionality.
@Suite("PDFFont Protocol Tests")
struct PDFFontTests {

    @Test("Font subtype extraction")
    func testSubtype() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica"))
        ]

        // Use Type1Font as concrete implementation
        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.subtype == .type1)
    }

    @Test("Base font name extraction")
    func testBaseFontName() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica-Bold"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.baseFontName == ASAtom("Helvetica-Bold"))
    }

    @Test("Missing base font name")
    func testMissingBaseFontName() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.baseFontName == nil)
    }

    @Test("ToUnicode CMap extraction")
    func testToUnicodeCMap() throws {
        let toUnicodeDict: [ASAtom: COSValue] = [
            .length: .integer(100)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            .toUnicode: .dictionary(toUnicodeDict)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.toUnicodeCMap != nil)
    }

    @Test("Composite font detection - Type0")
    func testCompositeType0() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.isComposite == true)
    }

    @Test("Composite font detection - Type1")
    func testNotCompositeType1() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.isComposite == false)
    }

    @Test("Default width fallback")
    func testDefaultWidth() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont"))
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        // Should return default width when no widths array is present
        #expect(font.width(for: 65) == 250.0)
    }

    @Test("Font with encoding")
    func testFontWithEncoding() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.winAnsiEncoding)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.encoding != nil)
        #expect(font.encoding?.encodingName == .winAnsiEncoding)
    }

    @Test("Font with font descriptor")
    func testFontWithDescriptor() throws {
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

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("MyFont")),
            .fontDescriptor: .dictionary(descriptorDict)
        ]

        let font = try Type1Font(cosObject: .dictionary(fontDict))
        #expect(font.fontDescriptor != nil)
        #expect(font.fontDescriptor?.fontName == ASAtom("MyFont"))
    }
}
