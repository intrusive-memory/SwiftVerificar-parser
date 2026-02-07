import Foundation

/// Represents a complete PDF document at the PD (Page Description) layer.
///
/// The PD document is the top-level object that provides access to the document's
/// catalog, pages, metadata, and other document-level structures. It encapsulates
/// the parsed COS-layer objects and provides a high-level, type-safe API.
///
/// This type corresponds to the Java `PDDocument` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let document = try PDDocument(
///     trailer: trailer,
///     catalog: catalogDict,
///     header: header
/// )
/// let pageCount = try document.pageCount()
/// let firstPage = try document.page(at: 0)
/// ```
public final class PDDocument: Sendable {

    // MARK: - Properties

    /// The PDF header information.
    public let header: PDFHeader

    /// The document trailer.
    public let trailer: PDFTrailer

    /// The document catalog.
    public let catalog: PDFCatalog

    /// The cross-reference table (optional, for advanced access).
    public let xrefTable: XRefTable?

    // MARK: - Initialization

    /// Creates a PDF document from parsed components.
    ///
    /// - Parameters:
    ///   - header: The PDF header.
    ///   - trailer: The document trailer.
    ///   - catalog: The document catalog dictionary.
    ///   - xrefTable: The cross-reference table (optional).
    /// - Throws: `PDError` if the catalog is invalid.
    public init(
        header: PDFHeader,
        trailer: PDFTrailer,
        catalog: COSValue,
        xrefTable: XRefTable? = nil
    ) throws {
        self.header = header
        self.trailer = trailer
        self.catalog = try PDFCatalog(cosObject: catalog)
        self.xrefTable = xrefTable
    }

    // MARK: - Document Properties

    /// The PDF version from the header.
    ///
    /// - Returns: The version tuple (e.g., (1, 7) for PDF 1.7).
    public var version: (major: Int, minor: Int) {
        (header.major, header.minor)
    }

    /// The PDF version as a string (e.g., "1.7").
    public var versionString: String {
        "\(version.major).\(version.minor)"
    }

    /// The catalog version, if specified.
    ///
    /// The catalog can override the version from the header using the `/Version` entry.
    ///
    /// - Returns: The catalog version string, or `nil` if not specified.
    public var catalogVersion: String? {
        catalog.version?.stringValue
    }

    /// The effective PDF version.
    ///
    /// Returns the catalog version if specified, otherwise the header version.
    public var effectiveVersion: String {
        catalogVersion ?? versionString
    }

    /// The document's language, if specified.
    ///
    /// - Returns: The language tag (e.g., "en-US"), or `nil` if not specified.
    public var language: String? {
        catalog.lang
    }

    // MARK: - Page Access

    /// Returns the page tree.
    ///
    /// - Returns: The document's page tree.
    /// - Throws: `PDError` if the page tree is invalid.
    public func pageTree() throws -> PDFPageTree {
        try catalog.pageTree()
    }

    /// Returns the total number of pages in the document.
    ///
    /// - Returns: The page count.
    /// - Throws: `PDError` if the page tree is invalid.
    public func pageCount() throws -> Int {
        try pageTree().count()
    }

    /// Returns the page at the specified index.
    ///
    /// - Parameter index: The zero-based page index.
    /// - Returns: The page object.
    /// - Throws: `PDError` if the index is out of bounds or the page tree is invalid.
    public func page(at index: Int) throws -> PDFPage {
        try pageTree().page(at: index)
    }

    /// Returns all pages in the document.
    ///
    /// Use with caution on large documents as this loads all pages into memory.
    ///
    /// - Returns: An array of all pages.
    /// - Throws: `PDError` if the page tree is invalid.
    public func allPages() throws -> [PDFPage] {
        try pageTree().allPages()
    }

    // MARK: - Metadata

    /// The document's XMP metadata stream, if present.
    ///
    /// - Returns: The COSValue for the metadata stream, or `nil` if not present.
    public var metadata: COSValue? {
        catalog.metadata
    }

    /// The document information dictionary, if present.
    ///
    /// Returns the `/Info` entry from the trailer which contains metadata
    /// like Title, Author, Subject, Keywords, Creator, Producer, etc.
    ///
    /// - Returns: The COSValue for the info dictionary, or `nil` if not present.
    public var info: COSValue? {
        trailer.infoValue
    }

    // MARK: - Structure and Accessibility

    /// The structure tree root, if present.
    ///
    /// Returns the `/StructTreeRoot` entry which contains the tagged PDF structure.
    ///
    /// - Returns: The COSValue for the structure tree root, or `nil` if not present.
    public var structTreeRoot: COSValue? {
        catalog.structTreeRoot
    }

    /// Whether the document is marked as tagged.
    ///
    /// Checks the `/MarkInfo` dictionary's `/Marked` entry.
    ///
    /// - Returns: `true` if the document is tagged, `false` otherwise.
    public var isTagged: Bool {
        catalog.markInfo?["Marked"]?.boolValue ?? false
    }

    /// The mark information dictionary, if present.
    ///
    /// - Returns: The COSValue for the mark info dictionary, or `nil` if not present.
    public var markInfo: COSValue? {
        catalog.markInfo
    }

    // MARK: - Encryption

    /// Whether the document is encrypted.
    ///
    /// - Returns: `true` if the trailer has an `/Encrypt` entry, `false` otherwise.
    public var isEncrypted: Bool {
        trailer.encryptValue != nil
    }

    /// The encryption dictionary, if present.
    ///
    /// - Returns: The COSValue for the encryption dictionary, or `nil` if not present.
    public var encryptionDict: COSValue? {
        trailer.encryptValue
    }

    // MARK: - Navigation and Viewing

    /// The document's outlines (bookmarks), if present.
    ///
    /// - Returns: The COSValue for the outlines dictionary, or `nil` if not present.
    public var outlines: COSValue? {
        catalog.outlines
    }

    /// The page mode (how the document should be displayed).
    ///
    /// - Returns: The page mode name, or `nil` if not specified.
    public var pageMode: ASAtom? {
        catalog.pageMode
    }

    /// The page layout (how pages should be arranged).
    ///
    /// - Returns: The page layout name, or `nil` if not specified.
    public var pageLayout: ASAtom? {
        catalog.pageLayout
    }

    /// The viewer preferences, if present.
    ///
    /// - Returns: The COSValue for the viewer preferences dictionary, or `nil` if not present.
    public var viewerPreferences: COSValue? {
        catalog.viewerPreferences
    }
}

// MARK: - CustomStringConvertible

extension PDDocument: CustomStringConvertible {
    public var description: String {
        let pageCountStr = (try? pageCount()).map { "\($0) pages" } ?? "unknown page count"
        return "PDDocument(version: \(effectiveVersion), \(pageCountStr), encrypted: \(isEncrypted), tagged: \(isTagged))"
    }
}
