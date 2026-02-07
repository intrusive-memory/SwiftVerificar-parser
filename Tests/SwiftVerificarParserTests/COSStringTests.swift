import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("COSString Tests")
struct COSStringTests {

    // MARK: - Initialization

    @Test("Init from Data")
    func initFromData() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        let cosStr = COSString(data: data)
        #expect(cosStr.data == data)
        #expect(!cosStr.isHex)
    }

    @Test("Init from Data with hex flag")
    func initFromDataHex() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        let cosStr = COSString(data: data, isHex: true)
        #expect(cosStr.data == data)
        #expect(cosStr.isHex)
    }

    @Test("Init from string")
    func initFromString() {
        let cosStr = COSString(string: "Hello")
        #expect(cosStr.data == Data("Hello".utf8))
        #expect(!cosStr.isHex)
    }

    @Test("Init from string literal")
    func initFromStringLiteral() {
        let cosStr: COSString = "Hello"
        #expect(cosStr.stringValue == "Hello")
        #expect(!cosStr.isHex)
    }

    @Test("Init from hex string - valid")
    func initFromHexStringValid() {
        let cosStr = COSString(hexString: "48656C6C6F")
        #expect(cosStr != nil)
        #expect(cosStr?.data == Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))
        #expect(cosStr?.isHex == true)
    }

    @Test("Init from hex string - lowercase")
    func initFromHexStringLowercase() {
        let cosStr = COSString(hexString: "48656c6c6f")
        #expect(cosStr != nil)
        #expect(cosStr?.data == Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))
    }

    @Test("Init from hex string - with whitespace")
    func initFromHexStringWhitespace() {
        let cosStr = COSString(hexString: "48 65 6C 6C 6F")
        #expect(cosStr != nil)
        #expect(cosStr?.data == Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))
    }

    @Test("Init from hex string - odd length pads with zero")
    func initFromHexStringOddLength() {
        // Odd number of hex chars: "4" becomes "40" => byte 0x40
        let cosStr = COSString(hexString: "4")
        #expect(cosStr != nil)
        #expect(cosStr?.data == Data([0x40]))
    }

    @Test("Init from hex string - invalid characters returns nil")
    func initFromHexStringInvalid() {
        let cosStr = COSString(hexString: "GHIJ")
        #expect(cosStr == nil)
    }

    @Test("Init from hex string - empty")
    func initFromHexStringEmpty() {
        let cosStr = COSString(hexString: "")
        #expect(cosStr != nil)
        #expect(cosStr?.data.isEmpty == true)
    }

    // MARK: - Text Decoding

    @Test("Decode ASCII text")
    func decodeASCII() {
        let cosStr = COSString(string: "Hello World")
        #expect(cosStr.stringValue == "Hello World")
    }

    @Test("Decode UTF-16BE with BOM")
    func decodeUTF16BE() {
        // UTF-16BE BOM (FE FF) + "Hi" (00 48, 00 69)
        let data = Data([0xFE, 0xFF, 0x00, 0x48, 0x00, 0x69])
        let cosStr = COSString(data: data)
        #expect(cosStr.hasUTF16BOM)
        #expect(cosStr.stringValue == "Hi")
    }

    @Test("Decode UTF-8 with BOM")
    func decodeUTF8WithBOM() {
        // UTF-8 BOM (EF BB BF) + "Hi"
        let data = Data([0xEF, 0xBB, 0xBF, 0x48, 0x69])
        let cosStr = COSString(data: data)
        #expect(cosStr.hasUTF8BOM)
        #expect(cosStr.stringValue == "Hi")
    }

    @Test("Decode PDFDocEncoding - ASCII range")
    func decodePDFDocEncodingASCII() {
        // Standard ASCII printable characters (0x20-0x7E)
        let data = Data([0x41, 0x42, 0x43])  // "ABC"
        let cosStr = COSString(data: data)
        #expect(cosStr.stringValue == "ABC")
    }

    @Test("Decode PDFDocEncoding - special mappings")
    func decodePDFDocEncodingSpecial() {
        // 0x80 = BULLET (U+2022)
        let data = Data([0x80])
        let cosStr = COSString(data: data)
        let decoded = cosStr.stringValue
        #expect(decoded == "\u{2022}")
    }

    @Test("Decode PDFDocEncoding - em dash")
    func decodePDFDocEncodingEmDash() {
        // 0x84 = EM DASH (U+2014)
        let data = Data([0x84])
        let cosStr = COSString(data: data)
        #expect(cosStr.stringValue == "\u{2014}")
    }

    @Test("Decode PDFDocEncoding - ISO Latin-1 range")
    func decodePDFDocEncodingLatin1() {
        // 0xC0 = Latin capital A with grave (same as ISO 8859-1)
        let data = Data([0xC0])
        let cosStr = COSString(data: data)
        #expect(cosStr.stringValue == "\u{00C0}")
    }

    @Test("UTF-16BE with odd byte count returns nil from decode")
    func utf16BEOddByteCount() {
        // UTF-16BE BOM + 1 byte (not even)
        let data = Data([0xFE, 0xFF, 0x00])
        let cosStr = COSString(data: data)
        #expect(cosStr.hasUTF16BOM)
        // Odd number of bytes after BOM should fail
        #expect(cosStr.stringValue == nil)
    }

    // MARK: - BOM Detection

    @Test("Has UTF-16BE BOM")
    func hasUTF16BOM() {
        let data = Data([0xFE, 0xFF, 0x00, 0x41])
        let cosStr = COSString(data: data)
        #expect(cosStr.hasUTF16BOM)
        #expect(!cosStr.hasUTF8BOM)
    }

    @Test("Has UTF-8 BOM")
    func hasUTF8BOM() {
        let data = Data([0xEF, 0xBB, 0xBF, 0x41])
        let cosStr = COSString(data: data)
        #expect(!cosStr.hasUTF16BOM)
        #expect(cosStr.hasUTF8BOM)
    }

    @Test("No BOM in short data")
    func noBOMShortData() {
        let cosStr = COSString(data: Data([0x41]))
        #expect(!cosStr.hasUTF16BOM)
        #expect(!cosStr.hasUTF8BOM)
    }

    @Test("No BOM in empty data")
    func noBOMEmptyData() {
        let cosStr = COSString(data: Data())
        #expect(!cosStr.hasUTF16BOM)
        #expect(!cosStr.hasUTF8BOM)
    }

    // MARK: - Properties

    @Test("Count returns byte count")
    func countReturnsByteCount() {
        let cosStr = COSString(string: "Hello")
        #expect(cosStr.count == 5)
    }

    @Test("IsEmpty for empty string")
    func isEmptyForEmpty() {
        let cosStr = COSString(data: Data())
        #expect(cosStr.isEmpty)
    }

    @Test("IsEmpty for non-empty string")
    func isEmptyForNonEmpty() {
        let cosStr = COSString(string: "A")
        #expect(!cosStr.isEmpty)
    }

    // MARK: - Hex Encoding

    @Test("Hex encoded lowercase")
    func hexEncodedLowercase() {
        let cosStr = COSString(data: Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))
        #expect(cosStr.hexEncoded() == "48656c6c6f")
    }

    @Test("Hex encoded uppercase")
    func hexEncodedUppercase() {
        let cosStr = COSString(data: Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))
        #expect(cosStr.hexEncoded(uppercase: true) == "48656C6C6F")
    }

    @Test("Hex encoded empty data")
    func hexEncodedEmpty() {
        let cosStr = COSString(data: Data())
        #expect(cosStr.hexEncoded() == "")
    }

    // MARK: - Description

    @Test("Description for literal string")
    func descriptionLiteral() {
        let cosStr = COSString(string: "Hello", isHex: false)
        #expect(cosStr.description == "(Hello)")
    }

    @Test("Description for hex string")
    func descriptionHex() {
        let cosStr = COSString(data: Data([0x48, 0x69]), isHex: true)
        #expect(cosStr.description == "<4869>")
    }

    // MARK: - Equality and Hashing

    @Test("Equal strings are equal")
    func equality() {
        let a = COSString(string: "Hello")
        let b = COSString(string: "Hello")
        #expect(a == b)
    }

    @Test("Different strings are not equal")
    func inequality() {
        let a = COSString(string: "Hello")
        let b = COSString(string: "World")
        #expect(a != b)
    }

    @Test("Same data different hex flag are not equal")
    func hexFlagAffectsEquality() {
        let a = COSString(data: Data([0x48, 0x69]), isHex: false)
        let b = COSString(data: Data([0x48, 0x69]), isHex: true)
        #expect(a != b)
    }

    @Test("Can be used in a Set")
    func setUsage() {
        let set: Set<COSString> = [
            COSString(string: "A"),
            COSString(string: "B"),
            COSString(string: "A")
        ]
        #expect(set.count == 2)
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = COSString(string: "Hello World")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSString.self, from: data)
        #expect(original == decoded)
    }

    @Test("Encode and decode hex string round-trip")
    func codableHexRoundTrip() throws {
        let original = COSString(data: Data([0xFF, 0x00, 0xAB]), isHex: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSString.self, from: data)
        #expect(original == decoded)
    }

    // MARK: - Empty Constant

    @Test("Empty constant")
    func emptyConstant() {
        let empty = COSString.empty
        #expect(empty.isEmpty)
        #expect(empty.data.isEmpty)
        #expect(!empty.isHex)
    }

    // MARK: - Sendable

    @Test("COSString is Sendable")
    func sendable() async {
        let cosStr = COSString(string: "Hello")
        let task = Task { cosStr }
        let result = await task.value
        #expect(result == cosStr)
    }

    // MARK: - Special PDFDocEncoding mappings

    @Test("PDFDocEncoding - control characters")
    func pdfDocEncodingControl() {
        // Tab (0x09), LF (0x0A), CR (0x0D) should decode
        let data = Data([0x09, 0x0A, 0x0D])
        let cosStr = COSString(data: data)
        let decoded = cosStr.stringValue
        #expect(decoded == "\t\n\r")
    }

    @Test("PDFDocEncoding - trade mark sign")
    func pdfDocEncodingTradeMark() {
        // 0x92 = TRADE MARK SIGN (U+2122)
        let data = Data([0x92])
        let cosStr = COSString(data: data)
        #expect(cosStr.stringValue == "\u{2122}")
    }

    @Test("PDFDocEncoding - accented characters from Latin-1")
    func pdfDocEncodingAccented() {
        // 0xE9 = e with acute (U+00E9) - same as Latin-1
        let data = Data([0xE9])
        let cosStr = COSString(data: data)
        #expect(cosStr.stringValue == "\u{00E9}")
    }

    @Test("PDFDocEncoding - undefined byte produces replacement character")
    func pdfDocEncodingUndefined() {
        // 0x00 is undefined in PDFDocEncoding
        let data = Data([0x00])
        let cosStr = COSString(data: data)
        #expect(cosStr.stringValue == "\u{FFFD}")
    }
}
