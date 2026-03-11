import Testing
import Foundation
@testable import SwiftVerificarParser

// MARK: - TrueType Binary Data Helpers

/// Builds a minimal TrueType font binary for testing table parsing.
///
/// The synthetic font contains only the tables specified in `tablePayloads`.
/// All integers are big-endian, matching the TrueType specification.
private func makeTrueTypeFont(tables: [(tag: String, data: Data)]) -> Data {
    // sfnt offset table: version (4), numTables (2), searchRange (2),
    //   entrySelector (2), rangeShift (2) = 12 bytes
    // Table directory: numTables × 16 bytes each
    // Table data: concatenated payloads
    let numTables = tables.count
    let directorySize = numTables * 16
    let headerSize = 12 + directorySize

    var tableDataOffset = headerSize
    var directoryEntries: [(tag: String, offset: Int, length: Int)] = []
    var allTableData = Data()
    for table in tables {
        directoryEntries.append((tag: table.tag, offset: tableDataOffset, length: table.data.count))
        allTableData.append(table.data)
        tableDataOffset += table.data.count
    }

    var result = Data()

    // sfnt version: 0x00010000
    result.append(contentsOf: [0x00, 0x01, 0x00, 0x00])
    // numTables
    result.appendUInt16BE(UInt16(numTables))
    // searchRange, entrySelector, rangeShift (set to 0 for test simplicity)
    result.appendUInt16BE(0)
    result.appendUInt16BE(0)
    result.appendUInt16BE(0)

    // Table directory entries
    for entry in directoryEntries {
        // Tag (4 bytes, padded with 0x20 if shorter)
        var tagBytes = Array(entry.tag.utf8)
        while tagBytes.count < 4 { tagBytes.append(0x20) }
        result.append(contentsOf: tagBytes.prefix(4))
        // checkSum (4 bytes) — not validated in our parser
        result.appendUInt32BE(0)
        // offset (4 bytes)
        result.appendUInt32BE(UInt32(entry.offset))
        // length (4 bytes)
        result.appendUInt32BE(UInt32(entry.length))
    }

    // Table payloads
    result.append(allTableData)
    return result
}

/// Builds a minimal `head` table payload (54 bytes).
private func makeHeadTable(
    unitsPerEm: UInt16,
    xMin: Int16, yMin: Int16,
    xMax: Int16, yMax: Int16,
    indexToLocFormat: Int16
) -> Data {
    var d = Data()
    // version Fixed (4 bytes)
    d.appendUInt32BE(0x00010000)
    // fontRevision Fixed (4 bytes)
    d.appendUInt32BE(0x00010000)
    // checkSumAdjustment UInt32 (4 bytes)
    d.appendUInt32BE(0)
    // magicNumber UInt32 (4 bytes) = 0x5F0F3CF5
    d.appendUInt32BE(0x5F0F3CF5)
    // flags UInt16 (2 bytes)
    d.appendUInt16BE(0x000B)
    // unitsPerEm UInt16 (2 bytes)
    d.appendUInt16BE(unitsPerEm)
    // created LONGDATETIME (8 bytes)
    d.appendUInt32BE(0); d.appendUInt32BE(0)
    // modified LONGDATETIME (8 bytes)
    d.appendUInt32BE(0); d.appendUInt32BE(0)
    // xMin Int16
    d.appendInt16BE(xMin)
    // yMin Int16
    d.appendInt16BE(yMin)
    // xMax Int16
    d.appendInt16BE(xMax)
    // yMax Int16
    d.appendInt16BE(yMax)
    // macStyle UInt16
    d.appendUInt16BE(0)
    // lowestRecPPEM UInt16
    d.appendUInt16BE(8)
    // fontDirectionHint Int16
    d.appendInt16BE(2)
    // indexToLocFormat Int16
    d.appendInt16BE(indexToLocFormat)
    // glyphDataFormat Int16
    d.appendInt16BE(0)
    return d  // 54 bytes
}

/// Builds a minimal `hhea` table payload (36 bytes).
private func makeHheaTable(
    ascent: Int16,
    descent: Int16,
    lineGap: Int16,
    numberOfHMetrics: UInt16
) -> Data {
    var d = Data()
    // version Fixed (4)
    d.appendUInt32BE(0x00010000)
    // ascent Int16
    d.appendInt16BE(ascent)
    // descent Int16
    d.appendInt16BE(descent)
    // lineGap Int16
    d.appendInt16BE(lineGap)
    // advanceWidthMax UInt16
    d.appendUInt16BE(2048)
    // minLSB, minRSB, xMaxExtent, caretSlopeRise, caretSlopeRun, caretOffset (6 × Int16)
    for _ in 0..<6 { d.appendInt16BE(0) }
    // reserved[0..3] (4 × Int16)
    for _ in 0..<4 { d.appendInt16BE(0) }
    // metricDataFormat Int16
    d.appendInt16BE(0)
    // numberOfHMetrics UInt16
    d.appendUInt16BE(numberOfHMetrics)
    return d  // 36 bytes
}

/// Builds a minimal `hmtx` table payload.
/// - Parameters:
///   - metrics: (advanceWidth, lsb) for each full hMetric entry.
///   - extraLSBs: Extra left-side bearings for monospaced glyphs.
private func makeHmtxTable(
    metrics: [(advanceWidth: UInt16, lsb: Int16)],
    extraLSBs: [Int16] = []
) -> Data {
    var d = Data()
    for m in metrics {
        d.appendUInt16BE(m.advanceWidth)
        d.appendInt16BE(m.lsb)
    }
    for lsb in extraLSBs {
        d.appendInt16BE(lsb)
    }
    return d
}

/// Builds a minimal Format 4 `cmap` subtable.
/// - Parameters:
///   - segments: (startCode, endCode, idDelta, idRangeOffset) tuples.
///   - glyphIdArray: Optional glyph ID override array.
private func makeCmapFormat4(
    segments: [(startCode: UInt16, endCode: UInt16, idDelta: Int16, idRangeOffset: UInt16)],
    glyphIdArray: [UInt16] = []
) -> Data {
    // The final segment must be (0xFFFF, 0xFFFF, 1, 0) as a terminator.
    var allSegments = segments
    let terminator = (startCode: UInt16(0xFFFF), endCode: UInt16(0xFFFF),
                      idDelta: Int16(1), idRangeOffset: UInt16(0))
    if allSegments.last?.endCode != 0xFFFF {
        allSegments.append(terminator)
    }
    let segCount = allSegments.count
    let glyphIdArrayByteCount = glyphIdArray.count * 2
    // length = 16 + segCount*8 + glyphIdArrayByteCount
    let length = UInt16(16 + segCount * 8 + glyphIdArrayByteCount)
    var d = Data()
    d.appendUInt16BE(4)           // format
    d.appendUInt16BE(length)      // length
    d.appendUInt16BE(0)           // language
    d.appendUInt16BE(UInt16(segCount * 2))  // segCountX2
    d.appendUInt16BE(0)           // searchRange (not used by our parser)
    d.appendUInt16BE(0)           // entrySelector
    d.appendUInt16BE(0)           // rangeShift
    // endCode array
    for seg in allSegments { d.appendUInt16BE(seg.endCode) }
    // reservedPad
    d.appendUInt16BE(0)
    // startCode array
    for seg in allSegments { d.appendUInt16BE(seg.startCode) }
    // idDelta array
    for seg in allSegments { d.appendInt16BE(seg.idDelta) }
    // idRangeOffset array
    for seg in allSegments { d.appendUInt16BE(seg.idRangeOffset) }
    // glyphIdArray
    for gid in glyphIdArray { d.appendUInt16BE(gid) }
    return d
}

/// Wraps a Format 4 cmap subtable in a full `cmap` table with one encoding record
/// (platform 3, encoding 1 — Windows Unicode BMP).
private func makeCmapTable(format4Payload: Data) -> Data {
    // cmap header: version (2) + numTables (2) = 4 bytes
    // encoding record: platformID (2) + encodingID (2) + offset (4) = 8 bytes
    // subtable follows at offset 12
    var d = Data()
    d.appendUInt16BE(0)   // version
    d.appendUInt16BE(1)   // numTables
    d.appendUInt16BE(3)   // platformID: Windows
    d.appendUInt16BE(1)   // encodingID: Unicode BMP
    d.appendUInt32BE(12)  // offset to subtable (from start of cmap table)
    d.append(format4Payload)
    return d
}

/// Builds a minimal `maxp` table payload.
private func makeMaxpTable(numGlyphs: UInt16) -> Data {
    var d = Data()
    d.appendUInt32BE(0x00010000)  // version
    d.appendUInt16BE(numGlyphs)   // numGlyphs
    // additional fields for version 1.0 (padding to silence any bounds checks)
    for _ in 0..<13 { d.appendUInt16BE(0) }
    return d
}

// MARK: - Data Extension for Big-Endian Writing

private extension Data {
    mutating func appendUInt16BE(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }
    mutating func appendInt16BE(_ value: Int16) {
        appendUInt16BE(UInt16(bitPattern: value))
    }
    mutating func appendUInt32BE(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }
}

// MARK: - Tests: TrueType Table Directory

@Suite("TrueType Table Directory Parsing")
struct TrueTypeTableDirectoryTests {

    @Test("Parser initialises from valid TrueType binary")
    func testValidFontInitialises() throws {
        let headData = makeHeadTable(
            unitsPerEm: 1000,
            xMin: -100, yMin: -200, xMax: 900, yMax: 800,
            indexToLocFormat: 0
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(parser.hasTable("head") == true)
        #expect(parser.hasTable("hhea") == false)
    }

    @Test("Parser rejects data with invalid sfnt signature")
    func testInvalidSignatureThrows() throws {
        // Corrupt the first four bytes so the signature is unrecognised
        var badData = Data(repeating: 0xFF, count: 100)
        badData[0] = 0xDE; badData[1] = 0xAD; badData[2] = 0xBE; badData[3] = 0xEF
        #expect(throws: TrueTypeParseError.invalidSignature) {
            _ = try TrueTypeTableParser(data: badData)
        }
    }

    @Test("Parser rejects data that is too short")
    func testDataTooShortThrows() throws {
        let shortData = Data([0x00, 0x01, 0x00])  // Only 3 bytes
        #expect(throws: TrueTypeParseError.dataTooShort) {
            _ = try TrueTypeTableParser(data: shortData)
        }
    }

    @Test("Table offset lookup returns nil for absent table")
    func testAbsentTableOffset() throws {
        let headData = makeHeadTable(
            unitsPerEm: 2048,
            xMin: 0, yMin: 0, xMax: 2048, yMax: 2048,
            indexToLocFormat: 1
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(parser.offset(of: "cmap") == nil)
    }

    @Test("Parser accepts Apple TrueType 'true' signature")
    func testAppleTrueTypeSignature() throws {
        // Build a font with 'true' signature manually
        let headData = makeHeadTable(
            unitsPerEm: 1000, xMin: 0, yMin: 0, xMax: 1000, yMax: 1000,
            indexToLocFormat: 0
        )
        var fontData = makeTrueTypeFont(tables: [("head", headData)])
        // Replace first 4 bytes with 'true' = 0x74 0x72 0x75 0x65
        fontData[0] = 0x74; fontData[1] = 0x72; fontData[2] = 0x75; fontData[3] = 0x65
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(parser.hasTable("head") == true)
    }
}

// MARK: - Tests: head Table

@Suite("TrueType head Table Parsing")
struct TrueTypeHeadTableTests {

    @Test("Parse head table with standard values")
    func testParseHead() throws {
        let headData = makeHeadTable(
            unitsPerEm: 2048,
            xMin: -150, yMin: -250,
            xMax: 1750, yMax: 1800,
            indexToLocFormat: 1
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let head = try parser.parseHead()

        #expect(head.unitsPerEm == 2048)
        #expect(head.xMin == -150)
        #expect(head.yMin == -250)
        #expect(head.xMax == 1750)
        #expect(head.yMax == 1800)
        #expect(head.indexToLocFormat == 1)
    }

    @Test("Parse head table with 1000 unitsPerEm")
    func testParseHeadUnitsPerEm1000() throws {
        let headData = makeHeadTable(
            unitsPerEm: 1000,
            xMin: -100, yMin: -200,
            xMax: 900, yMax: 800,
            indexToLocFormat: 0
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let head = try parser.parseHead()

        #expect(head.unitsPerEm == 1000)
        #expect(head.indexToLocFormat == 0)
    }

    @Test("Parse head throws when table is absent")
    func testHeadAbsentThrows() throws {
        let hheaData = makeHheaTable(ascent: 800, descent: -200, lineGap: 0, numberOfHMetrics: 3)
        let fontData = makeTrueTypeFont(tables: [("hhea", hheaData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(throws: TrueTypeParseError.tableNotFound("head")) {
            _ = try parser.parseHead()
        }
    }
}

// MARK: - Tests: hhea Table

@Suite("TrueType hhea Table Parsing")
struct TrueTypeHheaTableTests {

    @Test("Parse hhea table with typical values")
    func testParseHhea() throws {
        let hheaData = makeHheaTable(
            ascent: 1900,
            descent: -500,
            lineGap: 0,
            numberOfHMetrics: 256
        )
        let fontData = makeTrueTypeFont(tables: [("hhea", hheaData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let hhea = try parser.parseHhea()

        #expect(hhea.ascent == 1900)
        #expect(hhea.descent == -500)
        #expect(hhea.lineGap == 0)
        #expect(hhea.numberOfHMetrics == 256)
    }

    @Test("Parse hhea with non-zero lineGap")
    func testParseHheaWithLineGap() throws {
        let hheaData = makeHheaTable(
            ascent: 800,
            descent: -200,
            lineGap: 100,
            numberOfHMetrics: 3
        )
        let fontData = makeTrueTypeFont(tables: [("hhea", hheaData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let hhea = try parser.parseHhea()

        #expect(hhea.lineGap == 100)
        #expect(hhea.numberOfHMetrics == 3)
    }

    @Test("Parse hhea throws when table is absent")
    func testHheaAbsentThrows() throws {
        let headData = makeHeadTable(
            unitsPerEm: 1000, xMin: 0, yMin: 0, xMax: 1000, yMax: 1000,
            indexToLocFormat: 0
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(throws: TrueTypeParseError.tableNotFound("hhea")) {
            _ = try parser.parseHhea()
        }
    }
}

// MARK: - Tests: hmtx Table

@Suite("TrueType hmtx Table Parsing")
struct TrueTypeHmtxTableTests {

    @Test("Parse hmtx with three full hMetric entries")
    func testParseHmtxThreeMetrics() throws {
        let metrics: [(advanceWidth: UInt16, lsb: Int16)] = [
            (500, 20),
            (600, 30),
            (400, 10)
        ]
        let hmtxData = makeHmtxTable(metrics: metrics)
        let fontData = makeTrueTypeFont(tables: [("hmtx", hmtxData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let hmtx = try parser.parseHmtx(numberOfGlyphs: 3, numberOfHMetrics: 3)

        #expect(hmtx.hMetrics.count == 3)
        #expect(hmtx.hMetrics[0].advanceWidth == 500)
        #expect(hmtx.hMetrics[0].leftSideBearing == 20)
        #expect(hmtx.hMetrics[1].advanceWidth == 600)
        #expect(hmtx.hMetrics[2].advanceWidth == 400)
        #expect(hmtx.leftSideBearings.isEmpty)
    }

    @Test("Parse hmtx with monospaced extra LSBs")
    func testParseHmtxWithExtraLSBs() throws {
        // 2 full hMetrics + 3 extra LSB-only entries (monospaced remainder)
        let metrics: [(advanceWidth: UInt16, lsb: Int16)] = [(1000, 50), (1000, 60)]
        let extraLSBs: [Int16] = [70, 80, 90]
        let hmtxData = makeHmtxTable(metrics: metrics, extraLSBs: extraLSBs)
        let fontData = makeTrueTypeFont(tables: [("hmtx", hmtxData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let hmtx = try parser.parseHmtx(numberOfGlyphs: 5, numberOfHMetrics: 2)

        #expect(hmtx.hMetrics.count == 2)
        #expect(hmtx.leftSideBearings.count == 3)
        #expect(hmtx.leftSideBearings[0] == 70)
        #expect(hmtx.leftSideBearings[2] == 90)
    }

    @Test("Parse hmtx throws when table is absent")
    func testHmtxAbsentThrows() throws {
        let headData = makeHeadTable(
            unitsPerEm: 1000, xMin: 0, yMin: 0, xMax: 1000, yMax: 1000,
            indexToLocFormat: 0
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(throws: TrueTypeParseError.tableNotFound("hmtx")) {
            _ = try parser.parseHmtx(numberOfGlyphs: 10, numberOfHMetrics: 10)
        }
    }

    @Test("Parse hmtx with single glyph")
    func testParseHmtxSingleGlyph() throws {
        let metrics: [(advanceWidth: UInt16, lsb: Int16)] = [(750, 100)]
        let hmtxData = makeHmtxTable(metrics: metrics)
        let fontData = makeTrueTypeFont(tables: [("hmtx", hmtxData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let hmtx = try parser.parseHmtx(numberOfGlyphs: 1, numberOfHMetrics: 1)

        #expect(hmtx.hMetrics.count == 1)
        #expect(hmtx.hMetrics[0].advanceWidth == 750)
        #expect(hmtx.hMetrics[0].leftSideBearing == 100)
    }
}

// MARK: - Tests: cmap Table

@Suite("TrueType cmap Table Parsing")
struct TrueTypeCmapTableTests {

    @Test("Parse cmap Format 4 with delta mapping")
    func testParseCmapFormat4Delta() throws {
        // One segment covering ASCII letters A-Z (0x41-0x5A) with delta mapping
        // idDelta = 1 → glyphIDs = codePoint + 1
        let format4 = makeCmapFormat4(segments: [
            (startCode: 0x41, endCode: 0x5A, idDelta: 1, idRangeOffset: 0)
        ])
        let cmapData = makeCmapTable(format4Payload: format4)
        let fontData = makeTrueTypeFont(tables: [("cmap", cmapData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let cmap = try parser.parseCmap()

        // Should have 2 segments: the A-Z segment + 0xFFFF terminator
        #expect(cmap.segments.count == 2)
        #expect(cmap.platformID == 3)
        #expect(cmap.encodingID == 1)

        // Glyph ID lookup for 'A' (0x41): 0x41 + 1 = 0x42
        let glyphA = cmap.glyphID(for: 0x41)
        #expect(glyphA == 0x42)

        // Glyph ID lookup for 'Z' (0x5A): 0x5A + 1 = 0x5B
        let glyphZ = cmap.glyphID(for: 0x5A)
        #expect(glyphZ == 0x5B)
    }

    @Test("Parse cmap Format 4 segment values are correct")
    func testParseCmapSegmentValues() throws {
        let format4 = makeCmapFormat4(segments: [
            (startCode: 0x0020, endCode: 0x007E, idDelta: -31, idRangeOffset: 0)
        ])
        let cmapData = makeCmapTable(format4Payload: format4)
        let fontData = makeTrueTypeFont(tables: [("cmap", cmapData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let cmap = try parser.parseCmap()

        let spaceSeg = cmap.segments[0]
        #expect(spaceSeg.startCode == 0x0020)
        #expect(spaceSeg.endCode == 0x007E)
        #expect(spaceSeg.idDelta == -31)
        #expect(spaceSeg.idRangeOffset == 0)
    }

    @Test("cmap glyphID returns nil for unmapped character")
    func testCmapUnmappedReturnsNil() throws {
        // Segment maps only 0x41-0x5A
        let format4 = makeCmapFormat4(segments: [
            (startCode: 0x41, endCode: 0x5A, idDelta: 1, idRangeOffset: 0)
        ])
        let cmapData = makeCmapTable(format4Payload: format4)
        let fontData = makeTrueTypeFont(tables: [("cmap", cmapData)])
        let parser = try TrueTypeTableParser(data: fontData)
        let cmap = try parser.parseCmap()

        // 0x20 (space) is not in the segment
        #expect(cmap.glyphID(for: 0x20) == nil)
        // 0x61 ('a') is also outside
        #expect(cmap.glyphID(for: 0x61) == nil)
    }

    @Test("Parse cmap throws when table is absent")
    func testCmapAbsentThrows() throws {
        let headData = makeHeadTable(
            unitsPerEm: 1000, xMin: 0, yMin: 0, xMax: 1000, yMax: 1000,
            indexToLocFormat: 0
        )
        let fontData = makeTrueTypeFont(tables: [("head", headData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(throws: TrueTypeParseError.tableNotFound("cmap")) {
            _ = try parser.parseCmap()
        }
    }

    @Test("Parse cmap throws when no Format 4 subtable is present")
    func testCmapNoFormat4Throws() throws {
        // Build a cmap header that points to a Format 0 subtable (not Format 4)
        // Our parser only supports Format 4, so this should throw.
        var cmapData = Data()
        cmapData.appendUInt16BE(0)   // version
        cmapData.appendUInt16BE(1)   // numTables
        cmapData.appendUInt16BE(1)   // platformID: Mac
        cmapData.appendUInt16BE(0)   // encodingID
        cmapData.appendUInt32BE(12)  // offset
        // Format 0 subtable header (just format=0, length=262, language=0)
        cmapData.appendUInt16BE(0)   // format = 0
        cmapData.appendUInt16BE(262) // length
        cmapData.appendUInt16BE(0)   // language
        // 256 bytes of glyph indices
        for _ in 0..<256 { cmapData.append(0) }
        let fontData = makeTrueTypeFont(tables: [("cmap", cmapData)])
        let parser = try TrueTypeTableParser(data: fontData)
        #expect(throws: TrueTypeParseError.noSupportedCmapFormat) {
            _ = try parser.parseCmap()
        }
    }
}

// MARK: - Tests: All Four Tables Together

@Suite("TrueType Complete Font Parsing")
struct TrueTypeCompleteFontTests {

    @Test("Parse all four required tables from a single font binary")
    func testParseAllTablesFromSingleFont() throws {
        let headData = makeHeadTable(
            unitsPerEm: 2048,
            xMin: -200, yMin: -400,
            xMax: 2000, yMax: 2000,
            indexToLocFormat: 0
        )
        let hheaData = makeHheaTable(
            ascent: 1800,
            descent: -400,
            lineGap: 0,
            numberOfHMetrics: 4
        )
        let hmtxData = makeHmtxTable(metrics: [
            (500, 10), (600, 20), (700, 30), (550, 15)
        ])
        let maxpData = makeMaxpTable(numGlyphs: 4)
        let format4 = makeCmapFormat4(segments: [
            (startCode: 0x41, endCode: 0x44, idDelta: 0, idRangeOffset: 8),
        ], glyphIdArray: [1, 2, 3, 4])
        let cmapData = makeCmapTable(format4Payload: format4)

        let fontData = makeTrueTypeFont(tables: [
            ("head", headData),
            ("hhea", hheaData),
            ("hmtx", hmtxData),
            ("maxp", maxpData),
            ("cmap", cmapData)
        ])

        let parser = try TrueTypeTableParser(data: fontData)

        let head = try parser.parseHead()
        #expect(head.unitsPerEm == 2048)
        #expect(head.xMin == -200)
        #expect(head.indexToLocFormat == 0)

        let hhea = try parser.parseHhea()
        #expect(hhea.ascent == 1800)
        #expect(hhea.descent == -400)
        #expect(hhea.numberOfHMetrics == 4)

        let glyphCount = try parser.parseMaxpGlyphCount()
        let hmtx = try parser.parseHmtx(
            numberOfGlyphs: glyphCount,
            numberOfHMetrics: Int(hhea.numberOfHMetrics)
        )
        #expect(hmtx.hMetrics.count == 4)
        #expect(hmtx.hMetrics[0].advanceWidth == 500)
        #expect(hmtx.hMetrics[3].leftSideBearing == 15)

        let cmap = try parser.parseCmap()
        #expect(cmap.segments.count >= 2)  // user segment + terminator
    }

    @Test("TrueTypeHeadTable Equatable")
    func testHeadTableEquatable() {
        let a = TrueTypeHeadTable(
            unitsPerEm: 1000, xMin: -100, yMin: -200,
            xMax: 900, yMax: 800, indexToLocFormat: 0
        )
        let b = TrueTypeHeadTable(
            unitsPerEm: 1000, xMin: -100, yMin: -200,
            xMax: 900, yMax: 800, indexToLocFormat: 0
        )
        let c = TrueTypeHeadTable(
            unitsPerEm: 2048, xMin: -100, yMin: -200,
            xMax: 900, yMax: 800, indexToLocFormat: 0
        )
        #expect(a == b)
        #expect(a != c)
    }

    @Test("TrueTypeHheaTable Equatable")
    func testHheaTableEquatable() {
        let a = TrueTypeHheaTable(ascent: 800, descent: -200, lineGap: 0, numberOfHMetrics: 10)
        let b = TrueTypeHheaTable(ascent: 800, descent: -200, lineGap: 0, numberOfHMetrics: 10)
        let c = TrueTypeHheaTable(ascent: 900, descent: -200, lineGap: 0, numberOfHMetrics: 10)
        #expect(a == b)
        #expect(a != c)
    }

    @Test("TrueTypeHMetric Equatable")
    func testHMetricEquatable() {
        let a = TrueTypeHMetric(advanceWidth: 500, leftSideBearing: 20)
        let b = TrueTypeHMetric(advanceWidth: 500, leftSideBearing: 20)
        let c = TrueTypeHMetric(advanceWidth: 600, leftSideBearing: 20)
        #expect(a == b)
        #expect(a != c)
    }
}
