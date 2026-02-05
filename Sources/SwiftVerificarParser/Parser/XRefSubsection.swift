import Foundation

/// Represents a subsection of a PDF cross-reference table.
///
/// A cross-reference table is divided into one or more subsections, each
/// describing a contiguous range of object numbers. A subsection header
/// specifies the starting object number and the count of entries:
///
/// ```
/// xref
/// 0 6        ← subsection: start=0, count=6
/// 0000000000 65535 f
/// 0000000009 00000 n
/// 0000000074 00000 n
/// ...
/// 10 3       ← subsection: start=10, count=3
/// 0000001234 00000 n
/// 0000001500 00000 n
/// 0000001750 00000 n
/// ```
///
/// Each subsection contains:
/// - `startObjectNumber`: The first object number in this subsection
/// - `entries`: An array of `XRefEntry` values (one per object)
///
/// The subsection describes objects from `startObjectNumber` to
/// `startObjectNumber + entries.count - 1` (inclusive).
///
/// This type consolidates the Java `COSXRefSection` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let entries: [XRefEntry] = [
///     .free(nextFreeObjectNumber: 0, generation: 65535),
///     .inUse(offset: 9, generation: 0),
///     .inUse(offset: 74, generation: 0)
/// ]
/// let subsection = XRefSubsection(startObjectNumber: 0, entries: entries)
/// ```
public struct XRefSubsection: Sendable, Hashable, CustomStringConvertible {

    // MARK: - Properties

    /// The first object number described by this subsection.
    public let startObjectNumber: Int

    /// The cross-reference entries for this subsection.
    ///
    /// The array contains one entry per object, starting from `startObjectNumber`.
    /// For example, if `startObjectNumber` is 10 and `entries.count` is 3,
    /// this subsection describes objects 10, 11, and 12.
    public let entries: [XRefEntry]

    // MARK: - Initialization

    /// Creates a cross-reference subsection with the given start object number and entries.
    ///
    /// - Parameters:
    ///   - startObjectNumber: The first object number in this subsection.
    ///   - entries: The array of cross-reference entries (must not be empty).
    /// - Precondition: `entries` must not be empty.
    public init(startObjectNumber: Int, entries: [XRefEntry]) {
        precondition(!entries.isEmpty, "XRefSubsection entries must not be empty")
        self.startObjectNumber = startObjectNumber
        self.entries = entries
    }

    // MARK: - Computed Properties

    /// The number of entries in this subsection.
    public var count: Int {
        entries.count
    }

    /// The last object number described by this subsection (inclusive).
    public var endObjectNumber: Int {
        startObjectNumber + count - 1
    }

    /// The range of object numbers described by this subsection.
    public var objectRange: Range<Int> {
        startObjectNumber ..< (startObjectNumber + count)
    }

    // MARK: - Entry Access

    /// Returns the cross-reference entry for the given object number.
    ///
    /// - Parameter objectNumber: The object number to look up.
    /// - Returns: The entry for that object number, or `nil` if the object
    ///   number is outside this subsection's range.
    public func entry(for objectNumber: Int) -> XRefEntry? {
        guard objectRange.contains(objectNumber) else {
            return nil
        }
        let index = objectNumber - startObjectNumber
        return entries[index]
    }

    /// Subscript access to entries by object number.
    ///
    /// - Parameter objectNumber: The object number to look up.
    /// - Returns: The entry for that object number, or `nil` if out of range.
    public subscript(objectNumber: Int) -> XRefEntry? {
        entry(for: objectNumber)
    }

    // MARK: - Validation

    /// Whether this subsection contains the given object number.
    ///
    /// - Parameter objectNumber: The object number to check.
    /// - Returns: `true` if the object number is in this subsection's range.
    public func contains(objectNumber: Int) -> Bool {
        objectRange.contains(objectNumber)
    }

    // MARK: - Statistics

    /// The number of in-use entries in this subsection.
    public var inUseCount: Int {
        entries.filter(\.isInUse).count
    }

    /// The number of free entries in this subsection.
    public var freeCount: Int {
        entries.filter(\.isFree).count
    }

    /// The number of compressed entries in this subsection.
    public var compressedCount: Int {
        entries.filter(\.isCompressed).count
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        "subsection(start: \(startObjectNumber), count: \(count))"
    }
}
