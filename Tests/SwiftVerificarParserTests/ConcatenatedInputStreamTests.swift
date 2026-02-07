import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `ConcatenatedInputStream` struct.
@Suite("ConcatenatedInputStream Tests")
struct ConcatenatedInputStreamTests {

    // MARK: - Initialization

    @Test("init with empty array")
    func initEmpty() {
        let stream = ConcatenatedInputStream<DataInputStream>(streams: [])
        #expect(stream.position == 0)
        #expect(stream.streamCount == 0)
        #expect(stream.isClosed == false)
    }

    @Test("init with single stream")
    func initSingle() {
        let inner = DataInputStream(data: Data([0x01, 0x02]))
        let stream = ConcatenatedInputStream(streams: [inner])
        #expect(stream.streamCount == 1)
        #expect(stream.activeStreamIndex == 0)
    }

    @Test("init with multiple streams")
    func initMultiple() {
        let s1 = DataInputStream(data: Data([0x01]))
        let s2 = DataInputStream(data: Data([0x02]))
        let s3 = DataInputStream(data: Data([0x03]))
        let stream = ConcatenatedInputStream(streams: [s1, s2, s3])
        #expect(stream.streamCount == 3)
    }

    @Test("init from data array convenience")
    func initFromDataArray() {
        let stream = ConcatenatedInputStream(dataArray: [
            Data([0x01, 0x02]),
            Data([0x03, 0x04]),
        ])
        #expect(stream.streamCount == 2)
    }

    // MARK: - availableBytes

    @Test("availableBytes sums all streams")
    func availableBytesSumsAll() {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03, 0x04, 0x05]))
        let stream = ConcatenatedInputStream(streams: [s1, s2])
        #expect(stream.availableBytes == 5)
    }

    @Test("availableBytes for empty streams")
    func availableBytesEmpty() {
        let stream = ConcatenatedInputStream<DataInputStream>(streams: [])
        #expect(stream.availableBytes == 0)
    }

    // MARK: - readByte

    @Test("readByte crosses stream boundaries")
    func readByteCrossesBoundaries() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03, 0x04]))
        var stream = ConcatenatedInputStream(streams: [s1, s2])

        #expect(try stream.readByte() == 0x01)
        #expect(try stream.readByte() == 0x02)
        #expect(try stream.readByte() == 0x03)
        #expect(try stream.readByte() == 0x04)
        #expect(try stream.readByte() == nil)
    }

    @Test("readByte returns nil for empty stream list")
    func readByteEmptyList() throws {
        var stream = ConcatenatedInputStream<DataInputStream>(streams: [])
        #expect(try stream.readByte() == nil)
    }

    @Test("readByte skips empty inner streams")
    func readByteSkipsEmpty() throws {
        let s1 = DataInputStream(data: Data())
        let s2 = DataInputStream(data: Data([0x01]))
        let s3 = DataInputStream(data: Data())
        var stream = ConcatenatedInputStream(streams: [s1, s2, s3])

        #expect(try stream.readByte() == 0x01)
        #expect(try stream.readByte() == nil)
    }

    @Test("readByte throws when closed")
    func readByteWhenClosed() {
        let s1 = DataInputStream(data: Data([0x01]))
        var stream = ConcatenatedInputStream(streams: [s1])
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.readByte()
        }
    }

    @Test("readByte updates position correctly")
    func readByteUpdatesPosition() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03]))
        var stream = ConcatenatedInputStream(streams: [s1, s2])

        #expect(stream.position == 0)
        _ = try stream.readByte()
        #expect(stream.position == 1)
        _ = try stream.readByte()
        #expect(stream.position == 2)
        _ = try stream.readByte()
        #expect(stream.position == 3)
    }

    // MARK: - read buffer

    @Test("read buffer within single stream")
    func readBufferSingleStream() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        var stream = ConcatenatedInputStream(streams: [s1])
        var buffer = [UInt8](repeating: 0, count: 3)
        let bytesRead = try stream.read(&buffer, maxLength: 3)
        #expect(bytesRead == 3)
        #expect(buffer == [0x01, 0x02, 0x03])
    }

    @Test("read buffer across stream boundaries")
    func readBufferAcrossBoundaries() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03, 0x04]))
        var stream = ConcatenatedInputStream(streams: [s1, s2])
        var buffer = [UInt8](repeating: 0, count: 4)
        let bytesRead = try stream.read(&buffer, maxLength: 4)
        #expect(bytesRead == 4)
        #expect(buffer == [0x01, 0x02, 0x03, 0x04])
    }

    @Test("read buffer returns 0 when exhausted")
    func readBufferExhausted() throws {
        let s1 = DataInputStream(data: Data([0x01]))
        var stream = ConcatenatedInputStream(streams: [s1])
        var buffer = [UInt8](repeating: 0, count: 5)
        _ = try stream.read(&buffer, maxLength: 5)
        let bytesRead = try stream.read(&buffer, maxLength: 5)
        #expect(bytesRead == 0)
    }

    @Test("read buffer throws when closed")
    func readBufferWhenClosed() {
        let s1 = DataInputStream(data: Data([0x01]))
        var stream = ConcatenatedInputStream(streams: [s1])
        stream.close()
        var buffer = [UInt8](repeating: 0, count: 5)
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.read(&buffer, maxLength: 5)
        }
    }

    // MARK: - readAllBytes

    @Test("readAllBytes returns all data from all streams")
    func readAllBytesAll() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03, 0x04]))
        let s3 = DataInputStream(data: Data([0x05]))
        var stream = ConcatenatedInputStream(streams: [s1, s2, s3])

        let result = try stream.readAllBytes()
        #expect(result == Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        #expect(stream.position == 5)
    }

    @Test("readAllBytes returns remaining after partial read")
    func readAllBytesAfterPartial() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03, 0x04]))
        var stream = ConcatenatedInputStream(streams: [s1, s2])

        _ = try stream.readByte()
        let remaining = try stream.readAllBytes()
        #expect(remaining == Data([0x02, 0x03, 0x04]))
    }

    @Test("readAllBytes returns empty for empty streams")
    func readAllBytesEmpty() throws {
        var stream = ConcatenatedInputStream<DataInputStream>(streams: [])
        let result = try stream.readAllBytes()
        #expect(result.isEmpty)
    }

    @Test("readAllBytes throws when closed")
    func readAllBytesWhenClosed() {
        let s1 = DataInputStream(data: Data([0x01]))
        var stream = ConcatenatedInputStream(streams: [s1])
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.readAllBytes()
        }
    }

    // MARK: - skip

    @Test("skip within single stream")
    func skipWithinSingle() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        var stream = ConcatenatedInputStream(streams: [s1])
        let skipped = try stream.skip(3)
        #expect(skipped == 3)
        #expect(try stream.readByte() == 0x04)
    }

    @Test("skip across stream boundaries")
    func skipAcrossBoundaries() throws {
        let s1 = DataInputStream(data: Data([0x01, 0x02]))
        let s2 = DataInputStream(data: Data([0x03, 0x04, 0x05]))
        var stream = ConcatenatedInputStream(streams: [s1, s2])
        let skipped = try stream.skip(3)
        #expect(skipped == 3)
        #expect(try stream.readByte() == 0x04)
    }

    @Test("skip past all streams")
    func skipPastAll() throws {
        let s1 = DataInputStream(data: Data([0x01]))
        let s2 = DataInputStream(data: Data([0x02]))
        var stream = ConcatenatedInputStream(streams: [s1, s2])
        let skipped = try stream.skip(100)
        #expect(skipped == 2)
    }

    @Test("skip throws when closed")
    func skipWhenClosed() {
        let s1 = DataInputStream(data: Data([0x01]))
        var stream = ConcatenatedInputStream(streams: [s1])
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.skip(1)
        }
    }

    // MARK: - close

    @Test("close sets isClosed")
    func closeSetsFlag() {
        let s1 = DataInputStream(data: Data([0x01]))
        var stream = ConcatenatedInputStream(streams: [s1])
        #expect(stream.isClosed == false)
        stream.close()
        #expect(stream.isClosed == true)
    }

    // MARK: - Sendable

    @Test("ConcatenatedInputStream is Sendable")
    func isSendable() {
        let s1 = DataInputStream(data: Data([0x01]))
        let stream: any Sendable = ConcatenatedInputStream(streams: [s1])
        #expect(stream is ConcatenatedInputStream<DataInputStream>)
    }

    // MARK: - Edge Cases

    @Test("all inner streams are empty")
    func allEmpty() throws {
        let s1 = DataInputStream(data: Data())
        let s2 = DataInputStream(data: Data())
        var stream = ConcatenatedInputStream(streams: [s1, s2])
        #expect(try stream.readByte() == nil)
        let all = try stream.readAllBytes()
        #expect(all.isEmpty)
    }

    @Test("single byte per stream")
    func singleBytePerStream() throws {
        let streams = (0..<5).map { DataInputStream(data: Data([UInt8($0)])) }
        var stream = ConcatenatedInputStream(streams: streams)
        for i in 0..<5 {
            #expect(try stream.readByte() == UInt8(i))
        }
        #expect(try stream.readByte() == nil)
    }
}
