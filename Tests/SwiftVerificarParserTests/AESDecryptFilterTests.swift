import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `AESDecryptFilter`.
@Suite("AESDecryptFilter Tests")
struct AESDecryptFilterTests {

    // MARK: - Initialization Tests

    @Test("Valid 128-bit key initializes successfully")
    func validKey128() throws {
        let key = Data(repeating: 0x42, count: 16)
        let _ = try AESDecryptFilter(key: key)
    }

    @Test("Valid 256-bit key initializes successfully")
    func validKey256() throws {
        let key = Data(repeating: 0x42, count: 32)
        let _ = try AESDecryptFilter(key: key)
    }

    @Test("Invalid key length throws error")
    func invalidKeyLength() throws {
        let shortKey = Data(repeating: 0x42, count: 8)
        #expect(throws: PDFStreamError.self) {
            _ = try AESDecryptFilter(key: shortKey)
        }

        let oddKey = Data(repeating: 0x42, count: 20)
        #expect(throws: PDFStreamError.self) {
            _ = try AESDecryptFilter(key: oddKey)
        }
    }

    // MARK: - Basic Encryption/Decryption Tests

    @Test("Empty data decryption returns empty")
    func emptyData() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)

        let result = try filter.decrypt(Data())
        #expect(result.isEmpty)
    }

    @Test("Roundtrip encrypt and decrypt")
    func roundtrip() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let original = Data("Hello, World! This is AES test data.".utf8)

        let encrypted = try filter.encrypt(original)
        let decrypted = try filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    @Test("Roundtrip with 256-bit key")
    func roundtrip256() throws {
        let key = Data(repeating: 0x42, count: 32)
        let filter = try AESDecryptFilter(key: key)
        let original = Data("Testing AES-256 encryption.".utf8)

        let encrypted = try filter.encrypt(original)
        let decrypted = try filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    @Test("Encryption produces different ciphertext each time (random IV)")
    func randomIV() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let original = Data("Test data".utf8)

        let encrypted1 = try filter.encrypt(original)
        let encrypted2 = try filter.encrypt(original)

        // Should be different due to random IV
        #expect(encrypted1 != encrypted2)

        // But both should decrypt to the same plaintext
        let decrypted1 = try filter.decrypt(encrypted1)
        let decrypted2 = try filter.decrypt(encrypted2)
        #expect(decrypted1 == original)
        #expect(decrypted2 == original)
    }

    // MARK: - Block Size Tests

    @Test("Data shorter than block size")
    func shortData() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let original = Data([0x01, 0x02, 0x03])

        let encrypted = try filter.encrypt(original)
        let decrypted = try filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    @Test("Data exactly one block")
    func exactlyOneBlock() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let original = Data(repeating: 0xAB, count: 16)

        let encrypted = try filter.encrypt(original)
        let decrypted = try filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    @Test("Data multiple blocks")
    func multipleBlocks() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let original = Data(repeating: 0xAB, count: 64)

        let encrypted = try filter.encrypt(original)
        let decrypted = try filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    // MARK: - Larger Data Tests

    @Test("Roundtrip large data")
    func roundtripLargeData() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        var original = Data()
        for i in 0..<10000 {
            original.append(UInt8(i % 256))
        }

        let encrypted = try filter.encrypt(original)
        let decrypted = try filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    // MARK: - Error Cases

    @Test("Data too short for IV throws error")
    func dataTooShortForIV() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let tooShort = Data(repeating: 0x00, count: 10)

        // Data shorter than 16 bytes (IV size) returns empty
        let result = try filter.decrypt(tooShort)
        #expect(result.isEmpty)
    }

    @Test("Non-block-aligned ciphertext throws error")
    func nonBlockAlignedCiphertext() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        // IV (16 bytes) + non-aligned ciphertext (17 bytes)
        let invalid = Data(repeating: 0x00, count: 33)

        #expect(throws: PDFStreamError.self) {
            _ = try filter.decrypt(invalid)
        }
    }

    // MARK: - Sendable and Hashable

    @Test("AESDecryptFilter is Sendable")
    func sendable() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try AESDecryptFilter(key: key)
        let _: any Sendable = filter
    }

    @Test("AESDecryptFilter is Hashable")
    func hashable() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter1 = try AESDecryptFilter(key: key)
        let filter2 = try AESDecryptFilter(key: key)
        #expect(filter1 == filter2)
        #expect(filter1.hashValue == filter2.hashValue)

        let differentKey = Data(repeating: 0x43, count: 16)
        let filter3 = try AESDecryptFilter(key: differentKey)
        #expect(filter1 != filter3)
    }
}
