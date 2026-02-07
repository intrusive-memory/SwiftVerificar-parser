import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `PDFOutputStream` protocol and `DataOutputStream` struct.
@Suite("PDFOutputStream Tests")
struct PDFOutputStreamTests {

    // MARK: - DataOutputStream Initialization

    @Test("init creates empty stream")
    func initCreatesEmpty() {
        let stream = DataOutputStream()
        #expect(stream.bytesWritten == 0)
        #expect(stream.isClosed == false)
        #expect(stream.data.isEmpty)
    }

    @Test("init with capacity hint")
    func initWithCapacity() {
        let stream = DataOutputStream(capacity: 1024)
        #expect(stream.bytesWritten == 0)
        #expect(stream.data.isEmpty)
    }

    // MARK: - writeByte

    @Test("writeByte adds a byte")
    func writeByte() throws {
        var stream = DataOutputStream()
        try stream.writeByte(0x25)
        #expect(stream.bytesWritten == 1)
        #expect(stream.data == Data([0x25]))
    }

    @Test("writeByte multiple bytes")
    func writeMultipleBytes() throws {
        var stream = DataOutputStream()
        try stream.writeByte(0x25)
        try stream.writeByte(0x50)
        try stream.writeByte(0x44)
        #expect(stream.bytesWritten == 3)
        #expect(stream.data == Data([0x25, 0x50, 0x44]))
    }

    @Test("writeByte throws when closed")
    func writeByteWhenClosed() {
        var stream = DataOutputStream()
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.writeByte(0x01)
        }
    }

    // MARK: - write array

    @Test("write array of bytes")
    func writeArray() throws {
        var stream = DataOutputStream()
        try stream.write([0x01, 0x02, 0x03])
        #expect(stream.bytesWritten == 3)
        #expect(stream.data == Data([0x01, 0x02, 0x03]))
    }

    @Test("write empty array")
    func writeEmptyArray() throws {
        var stream = DataOutputStream()
        try stream.write([UInt8]())
        #expect(stream.bytesWritten == 0)
    }

    @Test("write array throws when closed")
    func writeArrayWhenClosed() {
        var stream = DataOutputStream()
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.write([0x01, 0x02])
        }
    }

    // MARK: - write with offset and length

    @Test("write with offset and length")
    func writeWithOffset() throws {
        var stream = DataOutputStream()
        let bytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05]
        try stream.write(bytes, offset: 1, length: 3)
        #expect(stream.bytesWritten == 3)
        #expect(stream.data == Data([0x02, 0x03, 0x04]))
    }

    @Test("write with offset throws when closed")
    func writeWithOffsetWhenClosed() {
        var stream = DataOutputStream()
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.write([0x01, 0x02], offset: 0, length: 1)
        }
    }

    // MARK: - write Data

    @Test("write Data instance")
    func writeData() throws {
        var stream = DataOutputStream()
        let data = Data([0xAA, 0xBB, 0xCC])
        try stream.write(data)
        #expect(stream.bytesWritten == 3)
        #expect(stream.data == data)
    }

    @Test("write empty Data")
    func writeEmptyData() throws {
        var stream = DataOutputStream()
        try stream.write(Data())
        #expect(stream.bytesWritten == 0)
    }

    @Test("write Data throws when closed")
    func writeDataWhenClosed() {
        var stream = DataOutputStream()
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.write(Data([0x01]))
        }
    }

    // MARK: - flush

    @Test("flush on open stream does nothing")
    func flushOpen() throws {
        var stream = DataOutputStream()
        try stream.writeByte(0x01)
        try stream.flush()
        #expect(stream.data == Data([0x01]))
    }

    @Test("flush throws when closed")
    func flushWhenClosed() {
        var stream = DataOutputStream()
        stream.close()
        #expect(throws: PDFStreamError.streamClosed) {
            try stream.flush()
        }
    }

    // MARK: - close

    @Test("close sets isClosed")
    func closeSetsFlag() {
        var stream = DataOutputStream()
        #expect(stream.isClosed == false)
        stream.close()
        #expect(stream.isClosed == true)
    }

    @Test("data is available after close")
    func dataAvailableAfterClose() throws {
        var stream = DataOutputStream()
        try stream.write([0x01, 0x02, 0x03])
        stream.close()
        #expect(stream.data == Data([0x01, 0x02, 0x03]))
    }

    // MARK: - reset

    @Test("reset clears data and reopens stream")
    func resetClearsAndReopens() throws {
        var stream = DataOutputStream()
        try stream.write([0x01, 0x02])
        stream.close()
        stream.reset()
        #expect(stream.data.isEmpty)
        #expect(stream.bytesWritten == 0)
        #expect(stream.isClosed == false)
        try stream.writeByte(0x03)
        #expect(stream.data == Data([0x03]))
    }

    // MARK: - Large Data

    @Test("write large data block")
    func writeLargeData() throws {
        var stream = DataOutputStream()
        let largeBlock = [UInt8](repeating: 0xAB, count: 100_000)
        try stream.write(largeBlock)
        #expect(stream.bytesWritten == 100_000)
        #expect(stream.data.count == 100_000)
    }

    // MARK: - Sendable

    @Test("DataOutputStream is Sendable")
    func isSendable() {
        let stream: any Sendable = DataOutputStream()
        #expect(stream is DataOutputStream)
    }

    // MARK: - Combined Operations

    @Test("interleaved writes produce correct output")
    func interleavedWrites() throws {
        var stream = DataOutputStream()
        try stream.writeByte(0x01)
        try stream.write([0x02, 0x03])
        try stream.write(Data([0x04, 0x05]))
        try stream.writeByte(0x06)
        #expect(stream.data == Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]))
        #expect(stream.bytesWritten == 6)
    }
}
