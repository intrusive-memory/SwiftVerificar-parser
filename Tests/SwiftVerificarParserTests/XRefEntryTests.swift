import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("XRefEntry Tests")
struct XRefEntryTests {

    // MARK: - In-Use Entry Tests

    @Test("Create in-use entry with offset and generation")
    func createInUseEntry() {
        let entry = XRefEntry.inUse(offset: 1234, generation: 0)
        #expect(entry.isInUse)
        #expect(!entry.isFree)
        #expect(!entry.isCompressed)
        #expect(entry.offset == 1234)
        #expect(entry.generation == 0)
    }

    @Test("Create in-use entry with default generation")
    func createInUseEntryDefaultGeneration() {
        let entry = XRefEntry.inUse(offset: 5678)
        #expect(entry.isInUse)
        #expect(entry.offset == 5678)
        #expect(entry.generation == 0)
    }

    @Test("In-use entry with non-zero generation")
    func inUseEntryNonZeroGeneration() {
        let entry = XRefEntry.inUse(offset: 9999, generation: 5)
        #expect(entry.isInUse)
        #expect(entry.offset == 9999)
        #expect(entry.generation == 5)
    }

    @Test("In-use entry has nil values for free/compressed properties")
    func inUseEntryNilProperties() {
        let entry = XRefEntry.inUse(offset: 1000, generation: 0)
        #expect(entry.nextFreeObjectNumber == nil)
        #expect(entry.objectStreamNumber == nil)
        #expect(entry.index == nil)
    }

    // MARK: - Free Entry Tests

    @Test("Create free entry with next object number and generation")
    func createFreeEntry() {
        let entry = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        #expect(entry.isFree)
        #expect(!entry.isInUse)
        #expect(!entry.isCompressed)
        #expect(entry.nextFreeObjectNumber == 5)
        #expect(entry.generation == 65535)
    }

    @Test("Create free entry with default generation 65535")
    func createFreeEntryDefaultGeneration() {
        let entry = XRefEntry.free(nextFreeObjectNumber: 10)
        #expect(entry.isFree)
        #expect(entry.nextFreeObjectNumber == 10)
        #expect(entry.generation == 65535)
    }

    @Test("Free entry with generation 0")
    func freeEntryGenerationZero() {
        let entry = XRefEntry.free(nextFreeObjectNumber: 0, generation: 0)
        #expect(entry.isFree)
        #expect(entry.nextFreeObjectNumber == 0)
        #expect(entry.generation == 0)
    }

    @Test("Free entry has nil values for in-use/compressed properties")
    func freeEntryNilProperties() {
        let entry = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        #expect(entry.offset == nil)
        #expect(entry.objectStreamNumber == nil)
        #expect(entry.index == nil)
    }

    // MARK: - Compressed Entry Tests

    @Test("Create compressed entry")
    func createCompressedEntry() {
        let entry = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        #expect(entry.isCompressed)
        #expect(!entry.isInUse)
        #expect(!entry.isFree)
        #expect(entry.objectStreamNumber == 10)
        #expect(entry.index == 3)
    }

    @Test("Compressed entry with zero index")
    func compressedEntryZeroIndex() {
        let entry = XRefEntry.compressed(objectStreamNumber: 20, index: 0)
        #expect(entry.isCompressed)
        #expect(entry.objectStreamNumber == 20)
        #expect(entry.index == 0)
    }

    @Test("Compressed entry has nil generation")
    func compressedEntryNilGeneration() {
        let entry = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        #expect(entry.generation == nil)
    }

    @Test("Compressed entry has nil values for in-use/free properties")
    func compressedEntryNilProperties() {
        let entry = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        #expect(entry.offset == nil)
        #expect(entry.nextFreeObjectNumber == nil)
    }

    // MARK: - Equality Tests

    @Test("Equal in-use entries")
    func equalInUseEntries() {
        let entry1 = XRefEntry.inUse(offset: 1234, generation: 0)
        let entry2 = XRefEntry.inUse(offset: 1234, generation: 0)
        #expect(entry1 == entry2)
    }

    @Test("Different in-use entries by offset")
    func differentInUseEntriesByOffset() {
        let entry1 = XRefEntry.inUse(offset: 1234, generation: 0)
        let entry2 = XRefEntry.inUse(offset: 5678, generation: 0)
        #expect(entry1 != entry2)
    }

    @Test("Different in-use entries by generation")
    func differentInUseEntriesByGeneration() {
        let entry1 = XRefEntry.inUse(offset: 1234, generation: 0)
        let entry2 = XRefEntry.inUse(offset: 1234, generation: 1)
        #expect(entry1 != entry2)
    }

    @Test("Equal free entries")
    func equalFreeEntries() {
        let entry1 = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        let entry2 = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        #expect(entry1 == entry2)
    }

    @Test("Different free entries by next object number")
    func differentFreeEntriesByNextObject() {
        let entry1 = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        let entry2 = XRefEntry.free(nextFreeObjectNumber: 10, generation: 65535)
        #expect(entry1 != entry2)
    }

    @Test("Equal compressed entries")
    func equalCompressedEntries() {
        let entry1 = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        let entry2 = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        #expect(entry1 == entry2)
    }

    @Test("Different compressed entries by stream number")
    func differentCompressedEntriesByStream() {
        let entry1 = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        let entry2 = XRefEntry.compressed(objectStreamNumber: 20, index: 3)
        #expect(entry1 != entry2)
    }

    @Test("Different compressed entries by index")
    func differentCompressedEntriesByIndex() {
        let entry1 = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
        let entry2 = XRefEntry.compressed(objectStreamNumber: 10, index: 5)
        #expect(entry1 != entry2)
    }

    @Test("Different entry types are not equal")
    func differentEntryTypes() {
        let inUse = XRefEntry.inUse(offset: 1234, generation: 0)
        let free = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        let compressed = XRefEntry.compressed(objectStreamNumber: 10, index: 3)

        #expect(inUse != free)
        #expect(inUse != compressed)
        #expect(free != compressed)
    }

    // MARK: - Hashable Tests

    @Test("Equal entries have equal hash values")
    func equalEntriesEqualHashes() {
        let entry1 = XRefEntry.inUse(offset: 1234, generation: 0)
        let entry2 = XRefEntry.inUse(offset: 1234, generation: 0)
        #expect(entry1.hashValue == entry2.hashValue)
    }

    @Test("Entries can be used in sets")
    func entriesInSets() {
        let entry1 = XRefEntry.inUse(offset: 1234, generation: 0)
        let entry2 = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
        let entry3 = XRefEntry.compressed(objectStreamNumber: 10, index: 3)

        let set: Set<XRefEntry> = [entry1, entry2, entry3]
        #expect(set.count == 3)
        #expect(set.contains(entry1))
        #expect(set.contains(entry2))
        #expect(set.contains(entry3))
    }

    @Test("Entries can be used as dictionary keys")
    func entriesAsDictionaryKeys() {
        let entry1 = XRefEntry.inUse(offset: 1234, generation: 0)
        let entry2 = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)

        var dict: [XRefEntry: String] = [:]
        dict[entry1] = "in-use"
        dict[entry2] = "free"

        #expect(dict[entry1] == "in-use")
        #expect(dict[entry2] == "free")
        #expect(dict.count == 2)
    }

    // MARK: - Description Tests

    @Test("In-use entry description")
    func inUseEntryDescription() {
        let entry = XRefEntry.inUse(offset: 1234, generation: 5)
        let desc = entry.description
        #expect(desc.contains("inUse"))
        #expect(desc.contains("1234"))
        #expect(desc.contains("5"))
    }

    @Test("Free entry description")
    func freeEntryDescription() {
        let entry = XRefEntry.free(nextFreeObjectNumber: 10, generation: 65535)
        let desc = entry.description
        #expect(desc.contains("free"))
        #expect(desc.contains("10"))
        #expect(desc.contains("65535"))
    }

    @Test("Compressed entry description")
    func compressedEntryDescription() {
        let entry = XRefEntry.compressed(objectStreamNumber: 20, index: 7)
        let desc = entry.description
        #expect(desc.contains("compressed"))
        #expect(desc.contains("20"))
        #expect(desc.contains("7"))
    }

    // MARK: - Edge Cases

    @Test("In-use entry with large offset")
    func inUseEntryLargeOffset() {
        let largeOffset: Int64 = 9_999_999_999
        let entry = XRefEntry.inUse(offset: largeOffset, generation: 0)
        #expect(entry.offset == largeOffset)
    }

    @Test("Free entry with object 0")
    func freeEntryObjectZero() {
        let entry = XRefEntry.free(nextFreeObjectNumber: 0, generation: 65535)
        #expect(entry.nextFreeObjectNumber == 0)
    }

    @Test("Compressed entry with large index")
    func compressedEntryLargeIndex() {
        let entry = XRefEntry.compressed(objectStreamNumber: 100, index: 999)
        #expect(entry.objectStreamNumber == 100)
        #expect(entry.index == 999)
    }
}
