import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("COSStream Tests")
struct COSStreamTests {

    // MARK: - Initialization

    @Test("Init with dictionary and encoded data")
    func initBasic() {
        let dict: [ASAtom: COSValue] = [.length: .integer(5)]
        let data = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let stream = COSStream(dictionary: dict, encodedData: data)
        #expect(stream.encodedData == data)
        #expect(stream.dictionary.count == 1)
        #expect(stream.decodedData == nil)
    }

    @Test("Init with empty defaults")
    func initDefaults() {
        let stream = COSStream(dictionary: [:])
        #expect(stream.encodedData.isEmpty)
        #expect(stream.decodedData == nil)
        #expect(stream.dictionary.isEmpty)
    }

    @Test("Init with decoded data")
    func initWithDecodedData() {
        let encoded = Data([0x78, 0x9C])
        let decoded = Data("Hello".utf8)
        let stream = COSStream(
            dictionary: [.filter: .name(.flateDecode)],
            encodedData: encoded,
            decodedData: decoded
        )
        #expect(stream.encodedData == encoded)
        #expect(stream.decodedData == decoded)
    }

    // MARK: - Dictionary Access

    @Test("Subscript by ASAtom key")
    func subscriptAtom() {
        let stream = COSStream(
            dictionary: [.length: .integer(42), .filter: .name(.flateDecode)],
            encodedData: Data()
        )
        #expect(stream[.length]?.integerValue == 42)
        #expect(stream[.filter]?.nameValue == .flateDecode)
    }

    @Test("Subscript by string key")
    func subscriptString() {
        let stream = COSStream(
            dictionary: [.length: .integer(42)],
            encodedData: Data()
        )
        #expect(stream["Length"]?.integerValue == 42)
    }

    @Test("Subscript returns nil for missing key")
    func subscriptMissing() {
        let stream = COSStream(dictionary: [:])
        #expect(stream[.length] == nil)
        #expect(stream["Filter"] == nil)
    }

    // MARK: - Declared Length

    @Test("Declared length from dictionary")
    func declaredLength() {
        let stream = COSStream(dictionary: [.length: .integer(100)])
        #expect(stream.declaredLength == 100)
    }

    @Test("Declared length returns nil when missing")
    func declaredLengthMissing() {
        let stream = COSStream(dictionary: [:])
        #expect(stream.declaredLength == nil)
    }

    @Test("Declared length returns nil for non-integer value")
    func declaredLengthNonInteger() {
        let stream = COSStream(dictionary: [.length: .name(ASAtom("ten"))])
        #expect(stream.declaredLength == nil)
    }

    // MARK: - Filters

    @Test("Single filter name")
    func singleFilter() {
        let stream = COSStream(dictionary: [.filter: .name(.flateDecode)])
        #expect(stream.filters == [.flateDecode])
        #expect(stream.isFiltered)
    }

    @Test("Multiple filters as array")
    func multipleFilters() {
        let stream = COSStream(dictionary: [
            .filter: .array([.name(.ascii85Decode), .name(.flateDecode)])
        ])
        #expect(stream.filters == [.ascii85Decode, .flateDecode])
        #expect(stream.isFiltered)
    }

    @Test("No filters")
    func noFilters() {
        let stream = COSStream(dictionary: [:])
        #expect(stream.filters.isEmpty)
        #expect(!stream.isFiltered)
    }

    @Test("Filter value that is not a name or array")
    func filterInvalidType() {
        let stream = COSStream(dictionary: [.filter: .integer(42)])
        #expect(stream.filters.isEmpty)
    }

    @Test("Mixed array with non-name values are filtered out")
    func filterMixedArray() {
        let stream = COSStream(dictionary: [
            .filter: .array([.name(.flateDecode), .integer(42), .name(.lzwDecode)])
        ])
        #expect(stream.filters == [.flateDecode, .lzwDecode])
    }

    // MARK: - Decode Parameters

    @Test("Decode parameters present")
    func decodeParamsPresent() {
        let params: COSValue = .dictionary([ASAtom("Predictor"): .integer(12)])
        let stream = COSStream(dictionary: [.decodeParms: params])
        #expect(stream.decodeParameters != nil)
    }

    @Test("Decode parameters missing")
    func decodeParamsMissing() {
        let stream = COSStream(dictionary: [:])
        #expect(stream.decodeParameters == nil)
    }

    // MARK: - Size Properties

    @Test("Dictionary count")
    func dictionaryCount() {
        let stream = COSStream(dictionary: [
            .length: .integer(10),
            .filter: .name(.flateDecode),
        ])
        #expect(stream.dictionaryCount == 2)
    }

    @Test("Encoded size")
    func encodedSize() {
        let data = Data(repeating: 0xFF, count: 100)
        let stream = COSStream(dictionary: [:], encodedData: data)
        #expect(stream.encodedSize == 100)
    }

    @Test("Decoded size when available")
    func decodedSizePresent() {
        let stream = COSStream(
            dictionary: [:],
            encodedData: Data(repeating: 0x00, count: 50),
            decodedData: Data(repeating: 0x01, count: 200)
        )
        #expect(stream.decodedSize == 200)
    }

    @Test("Decoded size when nil")
    func decodedSizeNil() {
        let stream = COSStream(dictionary: [:])
        #expect(stream.decodedSize == nil)
    }

    // MARK: - With Methods (Functional Updates)

    @Test("withDecodedData returns new stream with decoded data")
    func withDecodedData() {
        let original = COSStream(
            dictionary: [.length: .integer(5)],
            encodedData: Data([0x01, 0x02, 0x03, 0x04, 0x05])
        )
        let decoded = Data("Hello".utf8)
        let updated = original.withDecodedData(decoded)

        // Original unchanged
        #expect(original.decodedData == nil)
        // Updated has decoded data
        #expect(updated.decodedData == decoded)
        // Dictionary and encoded data preserved
        #expect(updated.dictionary == original.dictionary)
        #expect(updated.encodedData == original.encodedData)
    }

    @Test("settingDictionaryValue returns new stream with updated dictionary")
    func settingDictionaryValue() {
        let original = COSStream(
            dictionary: [.length: .integer(5)],
            encodedData: Data([0x01, 0x02])
        )
        let updated = original.settingDictionaryValue(.name(.flateDecode), forKey: .filter)

        // Original unchanged
        #expect(original.dictionary[.filter] == nil)
        #expect(original.dictionaryCount == 1)
        // Updated has new entry
        #expect(updated.dictionary[.filter]?.nameValue == .flateDecode)
        #expect(updated.dictionaryCount == 2)
        // Encoded data preserved
        #expect(updated.encodedData == original.encodedData)
    }

    @Test("settingDictionaryValue overwrites existing key")
    func settingDictionaryValueOverwrite() {
        let original = COSStream(
            dictionary: [.length: .integer(5)],
            encodedData: Data()
        )
        let updated = original.settingDictionaryValue(.integer(10), forKey: .length)
        #expect(updated.dictionary[.length]?.integerValue == 10)
        #expect(updated.dictionaryCount == 1)
    }

    // MARK: - Equality

    @Test("Equal streams")
    func equalStreams() {
        let dict: [ASAtom: COSValue] = [.length: .integer(3)]
        let data = Data([0x01, 0x02, 0x03])
        let a = COSStream(dictionary: dict, encodedData: data)
        let b = COSStream(dictionary: dict, encodedData: data)
        #expect(a == b)
    }

    @Test("Different dictionaries are not equal")
    func differentDictionaries() {
        let data = Data([0x01])
        let a = COSStream(dictionary: [.length: .integer(1)], encodedData: data)
        let b = COSStream(dictionary: [.length: .integer(2)], encodedData: data)
        #expect(a != b)
    }

    @Test("Different encoded data are not equal")
    func differentEncodedData() {
        let dict: [ASAtom: COSValue] = [.length: .integer(1)]
        let a = COSStream(dictionary: dict, encodedData: Data([0x01]))
        let b = COSStream(dictionary: dict, encodedData: Data([0x02]))
        #expect(a != b)
    }

    @Test("Different decoded data are not equal")
    func differentDecodedData() {
        let dict: [ASAtom: COSValue] = [:]
        let a = COSStream(dictionary: dict, decodedData: Data([0x01]))
        let b = COSStream(dictionary: dict, decodedData: Data([0x02]))
        #expect(a != b)
    }

    @Test("Nil vs present decoded data are not equal")
    func nilVsPresentDecodedData() {
        let dict: [ASAtom: COSValue] = [:]
        let a = COSStream(dictionary: dict)
        let b = COSStream(dictionary: dict, decodedData: Data())
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Equal streams have same hash")
    func equalHashValues() {
        let dict: [ASAtom: COSValue] = [.length: .integer(3)]
        let data = Data([0x01, 0x02, 0x03])
        let a = COSStream(dictionary: dict, encodedData: data)
        let b = COSStream(dictionary: dict, encodedData: data)
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Description

    @Test("Description with no filters")
    func descriptionNoFilters() {
        let stream = COSStream(
            dictionary: [.length: .integer(5)],
            encodedData: Data(repeating: 0x00, count: 5)
        )
        #expect(stream.description.contains("1 entries"))
        #expect(stream.description.contains("5 bytes"))
        #expect(stream.description.contains("none"))
    }

    @Test("Description with single filter")
    func descriptionSingleFilter() {
        let stream = COSStream(
            dictionary: [.filter: .name(.flateDecode)],
            encodedData: Data(repeating: 0x00, count: 10)
        )
        #expect(stream.description.contains("FlateDecode"))
    }

    @Test("Description with multiple filters")
    func descriptionMultipleFilters() {
        let stream = COSStream(
            dictionary: [.filter: .array([.name(.ascii85Decode), .name(.flateDecode)])],
            encodedData: Data()
        )
        let desc = stream.description
        #expect(desc.contains("ASCII85Decode"))
        #expect(desc.contains("FlateDecode"))
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = COSStream(
            dictionary: [.length: .integer(3)],
            encodedData: Data([0x01, 0x02, 0x03])
        )
        let jsonData = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSStream.self, from: jsonData)
        #expect(original == decoded)
    }

    @Test("Encode and decode with decoded data")
    func codableWithDecodedData() throws {
        let original = COSStream(
            dictionary: [.filter: .name(.flateDecode)],
            encodedData: Data([0x78, 0x9C]),
            decodedData: Data("Hello".utf8)
        )
        let jsonData = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSStream.self, from: jsonData)
        #expect(decoded.decodedData == Data("Hello".utf8))
    }

    @Test("Encode and decode empty stream")
    func codableEmptyStream() throws {
        let original = COSStream(dictionary: [:])
        let jsonData = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSStream.self, from: jsonData)
        #expect(decoded.dictionary.isEmpty)
        #expect(decoded.encodedData.isEmpty)
        #expect(decoded.decodedData == nil)
    }

    // MARK: - Sendable

    @Test("COSStream is Sendable")
    func sendable() async {
        let stream = COSStream(
            dictionary: [.length: .integer(5)],
            encodedData: Data([0x01, 0x02, 0x03, 0x04, 0x05])
        )
        let task = Task { stream }
        let result = await task.value
        #expect(result == stream)
    }

    // MARK: - Edge Cases

    @Test("Large encoded data")
    func largeEncodedData() {
        let data = Data(repeating: 0xAB, count: 1_000_000)
        let stream = COSStream(
            dictionary: [.length: .integer(1_000_000)],
            encodedData: data
        )
        #expect(stream.encodedSize == 1_000_000)
    }

    @Test("Stream with many dictionary entries")
    func manyDictionaryEntries() {
        var dict: [ASAtom: COSValue] = [:]
        for i in 0..<50 {
            dict[ASAtom("Key\(i)")] = .integer(Int64(i))
        }
        let stream = COSStream(dictionary: dict)
        #expect(stream.dictionaryCount == 50)
    }

    @Test("Stream with all common filter types")
    func allFilterTypes() {
        let filters: [ASAtom] = [
            .flateDecode, .lzwDecode, .ascii85Decode,
            .asciiHexDecode, .runLengthDecode, .dctDecode,
            .jpxDecode, .ccittFaxDecode,
        ]
        let stream = COSStream(dictionary: [
            .filter: .array(filters.map { .name($0) })
        ])
        #expect(stream.filters == filters)
    }
}
