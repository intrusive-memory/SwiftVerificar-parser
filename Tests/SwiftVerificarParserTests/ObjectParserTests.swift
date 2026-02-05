import Testing
import Foundation
@testable import SwiftVerificarParser

/// Test suite for ObjectParser.
@Suite("ObjectParser Tests")
struct ObjectParserTests {

    // MARK: - Primitive Value Parsing

    @Test("Parse null value")
    func parseNull() async throws {
        let data = Data("null".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .null)
    }

    @Test("Parse boolean true")
    func parseBooleanTrue() async throws {
        let data = Data("true".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .boolean(true))
    }

    @Test("Parse boolean false")
    func parseBooleanFalse() async throws {
        let data = Data("false".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .boolean(false))
    }

    @Test("Parse positive integer")
    func parsePositiveInteger() async throws {
        let data = Data("42".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .integer(42))
    }

    @Test("Parse negative integer")
    func parseNegativeInteger() async throws {
        let data = Data("-17".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .integer(-17))
    }

    @Test("Parse zero")
    func parseZero() async throws {
        let data = Data("0".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .integer(0))
    }

    @Test("Parse positive real number")
    func parsePositiveReal() async throws {
        let data = Data("3.14".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .real(3.14))
    }

    @Test("Parse negative real number")
    func parseNegativeReal() async throws {
        let data = Data("-0.5".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .real(-0.5))
    }

    // MARK: - String Parsing

    @Test("Parse literal string")
    func parseLiteralString() async throws {
        let data = Data("(Hello World)".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isString)
        #expect(value.textValue == "Hello World")
    }

    @Test("Parse empty literal string")
    func parseEmptyLiteralString() async throws {
        let data = Data("()".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isString)
        #expect(value.textValue == "")
    }

    @Test("Parse hex string")
    func parseHexString() async throws {
        let data = Data("<48656C6C6F>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isString)
        #expect(value.textValue == "Hello")
    }

    @Test("Parse empty hex string")
    func parseEmptyHexString() async throws {
        let data = Data("<>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isString)
    }

    // MARK: - Name Parsing

    @Test("Parse simple name")
    func parseSimpleName() async throws {
        let data = Data("/Type".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isName)
        #expect(value.nameValue == ASAtom("Type"))
    }

    @Test("Parse name with special characters")
    func parseNameWithSpecialChars() async throws {
        let data = Data("/A#20B".utf8) // /A B (space encoded)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isName)
        #expect(value.nameValue == ASAtom("A B"))
    }

    @Test("Parse empty name")
    func parseEmptyName() async throws {
        let data = Data("/".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isName)
    }

    // MARK: - Array Parsing

    @Test("Parse empty array")
    func parseEmptyArray() async throws {
        let data = Data("[]".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isArray)
        #expect(value.arrayValue?.isEmpty == true)
    }

    @Test("Parse array with integers")
    func parseArrayWithIntegers() async throws {
        let data = Data("[1 2 3]".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isArray)
        let arr = value.arrayValue
        #expect(arr?.count == 3)
        #expect(arr?[0] == .integer(1))
        #expect(arr?[1] == .integer(2))
        #expect(arr?[2] == .integer(3))
    }

    @Test("Parse array with mixed types")
    func parseArrayWithMixedTypes() async throws {
        let data = Data("[42 3.14 /Name (String) true false null]".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isArray)
        let arr = value.arrayValue
        #expect(arr?.count == 6)
        #expect(arr?[0] == .integer(42))
        #expect(arr?[1] == .real(3.14))
        #expect(arr?[2].isName == true)
        #expect(arr?[3].isString == true)
        #expect(arr?[4] == .boolean(true))
        #expect(arr?[5] == .null)
    }

    @Test("Parse nested arrays")
    func parseNestedArrays() async throws {
        let data = Data("[[1 2] [3 4]]".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isArray)
        let arr = value.arrayValue
        #expect(arr?.count == 2)
        #expect(arr?[0].isArray == true)
        #expect(arr?[1].isArray == true)
    }

    // MARK: - Dictionary Parsing

    @Test("Parse empty dictionary")
    func parseEmptyDictionary() async throws {
        let data = Data("<<>>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isDictionary)
        #expect(value.dictionaryValue?.isEmpty == true)
    }

    @Test("Parse dictionary with single entry")
    func parseDictionaryWithSingleEntry() async throws {
        let data = Data("<</Type /Page>>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isDictionary)
        let dict = value.dictionaryValue
        #expect(dict?.count == 1)
        #expect(dict?[.type]?.isName == true)
        #expect(dict?[.type]?.nameValue == ASAtom("Page"))
    }

    @Test("Parse dictionary with multiple entries")
    func parseDictionaryWithMultipleEntries() async throws {
        let data = Data("<</Type /Page /Count 42 /Title (Test)>>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isDictionary)
        let dict = value.dictionaryValue
        #expect(dict?.count == 3)
        #expect(dict?[.type]?.nameValue == ASAtom("Page"))
        #expect(dict?[ASAtom("Count")]?.integerValue == 42)
        #expect(dict?[ASAtom("Title")]?.isString == true)
    }

    @Test("Parse nested dictionaries")
    func parseNestedDictionaries() async throws {
        let data = Data("<</Outer <</Inner 123>>>>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isDictionary)
        let outer = value.dictionaryValue
        #expect(outer?.count == 1)
        let inner = outer?[ASAtom("Outer")]
        #expect(inner?.isDictionary == true)
    }

    // MARK: - Indirect Reference Parsing

    @Test("Parse indirect reference")
    func parseIndirectReference() async throws {
        let data = Data("12 0 R".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseReference(&tokenizer)
        #expect(value.isReference)
        #expect(value.referenceValue?.objectNumber == 12)
        #expect(value.referenceValue?.generation == 0)
    }

    @Test("Parse reference with non-zero generation")
    func parseReferenceWithGeneration() async throws {
        let data = Data("42 5 R".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseReference(&tokenizer)
        #expect(value.isReference)
        #expect(value.referenceValue?.objectNumber == 42)
        #expect(value.referenceValue?.generation == 5)
    }

    // MARK: - Indirect Object Parsing

    @Test("Parse simple indirect object")
    func parseSimpleIndirectObject() async throws {
        let data = Data("1 0 obj\n42\nendobj".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let (objNum, genNum, value) = try await parser.parseIndirectObject(&tokenizer)
        #expect(objNum == 1)
        #expect(genNum == 0)
        #expect(value == .integer(42))
    }

    @Test("Parse indirect object with dictionary")
    func parseIndirectObjectWithDictionary() async throws {
        let data = Data("12 0 obj\n<</Type /Page>>\nendobj".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let (objNum, genNum, value) = try await parser.parseIndirectObject(&tokenizer)
        #expect(objNum == 12)
        #expect(genNum == 0)
        #expect(value.isDictionary)
        #expect(value[.type]?.nameValue == ASAtom("Page"))
    }

    // MARK: - Error Handling

    @Test("Parse fails on unexpected token")
    func parseFailsOnUnexpectedToken() async throws {
        let data = Data("obj".utf8) // 'obj' is not a valid value
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        await #expect(throws: ObjectParser.ParserError.self) {
            _ = try await parser.parseObject(&tokenizer)
        }
    }

    @Test("Parse fails on unclosed array")
    func parseFailsOnUnclosedArray() async throws {
        let data = Data("[1 2 3".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        await #expect(throws: ObjectParser.ParserError.self) {
            _ = try await parser.parseObject(&tokenizer)
        }
    }

    @Test("Parse fails on unclosed dictionary")
    func parseFailsOnUnclosedDictionary() async throws {
        let data = Data("<</Type /Page".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        await #expect(throws: ObjectParser.ParserError.self) {
            _ = try await parser.parseObject(&tokenizer)
        }
    }

    @Test("Parse fails on non-name dictionary key")
    func parseFailsOnNonNameDictionaryKey() async throws {
        let data = Data("<<42 /Value>>".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        await #expect(throws: ObjectParser.ParserError.self) {
            _ = try await parser.parseObject(&tokenizer)
        }
    }

    // MARK: - Comment Handling

    @Test("Parse skips comments")
    func parseSkipsComments() async throws {
        let data = Data("% This is a comment\n42".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .integer(42))
    }

    // MARK: - Whitespace Handling

    @Test("Parse handles extra whitespace")
    func parseHandlesExtraWhitespace() async throws {
        let data = Data("  \n\t  42  \n  ".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value == .integer(42))
    }

    @Test("Parse array with whitespace")
    func parseArrayWithWhitespace() async throws {
        let data = Data("[ 1  2   3 ]".utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isArray)
        #expect(value.arrayValue?.count == 3)
    }

    @Test("Parse dictionary with whitespace and newlines")
    func parseDictionaryWithWhitespace() async throws {
        let data = Data("""
        <<
          /Type /Page
          /Count 42
        >>
        """.utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isDictionary)
        #expect(value.dictionaryValue?.count == 2)
    }

    // MARK: - Complex Nested Structures

    @Test("Parse complex nested structure")
    func parseComplexNestedStructure() async throws {
        let data = Data("""
        <<
          /Type /Page
          /MediaBox [0 0 612 792]
          /Resources <<
            /Font <<
              /F1 <</Type /Font /Subtype /Type1>>
            >>
          >>
          /Contents [1 0 R 2 0 R]
        >>
        """.utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        let parser = ObjectParser()

        let value = try await parser.parseObject(&tokenizer)
        #expect(value.isDictionary)
        let dict = value.dictionaryValue
        #expect(dict?[.type]?.nameValue == ASAtom("Page"))
        #expect(dict?[ASAtom("MediaBox")]?.isArray == true)
        #expect(dict?[ASAtom("Resources")]?.isDictionary == true)
    }
}
