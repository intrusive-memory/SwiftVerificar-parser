import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("XRefTable Tests")
struct XRefTableTests {

    // MARK: - Initialization Tests

    @Test("Create table with single subsection")
    func createTableSingleSubsection() {
        let entries: [XRefEntry] = [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 9, generation: 0),
            .inUse(offset: 74, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.subsectionCount == 1)
        #expect(table.totalEntryCount == 3)
    }

    @Test("Create table with multiple subsections")
    func createTableMultipleSubsections() {
        let subsection1 = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 9, generation: 0),
            .inUse(offset: 74, generation: 0)
        ])

        let subsection2 = XRefSubsection(startObjectNumber: 10, entries: [
            .inUse(offset: 1234, generation: 0),
            .inUse(offset: 1500, generation: 0),
            .inUse(offset: 1750, generation: 0)
        ])

        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 13
        )
        let table = XRefTable(subsections: [subsection1, subsection2], trailer: trailer)

        #expect(table.subsectionCount == 2)
        #expect(table.totalEntryCount == 6)
    }

    @Test("Create table with byte offset")
    func createTableWithByteOffset() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 1
        )
        let table = XRefTable(
            subsections: [subsection],
            trailer: trailer,
            byteOffset: 12345
        )

        #expect(table.byteOffset == 12345)
    }

    // MARK: - Entry Lookup Tests

    @Test("Lookup entry in single subsection")
    func lookupEntryInSingleSubsection() {
        let entries: [XRefEntry] = [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .inUse(offset: 300, generation: 0)
        ]
        let subsection = XRefSubsection(startObjectNumber: 5, entries: entries)
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 5),
            size: 8
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.entry(for: 5) == entries[0])
        #expect(table.entry(for: 6) == entries[1])
        #expect(table.entry(for: 7) == entries[2])
    }

    @Test("Lookup entry across multiple subsections")
    func lookupEntryAcrossSubsections() {
        let subsection1 = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])

        let subsection2 = XRefSubsection(startObjectNumber: 10, entries: [
            .inUse(offset: 1000, generation: 0),
            .inUse(offset: 2000, generation: 0)
        ])

        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 12
        )
        let table = XRefTable(subsections: [subsection1, subsection2], trailer: trailer)

        #expect(table.entry(for: 0)?.offset == 100)
        #expect(table.entry(for: 1)?.offset == 200)
        #expect(table.entry(for: 10)?.offset == 1000)
        #expect(table.entry(for: 11)?.offset == 2000)
    }

    @Test("Lookup entry not in any subsection")
    func lookupEntryNotFound() {
        let subsection = XRefSubsection(startObjectNumber: 10, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 10),
            size: 11
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.entry(for: 0) == nil)
        #expect(table.entry(for: 5) == nil)
        #expect(table.entry(for: 11) == nil)
    }

    @Test("Later subsection overrides earlier one")
    func laterSubsectionOverrides() {
        // Simulate incremental update where object 1 is updated
        let subsection1 = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])

        let subsection2 = XRefSubsection(startObjectNumber: 1, entries: [
            .inUse(offset: 999, generation: 1) // Updated object 1
        ])

        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 2
        )
        let table = XRefTable(subsections: [subsection1, subsection2], trailer: trailer)

        // Object 1 should have the value from subsection2 (last one wins)
        #expect(table.entry(for: 1)?.offset == 999)
        #expect(table.entry(for: 1)?.generation == 1)
    }

    @Test("Subscript access to entries")
    func subscriptAccess() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 2
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table[0]?.offset == 100)
        #expect(table[1]?.offset == 200)
        #expect(table[2] == nil)
    }

    @Test("Offset lookup")
    func offsetLookup() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 300, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 2),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.offset(for: 0) == 100)
        #expect(table.offset(for: 1) == nil) // free entry has no offset
        #expect(table.offset(for: 2) == 300)
    }

    // MARK: - Contains Tests

    @Test("Contains object number")
    func containsObjectNumber() {
        let subsection = XRefSubsection(startObjectNumber: 5, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 5),
            size: 7
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.contains(objectNumber: 5))
        #expect(table.contains(objectNumber: 6))
        #expect(!table.contains(objectNumber: 4))
        #expect(!table.contains(objectNumber: 7))
    }

    @Test("Is in use")
    func isInUse() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .compressed(objectStreamNumber: 10, index: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 0),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.isInUse(objectNumber: 0))
        #expect(!table.isInUse(objectNumber: 1))
        #expect(!table.isInUse(objectNumber: 2))
    }

    @Test("Is free")
    func isFree() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .compressed(objectStreamNumber: 10, index: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 0),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(!table.isFree(objectNumber: 0))
        #expect(table.isFree(objectNumber: 1))
        #expect(!table.isFree(objectNumber: 2))
    }

    @Test("Is compressed")
    func isCompressed() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .compressed(objectStreamNumber: 10, index: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 0),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(!table.isCompressed(objectNumber: 0))
        #expect(!table.isCompressed(objectNumber: 1))
        #expect(table.isCompressed(objectNumber: 2))
    }

    // MARK: - Trailer Access Tests

    @Test("Access trailer size")
    func accessTrailerSize() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 100
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.size == 100)
    }

    @Test("Has incremental update")
    func hasIncrementalUpdate() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let trailerWithPrev = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 1,
            previousXRefOffset: 5000
        )
        let tableWithPrev = XRefTable(subsections: [subsection], trailer: trailerWithPrev)

        #expect(tableWithPrev.hasIncrementalUpdate)
        #expect(tableWithPrev.previousXRefOffset == 5000)

        let trailerNoPrev = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 1
        )
        let tableNoPrev = XRefTable(subsections: [subsection], trailer: trailerNoPrev)

        #expect(!tableNoPrev.hasIncrementalUpdate)
        #expect(tableNoPrev.previousXRefOffset == nil)
    }

    // MARK: - Statistics Tests

    @Test("Count in-use entries")
    func countInUseEntries() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0),
            .compressed(objectStreamNumber: 10, index: 0),
            .inUse(offset: 300, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 5
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.inUseCount == 3)
    }

    @Test("Count free entries")
    func countFreeEntries() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .free(nextFreeObjectNumber: 3, generation: 65535)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.freeCount == 2)
    }

    @Test("Count compressed entries")
    func countCompressedEntries() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .compressed(objectStreamNumber: 10, index: 0),
            .compressed(objectStreamNumber: 10, index: 1)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 0),
            size: 3
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table.compressedCount == 2)
    }

    @Test("Statistics across multiple subsections")
    func statisticsAcrossSubsections() {
        let subsection1 = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])

        let subsection2 = XRefSubsection(startObjectNumber: 10, entries: [
            .compressed(objectStreamNumber: 20, index: 0),
            .compressed(objectStreamNumber: 20, index: 1),
            .inUse(offset: 300, generation: 0)
        ])

        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 13
        )
        let table = XRefTable(subsections: [subsection1, subsection2], trailer: trailer)

        #expect(table.inUseCount == 3)
        #expect(table.freeCount == 1)
        #expect(table.compressedCount == 2)
        #expect(table.totalEntryCount == 6)
    }

    // MARK: - Object Number Collection Tests

    @Test("All object numbers")
    func allObjectNumbers() {
        let subsection1 = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])

        let subsection2 = XRefSubsection(startObjectNumber: 5, entries: [
            .inUse(offset: 500, generation: 0),
            .inUse(offset: 600, generation: 0)
        ])

        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 7
        )
        let table = XRefTable(subsections: [subsection1, subsection2], trailer: trailer)

        let allObjects = table.allObjectNumbers()
        #expect(allObjects.count == 4)
        #expect(allObjects.contains(0))
        #expect(allObjects.contains(1))
        #expect(allObjects.contains(5))
        #expect(allObjects.contains(6))
    }

    @Test("In-use object numbers only")
    func inUseObjectNumbers() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .free(nextFreeObjectNumber: 0, generation: 65535),
            .inUse(offset: 100, generation: 0),
            .compressed(objectStreamNumber: 10, index: 0),
            .inUse(offset: 300, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 4
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        let inUseObjects = table.inUseObjectNumbers()
        #expect(inUseObjects.count == 2)
        #expect(inUseObjects.contains(1))
        #expect(inUseObjects.contains(3))
        #expect(!inUseObjects.contains(0))
        #expect(!inUseObjects.contains(2))
    }

    // MARK: - Equality Tests

    @Test("Equal tables")
    func equalTables() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 0),
            size: 1
        )

        let table1 = XRefTable(subsections: [subsection], trailer: trailer)
        let table2 = XRefTable(subsections: [subsection], trailer: trailer)

        #expect(table1 == table2)
    }

    @Test("Different tables by subsections")
    func differentTablesBySubsections() {
        let subsection1 = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0)
        ])
        let subsection2 = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 200, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 0),
            size: 1
        )

        let table1 = XRefTable(subsections: [subsection1], trailer: trailer)
        let table2 = XRefTable(subsections: [subsection2], trailer: trailer)

        #expect(table1 != table2)
    }

    // MARK: - Description Tests

    @Test("Table description")
    func tableDescription() {
        let subsection = XRefSubsection(startObjectNumber: 0, entries: [
            .inUse(offset: 100, generation: 0),
            .inUse(offset: 200, generation: 0)
        ])
        let trailer = PDFTrailer(
            rootReference: COSReference(objectNumber: 1),
            size: 2
        )
        let table = XRefTable(subsections: [subsection], trailer: trailer)

        let desc = table.description
        #expect(desc.contains("xref"))
        #expect(desc.contains("1")) // subsection count
        #expect(desc.contains("2")) // entry count or size
    }
}
