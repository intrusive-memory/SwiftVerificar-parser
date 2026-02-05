import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for the FontEncoding struct.
@Suite("FontEncoding Tests")
struct FontEncodingTests {

    @Test("Name encoding - WinAnsiEncoding")
    func testNameEncoding() throws {
        let encoding = try FontEncoding(cosObject: .name(.winAnsiEncoding))
        #expect(encoding.isNameEncoding == true)
        #expect(encoding.isDictionaryEncoding == false)
        #expect(encoding.encodingName == .winAnsiEncoding)
        #expect(encoding.baseEncoding == nil)
        #expect(encoding.differences == nil)
    }

    @Test("Name encoding - MacRomanEncoding")
    func testMacRomanEncoding() throws {
        let encoding = try FontEncoding(cosObject: .name(.macRomanEncoding))
        #expect(encoding.encodingName == .macRomanEncoding)
    }

    @Test("Name encoding - StandardEncoding")
    func testStandardEncoding() throws {
        let encoding = try FontEncoding(cosObject: .name(.standardEncoding))
        #expect(encoding.encodingName == .standardEncoding)
    }

    @Test("Dictionary encoding with base")
    func testDictionaryEncodingWithBase() throws {
        let encodingDict: [ASAtom: COSValue] = [
            ASAtom("BaseEncoding"): .name(.winAnsiEncoding)
        ]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))
        #expect(encoding.isNameEncoding == false)
        #expect(encoding.isDictionaryEncoding == true)
        #expect(encoding.baseEncoding == .winAnsiEncoding)
        #expect(encoding.encodingName == nil)
    }

    @Test("Dictionary encoding with differences")
    func testDictionaryEncodingWithDifferences() throws {
        let differencesArray: [COSValue] = [
            .integer(39),
            .name(ASAtom("quotesingle")),
            .integer(96),
            .name(ASAtom("grave"))
        ]

        let encodingDict: [ASAtom: COSValue] = [
            ASAtom("BaseEncoding"): .name(.winAnsiEncoding),
            ASAtom("Differences"): .array(differencesArray)
        ]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))
        #expect(encoding.baseEncoding == .winAnsiEncoding)
        #expect(encoding.differences != nil)
        #expect(encoding.differences?.count == 4)
    }

    @Test("Glyph name lookup - from differences")
    func testGlyphNameLookupFromDifferences() throws {
        let differencesArray: [COSValue] = [
            .integer(39),
            .name(ASAtom("quotesingle")),
            .name(ASAtom("parenleft")),
            .integer(96),
            .name(ASAtom("grave"))
        ]

        let encodingDict: [ASAtom: COSValue] = [
            ASAtom("BaseEncoding"): .name(.standardEncoding),
            ASAtom("Differences"): .array(differencesArray)
        ]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))

        // Code 39 should map to 'quotesingle' from differences
        let glyph39 = encoding.glyphName(for: 39)
        #expect(glyph39 == ASAtom("quotesingle"))

        // Code 40 should map to 'parenleft' (next in sequence)
        let glyph40 = encoding.glyphName(for: 40)
        #expect(glyph40 == ASAtom("parenleft"))

        // Code 96 should map to 'grave' from differences
        let glyph96 = encoding.glyphName(for: 96)
        #expect(glyph96 == ASAtom("grave"))
    }

    @Test("Glyph name lookup - not in differences")
    func testGlyphNameLookupNotInDifferences() throws {
        let differencesArray: [COSValue] = [
            .integer(39),
            .name(ASAtom("quotesingle"))
        ]

        let encodingDict: [ASAtom: COSValue] = [
            ASAtom("BaseEncoding"): .name(.standardEncoding),
            ASAtom("Differences"): .array(differencesArray)
        ]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))

        // Code 65 (not in differences) should return nil (base encoding not fully implemented)
        let glyphA = encoding.glyphName(for: 65)
        #expect(glyphA == nil)
    }

    @Test("Empty differences array")
    func testEmptyDifferences() throws {
        let encodingDict: [ASAtom: COSValue] = [
            ASAtom("BaseEncoding"): .name(.winAnsiEncoding),
            ASAtom("Differences"): .array([])
        ]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))
        #expect(encoding.differences?.isEmpty == true)
    }

    @Test("Dictionary encoding without base or differences")
    func testDictionaryEncodingMinimal() throws {
        let encodingDict: [ASAtom: COSValue] = [:]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))
        #expect(encoding.baseEncoding == nil)
        #expect(encoding.differences == nil)
        #expect(encoding.isDictionaryEncoding == true)
    }

    @Test("Glyph name constants")
    func testGlyphNameConstants() {
        #expect(ASAtom.notdef.stringValue == ".notdef")
        #expect(ASAtom.space.stringValue == "space")
        #expect(ASAtom.A.stringValue == "A")
    }

    @Test("Encoding name constants")
    func testEncodingNameConstants() {
        #expect(ASAtom.macRomanEncoding.stringValue == "MacRomanEncoding")
        #expect(ASAtom.winAnsiEncoding.stringValue == "WinAnsiEncoding")
        #expect(ASAtom.macExpertEncoding.stringValue == "MacExpertEncoding")
        #expect(ASAtom.standardEncoding.stringValue == "StandardEncoding")
        #expect(ASAtom.symbolEncoding.stringValue == "SymbolEncoding")
        #expect(ASAtom.zapfDingbatsEncoding.stringValue == "ZapfDingbatsEncoding")
        #expect(ASAtom.identityH.stringValue == "Identity-H")
        #expect(ASAtom.identityV.stringValue == "Identity-V")
    }

    @Test("Complex differences array")
    func testComplexDifferencesArray() throws {
        // Multiple ranges in differences
        let differencesArray: [COSValue] = [
            .integer(32),
            .name(ASAtom("space")),
            .name(ASAtom("exclam")),
            .name(ASAtom("quotedbl")),
            .integer(65),
            .name(ASAtom("A")),
            .name(ASAtom("B")),
            .name(ASAtom("C"))
        ]

        let encodingDict: [ASAtom: COSValue] = [
            ASAtom("Differences"): .array(differencesArray)
        ]

        let encoding = try FontEncoding(cosObject: .dictionary(encodingDict))

        #expect(encoding.glyphName(for: 32) == ASAtom("space"))
        #expect(encoding.glyphName(for: 33) == ASAtom("exclam"))
        #expect(encoding.glyphName(for: 34) == ASAtom("quotedbl"))
        #expect(encoding.glyphName(for: 65) == ASAtom("A"))
        #expect(encoding.glyphName(for: 66) == ASAtom("B"))
        #expect(encoding.glyphName(for: 67) == ASAtom("C"))
    }
}
