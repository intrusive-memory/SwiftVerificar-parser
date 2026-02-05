import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the Type0Font struct (composite fonts).
@Suite("Type0Font Tests")
struct Type0FontTests {

    @Test("Create valid Type0 font")
    func testValidType0Font() throws {
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

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyCompositeFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([.dictionary(cidFontDict)])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.subtype == .type0)
        #expect(font.baseFontName == ASAtom("MyCompositeFont"))
        #expect(font.isComposite == true)
    }

    @Test("Error - wrong subtype")
    func testWrongSubtype() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type1),
            .baseFont: .name(ASAtom("Helvetica"))
        ]

        #expect(throws: PDError.self) {
            _ = try Type0Font(cosObject: .dictionary(fontDict))
        }
    }

    @Test("Error - not a dictionary")
    func testNotADictionary() throws {
        #expect(throws: PDError.notADictionary) {
            _ = try Type0Font(cosObject: .name(ASAtom("NotADict")))
        }
    }

    @Test("Encoding CMap - Identity-H")
    func testEncodingIdentityH() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.encodingCMapName == .identityH)
        #expect(font.isIdentityH == true)
        #expect(font.isIdentityV == false)
    }

    @Test("Encoding CMap - Identity-V")
    func testEncodingIdentityV() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityV),
            .descendantFonts: .array([])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.encodingCMapName == .identityV)
        #expect(font.isIdentityH == false)
        #expect(font.isIdentityV == true)
    }

    @Test("Encoding CMap - stream")
    func testEncodingCMapStream() throws {
        let cmapDict: [ASAtom: COSValue] = [
            .length: .integer(1000)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .dictionary( cmapDict),
            .descendantFonts: .array([])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.encodingCMap != nil)
        #expect(font.encodingCMapName == nil)  // Not a name, it's a stream
    }

    @Test("Descendant fonts array")
    func testDescendantFontsArray() throws {
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

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([.dictionary(cidFontDict)])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.descendantFonts?.count == 1)
        #expect(font.descendantFont != nil)
    }

    @Test("Descendant font access")
    func testDescendantFontAccess() throws {
        let cidFontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.cidFontType2),
            .baseFont: .name(ASAtom("MyCIDFont")),
            ASAtom("CIDSystemInfo"): .dictionary([
                ASAtom("Registry"): .string(COSString(string: "Adobe")),
                ASAtom("Ordering"): .string(COSString(string: "Korea1")),
                ASAtom("Supplement"): .integer(2)
            ]),
            ASAtom("DW"): .integer(1000)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([.dictionary(cidFontDict)])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        let descendant = font.descendantFont
        #expect(descendant != nil)
        #expect(descendant?.baseFontName == ASAtom("MyCIDFont"))
        #expect(descendant?.defaultWidth == 1000.0)
    }

    @Test("Type0 font does not have simple encoding")
    func testNoSimpleEncoding() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.encoding == nil)
    }

    @Test("Width delegation to CIDFont")
    func testWidthDelegation() throws {
        let widthArray: [COSValue] = [
            .integer(1),    // Start CID
            .array([.integer(500), .integer(600), .integer(700)]),
            .integer(100),  // Start CID for range
            .integer(200),  // End CID for range
            .integer(800)   // Width for range
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

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([.dictionary(cidFontDict)])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))

        // Width should be delegated to CIDFont
        #expect(font.width(for: 1) == 500.0)
        #expect(font.width(for: 2) == 600.0)
        #expect(font.width(for: 3) == 700.0)
        #expect(font.width(for: 150) == 800.0)  // In range [100, 200]
        #expect(font.width(for: 500) == 1000.0) // Default width
    }

    @Test("ToUnicode CMap")
    func testToUnicodeCMap() throws {
        let toUnicodeDict: [ASAtom: COSValue] = [
            .length: .integer(2000)
        ]

        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([]),
            .toUnicode: .dictionary( toUnicodeDict)
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.toUnicodeCMap != nil)
    }

    @Test("Empty descendant fonts array")
    func testEmptyDescendantFonts() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH),
            .descendantFonts: .array([])
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.descendantFonts?.isEmpty == true)
        #expect(font.descendantFont == nil)
    }

    @Test("Missing descendant fonts")
    func testMissingDescendantFonts() throws {
        let fontDict: [ASAtom: COSValue] = [
            .type: .name(.font),
            .subtype: .name(.type0),
            .baseFont: .name(ASAtom("MyFont")),
            .encoding: .name(.identityH)
        ]

        let font = try Type0Font(cosObject: .dictionary(fontDict))
        #expect(font.descendantFonts == nil)
        #expect(font.descendantFont == nil)
    }
}
