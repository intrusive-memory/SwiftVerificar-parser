import Foundation

/// Identifies a PDF indirect object by its object number and generation number.
///
/// In PDF, indirect objects are referenced by a pair of integers:
/// - **Object number**: A positive integer uniquely identifying the object.
/// - **Generation number**: A non-negative integer indicating the generation
///   (typically 0 for most objects, incremented when objects are reused in
///   incremental updates).
///
/// This type corresponds to the Java `COSKey` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let key = COSObjectKey(objectNumber: 42, generation: 0)
/// // In cross-reference tables, used to look up object byte offsets
/// ```
public struct COSObjectKey: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {

    // MARK: - Properties

    /// The object number (a positive integer in valid PDFs).
    public let objectNumber: Int

    /// The generation number (a non-negative integer in valid PDFs).
    public let generation: Int

    // MARK: - Initialization

    /// Creates a new object key with the given object and generation numbers.
    ///
    /// - Parameters:
    ///   - objectNumber: The object number.
    ///   - generation: The generation number. Defaults to 0.
    public init(objectNumber: Int, generation: Int = 0) {
        self.objectNumber = objectNumber
        self.generation = generation
    }

    // MARK: - Comparable

    /// Compares object keys first by object number, then by generation.
    public static func < (lhs: COSObjectKey, rhs: COSObjectKey) -> Bool {
        if lhs.objectNumber != rhs.objectNumber {
            return lhs.objectNumber < rhs.objectNumber
        }
        return lhs.generation < rhs.generation
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        "\(objectNumber) \(generation) R"
    }
}
