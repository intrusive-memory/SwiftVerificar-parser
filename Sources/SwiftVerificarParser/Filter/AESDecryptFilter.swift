import Foundation
import CryptoKit

/// A filter that decrypts data using AES (Advanced Encryption Standard).
///
/// `AESDecryptFilter` corresponds to the Java `COSFilterAESDecryptionDefault` class
/// from veraPDF-parser. It implements AES decryption for PDF encryption handlers
/// as specified in PDF 1.5+ (ISO 32000).
///
/// PDF uses AES in CBC mode with PKCS#7 padding. The initialization vector (IV)
/// is stored as the first 16 bytes of the encrypted data.
///
/// ## PDF Specification
/// - AES-128 (128-bit key, PDF 1.5+)
/// - AES-256 (256-bit key, PDF 1.6+ / PDF 2.0)
/// - CBC mode with PKCS#7 padding
/// - IV is prepended to the ciphertext (first 16 bytes)
///
/// ## Usage
/// ```swift
/// let filter = AESDecryptFilter(key: encryptionKey)
/// let decrypted = try filter.decrypt(encryptedData)
/// ```
///
/// ## Security Note
/// This filter is used for decrypting PDF streams and strings as part of the
/// PDF encryption standard. The key must be derived from the document's encryption
/// dictionary using the appropriate security handler.
public struct AESDecryptFilter: Sendable {

    // MARK: - Constants

    /// AES block size in bytes.
    public static let blockSize = 16

    /// AES-128 key size in bytes.
    public static let key128Size = 16

    /// AES-256 key size in bytes.
    public static let key256Size = 32

    // MARK: - Properties

    /// The encryption key (16 or 32 bytes for AES-128 or AES-256).
    private let key: Data

    // MARK: - Initialization

    /// Creates an AES decrypt filter with the given key.
    ///
    /// - Parameter key: The AES encryption key (16 bytes for AES-128, 32 bytes for AES-256).
    /// - Throws: `PDFStreamError.filterError` if the key length is invalid.
    public init(key: Data) throws {
        guard key.count == Self.key128Size || key.count == Self.key256Size else {
            throw PDFStreamError.filterError("AESDecryptFilter: Invalid key length \(key.count). Must be 16 (AES-128) or 32 (AES-256) bytes.")
        }
        self.key = key
    }

    // MARK: - Decryption

    /// Decrypts AES-encrypted data.
    ///
    /// The input data must contain the 16-byte IV followed by the ciphertext.
    /// The ciphertext must be a multiple of 16 bytes (AES block size).
    ///
    /// - Parameter data: The encrypted data (IV + ciphertext).
    /// - Returns: The decrypted plaintext data.
    /// - Throws: `PDFStreamError.filterError` if decryption fails.
    public func decrypt(_ data: Data) throws -> Data {
        // Need at least IV (16 bytes) + one block of data
        guard data.count >= Self.blockSize else {
            // Empty or very short data - return as-is
            return Data()
        }

        // Extract IV from first 16 bytes
        let iv = data.prefix(Self.blockSize)
        let ciphertext = data.dropFirst(Self.blockSize)

        // Ciphertext must be a multiple of block size
        guard ciphertext.count % Self.blockSize == 0 else {
            throw PDFStreamError.filterError("AESDecryptFilter: Ciphertext length (\(ciphertext.count)) is not a multiple of block size")
        }

        guard !ciphertext.isEmpty else {
            return Data()
        }

        // Perform AES-CBC decryption
        return try decryptCBC(ciphertext: Data(ciphertext), iv: Data(iv))
    }

    /// Decrypts data with optional parameters.
    ///
    /// - Parameters:
    ///   - data: The encrypted data.
    ///   - parameters: Optional decode parameters (currently unused for AES).
    /// - Returns: The decrypted data.
    /// - Throws: `PDFStreamError.filterError` if decryption fails.
    public func decrypt(_ data: Data, parameters: COSValue?) throws -> Data {
        return try decrypt(data)
    }

    // MARK: - Encryption

    /// Encrypts data using AES-CBC.
    ///
    /// Generates a random IV and prepends it to the ciphertext.
    ///
    /// - Parameter data: The plaintext data to encrypt.
    /// - Returns: The encrypted data (IV + ciphertext).
    /// - Throws: `PDFStreamError.filterError` if encryption fails.
    public func encrypt(_ data: Data) throws -> Data {
        // Generate random IV
        var ivBytes = [UInt8](repeating: 0, count: Self.blockSize)
        let status = SecRandomCopyBytes(kSecRandomDefault, Self.blockSize, &ivBytes)
        guard status == errSecSuccess else {
            throw PDFStreamError.filterError("AESDecryptFilter: Failed to generate random IV")
        }
        let iv = Data(ivBytes)

        // Encrypt with PKCS#7 padding
        let ciphertext = try encryptCBC(plaintext: data, iv: iv)

        // Prepend IV to ciphertext
        return iv + ciphertext
    }

    /// Encrypts data with optional parameters.
    ///
    /// - Parameters:
    ///   - data: The plaintext data to encrypt.
    ///   - parameters: Optional encode parameters (currently unused for AES).
    /// - Returns: The encrypted data.
    /// - Throws: `PDFStreamError.filterError` if encryption fails.
    public func encrypt(_ data: Data, parameters: COSValue?) throws -> Data {
        return try encrypt(data)
    }

    // MARK: - Private Implementation

    /// Decrypts ciphertext using AES-CBC and removes PKCS#7 padding.
    private func decryptCBC(ciphertext: Data, iv: Data) throws -> Data {
        guard ciphertext.count % Self.blockSize == 0 else {
            throw PDFStreamError.filterError("AESDecryptFilter: Invalid ciphertext length")
        }

        var plaintext = Data()
        var previousBlock = iv

        // Process each block
        for blockStart in stride(from: 0, to: ciphertext.count, by: Self.blockSize) {
            let blockEnd = blockStart + Self.blockSize
            let encryptedBlock = ciphertext[blockStart..<blockEnd]

            // Decrypt block using ECB mode (single block)
            let decryptedBlock = try decryptBlock(Data(encryptedBlock))

            // XOR with previous ciphertext block (CBC mode)
            var xoredBlock = Data(count: Self.blockSize)
            for i in 0..<Self.blockSize {
                xoredBlock[i] = decryptedBlock[i] ^ previousBlock[previousBlock.startIndex + i]
            }

            plaintext.append(xoredBlock)
            previousBlock = Data(encryptedBlock)
        }

        // Remove PKCS#7 padding
        return try removePKCS7Padding(plaintext)
    }

    /// Encrypts plaintext using AES-CBC with PKCS#7 padding.
    private func encryptCBC(plaintext: Data, iv: Data) throws -> Data {
        // Add PKCS#7 padding
        let paddedData = addPKCS7Padding(plaintext)

        var ciphertext = Data()
        var previousBlock = iv

        // Process each block
        for blockStart in stride(from: 0, to: paddedData.count, by: Self.blockSize) {
            let blockEnd = blockStart + Self.blockSize
            let plaintextBlock = paddedData[blockStart..<blockEnd]

            // XOR with previous ciphertext block (CBC mode)
            var xoredBlock = Data(count: Self.blockSize)
            for i in 0..<Self.blockSize {
                xoredBlock[i] = plaintextBlock[plaintextBlock.startIndex + i] ^ previousBlock[previousBlock.startIndex + i]
            }

            // Encrypt block using ECB mode (single block)
            let encryptedBlock = try encryptBlock(xoredBlock)

            ciphertext.append(encryptedBlock)
            previousBlock = encryptedBlock
        }

        return ciphertext
    }

    /// Decrypts a single AES block using CommonCrypto.
    private func decryptBlock(_ block: Data) throws -> Data {
        // CryptoKit doesn't expose raw AES block cipher (ECB mode).
        // For PDF CBC mode, we need raw AES-ECB for single block decryption.
        // We use CommonCrypto's CCCrypt for this.
        return try aesDecryptECB(block, key: key)
    }

    /// Encrypts a single AES block using CryptoKit.
    private func encryptBlock(_ block: Data) throws -> Data {
        return try aesEncryptECB(block, key: key)
    }

    /// Adds PKCS#7 padding to data.
    private func addPKCS7Padding(_ data: Data) -> Data {
        let paddingLength = Self.blockSize - (data.count % Self.blockSize)
        let padding = Data(repeating: UInt8(paddingLength), count: paddingLength)
        return data + padding
    }

    /// Removes PKCS#7 padding from data.
    private func removePKCS7Padding(_ data: Data) throws -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        let paddingLength = Int(data[data.count - 1])

        // Validate padding
        guard paddingLength >= 1 && paddingLength <= Self.blockSize else {
            throw PDFStreamError.filterError("AESDecryptFilter: Invalid PKCS#7 padding value \(paddingLength)")
        }

        guard data.count >= paddingLength else {
            throw PDFStreamError.filterError("AESDecryptFilter: Padding length exceeds data length")
        }

        // Verify all padding bytes have the same value
        for i in 0..<paddingLength {
            if data[data.count - 1 - i] != UInt8(paddingLength) {
                throw PDFStreamError.filterError("AESDecryptFilter: Invalid PKCS#7 padding bytes")
            }
        }

        return data.prefix(data.count - paddingLength)
    }

    /// AES-ECB decryption using Security framework (CommonCrypto).
    private func aesDecryptECB(_ block: Data, key: Data) throws -> Data {
        var outBuffer = [UInt8](repeating: 0, count: Self.blockSize)
        var outLength = 0

        let status = block.withUnsafeBytes { blockPtr in
            key.withUnsafeBytes { keyPtr in
                CCCrypt(
                    CCOperation(kCCDecrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionECBMode),
                    keyPtr.baseAddress,
                    key.count,
                    nil,  // No IV for ECB
                    blockPtr.baseAddress,
                    block.count,
                    &outBuffer,
                    outBuffer.count,
                    &outLength
                )
            }
        }

        guard status == kCCSuccess else {
            throw PDFStreamError.filterError("AESDecryptFilter: ECB decryption failed with status \(status)")
        }

        return Data(outBuffer.prefix(outLength))
    }

    /// AES-ECB encryption using Security framework (CommonCrypto).
    private func aesEncryptECB(_ block: Data, key: Data) throws -> Data {
        var outBuffer = [UInt8](repeating: 0, count: Self.blockSize + kCCBlockSizeAES128)
        var outLength = 0

        let status = block.withUnsafeBytes { blockPtr in
            key.withUnsafeBytes { keyPtr in
                CCCrypt(
                    CCOperation(kCCEncrypt),
                    CCAlgorithm(kCCAlgorithmAES),
                    CCOptions(kCCOptionECBMode),
                    keyPtr.baseAddress,
                    key.count,
                    nil,  // No IV for ECB
                    blockPtr.baseAddress,
                    block.count,
                    &outBuffer,
                    outBuffer.count,
                    &outLength
                )
            }
        }

        guard status == kCCSuccess else {
            throw PDFStreamError.filterError("AESDecryptFilter: ECB encryption failed with status \(status)")
        }

        return Data(outBuffer.prefix(outLength))
    }
}

// MARK: - Hashable Conformance

extension AESDecryptFilter: Hashable {
    public static func == (lhs: AESDecryptFilter, rhs: AESDecryptFilter) -> Bool {
        lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

// MARK: - CommonCrypto Interop

// These constants are from CommonCrypto but we define them here to avoid
// importing the entire framework header.
private let kCCSuccess: Int32 = 0
private let kCCDecrypt: Int = 1
private let kCCEncrypt: Int = 0
private let kCCAlgorithmAES: Int = 0
private let kCCOptionECBMode: Int = 2
private let kCCBlockSizeAES128 = 16

/// CommonCrypto CCCrypt function signature.
@_silgen_name("CCCrypt")
private func CCCrypt(
    _ op: Int,
    _ alg: Int,
    _ options: Int,
    _ key: UnsafeRawPointer?,
    _ keyLength: Int,
    _ iv: UnsafeRawPointer?,
    _ dataIn: UnsafeRawPointer?,
    _ dataInLength: Int,
    _ dataOut: UnsafeMutableRawPointer?,
    _ dataOutAvailable: Int,
    _ dataOutMoved: UnsafeMutablePointer<Int>?
) -> Int32

private typealias CCOperation = Int
private typealias CCAlgorithm = Int
private typealias CCOptions = Int
