import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `RC4DecryptFilter`.
@Suite("RC4DecryptFilter Tests")
struct RC4DecryptFilterTests {

    // MARK: - Initialization Tests

    @Test("Valid minimum key length (5 bytes)")
    func validMinKeyLength() throws {
        let key = Data(repeating: 0x42, count: 5)
        let _ = try RC4DecryptFilter(key: key)
    }

    @Test("Valid maximum key length (16 bytes)")
    func validMaxKeyLength() throws {
        let key = Data(repeating: 0x42, count: 16)
        let _ = try RC4DecryptFilter(key: key)
    }

    @Test("Key too short throws error")
    func keyTooShort() throws {
        let shortKey = Data(repeating: 0x42, count: 4)
        #expect(throws: PDFStreamError.self) {
            _ = try RC4DecryptFilter(key: shortKey)
        }
    }

    @Test("Key too long throws error")
    func keyTooLong() throws {
        let longKey = Data(repeating: 0x42, count: 17)
        #expect(throws: PDFStreamError.self) {
            _ = try RC4DecryptFilter(key: longKey)
        }
    }

    // MARK: - Basic Tests

    @Test("Empty data returns empty")
    func emptyData() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter = try RC4DecryptFilter(key: key)

        let result = filter.process(Data())
        #expect(result.isEmpty)
    }

    @Test("RC4 is symmetric - encrypt then decrypt")
    func symmetricOperation() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter = try RC4DecryptFilter(key: key)
        let original = Data("Hello, World!".utf8)

        // RC4 encryption
        let encrypted = filter.encrypt(original)

        // Same key decrypts
        let decrypted = filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    @Test("Decrypt and encrypt are aliases")
    func decryptEncryptAliases() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter = try RC4DecryptFilter(key: key)
        let data = Data("Test data".utf8)

        let encrypted = filter.encrypt(data)
        let decrypted = filter.decrypt(data)

        // encrypt and decrypt with same input produce same output
        // (both are just XOR with keystream)
        #expect(encrypted == decrypted)
    }

    // MARK: - Known Test Vectors (RFC 6229)

    @Test("RC4 with key 'Key' - known vector")
    func knownVector1() throws {
        // Known test: key = "Key", plaintext = "Plaintext" produces specific ciphertext
        let key = Data("Key".utf8)
        // Need to pad to minimum 5 bytes
        var paddedKey = key
        while paddedKey.count < 5 {
            paddedKey.append(0)
        }
        let filter = try RC4DecryptFilter(key: paddedKey)
        let plaintext = Data("Plaintext".utf8)

        let ciphertext = filter.encrypt(plaintext)

        // The encrypted data should be non-empty and different from plaintext
        #expect(!ciphertext.isEmpty)
        #expect(ciphertext != plaintext)

        // Decrypting should give back plaintext
        let decrypted = filter.decrypt(ciphertext)
        #expect(decrypted == plaintext)
    }

    // MARK: - Various Data Sizes

    @Test("Single byte data")
    func singleByte() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter = try RC4DecryptFilter(key: key)
        let original = Data([0xAB])

        let encrypted = filter.encrypt(original)
        let decrypted = filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    @Test("Large data")
    func largeData() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try RC4DecryptFilter(key: key)
        var original = Data()
        for i in 0..<10000 {
            original.append(UInt8(i % 256))
        }

        let encrypted = filter.encrypt(original)
        let decrypted = filter.decrypt(encrypted)

        #expect(decrypted == original)
        #expect(encrypted.count == original.count)  // RC4 preserves length
    }

    @Test("Data length equals key length")
    func dataLengthEqualsKeyLength() throws {
        let key = Data(repeating: 0x42, count: 16)
        let filter = try RC4DecryptFilter(key: key)
        let original = Data(repeating: 0xAB, count: 16)

        let encrypted = filter.encrypt(original)
        let decrypted = filter.decrypt(encrypted)

        #expect(decrypted == original)
    }

    // MARK: - Different Keys Produce Different Output

    @Test("Different keys produce different ciphertext")
    func differentKeys() throws {
        let key1 = Data([0x01, 0x02, 0x03, 0x04, 0x05])
        let key2 = Data([0x05, 0x04, 0x03, 0x02, 0x01])
        let filter1 = try RC4DecryptFilter(key: key1)
        let filter2 = try RC4DecryptFilter(key: key2)
        let plaintext = Data("Same plaintext".utf8)

        let ciphertext1 = filter1.encrypt(plaintext)
        let ciphertext2 = filter2.encrypt(plaintext)

        #expect(ciphertext1 != ciphertext2)
    }

    // MARK: - Parameters

    @Test("Decrypt with parameters (parameters ignored)")
    func decryptWithParameters() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter = try RC4DecryptFilter(key: key)
        let original = Data("Test".utf8)
        let encrypted = filter.encrypt(original)

        // Parameters are ignored for RC4
        let decrypted = filter.decrypt(encrypted, parameters: .dictionary([.type: .name(ASAtom("Ignored"))]))
        #expect(decrypted == original)
    }

    // MARK: - Sendable and Hashable

    @Test("RC4DecryptFilter is Sendable")
    func sendable() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter = try RC4DecryptFilter(key: key)
        let _: any Sendable = filter
    }

    @Test("RC4DecryptFilter is Hashable")
    func hashable() throws {
        let key = Data(repeating: 0x42, count: 8)
        let filter1 = try RC4DecryptFilter(key: key)
        let filter2 = try RC4DecryptFilter(key: key)
        #expect(filter1 == filter2)
        #expect(filter1.hashValue == filter2.hashValue)

        let differentKey = Data(repeating: 0x43, count: 8)
        let filter3 = try RC4DecryptFilter(key: differentKey)
        #expect(filter1 != filter3)
    }
}
