import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("COSReference Tests")
struct COSReferenceTests {

    // MARK: - Initialization

    @Test("Init with object number and default generation")
    func initDefaultGeneration() {
        let ref = COSReference(objectNumber: 42)
        #expect(ref.objectNumber == 42)
        #expect(ref.generation == 0)
    }

    @Test("Init with object number and generation")
    func initWithGeneration() {
        let ref = COSReference(objectNumber: 10, generation: 3)
        #expect(ref.objectNumber == 10)
        #expect(ref.generation == 3)
    }

    @Test("Init from COSObjectKey")
    func initFromKey() {
        let key = COSObjectKey(objectNumber: 55, generation: 2)
        let ref = COSReference(key: key)
        #expect(ref.objectNumber == 55)
        #expect(ref.generation == 2)
        #expect(ref.key == key)
    }

    @Test("Init with zero object number")
    func initZeroObjectNumber() {
        let ref = COSReference(objectNumber: 0, generation: 65535)
        #expect(ref.objectNumber == 0)
        #expect(ref.generation == 65535)
    }

    // MARK: - Key Access

    @Test("Key property matches constructor values")
    func keyProperty() {
        let ref = COSReference(objectNumber: 42, generation: 5)
        #expect(ref.key.objectNumber == 42)
        #expect(ref.key.generation == 5)
    }

    @Test("Key from COSObjectKey init matches")
    func keyFromKeyInit() {
        let key = COSObjectKey(objectNumber: 7, generation: 1)
        let ref = COSReference(key: key)
        #expect(ref.key == key)
    }

    // MARK: - Equality

    @Test("Equal references")
    func equalReferences() {
        let a = COSReference(objectNumber: 42, generation: 0)
        let b = COSReference(objectNumber: 42, generation: 0)
        #expect(a == b)
    }

    @Test("Different object numbers are not equal")
    func differentObjectNumbers() {
        let a = COSReference(objectNumber: 42, generation: 0)
        let b = COSReference(objectNumber: 43, generation: 0)
        #expect(a != b)
    }

    @Test("Different generations are not equal")
    func differentGenerations() {
        let a = COSReference(objectNumber: 42, generation: 0)
        let b = COSReference(objectNumber: 42, generation: 1)
        #expect(a != b)
    }

    @Test("Reference from key equals reference from components")
    func referenceFromKeyEqualsComponents() {
        let key = COSObjectKey(objectNumber: 42, generation: 3)
        let fromKey = COSReference(key: key)
        let fromComponents = COSReference(objectNumber: 42, generation: 3)
        #expect(fromKey == fromComponents)
    }

    // MARK: - Hashable

    @Test("Equal references have same hash")
    func equalHashValues() {
        let a = COSReference(objectNumber: 42, generation: 0)
        let b = COSReference(objectNumber: 42, generation: 0)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        var dict: [COSReference: String] = [:]
        let ref1 = COSReference(objectNumber: 1)
        let ref2 = COSReference(objectNumber: 2)
        dict[ref1] = "Object 1"
        dict[ref2] = "Object 2"
        #expect(dict[ref1] == "Object 1")
        #expect(dict[ref2] == "Object 2")
        #expect(dict.count == 2)
    }

    @Test("Can be stored in a Set")
    func setUsage() {
        let set: Set<COSReference> = [
            COSReference(objectNumber: 1),
            COSReference(objectNumber: 2),
            COSReference(objectNumber: 1),
        ]
        #expect(set.count == 2)
    }

    // MARK: - Description

    @Test("Description format")
    func descriptionFormat() {
        let ref = COSReference(objectNumber: 42, generation: 0)
        #expect(ref.description == "42 0 R")
    }

    @Test("Description with non-zero generation")
    func descriptionNonZeroGeneration() {
        let ref = COSReference(objectNumber: 10, generation: 3)
        #expect(ref.description == "10 3 R")
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = COSReference(objectNumber: 42, generation: 5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSReference.self, from: data)
        #expect(original == decoded)
    }

    @Test("Encode and decode with default generation")
    func codableDefaultGeneration() throws {
        let original = COSReference(objectNumber: 100)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSReference.self, from: data)
        #expect(decoded.objectNumber == 100)
        #expect(decoded.generation == 0)
    }

    @Test("Encode and decode with COSObjectKey init")
    func codableFromKey() throws {
        let key = COSObjectKey(objectNumber: 77, generation: 2)
        let original = COSReference(key: key)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(COSReference.self, from: data)
        #expect(decoded == original)
        #expect(decoded.key == key)
    }

    // MARK: - Sendable

    @Test("COSReference is Sendable")
    func sendable() async {
        let ref = COSReference(objectNumber: 42)
        let task = Task { ref }
        let result = await task.value
        #expect(result == ref)
    }

    // MARK: - Edge Cases

    @Test("Large object number")
    func largeObjectNumber() {
        let ref = COSReference(objectNumber: 999999, generation: 0)
        #expect(ref.objectNumber == 999999)
        #expect(ref.description == "999999 0 R")
    }

    @Test("Maximum generation number")
    func maxGeneration() {
        let ref = COSReference(objectNumber: 1, generation: 65535)
        #expect(ref.generation == 65535)
        #expect(ref.description == "1 65535 R")
    }
}
