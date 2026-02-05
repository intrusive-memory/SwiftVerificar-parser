import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `DataInputStream` struct.
@Suite("DataInputStream Tests")
struct DataInputStreamTests {

    // MARK: - Initialization

    @Test("init with Data")
    func initWithData() {
        let data = Data([0x01, 0x02, 0x03])
        let stream = DataInputStream(data: data)
        #expect(stream.position == 0)
        #expect(stream.availableBytes == 3)
        #expect(stream.isClosed == false)
        #expect(stream.isAtEnd == false)
        #expect(stream.remainingBytes == 3)
    }

    @Test("init with bytes array")
    func initWithBytes() {
        let stream = DataInputStream(bytes: [0x01, 0x02, 0x03])
        #expect(stream.position == 0)
        #expect(stream.availableBytes == 3)
    }

    @Test("init with empty data")
    func initWithEmptyData() {
        let stream = DataInputStream(data: Data())
        #expect(stream.position == 0)
        #expect(stream.availableBytes == 0)
        #expect(stream.isAtEnd == true)
        #expect(stream.remainingBytes == 0)
    }

    // MARK: - readByte

    @Test("readByte returns bytes sequentially")
    func readByteSequential() throws {
        var stream = DataInputStream(data: Data([0xAA, 0xBB, 0xCC]))
        #expect(try stream.readByte() == 0xAA)
        #expect(stream.position == 1)
        #expect(try stream.readByte() == 0xBB)
        #expect(stream.position == 2)
        #expect(try stream.readByte() == 0xCC)
        #expect(stream.position == 3)
    }

    @Test("readByte returns nil at end of stream")
    func readByteAtEnd() throws {
        var stream = DataInputStream(data: Data([0x01]))
        _ = try stream.readByte()
        #expect(try stream.readByte() == nil)
    }

    @Test("readByte returns nil for empty stream")
    func readByteEmpty() throws {
        var stream = DataInputStream(data: Data())
        #expect(try stream.readByte() == nil)
    }

    @Test("readByte throws when closed")
    func readByteWhenClosed() {
        var stream = DataInputStream(data: Data([0x01]))
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.readByte()
        }
    }

    // MARK: - read buffer

    @Test("read into buffer")
    func readBuffer() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        var buffer = [UInt8](repeating: 0, count: 3)
        let bytesRead = try stream.read(&buffer, maxLength: 3)
        #expect(bytesRead == 3)
        #expect(buffer == [0x01, 0x02, 0x03])
        #expect(stream.position == 3)
    }

    @Test("read into buffer with maxLength larger than remaining")
    func readBufferLargerThanRemaining() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        var buffer = [UInt8](repeating: 0, count: 10)
        let bytesRead = try stream.read(&buffer, maxLength: 10)
        #expect(bytesRead == 2)
        #expect(buffer[0] == 0x01)
        #expect(buffer[1] == 0x02)
    }

    @Test("read into buffer returns 0 at end")
    func readBufferAtEnd() throws {
        var stream = DataInputStream(data: Data([0x01]))
        var buffer = [UInt8](repeating: 0, count: 5)
        _ = try stream.read(&buffer, maxLength: 5)
        let bytesRead = try stream.read(&buffer, maxLength: 5)
        #expect(bytesRead == 0)
    }

    @Test("read into buffer throws when closed")
    func readBufferWhenClosed() {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        stream.close()
        var buffer = [UInt8](repeating: 0, count: 5)
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.read(&buffer, maxLength: 5)
        }
    }

    // MARK: - readAllBytes

    @Test("readAllBytes returns all remaining data")
    func readAllBytes() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04]))
        _ = try stream.readByte()
        let remaining = try stream.readAllBytes()
        #expect(remaining == Data([0x02, 0x03, 0x04]))
        #expect(stream.position == 4)
    }

    @Test("readAllBytes returns empty data at end")
    func readAllBytesAtEnd() throws {
        var stream = DataInputStream(data: Data([0x01]))
        _ = try stream.readAllBytes()
        let remaining = try stream.readAllBytes()
        #expect(remaining.isEmpty)
    }

    @Test("readAllBytes from empty stream")
    func readAllBytesEmpty() throws {
        var stream = DataInputStream(data: Data())
        let data = try stream.readAllBytes()
        #expect(data.isEmpty)
    }

    @Test("readAllBytes throws when closed")
    func readAllBytesWhenClosed() {
        var stream = DataInputStream(data: Data([0x01]))
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.readAllBytes()
        }
    }

    // MARK: - skip

    @Test("skip advances position")
    func skip() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        let skipped = try stream.skip(3)
        #expect(skipped == 3)
        #expect(stream.position == 3)
        #expect(try stream.readByte() == 0x04)
    }

    @Test("skip past end of stream")
    func skipPastEnd() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        let skipped = try stream.skip(10)
        #expect(skipped == 2)
        #expect(stream.position == 2)
    }

    @Test("skip zero bytes")
    func skipZero() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        let skipped = try stream.skip(0)
        #expect(skipped == 0)
        #expect(stream.position == 0)
    }

    @Test("skip throws when closed")
    func skipWhenClosed() {
        var stream = DataInputStream(data: Data([0x01]))
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.skip(1)
        }
    }

    // MARK: - peek

    @Test("peek returns next byte without advancing")
    func peek() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        #expect(try stream.peek() == 0x01)
        #expect(stream.position == 0)
        #expect(try stream.peek() == 0x01)
    }

    @Test("peek returns nil at end")
    func peekAtEnd() throws {
        var stream = DataInputStream(data: Data())
        #expect(try stream.peek() == nil)
    }

    @Test("peek throws when closed")
    func peekWhenClosed() {
        var stream = DataInputStream(data: Data([0x01]))
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            _ = try stream.peek()
        }
    }

    // MARK: - seek

    @Test("seek to beginning")
    func seekToBeginning() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03]))
        _ = try stream.readByte()
        _ = try stream.readByte()
        try stream.seek(to: 0)
        #expect(stream.position == 0)
        #expect(try stream.readByte() == 0x01)
    }

    @Test("seek to middle")
    func seekToMiddle() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04]))
        try stream.seek(to: 2)
        #expect(stream.position == 2)
        #expect(try stream.readByte() == 0x03)
    }

    @Test("seek to end")
    func seekToEnd() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        try stream.seek(to: 2)
        #expect(stream.position == 2)
        #expect(stream.isAtEnd == true)
        #expect(try stream.readByte() == nil)
    }

    @Test("seek to invalid position throws")
    func seekInvalid() {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        #expect(throws: PDFStreamError.invalidSeekPosition(10)) {
            try stream.seek(to: 10)
        }
    }

    @Test("seek to negative position throws")
    func seekNegative() {
        var stream = DataInputStream(data: Data([0x01, 0x02]))
        #expect(throws: PDFStreamError.invalidSeekPosition(-1)) {
            try stream.seek(to: -1)
        }
    }

    @Test("seek when closed throws")
    func seekWhenClosed() {
        var stream = DataInputStream(data: Data([0x01]))
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.seek(to: 0)
        }
    }

    // MARK: - reset

    @Test("reset goes to beginning")
    func resetGoesToBeginning() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03]))
        _ = try stream.readByte()
        _ = try stream.readByte()
        try stream.reset()
        #expect(stream.position == 0)
        #expect(try stream.readByte() == 0x01)
    }

    // MARK: - length

    @Test("length matches data size")
    func lengthMatchesData() {
        let stream = DataInputStream(data: Data([0x01, 0x02, 0x03]))
        #expect(stream.length == 3)
    }

    @Test("length is 0 for empty data")
    func lengthEmpty() {
        let stream = DataInputStream(data: Data())
        #expect(stream.length == 0)
    }

    // MARK: - close

    @Test("close sets isClosed")
    func closeSetsFlag() {
        var stream = DataInputStream(data: Data([0x01]))
        #expect(stream.isClosed == false)
        stream.close()
        #expect(stream.isClosed == true)
    }

    // MARK: - Large Data

    @Test("read large data block")
    func readLargeData() throws {
        let size = 100_000
        let data = Data(repeating: 0xAB, count: size)
        var stream = DataInputStream(data: data)
        let result = try stream.readAllBytes()
        #expect(result.count == size)
        #expect(result == data)
    }

    // MARK: - Sendable

    @Test("DataInputStream is Sendable")
    func isSendable() {
        let stream: any Sendable = DataInputStream(data: Data())
        #expect(stream is DataInputStream)
    }

    // MARK: - Combined Operations

    @Test("read, seek, read pattern")
    func readSeekReadPattern() throws {
        var stream = DataInputStream(data: Data([0x10, 0x20, 0x30, 0x40, 0x50]))
        #expect(try stream.readByte() == 0x10)
        #expect(try stream.readByte() == 0x20)
        try stream.seek(to: 0)
        #expect(try stream.readByte() == 0x10)
        try stream.seek(to: 4)
        #expect(try stream.readByte() == 0x50)
        #expect(try stream.readByte() == nil)
    }

    @Test("skip then read remaining")
    func skipThenReadRemaining() throws {
        var stream = DataInputStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        _ = try stream.skip(3)
        let remaining = try stream.readAllBytes()
        #expect(remaining == Data([0x04, 0x05]))
    }
}
