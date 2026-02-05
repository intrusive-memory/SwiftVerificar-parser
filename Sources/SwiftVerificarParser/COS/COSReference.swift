import Foundation

/// Represents an indirect object reference in a PDF document.
///
/// In PDF, indirect references allow objects to be shared and referenced
/// by their object number and generation number without embedding the
/// full object value at each usage site. The syntax in a PDF file is:
///
///     objectNumber generationNumber R
///
/// For example, `42 0 R` refers to object 42 at generation 0.
///
/// This type corresponds to the Java `COSIndirect` class from veraPDF-parser
/// and is composed with `COSObjectKey` which provides the object/generation
/// number pair.
///
/// ## Usage
/// ```swift
/// let ref = COSReference(objectNumber: 42, generation: 0)
/// let sameRef = COSReference(key: COSObjectKey(objectNumber: 42))
/// assert(ref == sameRef)
/// ```
public struct COSReference: Sendable, Hashable, Codable, CustomStringConvertible {

    // MARK: - Properties

    /// The object key identifying this reference (object number + generation).
    public let key: COSObjectKey

    // MARK: - Initialization

    /// Creates a reference from an existing `COSObjectKey`.
    ///
    /// - Parameter key: The object key for this reference.
    public init(key: COSObjectKey) {
        self.key = key
    }

    /// Creates a reference from an object number and generation number.
    ///
    /// - Parameters:
    ///   - objectNumber: The object number.
    ///   - generation: The generation number. Defaults to 0.
    public init(objectNumber: Int, generation: Int = 0) {
        self.key = COSObjectKey(objectNumber: objectNumber, generation: generation)
    }

    // MARK: - Convenience Properties

    /// The object number of this reference.
    public var objectNumber: Int {
        key.objectNumber
    }

    /// The generation number of this reference.
    public var generation: Int {
        key.generation
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        "\(objectNumber) \(generation) R"
    }
}
