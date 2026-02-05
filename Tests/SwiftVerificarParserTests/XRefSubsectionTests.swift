import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("XRefSubsection Tests")
struct XRefSubsectionTests {

    // MARK: - Initialization Tests

    @Test("Create subsection with single entry")
    func createSubsectionSingleEntry() {
        let entry = XRefEntry.inUse(offset: 1234, generation: 0)
        let subsection = XRefSubsection(startObjectNumber: 1, entries: [entry])

        #expect(subsection.startObjectNumber == 1)
        #expect(subsection.count == 1)
        #expect(subsection.entries.count == 1)
    }

    @Test("Create subsection with multiple entries")
    func createSubsectionMultipleEntries() {
        let entries: [XRefEntry] = [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 9, generation: 0),
            .inUse(offset: 74, generation: 0),
            .inUse(offset: 120, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection.startObjectNumber == 0)
        #expect(subsection.count == 4)
        #expect(subsection.entries.count == 4)
    }

    @Test("Create subsection with non-zero start")
    func createSubsectionNonZeroStart() {
        let entries: [XRefEntry] = [
            .inUse(offset: 1234, generation: 0),
            .inUse(offset: 1500, generation: 0),
            .inUse(offset: 1750, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(subsection.startObjectNumber == 10)
        #expect(subsection.count == 3)
    }

    // MARK: - Computed Properties Tests

    @Test("End object number calculation")
    func endObjectNumberCalculation() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 5, entries: entries)

        // Start=5, count=3 → objects 5, 6, 7 → end=7
        #expect(subsection.endObjectNumber == 7)
    }

    @Test("Object range calculation")
    func objectRangeCalculation() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 10, entries: entries)

        let range = subsection.objectRange
        #expect(range == 10..<12)
        #expect(range.contains(10))
        #expect(range.contains(11))
        #expect(!range.contains(12))
    }

    @Test("Single entry object range")
    func singleEntryObjectRange() {
        let entry = XRefEntry.inUse(offset: 1234, generation: 0)
        let subsection = XRefSubsection(startObjectNumber: 42, entries: [entry])

        let range = subsection.objectRange
        #expect(range == 42..<43)
        #expect(range.contains(42))
        #expect(!range.contains(43))
    }

    // MARK: - Entry Access Tests

    @Test("Access entry by object number - in range")
    func accessEntryInRange() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(subsection.entry(for: 10) == entries[0])
        #expect(subsection.entry(for: 11) == entries[1])
        #expect(subsection.entry(for: 12) == entries[2])
    }

    @Test("Access entry by object number - out of range")
    func accessEntryOutOfRange() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(subsection.entry(for: 9) == nil)
        #expect(subsection.entry(for: 12) == nil)
        #expect(subsection.entry(for: 0) == nil)
        #expect(subsection.entry(for: 100) == nil)
    }

    @Test("Subscript access to entries")
    func subscriptAccess() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 5, entries: entries)

        #expect(subsection[5] == entries[0])
        #expect(subsection[6] == entries[1])
        #expect(subsection[7] == entries[2])
        #expect(subsection[4] == nil)
        #expect(subsection[8] == nil)
    }

    @Test("Access first entry")
    func accessFirstEntry() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection[0] == entries[0])
    }

    // MARK: - Contains Tests

    @Test("Contains object number in range")
    func containsInRange() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(subsection.contains(objectNumber: 10))
        #expect(subsection.contains(objectNumber: 11))
        #expect(subsection.contains(objectNumber: 12))
    }

    @Test("Does not contain object number out of range")
    func doesNotContainOutOfRange() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(!subsection.contains(objectNumber: 9))
        #expect(!subsection.contains(objectNumber: 12))
        #expect(!subsection.contains(objectNumber: 0))
    }

    // MARK: - Statistics Tests

    @Test("Count in-use entries")
    func countInUseEntries() {
        let entries: [XRefEntry] = [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .compressed(objectStreamNumber: 10, index: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection.inUseCount == 3)
    }

    @Test("Count free entries")
    func countFreeEntries() {
        let entries: [XRefEntry] = [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .free(nextFreeObjectNumber: 3, generation: 65535),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection.freeCount == 2)
    }

    @Test("Count compressed entries")
    func countCompressedEntries() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .compressed(objectStreamNumber: 10, index: 0),
            .compressed(objectStreamNumber: 10, index: 1),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection.compressedCount == 2)
    }

    @Test("All entries in-use")
    func allEntriesInUse() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection.inUseCount == 3)
        #expect(subsection.freeCount == 0)
        #expect(subsection.compressedCount == 0)
    }

    @Test("Mixed entry types statistics")
    func mixedEntryTypesStatistics() {
        let entries: [XRefEntry] = [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .compressed(objectStreamNumber: 10, index: 0),
            .compressed(objectStreamNumber: 10, index: 1),
            .inUse(offset: 200, generation: 0),
            .free(nextFreeObjectNumber: 6, generation: 65535)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)

        #expect(subsection.inUseCount == 2)
        #expect(subsection.freeCount == 2)
        #expect(subsection.compressedCount == 2)
        #expect(subsection.count == 6)
    }

    // MARK: - Equality Tests

    @Test("Equal subsections")
    func equalSubsections() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ]
        let subsection1 = XRefSubsection(startObjectNumber: 10, entries: entries)
        let subsection2 = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(subsection1 == subsection2)
    }

    @Test("Different subsections by start number")
    func differentSubsectionsByStart() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0)
        ]
        let subsection1 = XRefSubsection(startObjectNumber: 10, entries: entries)
        let subsection2 = XRefSubsection(startObjectNumber: 20, entries: entries)

        #expect(subsection1 != subsection2)
    }

    @Test("Different subsections by entries")
    func differentSubsectionsByEntries() {
        let entries1: [XRefEntry] = [.inUse(offset: 100, generation: 0)]
        let entries2: [XRefEntry] = [.inUse(offset: 200, generation: 0)]

        let subsection1 = XRefSubsection(startObjectNumber: 10, entries: entries1)
        let subsection2 = XRefSubsection(startObjectNumber: 10, entries: entries2)

        #expect(subsection1 != subsection2)
    }

    // MARK: - Hashable Tests

    @Test("Equal subsections have equal hash values")
    func equalSubsectionsEqualHashes() {
        let entries: [XRefEntry] = [.inUse(offset: 100, generation: 0)]
        let subsection1 = XRefSubsection(startObjectNumber: 10, entries: entries)
        let subsection2 = XRefSubsection(startObjectNumber: 10, entries: entries)

        #expect(subsection1.hashValue == subsection2.hashValue)
    }

    @Test("Subsections can be used in sets")
    func subsectionsInSets() {
        let entries1: [XRefEntry] = [.inUse(offset: 100, generation: 0)]
        let entries2: [XRefEntry] = [.inUse(offset: 200, generation: 0)]

        let subsection1 = XRefSubsection(startObjectNumber: 10, entries: entries1)
        let subsection2 = XRefSubsection(startObjectNumber: 20, entries: entries2)

        let set: Set<XRefSubsection> = [subsection1, subsection2]
        #expect(set.count == 2)
        #expect(set.contains(subsection1))
        #expect(set.contains(subsection2))
    }

    // MARK: - Description Tests

    @Test("Subsection description")
    func subsectionDescription() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 5, entries: entries)

        let desc = subsection.description
        #expect(desc.contains("subsection"))
        #expect(desc.contains("5"))
        #expect(desc.contains("3"))
    }
}
