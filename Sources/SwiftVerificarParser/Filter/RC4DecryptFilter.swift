import Foundation

/// A filter that encrypts/decrypts data using the RC4 stream cipher.
///
/// `RC4DecryptFilter` corresponds to the Java `COSFilterRC4DecryptionDefault` class
/// from veraPDF-parser. It implements RC4 encryption for PDF encryption handlers
/// as specified in PDF 1.1-1.4 (ISO 32000).
///
/// RC4 is a symmetric stream cipher. It was used in PDF encryption through revision 3
/// (40-bit and 128-bit keys). PDF 1.5+ deprecated RC4 in favor of AES, and PDF 2.0
/// disallows RC4 entirely.
///
/// ## PDF Specification
/// - Key length: 5 to 16 bytes (40 to 128 bits)
/// - No IV required (stream cipher)
/// - Same operation for encryption and decryption (XOR-based)
///
/// ## Usage
/// ```swift
/// let filter = RC4DecryptFilter(key: encryptionKey)
/// let decrypted = filter.process(encryptedData)
/// let encrypted = filter.process(plaintextData)  // Same operation
/// ```
///
/// ## Security Note
/// RC4 is considered cryptographically weak and should not be used for new
/// documents. This implementation exists solely for reading legacy PDF files.
public struct RC4DecryptFilter: Sendable {

    // MARK: - Constants

    /// Minimum key length in bytes (40 bits).
    public static let minKeyLength = 5

    /// Maximum key length in bytes (128 bits).
    public static let maxKeyLength = 16

    // MARK: - Properties

    /// The encryption key (5-16 bytes).
    private let key: Data

    // MARK: - Initialization

    /// Creates an RC4 decrypt filter with the given key.
    ///
    /// - Parameter key: The RC4 encryption key (5 to 16 bytes).
    /// - Throws: `PDFStreamError.filterError` if the key length is invalid.
    public init(key: Data) throws {
        guard key.count >= Self.minKeyLength && key.count <= Self.maxKeyLength else {
            throw PDFStreamError.filterError("RC4DecryptFilter: Invalid key length \(key.count). Must be 5-16 bytes.")
        }
        self.key = key
    }

    // MARK: - Processing

    /// Processes (encrypts or decrypts) data using RC4.
    ///
    /// RC4 is symmetric: encryption and decryption use the same operation.
    /// The keystream is XORed with the input to produce the output.
    ///
    /// - Parameter data: The input data.
    /// - Returns: The processed output data.
    public func process(_ data: Data) -> Data {
        guard !data.isEmpty else {
            return Data()
        }

        // Initialize the S-box (permutation of 0-255)
        var state = RC4State(key: key)

        // Generate keystream and XOR with input
        var result = Data(count: data.count)
        for i in 0..<data.count {
            result[i] = data[i] ^ state.nextByte()
        }

        return result
    }

    /// Decrypts data using RC4.
    ///
    /// This is an alias for `process(_:)` since RC4 encryption and decryption
    /// are identical operations.
    ///
    /// - Parameter data: The encrypted data.
    /// - Returns: The decrypted data.
    public func decrypt(_ data: Data) -> Data {
        process(data)
    }

    /// Decrypts data with optional parameters.
    ///
    /// - Parameters:
    ///   - data: The encrypted data.
    ///   - parameters: Optional decode parameters (unused for RC4).
    /// - Returns: The decrypted data.
    public func decrypt(_ data: Data, parameters: COSValue?) -> Data {
        process(data)
    }

    /// Encrypts data using RC4.
    ///
    /// This is an alias for `process(_:)` since RC4 encryption and decryption
    /// are identical operations.
    ///
    /// - Parameter data: The plaintext data.
    /// - Returns: The encrypted data.
    public func encrypt(_ data: Data) -> Data {
        process(data)
    }

    /// Encrypts data with optional parameters.
    ///
    /// - Parameters:
    ///   - data: The plaintext data.
    ///   - parameters: Optional encode parameters (unused for RC4).
    /// - Returns: The encrypted data.
    public func encrypt(_ data: Data, parameters: COSValue?) -> Data {
        process(data)
    }
}

// MARK: - Hashable Conformance

extension RC4DecryptFilter: Hashable {
    public static func == (lhs: RC4DecryptFilter, rhs: RC4DecryptFilter) -> Bool {
        lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}

// MARK: - RC4State

/// Internal state machine for RC4 keystream generation.
///
/// The RC4 algorithm uses:
/// 1. Key-Scheduling Algorithm (KSA) to initialize the S-box
/// 2. Pseudo-Random Generation Algorithm (PRGA) to generate keystream bytes
private struct RC4State {
    /// The S-box (permutation array).
    private var sBox: [UInt8]

    /// Index i for PRGA.
    private var i: Int = 0

    /// Index j for PRGA.
    private var j: Int = 0

    /// Creates a new RC4 state initialized with the given key.
    ///
    /// This performs the Key-Scheduling Algorithm (KSA) to set up the S-box.
    init(key: Data) {
        // Initialize S-box with identity permutation
        sBox = [UInt8](0...255)

        // Key-Scheduling Algorithm (KSA)
        var j = 0
        for i in 0..<256 {
            j = (j + Int(sBox[i]) + Int(key[i % key.count])) & 0xFF
            sBox.swapAt(i, j)
        }
    }

    /// Generates and returns the next keystream byte.
    ///
    /// This implements the Pseudo-Random Generation Algorithm (PRGA).
    mutating func nextByte() -> UInt8 {
        i = (i + 1) & 0xFF
        j = (j + Int(sBox[i])) & 0xFF
        sBox.swapAt(i, j)
        let k = (Int(sBox[i]) + Int(sBox[j])) & 0xFF
        return sBox[k]
    }
}
