import Foundation

/// Represents the trailer of a PDF document, which contains references to
/// the document's root (catalog), info dictionary, and encryption dictionary.
///
/// The trailer is the entry point for navigating the PDF object graph.
/// It appears at the end of a PDF file (or at the end of each incremental
/// update) and contains critical references:
///
/// - `/Root` — The document catalog (required).
/// - `/Info` — The document information dictionary (optional).
/// - `/Encrypt` — The encryption dictionary (optional).
/// - `/Size` — The total number of entries in the cross-reference table.
/// - `/Prev` — The byte offset of the previous cross-reference section
///   (for incremental updates).
/// - `/ID` — A two-element array of string IDs for the document.
///
/// This type corresponds to the Java `COSTrailer` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let trailer = PDFTrailer(
///     dictionary: trailerDict,
///     rootReference: COSReference(objectNumber: 1),
///     size: 100
/// )
/// ```
public struct PDFTrailer: Sendable, Hashable, Codable, CustomStringConvertible {

    // MARK: - Properties

    /// The full trailer dictionary as parsed from the PDF file.
    public let dictionary: [ASAtom: COSValue]

    // MARK: - Initialization

    /// Creates a trailer from the given dictionary entries.
    ///
    /// - Parameter dictionary: The trailer dictionary containing root, size, and
    ///   other standard entries.
    public init(dictionary: [ASAtom: COSValue]) {
        self.dictionary = dictionary
    }

    /// Creates a trailer with explicit root reference and size.
    ///
    /// - Parameters:
    ///   - rootReference: A reference to the document catalog.
    ///   - infoReference: An optional reference to the info dictionary.
    ///   - encryptReference: An optional reference to the encryption dictionary.
    ///   - size: The total number of cross-reference entries.
    ///   - previousXRefOffset: The byte offset of the previous cross-reference section.
    ///   - documentID: The two-element document ID array.
    public init(
        rootReference: COSReference,
        infoReference: COSReference? = nil,
        encryptReference: COSReference? = nil,
        size: Int64,
        previousXRefOffset: Int64? = nil,
        documentID: (COSString, COSString)? = nil
    ) {
        var dict: [ASAtom: COSValue] = [:]
        dict[.root] = .integer(Int64(rootReference.objectNumber))
        dict[.size] = .integer(size)

        if let infoRef = infoReference {
            dict[.info] = .integer(Int64(infoRef.objectNumber))
        }
        if let encryptRef = encryptReference {
            dict[.encrypt] = .integer(Int64(encryptRef.objectNumber))
        }
        if let prev = previousXRefOffset {
            dict[.prev] = .integer(prev)
        }
        if let (id1, id2) = documentID {
            dict[.id] = .array([.string(id1), .string(id2)])
        }

        self.dictionary = dict
    }

    // MARK: - Dictionary Access

    /// Accesses a value in the trailer dictionary by name key.
    ///
    /// - Parameter key: The name key to look up.
    /// - Returns: The value associated with the key, or `nil` if not found.
    public subscript(key: ASAtom) -> COSValue? {
        dictionary[key]
    }

    /// Accesses a value in the trailer dictionary by string key.
    ///
    /// - Parameter key: The string key to look up.
    /// - Returns: The value associated with the key, or `nil` if not found.
    public subscript(key: String) -> COSValue? {
        dictionary[ASAtom(key)]
    }

    // MARK: - Standard Trailer Entries

    /// The value of the `/Root` entry (document catalog reference).
    ///
    /// This is the most important entry in the trailer. It points to the
    /// document catalog, which is the root of the PDF object hierarchy.
    public var rootValue: COSValue? {
        dictionary[.root]
    }

    /// The value of the `/Info` entry (document information dictionary reference).
    public var infoValue: COSValue? {
        dictionary[.info]
    }

    /// The value of the `/Encrypt` entry (encryption dictionary reference).
    public var encryptValue: COSValue? {
        dictionary[.encrypt]
    }

    /// The total number of cross-reference entries, from the `/Size` entry.
    ///
    /// This is one greater than the highest object number used in the file.
    public var size: Int64? {
        dictionary[.size]?.integerValue
    }

    /// The byte offset of the previous cross-reference section, from `/Prev`.
    ///
    /// Present only in files with incremental updates. Each incremental update
    /// adds a new cross-reference section that links back to the previous one.
    public var previousXRefOffset: Int64? {
        dictionary[.prev]?.integerValue
    }

    /// The document ID array from the `/ID` entry.
    ///
    /// If present, this is a two-element array of `COSString` values:
    /// - The first is a permanent ID assigned when the file was created.
    /// - The second is an ID that changes each time the file is modified.
    public var documentID: (COSString, COSString)? {
        guard let idArray = dictionary[.id]?.arrayValue,
              idArray.count >= 2,
              let first = idArray[0].stringValue,
              let second = idArray[1].stringValue else {
            return nil
        }
        return (first, second)
    }

    /// Whether this trailer indicates an encrypted document.
    public var isEncrypted: Bool {
        encryptValue != nil
    }

    /// Whether this trailer has a previous cross-reference section (incremental update).
    public var hasIncrementalUpdate: Bool {
        previousXRefOffset != nil
    }

    /// The number of entries in the trailer dictionary.
    public var entryCount: Int {
        dictionary.count
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        var parts: [String] = []
        if let s = size {
            parts.append("size: \(s)")
        }
        parts.append("root: \(rootValue?.description ?? "nil")")
        if infoValue != nil {
            parts.append("info: present")
        }
        if isEncrypted {
            parts.append("encrypted: yes")
        }
        if hasIncrementalUpdate {
            parts.append("prev: \(previousXRefOffset ?? 0)")
        }
        return "trailer(\(parts.joined(separator: ", ")))"
    }
}
