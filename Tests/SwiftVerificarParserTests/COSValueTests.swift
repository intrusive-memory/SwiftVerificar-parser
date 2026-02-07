import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("COSValue Tests")
struct COSValueTests {

    // MARK: - Null

    @Test("Null value")
    func nullValue() {
        let value = COSValue.null
        #expect(value.isNull)
        #expect(!value.isBoolean)
        #expect(!value.isInteger)
        #expect(!value.isReal)
        #expect(!value.isNumeric)
        #expect(!value.isString)
        #expect(!value.isName)
        #expect(!value.isArray)
        #expect(!value.isDictionary)
    }

    @Test("Null literal")
    func nullLiteral() {
        let value: COSValue = nil
        #expect(value.isNull)
        #expect(value == .null)
    }

    @Test("Null value extraction returns nil")
    func nullValueExtraction() {
        let value = COSValue.null
        #expect(value.boolValue == nil)
        #expect(value.integerValue == nil)
        #expect(value.realValue == nil)
        #expect(value.numericValue == nil)
        #expect(value.stringValue == nil)
        #expect(value.textValue == nil)
        #expect(value.nameValue == nil)
        #expect(value.arrayValue == nil)
        #expect(value.dictionaryValue == nil)
    }

    // MARK: - Boolean

    @Test("Boolean true")
    func booleanTrue() {
        let value = COSValue.boolean(true)
        #expect(value.isBoolean)
        #expect(value.boolValue == true)
        #expect(!value.isNull)
        #expect(!value.isInteger)
    }

    @Test("Boolean false")
    func booleanFalse() {
        let value = COSValue.boolean(false)
        #expect(value.isBoolean)
        #expect(value.boolValue == false)
    }

    @Test("Boolean literal")
    func booleanLiteral() {
        let trueVal: COSValue = true
        let falseVal: COSValue = false
        #expect(trueVal == .boolean(true))
        #expect(falseVal == .boolean(false))
    }

    // MARK: - Integer

    @Test("Integer value")
    func integerValue() {
        let value = COSValue.integer(42)
        #expect(value.isInteger)
        #expect(value.integerValue == 42)
        #expect(value.isNumeric)
        #expect(value.numericValue == 42.0)
        #expect(!value.isReal)
    }

    @Test("Negative integer")
    func negativeInteger() {
        let value = COSValue.integer(-100)
        #expect(value.integerValue == -100)
        #expect(value.numericValue == -100.0)
    }

    @Test("Zero integer")
    func zeroInteger() {
        let value = COSValue.integer(0)
        #expect(value.integerValue == 0)
        #expect(value.numericValue == 0.0)
    }

    @Test("Large integer")
    func largeInteger() {
        let value = COSValue.integer(Int64.max)
        #expect(value.integerValue == Int64.max)
    }

    @Test("Integer literal")
    func integerLiteral() {
        let value: COSValue = 42
        #expect(value == .integer(42))
    }

    // MARK: - Real

    @Test("Real value")
    func realValue() {
        let value = COSValue.real(3.14)
        #expect(value.isReal)
        #expect(value.realValue == 3.14)
        #expect(value.isNumeric)
        #expect(value.numericValue == 3.14)
        #expect(!value.isInteger)
    }

    @Test("Negative real")
    func negativeReal() {
        let value = COSValue.real(-2.5)
        #expect(value.realValue == -2.5)
    }

    @Test("Zero real")
    func zeroReal() {
        let value = COSValue.real(0.0)
        #expect(value.realValue == 0.0)
    }

    @Test("Float literal")
    func floatLiteral() {
        let value: COSValue = 3.14
        #expect(value == .real(3.14))
    }

    @Test("Real value does not return integer")
    func realNotInteger() {
        let value = COSValue.real(42.0)
        #expect(value.integerValue == nil)
        #expect(value.realValue == 42.0)
    }

    @Test("Integer value does not return real")
    func integerNotReal() {
        let value = COSValue.integer(42)
        #expect(value.realValue == nil)
        #expect(value.integerValue == 42)
    }

    // MARK: - String

    @Test("String value")
    func stringValue() {
        let cosStr = COSString(string: "Hello")
        let value = COSValue.string(cosStr)
        #expect(value.isString)
        #expect(value.stringValue == cosStr)
        #expect(value.textValue == "Hello")
    }

    @Test("Hex string value")
    func hexStringValue() {
        let cosStr = COSString(hexString: "48656C6C6F")
        let value = COSValue.string(cosStr!)
        #expect(value.isString)
        #expect(value.stringValue?.isHex == true)
    }

    @Test("Empty string value")
    func emptyStringValue() {
        let value = COSValue.string(.empty)
        #expect(value.isString)
        #expect(value.stringValue?.isEmpty == true)
    }

    // MARK: - Name

    @Test("Name value")
    func nameValue() {
        let value = COSValue.name(.type)
        #expect(value.isName)
        #expect(value.nameValue == .type)
        #expect(!value.isString)
    }

    @Test("Name from string literal creates name not string")
    func stringLiteralCreatesName() {
        let value: COSValue = "Type"
        #expect(value.isName)
        #expect(value.nameValue == ASAtom("Type"))
    }

    // MARK: - Array

    @Test("Array value")
    func arrayValue() {
        let arr: [COSValue] = [.integer(1), .integer(2), .integer(3)]
        let value = COSValue.array(arr)
        #expect(value.isArray)
        #expect(value.arrayValue?.count == 3)
    }

    @Test("Empty array")
    func emptyArray() {
        let value = COSValue.array([])
        #expect(value.isArray)
        #expect(value.arrayValue?.isEmpty == true)
    }

    @Test("Array literal")
    func arrayLiteral() {
        let value: COSValue = [.integer(1), .real(2.0), .null]
        #expect(value.isArray)
        #expect(value.arrayValue?.count == 3)
    }

    @Test("Nested array")
    func nestedArray() {
        let inner: COSValue = [.integer(1), .integer(2)]
        let outer: COSValue = .array([inner, .integer(3)])
        #expect(outer.arrayValue?.count == 2)
        #expect(outer[0]?.isArray == true)
        #expect(outer[1]?.integerValue == 3)
    }

    @Test("Array subscript in bounds")
    func arraySubscriptInBounds() {
        let value: COSValue = [.integer(10), .integer(20), .integer(30)]
        #expect(value[0]?.integerValue == 10)
        #expect(value[1]?.integerValue == 20)
        #expect(value[2]?.integerValue == 30)
    }

    @Test("Array subscript out of bounds returns nil")
    func arraySubscriptOutOfBounds() {
        let value: COSValue = [.integer(10)]
        #expect(value[-1] == nil)
        #expect(value[1] == nil)
        #expect(value[100] == nil)
    }

    @Test("Array subscript on non-array returns nil")
    func arraySubscriptOnNonArray() {
        let value = COSValue.integer(42)
        #expect(value[0] == nil)
    }

    // MARK: - Dictionary

    @Test("Dictionary value")
    func dictionaryValue() {
        let dict: [ASAtom: COSValue] = [
            .type: .name(.page),
            .mediaBox: .array([.integer(0), .integer(0), .integer(612), .integer(792)])
        ]
        let value = COSValue.dictionary(dict)
        #expect(value.isDictionary)
        #expect(value.dictionaryValue?.count == 2)
    }

    @Test("Empty dictionary")
    func emptyDictionary() {
        let value = COSValue.dictionary([:])
        #expect(value.isDictionary)
        #expect(value.dictionaryValue?.isEmpty == true)
    }

    @Test("Dictionary literal")
    func dictionaryLiteral() {
        let value: COSValue = [.type: .name(.page)]
        #expect(value.isDictionary)
        #expect(value.dictionaryValue?.count == 1)
    }

    @Test("Dictionary subscript by ASAtom")
    func dictSubscriptByAtom() {
        let value: COSValue = [.type: .name(.page), .subtype: .name(.form)]
        #expect(value[.type]?.nameValue == .page)
        #expect(value[.subtype]?.nameValue == .form)
    }

    @Test("Dictionary subscript by string")
    func dictSubscriptByString() {
        let value: COSValue = [.type: .name(.page)]
        #expect(value["Type"]?.nameValue == .page)
    }

    @Test("Dictionary subscript missing key returns nil")
    func dictSubscriptMissing() {
        let value: COSValue = [.type: .name(.page)]
        #expect(value[.subtype] == nil)
        #expect(value["Missing"] == nil)
    }

    @Test("Dictionary subscript on non-dictionary returns nil")
    func dictSubscriptOnNonDict() {
        let value = COSValue.integer(42)
        #expect(value[.type] == nil)
        #expect(value["Type"] == nil)
    }

    // MARK: - Type Entry Helpers

    @Test("Type entry")
    func typeEntry() {
        let value: COSValue = [.type: .name(.page)]
        #expect(value.typeEntry == .page)
    }

    @Test("Subtype entry")
    func subtypeEntry() {
        let value: COSValue = [.subtype: .name(.image)]
        #expect(value.subtypeEntry == .image)
    }

    @Test("Type entry missing returns nil")
    func typeEntryMissing() {
        let value: COSValue = [.subtype: .name(.form)]
        #expect(value.typeEntry == nil)
    }

    @Test("Type entry on non-dict returns nil")
    func typeEntryNonDict() {
        let value = COSValue.integer(42)
        #expect(value.typeEntry == nil)
    }

    // MARK: - Count

    @Test("Count for array")
    func countForArray() {
        let value: COSValue = [.integer(1), .integer(2)]
        #expect(value.count == 2)
    }

    @Test("Count for dictionary")
    func countForDictionary() {
        let value: COSValue = [.type: .name(.page), .subtype: .name(.form)]
        #expect(value.count == 2)
    }

    @Test("Count for empty array")
    func countForEmptyArray() {
        let value = COSValue.array([])
        #expect(value.count == 0)
    }

    @Test("Count for non-collection returns nil")
    func countForNonCollection() {
        #expect(COSValue.null.count == nil)
        #expect(COSValue.integer(42).count == nil)
        #expect(COSValue.boolean(true).count == nil)
    }

    // MARK: - Description

    @Test("Null description")
    func nullDescription() {
        #expect(COSValue.null.description == "null")
    }

    @Test("Boolean description")
    func booleanDescription() {
        #expect(COSValue.boolean(true).description == "true")
        #expect(COSValue.boolean(false).description == "false")
    }

    @Test("Integer description")
    func integerDescription() {
        #expect(COSValue.integer(42).description == "42")
        #expect(COSValue.integer(-100).description == "-100")
        #expect(COSValue.integer(0).description == "0")
    }

    @Test("Real description")
    func realDescription() {
        #expect(COSValue.real(3.14).description == "3.14")
        #expect(COSValue.real(0.0).description == "0.0")
    }

    @Test("Name description")
    func nameDescription() {
        #expect(COSValue.name(.type).description == "/Type")
    }

    @Test("Array description")
    func arrayDescription() {
        let value: COSValue = [.integer(1), .integer(2)]
        #expect(value.description == "[1 2]")
    }

    @Test("Empty array description")
    func emptyArrayDescription() {
        let value = COSValue.array([])
        #expect(value.description == "[]")
    }

    // MARK: - Equality

    @Test("Null equality")
    func nullEquality() {
        #expect(COSValue.null == COSValue.null)
    }

    @Test("Boolean equality")
    func booleanEquality() {
        #expect(COSValue.boolean(true) == COSValue.boolean(true))
        #expect(COSValue.boolean(false) == COSValue.boolean(false))
        #expect(COSValue.boolean(true) != COSValue.boolean(false))
    }

    @Test("Integer equality")
    func integerEquality() {
        #expect(COSValue.integer(42) == COSValue.integer(42))
        #expect(COSValue.integer(42) != COSValue.integer(43))
    }

    @Test("Real equality")
    func realEquality() {
        #expect(COSValue.real(3.14) == COSValue.real(3.14))
        #expect(COSValue.real(3.14) != COSValue.real(3.15))
    }

    @Test("Integer and real are not equal even with same numeric value")
    func integerRealNotEqual() {
        #expect(COSValue.integer(42) != COSValue.real(42.0))
    }

    @Test("Different types are not equal")
    func differentTypesNotEqual() {
        #expect(COSValue.null != COSValue.boolean(false))
        #expect(COSValue.integer(0) != COSValue.real(0.0))
        #expect(COSValue.integer(0) != COSValue.null)
    }

    @Test("Array equality")
    func arrayEquality() {
        let a: COSValue = [.integer(1), .integer(2)]
        let b: COSValue = [.integer(1), .integer(2)]
        let c: COSValue = [.integer(1), .integer(3)]
        #expect(a == b)
        #expect(a != c)
    }

    @Test("Dictionary equality")
    func dictionaryEquality() {
        let a: COSValue = [.type: .name(.page)]
        let b: COSValue = [.type: .name(.page)]
        let c: COSValue = [.type: .name(.catalog)]
        #expect(a == b)
        #expect(a != c)
    }

    // MARK: - Hashable

    @Test("Equal values have same hash")
    func hashEquality() {
        let a = COSValue.integer(42)
        let b = COSValue.integer(42)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used in a Set")
    func setUsage() {
        let set: Set<COSValue> = [
            .integer(1),
            .integer(2),
            .integer(1),
            .null,
            .boolean(true)
        ]
        #expect(set.count == 4)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKeyUsage() {
        var dict: [COSValue: String] = [:]
        dict[.integer(1)] = "one"
        dict[.name(.type)] = "type"
        #expect(dict[.integer(1)] == "one")
        #expect(dict[.name(.type)] == "type")
    }

    // MARK: - Codable

    @Test("Null codable round-trip")
    func nullCodable() throws {
        let original = COSValue.null
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("Boolean codable round-trip")
    func booleanCodable() throws {
        for value in [COSValue.boolean(true), .boolean(false)] {
            let data = try JSONEncoder().encode(value)
            let decoded = try JSONDecoder().decode(COSValue.self, from: data)
            #expect(value == decoded)
        }
    }

    @Test("Integer codable round-trip")
    func integerCodable() throws {
        let original = COSValue.integer(42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("Real codable round-trip")
    func realCodable() throws {
        let original = COSValue.real(3.14)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("String codable round-trip")
    func stringCodable() throws {
        let original = COSValue.string(COSString(string: "Hello"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("Name codable round-trip")
    func nameCodable() throws {
        let original = COSValue.name(.type)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("Array codable round-trip")
    func arrayCodable() throws {
        let original: COSValue = [.integer(1), .real(2.0), .null, .boolean(true)]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("Dictionary codable round-trip")
    func dictionaryCodable() throws {
        let original: COSValue = [
            .type: .name(.page),
            .count: .integer(5)
        ]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    @Test("Nested structure codable round-trip")
    func nestedCodable() throws {
        let original: COSValue = [
            .type: .name(.catalog),
            .pages: .dictionary([
                .type: .name(.pages),
                .count: .integer(3),
                .kids: .array([
                    .dictionary([.type: .name(.page)])
                ])
            ])
        ]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSValue.self, from: data)
        #expect(original == decoded)
    }

    // MARK: - Sendable

    @Test("COSValue is Sendable")
    func sendable() async {
        let value: COSValue = [.type: .name(.page)]
        let task = Task { value }
        let result = await task.value
        #expect(result == value)
    }

    // MARK: - Mixed Type Array

    @Test("Array with mixed types")
    func mixedTypeArray() {
        let arr: COSValue = [
            .null,
            .boolean(true),
            .integer(42),
            .real(3.14),
            .string(COSString(string: "Hello")),
            .name(.type)
        ]
        #expect(arr.count == 6)
        #expect(arr[0]?.isNull == true)
        #expect(arr[1]?.boolValue == true)
        #expect(arr[2]?.integerValue == 42)
        #expect(arr[3]?.realValue == 3.14)
        #expect(arr[4]?.isString == true)
        #expect(arr[5]?.nameValue == .type)
    }

    // MARK: - Deeply Nested

    @Test("Deeply nested dictionary")
    func deeplyNested() {
        let value: COSValue = [
            .type: .name(.catalog),
            .pages: .dictionary([
                .type: .name(.pages),
                .kids: .array([
                    .dictionary([
                        .type: .name(.page),
                        .mediaBox: .array([.integer(0), .integer(0), .integer(612), .integer(792)])
                    ])
                ])
            ])
        ]

        let pages = value[.pages]
        #expect(pages?.typeEntry == .pages)

        let kids = pages?[.kids]
        #expect(kids?.count == 1)

        let firstPage = kids?[0]
        #expect(firstPage?.typeEntry == .page)

        let mediaBox = firstPage?[.mediaBox]
        #expect(mediaBox?.count == 4)
        #expect(mediaBox?[2]?.integerValue == 612)
    }

    // MARK: - numericValue edge cases

    @Test("numericValue for integer returns Double")
    func numericValueFromInteger() {
        let value = COSValue.integer(100)
        #expect(value.numericValue == 100.0)
    }

    @Test("numericValue for real returns Double")
    func numericValueFromReal() {
        let value = COSValue.real(3.14)
        #expect(value.numericValue == 3.14)
    }

    @Test("numericValue for non-numeric returns nil")
    func numericValueFromNonNumeric() {
        #expect(COSValue.null.numericValue == nil)
        #expect(COSValue.boolean(true).numericValue == nil)
        #expect(COSValue.name(.type).numericValue == nil)
        #expect(COSValue.string(COSString(string: "42")).numericValue == nil)
    }

    // MARK: - Edge Cases

    @Test("Empty dictionary description starts with angle brackets")
    func emptyDictDescription() {
        let value = COSValue.dictionary([:])
        #expect(value.description == "<<>>")
    }

    @Test("Real value with no fractional part")
    func realWholeNumber() {
        let value = COSValue.real(42.0)
        // Should display as "42.0" to distinguish from integer
        #expect(value.description == "42.0")
    }

    @Test("Negative zero real")
    func negativeZeroReal() {
        let positiveZero = COSValue.real(0.0)
        let negativeZero = COSValue.real(-0.0)
        // IEEE 754: -0.0 == 0.0
        #expect(positiveZero == negativeZero)
    }
}
