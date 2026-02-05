import Foundation

/// Represents a single entry in a PDF cross-reference table.
///
/// The cross-reference (xref) table is a core PDF data structure that maps
/// object numbers to byte offsets in the file. Each entry describes either:
/// - An **in-use** object (with its file offset and generation number)
/// - A **free** object (available for reuse)
/// - A **compressed** object (stored in an object stream)
///
/// The PDF specification (ISO 32000-2:2020, Section 7.5.4) defines three
/// entry types:
///
/// 1. **In-use entry** (type 1 or 'n'):
///    - `offset`: Byte offset of the object in the file
///    - `generation`: Generation number
///
/// 2. **Free entry** (type 0 or 'f'):
///    - `nextFreeObjectNumber`: Object number of next free object
///    - `generation`: Generation number to use when reusing
///
/// 3. **Compressed entry** (type 2):
///    - `objectStreamNumber`: Object number of containing object stream
///    - `index`: Index within the object stream
///
/// This type consolidates the Java `COSXRefEntry` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// // In-use object at offset 1234
/// let inUse = XRefEntry.inUse(offset: 1234, generation: 0)
///
/// // Free object
/// let free = XRefEntry.free(nextFreeObjectNumber: 5, generation: 65535)
///
/// // Compressed object
/// let compressed = XRefEntry.compressed(objectStreamNumber: 10, index: 3)
/// ```
public enum XRefEntry: Sendable, Hashable, CustomStringConvertible {

    // MARK: - Cases

    /// An in-use entry pointing to an object at a specific byte offset.
    ///
    /// - Parameters:
    ///   - offset: Byte offset of the object in the file (must be non-negative).
    ///   - generation: Generation number of the object (typically 0-65535).
    case inUse(offset: Int64, generation: Int)

    /// A free entry indicating an unused object number.
    ///
    /// Free entries form a linked list through the file, where each free entry
    /// points to the next free object number. The head of the list is object 0.
    ///
    /// - Parameters:
    ///   - nextFreeObjectNumber: Object number of the next free entry in the list.
    ///   - generation: Generation number to use when this entry is reused.
    case free(nextFreeObjectNumber: Int, generation: Int)

    /// A compressed entry pointing to an object stored in an object stream.
    ///
    /// Object streams (PDF 1.5+) allow multiple objects to be compressed together.
    /// This entry type identifies which object stream contains the object and
    /// its index within that stream.
    ///
    /// - Parameters:
    ///   - objectStreamNumber: Object number of the containing object stream.
    ///   - index: Zero-based index of this object within the stream.
    case compressed(objectStreamNumber: Int, index: Int)

    // MARK: - Type Checking

    /// Whether this entry is in use (type 1 or 'n').
    public var isInUse: Bool {
        if case .inUse = self { return true }
        return false
    }

    /// Whether this entry is free (type 0 or 'f').
    public var isFree: Bool {
        if case .free = self { return true }
        return false
    }

    /// Whether this entry is compressed (type 2).
    public var isCompressed: Bool {
        if case .compressed = self { return true }
        return false
    }

    // MARK: - Value Extraction

    /// The byte offset for an in-use entry, or `nil` for other types.
    public var offset: Int64? {
        if case .inUse(let offset, _) = self { return offset }
        return nil
    }

    /// The generation number for in-use or free entries, or `nil` for compressed.
    public var generation: Int? {
        switch self {
        case .inUse(_, let gen), .free(_, let gen):
            return gen
        case .compressed:
            return nil
        }
    }

    /// The next free object number for free entries, or `nil` for other types.
    public var nextFreeObjectNumber: Int? {
        if case .free(let next, _) = self { return next }
        return nil
    }

    /// The object stream number for compressed entries, or `nil` for other types.
    public var objectStreamNumber: Int? {
        if case .compressed(let streamNum, _) = self { return streamNum }
        return nil
    }

    /// The index within an object stream for compressed entries, or `nil` for other types.
    public var index: Int? {
        if case .compressed(_, let idx) = self { return idx }
        return nil
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .inUse(let offset, let gen):
            return "inUse(offset: \(offset), gen: \(gen))"
        case .free(let next, let gen):
            return "free(next: \(next), gen: \(gen))"
        case .compressed(let streamNum, let idx):
            return "compressed(stream: \(streamNum), index: \(idx))"
        }
    }
}

// MARK: - Convenience Initializers

extension XRefEntry {

    /// Creates an in-use entry with the given offset and default generation 0.
    ///
    /// - Parameter offset: Byte offset of the object in the file.
    /// - Returns: An in-use entry.
    public static func inUse(offset: Int64) -> XRefEntry {
        .inUse(offset: offset, generation: 0)
    }

    /// Creates a free entry with default generation 65535.
    ///
    /// Generation 65535 is the maximum generation number allowed in PDF,
    /// typically used for never-reused free entries.
    ///
    /// - Parameter nextFreeObjectNumber: Object number of the next free entry.
    /// - Returns: A free entry.
    public static func free(nextFreeObjectNumber: Int) -> XRefEntry {
        .free(nextFreeObjectNumber: nextFreeObjectNumber, generation: 65535)
    }
}
