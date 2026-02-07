import Testing
import Foundation
@testable import SwiftVerificarParser

/// A minimal seekable stream to test the `SeekableStream` protocol default implementations.
///
/// This type implements only the required protocol methods, relying on the
/// default implementations of `reset()`, `skip(_:)`, and `peek()`.
private struct MinimalSeekableStream: SeekableStream, Sendable {
    private let data: Data
    private var currentPosition: Int
    private var closed: Bool

    init(data: Data) {
        self.data = data
        self.currentPosition = 0
        self.closed = false
    }

    var position: Int64 { Int64(currentPosition) }
    var availableBytes: Int64? { Int64(data.count) }
    var isClosed: Bool { closed }
    var length: Int64 { Int64(data.count) }

    mutating func readByte() throws -> UInt8? {
        guard !closed else { throw PDFStreamError.streamClosed }
        guard currentPosition < data.count else { return nil }
        let byte = data[data.startIndex + currentPosition]
        currentPosition += 1
        return byte
    }

    mutating func read(_ buffer: inout [UInt8], maxLength: Int) throws -> Int {
        guard !closed else { throw PDFStreamError.streamClosed }
        guard currentPosition < data.count else { return 0 }
        let bytesToRead = min(maxLength, data.count - currentPosition)
        let startIndex = data.startIndex + currentPosition
        let endIndex = startIndex + bytesToRead
        data.copyBytes(to: &buffer, from: startIndex..<endIndex)
        currentPosition += bytesToRead
        return bytesToRead
    }

    mutating func seek(to position: Int64) throws {
        guard !closed else { throw PDFStreamError.streamClosed }
        guard position >= 0, position <= Int64(data.count) else {
            throw PDFStreamError.invalidSeekPosition(position)
        }
        currentPosition = Int(position)
    }

    mutating func close() {
        closed = true
    }
}

/// A minimal input stream to test `PDFInputStream` default implementations
/// (readAllBytes, skip, peek) on a non-seekable stream.
private struct MinimalInputStream: PDFInputStream, Sendable {
    private let data: Data
    private var currentPosition: Int
    private var closed: Bool

    init(data: Data) {
        self.data = data
        self.currentPosition = 0
        self.closed = false
    }

    var position: Int64 { Int64(currentPosition) }
    var availableBytes: Int64? { Int64(data.count) }
    var isClosed: Bool { closed }

    mutating func readByte() throws -> UInt8? {
        guard !closed else { throw PDFStreamError.streamClosed }
        guard currentPosition < data.count else { return nil }
        let byte = data[data.startIndex + currentPosition]
        currentPosition += 1
        return byte
    }

    mutating func read(_ buffer: inout [UInt8], maxLength: Int) throws -> Int {
        guard !closed else { throw PDFStreamError.streamClosed }
        guard currentPosition < data.count else { return 0 }
        let bytesToRead = min(maxLength, data.count - currentPosition)
        let startIndex = data.startIndex + currentPosition
        let endIndex = startIndex + bytesToRead
        data.copyBytes(to: &buffer, from: startIndex..<endIndex)
        currentPosition += bytesToRead
        return bytesToRead
    }

    mutating func close() {
        closed = true
    }
}

/// Tests for `SeekableStream` protocol default implementations.
@Suite("SeekableStream Tests")
struct SeekableStreamTests {

    // MARK: - Default reset()

    @Test("default reset() seeks to 0")
    func defaultReset() throws {
        var stream = MinimalSeekableStream(data: Data([0x01, 0x02, 0x03]))
        _ = try stream.readByte()
        _ = try stream.readByte()
        try stream.reset()
        #expect(stream.position == 0)
        #expect(try stream.readByte() == 0x01)
    }

    // MARK: - Default skip()

    @Test("default skip() uses seeking")
    func defaultSkip() throws {
        var stream = MinimalSeekableStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        let skipped = try stream.skip(3)
        #expect(skipped == 3)
        #expect(stream.position == 3)
        #expect(try stream.readByte() == 0x04)
    }

    @Test("default skip() clamps to length")
    func defaultSkipClamps() throws {
        var stream = MinimalSeekableStream(data: Data([0x01, 0x02]))
        let skipped = try stream.skip(100)
        #expect(skipped == 2)
        #expect(stream.position == 2)
    }

    @Test("default skip() from middle")
    func defaultSkipFromMiddle() throws {
        var stream = MinimalSeekableStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        _ = try stream.readByte()
        let skipped = try stream.skip(2)
        #expect(skipped == 2)
        #expect(stream.position == 3)
        #expect(try stream.readByte() == 0x04)
    }

    // MARK: - Default peek()

    @Test("default peek() reads without advancing via seeking")
    func defaultPeek() throws {
        var stream = MinimalSeekableStream(data: Data([0x01, 0x02, 0x03]))
        #expect(try stream.peek() == 0x01)
        #expect(stream.position == 0)
        _ = try stream.readByte()
        #expect(try stream.peek() == 0x02)
        #expect(stream.position == 1)
    }

    @Test("default peek() returns nil at end")
    func defaultPeekAtEnd() throws {
        var stream = MinimalSeekableStream(data: Data([0x01]))
        _ = try stream.readByte()
        #expect(try stream.peek() == nil)
    }

    // MARK: - Length

    @Test("length is correct")
    func lengthCorrect() {
        let stream = MinimalSeekableStream(data: Data([0x01, 0x02, 0x03]))
        #expect(stream.length == 3)
    }

    @Test("length is 0 for empty data")
    func lengthEmpty() {
        let stream = MinimalSeekableStream(data: Data())
        #expect(stream.length == 0)
    }
}

/// Tests for `PDFInputStream` protocol default implementations.
@Suite("PDFInputStream Default Tests")
struct PDFInputStreamDefaultTests {

    // MARK: - Default readAllBytes()

    @Test("default readAllBytes() reads all data")
    func defaultReadAllBytes() throws {
        var stream = MinimalInputStream(data: Data([0x01, 0x02, 0x03, 0x04]))
        let result = try stream.readAllBytes()
        #expect(result == Data([0x01, 0x02, 0x03, 0x04]))
    }

    @Test("default readAllBytes() reads remaining after partial")
    func defaultReadAllBytesAfterPartial() throws {
        var stream = MinimalInputStream(data: Data([0x01, 0x02, 0x03]))
        _ = try stream.readByte()
        let result = try stream.readAllBytes()
        #expect(result == Data([0x02, 0x03]))
    }

    @Test("default readAllBytes() returns empty at end")
    func defaultReadAllBytesEmpty() throws {
        var stream = MinimalInputStream(data: Data())
        let result = try stream.readAllBytes()
        #expect(result.isEmpty)
    }

    // MARK: - Default skip()

    @Test("default skip() reads and discards")
    func defaultSkipReadsAndDiscards() throws {
        var stream = MinimalInputStream(data: Data([0x01, 0x02, 0x03, 0x04, 0x05]))
        let skipped = try stream.skip(3)
        #expect(skipped == 3)
        #expect(try stream.readByte() == 0x04)
    }

    @Test("default skip() clamps to remaining data")
    func defaultSkipClamps() throws {
        var stream = MinimalInputStream(data: Data([0x01, 0x02]))
        let skipped = try stream.skip(10)
        #expect(skipped == 2)
    }

    // MARK: - Default peek()

    @Test("default peek() returns nil for non-seekable stream")
    func defaultPeekReturnsNil() throws {
        var stream = MinimalInputStream(data: Data([0x01, 0x02]))
        let result = try stream.peek()
        #expect(result == nil)
    }

    // MARK: - Large data with default readAllBytes

    @Test("default readAllBytes with large data")
    func defaultReadAllBytesLarge() throws {
        let data = Data(repeating: 0xAB, count: 50_000)
        var stream = MinimalInputStream(data: data)
        let result = try stream.readAllBytes()
        #expect(result.count == 50_000)
        #expect(result == data)
    }
}

/// A minimal output stream to test `PDFOutputStream` default implementations.
private struct MinimalOutputStream: PDFOutputStream, Sendable {
    private var buffer: Data
    private var closed: Bool

    init() {
        self.buffer = Data()
        self.closed = false
    }

    var bytesWritten: Int64 { Int64(buffer.count) }
    var isClosed: Bool { closed }
    var data: Data { buffer }

    mutating func writeByte(_ byte: UInt8) throws {
        guard !closed else { throw PDFStreamError.streamClosed }
        buffer.append(byte)
    }

    mutating func close() {
        closed = true
    }
}

/// Tests for `PDFOutputStream` default implementations.
@Suite("PDFOutputStream Default Tests")
struct PDFOutputStreamDefaultTests {

    @Test("default write([UInt8]) calls writeByte for each byte")
    func defaultWriteArray() throws {
        var stream = MinimalOutputStream()
        try stream.write([0x01, 0x02, 0x03])
        #expect(stream.data == Data([0x01, 0x02, 0x03]))
    }

    @Test("default write with offset and length")
    func defaultWriteWithOffset() throws {
        var stream = MinimalOutputStream()
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        try stream.write(bytes, offset: 1, length: 3)
        #expect(stream.data == Data([0x02, 0x03, 0x04]))
    }

    @Test("default write Data converts to array")
    func defaultWriteData() throws {
        var stream = MinimalOutputStream()
        try stream.write(Data([0xAA, 0xBB]))
        #expect(stream.data == Data([0xAA, 0xBB]))
    }

    @Test("default flush throws when closed")
    func defaultFlushThrowsWhenClosed() {
        var stream = MinimalOutputStream()
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.flush()
        }
    }

    @Test("default flush does nothing when open")
    func defaultFlushDoesNothing() throws {
        var stream = MinimalOutputStream()
        try stream.writeByte(0x01)
        try stream.flush()
        #expect(stream.data == Data([0x01]))
    }
}
