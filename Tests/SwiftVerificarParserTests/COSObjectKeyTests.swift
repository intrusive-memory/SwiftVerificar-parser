import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("COSObjectKey Tests")
struct COSObjectKeyTests {

    // MARK: - Initialization

    @Test("Init with object number and generation")
    func initWithBoth() {
        let key = COSObjectKey(objectNumber: 42, generation: 3)
        #expect(key.objectNumber == 42)
        #expect(key.generation == 3)
    }

    @Test("Init with default generation")
    func initDefaultGeneration() {
        let key = COSObjectKey(objectNumber: 10)
        #expect(key.objectNumber == 10)
        #expect(key.generation == 0)
    }

    @Test("Init with zero object number")
    func initZeroObjectNumber() {
        let key = COSObjectKey(objectNumber: 0, generation: 65535)
        #expect(key.objectNumber == 0)
        #expect(key.generation == 65535)
    }

    // MARK: - Equality

    @Test("Equal keys")
    func equalKeys() {
        let a = COSObjectKey(objectNumber: 42, generation: 0)
        let b = COSObjectKey(objectNumber: 42, generation: 0)
        #expect(a == b)
    }

    @Test("Different object numbers")
    func differentObjectNumbers() {
        let a = COSObjectKey(objectNumber: 42, generation: 0)
        let b = COSObjectKey(objectNumber: 43, generation: 0)
        #expect(a != b)
    }

    @Test("Different generations")
    func differentGenerations() {
        let a = COSObjectKey(objectNumber: 42, generation: 0)
        let b = COSObjectKey(objectNumber: 42, generation: 1)
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Equal keys have same hash")
    func equalHashValues() {
        let a = COSObjectKey(objectNumber: 42, generation: 0)
        let b = COSObjectKey(objectNumber: 42, generation: 0)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        var dict: [COSObjectKey: String] = [:]
        let key1 = COSObjectKey(objectNumber: 1)
        let key2 = COSObjectKey(objectNumber: 2)
        dict[key1] = "Object 1"
        dict[key2] = "Object 2"
        #expect(dict[key1] == "Object 1")
        #expect(dict[key2] == "Object 2")
        #expect(dict.count == 2)
    }

    @Test("Can be stored in a Set")
    func setUsage() {
        let set: Set<COSObjectKey> = [
            COSObjectKey(objectNumber: 1),
            COSObjectKey(objectNumber: 2),
            COSObjectKey(objectNumber: 1)
        ]
        #expect(set.count == 2)
    }

    // MARK: - Comparable

    @Test("Compare by object number")
    func compareByObjectNumber() {
        let a = COSObjectKey(objectNumber: 1, generation: 0)
        let b = COSObjectKey(objectNumber: 2, generation: 0)
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Compare by generation when object numbers equal")
    func compareByGeneration() {
        let a = COSObjectKey(objectNumber: 5, generation: 0)
        let b = COSObjectKey(objectNumber: 5, generation: 1)
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Equal keys are not less than")
    func equalNotLessThan() {
        let a = COSObjectKey(objectNumber: 5, generation: 0)
        let b = COSObjectKey(objectNumber: 5, generation: 0)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    @Test("Sorting keys")
    func sortingKeys() {
        let keys = [
            COSObjectKey(objectNumber: 3),
            COSObjectKey(objectNumber: 1),
            COSObjectKey(objectNumber: 2),
        ]
        let sorted = keys.sorted()
        #expect(sorted.map(\.objectNumber) == [1, 2, 3])
    }

    @Test("Sorting with same object number different generations")
    func sortingByGeneration() {
        let keys = [
            COSObjectKey(objectNumber: 1, generation: 2),
            COSObjectKey(objectNumber: 1, generation: 0),
            COSObjectKey(objectNumber: 1, generation: 1),
        ]
        let sorted = keys.sorted()
        #expect(sorted.map(\.generation) == [0, 1, 2])
    }

    // MARK: - Description

    @Test("Description format")
    func descriptionFormat() {
        let key = COSObjectKey(objectNumber: 42, generation: 0)
        #expect(key.description == "42 0 R")
    }

    @Test("Description with non-zero generation")
    func descriptionNonZeroGeneration() {
        let key = COSObjectKey(objectNumber: 10, generation: 3)
        #expect(key.description == "10 3 R")
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = COSObjectKey(objectNumber: 42, generation: 5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSObjectKey.self, from: data)
        #expect(original == decoded)
    }

    @Test("Encode and decode with default generation")
    func codableDefaultGeneration() throws {
        let original = COSObjectKey(objectNumber: 100)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSObjectKey.self, from: data)
        #expect(decoded.objectNumber == 100)
        #expect(decoded.generation == 0)
    }

    // MARK: - Sendable

    @Test("COSObjectKey is Sendable")
    func sendable() async {
        let key = COSObjectKey(objectNumber: 42)
        let task = Task { key }
        let result = await task.value
        #expect(result == key)
    }

    // MARK: - Edge Cases

    @Test("Large object number")
    func largeObjectNumber() {
        let key = COSObjectKey(objectNumber: 999999, generation: 0)
        #expect(key.objectNumber == 999999)
        #expect(key.description == "999999 0 R")
    }

    @Test("Maximum generation number")
    func maxGeneration() {
        // PDF spec allows up to 65535 for generation
        let key = COSObjectKey(objectNumber: 1, generation: 65535)
        #expect(key.generation == 65535)
        #expect(key.description == "1 65535 R")
    }
}
