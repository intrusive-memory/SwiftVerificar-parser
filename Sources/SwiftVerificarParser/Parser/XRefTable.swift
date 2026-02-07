import Foundation

/// Represents a complete PDF cross-reference table with subsections and trailer.
///
/// The cross-reference (xref) table is the index that maps PDF object numbers
/// to their byte offsets in the file. It allows random access to any object
/// without scanning the entire file.
///
/// A PDF file may have multiple cross-reference sections due to incremental
/// updates. Each section contains:
/// - One or more **subsections** (contiguous ranges of object numbers)
/// - A **trailer dictionary** (metadata, root reference, etc.)
///
/// The PDF specification (ISO 32000-2:2020, Section 7.5.4) defines two formats:
/// 1. **Traditional xref table** (text format, PDF 1.0+)
/// 2. **Cross-reference stream** (binary format, PDF 1.5+)
///
/// This type supports both formats and consolidates the Java `COSXRefTable`,
/// `COSXRefSection`, and `COSXRefInfo` classes from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let subsection = XRefSubsection(startObjectNumber: 0, entries: [...])
/// let trailer = PDFTrailer(rootReference: COSReference(objectNumber: 1), size: 100)
/// let xrefTable = XRefTable(subsections: [subsection], trailer: trailer)
///
/// if let entry = xrefTable.entry(for: 42) {
///     print("Object 42 is at offset \(entry.offset ?? 0)")
/// }
/// ```
public struct XRefTable: Sendable, Hashable, CustomStringConvertible {

    // MARK: - Properties

    /// The subsections of this cross-reference table.
    ///
    /// Subsections are stored in the order they appear in the file. Multiple
    /// subsections may describe the same object numbers, with later subsections
    /// overriding earlier ones (incremental updates).
    public let subsections: [XRefSubsection]

    /// The trailer dictionary associated with this cross-reference section.
    ///
    /// The trailer contains critical document metadata:
    /// - `/Root` — Reference to the document catalog
    /// - `/Size` — Total number of objects in the file
    /// - `/Prev` — Offset of previous cross-reference section (if any)
    /// - `/Info` — Reference to document information dictionary
    /// - `/Encrypt` — Reference to encryption dictionary (if encrypted)
    public let trailer: PDFTrailer

    /// The byte offset of this cross-reference table in the file.
    ///
    /// This is the value that appears after the `startxref` keyword at the
    /// end of the PDF file (or at the end of each incremental update).
    public let byteOffset: Int64

    // MARK: - Initialization

    /// Creates a cross-reference table with the given subsections and trailer.
    ///
    /// - Parameters:
    ///   - subsections: The array of subsections (must not be empty).
    ///   - trailer: The trailer dictionary for this section.
    ///   - byteOffset: The byte offset of this xref table in the file (default 0).
    /// - Precondition: `subsections` must not be empty.
    public init(
        subsections: [XRefSubsection],
        trailer: PDFTrailer,
        byteOffset: Int64 = 0
    ) {
        precondition(!subsections.isEmpty, "XRefTable must have at least one subsection")
        self.subsections = subsections
        self.trailer = trailer
        self.byteOffset = byteOffset
    }

    // MARK: - Entry Lookup

    /// Returns the cross-reference entry for the given object number.
    ///
    /// If multiple subsections describe the same object number (due to
    /// incremental updates), the last subsection's entry is returned.
    ///
    /// - Parameter objectNumber: The object number to look up.
    /// - Returns: The entry for that object, or `nil` if not found.
    public func entry(for objectNumber: Int) -> XRefEntry? {
        // Search subsections in reverse order (last one wins)
        for subsection in subsections.reversed() {
            if let entry = subsection.entry(for: objectNumber) {
                return entry
            }
        }
        return nil
    }

    /// Subscript access to entries by object number.
    ///
    /// - Parameter objectNumber: The object number to look up.
    /// - Returns: The entry for that object, or `nil` if not found.
    public subscript(objectNumber: Int) -> XRefEntry? {
        entry(for: objectNumber)
    }

    /// Returns the byte offset for an in-use object, or `nil` if not found or not in use.
    ///
    /// - Parameter objectNumber: The object number to look up.
    /// - Returns: The byte offset, or `nil`.
    public func offset(for objectNumber: Int) -> Int64? {
        entry(for: objectNumber)?.offset
    }

    // MARK: - Validation

    /// Whether this table contains an entry for the given object number.
    ///
    /// - Parameter objectNumber: The object number to check.
    /// - Returns: `true` if an entry exists (free, in-use, or compressed).
    public func contains(objectNumber: Int) -> Bool {
        entry(for: objectNumber) != nil
    }

    /// Whether the given object is in use (not free, not compressed).
    ///
    /// - Parameter objectNumber: The object number to check.
    /// - Returns: `true` if the object is in use.
    public func isInUse(objectNumber: Int) -> Bool {
        entry(for: objectNumber)?.isInUse ?? false
    }

    /// Whether the given object is free.
    ///
    /// - Parameter objectNumber: The object number to check.
    /// - Returns: `true` if the object is free.
    public func isFree(objectNumber: Int) -> Bool {
        entry(for: objectNumber)?.isFree ?? false
    }

    /// Whether the given object is compressed.
    ///
    /// - Parameter objectNumber: The object number to check.
    /// - Returns: `true` if the object is compressed.
    public func isCompressed(objectNumber: Int) -> Bool {
        entry(for: objectNumber)?.isCompressed ?? false
    }

    // MARK: - Computed Properties

    /// The total number of subsections in this table.
    public var subsectionCount: Int {
        subsections.count
    }

    /// The total number of entries across all subsections.
    ///
    /// Note: This counts all entries, including duplicates from multiple
    /// subsections describing the same object numbers.
    public var totalEntryCount: Int {
        subsections.reduce(0) { $0 + $1.count }
    }

    /// The size value from the trailer (total number of objects in the file).
    public var size: Int64? {
        trailer.size
    }

    /// Whether this table is part of an incremental update (has a `/Prev` entry).
    public var hasIncrementalUpdate: Bool {
        trailer.hasIncrementalUpdate
    }

    /// The byte offset of the previous cross-reference section, if any.
    public var previousXRefOffset: Int64? {
        trailer.previousXRefOffset
    }

    // MARK: - Statistics

    /// The total number of in-use entries across all subsections.
    public var inUseCount: Int {
        subsections.reduce(0) { $0 + $1.inUseCount }
    }

    /// The total number of free entries across all subsections.
    public var freeCount: Int {
        subsections.reduce(0) { $0 + $1.freeCount }
    }

    /// The total number of compressed entries across all subsections.
    public var compressedCount: Int {
        subsections.reduce(0) { $0 + $1.compressedCount }
    }

    // MARK: - Object Number Ranges

    /// Returns all object numbers described by this cross-reference table.
    ///
    /// - Returns: A set of all object numbers that have entries.
    public func allObjectNumbers() -> Set<Int> {
        var numbers = Set<Int>()
        for subsection in subsections {
            numbers.formUnion(subsection.objectRange)
        }
        return numbers
    }

    /// Returns all in-use object numbers in this table.
    ///
    /// - Returns: A set of object numbers that are in use.
    public func inUseObjectNumbers() -> Set<Int> {
        allObjectNumbers().filter { isInUse(objectNumber: $0) }
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var parts: [String] = []
        parts.append("xref(subsections: \(subsectionCount)")
        if let size = size {
            parts.append("size: \(size)")
        }
        parts.append("entries: \(totalEntryCount)")
        if hasIncrementalUpdate {
            parts.append("prev: \(previousXRefOffset ?? 0)")
        }
        return parts.joined(separator: ", ") + ")"
    }
}
