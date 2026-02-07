import Foundation

/// Represents the PDF document catalog (root object).
///
/// The catalog is the root of a PDF's object hierarchy and contains references
/// to other objects defining the document's contents, outline, article threads,
/// named destinations, and other attributes.
///
/// This type corresponds to the Java `PDCatalog` class from veraPDF-parser.
///
/// ## PDF Specification
/// The catalog dictionary is identified by the `/Root` entry in the document trailer
/// and must have a `/Type` entry with value `/Catalog`.
///
/// ## Usage
/// ```swift
/// let catalog = try PDFCatalog(cosObject: rootDict)
/// let pageTree = try catalog.pages()
/// let metadata = catalog.metadata
/// ```
public struct PDFCatalog: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this catalog.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a catalog from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Catalog Entries

    /// The document's page tree (required).
    ///
    /// Returns the `/Pages` entry which references the root of the page tree.
    ///
    /// - Returns: The COSValue for the Pages dictionary.
    /// - Throws: `PDError.missingRequiredEntry` if the `/Pages` entry is missing.
    public func pagesObject() throws -> COSValue {
        try requireEntry(.pages)
    }

    /// The document's page tree as a PDFPageTree.
    ///
    /// - Returns: The page tree object.
    /// - Throws: `PDError` if the page tree is invalid.
    public func pageTree() throws -> PDFPageTree {
        let pagesObj = try pagesObject()
        return try PDFPageTree(cosObject: pagesObj)
    }

    /// The document's metadata stream (optional).
    ///
    /// Returns the `/Metadata` entry which references an XMP metadata stream.
    ///
    /// - Returns: The COSValue for the metadata stream, or `nil` if not present.
    public var metadata: COSValue? {
        optionalEntry(.metadata)
    }

    /// The structure tree root (optional).
    ///
    /// Returns the `/StructTreeRoot` entry for tagged PDF structure.
    ///
    /// - Returns: The COSValue for the structure tree root, or `nil` if not present.
    public var structTreeRoot: COSValue? {
        optionalEntry(.structTreeRoot)
    }

    /// The mark information dictionary (optional).
    ///
    /// Returns the `/MarkInfo` entry which indicates whether the document
    /// is tagged and contains marked content.
    ///
    /// - Returns: The COSValue for the mark info dictionary, or `nil` if not present.
    public var markInfo: COSValue? {
        optionalEntry(.markInfo)
    }

    /// The document's language (optional).
    ///
    /// Returns the `/Lang` entry as a text string (e.g., "en-US").
    ///
    /// - Returns: The language string, or `nil` if not present.
    public var lang: String? {
        optionalEntry(.lang)?.textValue
    }

    /// The version of the PDF specification to which the document conforms (optional).
    ///
    /// Returns the `/Version` entry as a name (e.g., "1.7").
    ///
    /// - Returns: The version name, or `nil` if not present.
    public var version: ASAtom? {
        optionalName("Version")
    }

    /// The document's outlines (bookmarks) dictionary (optional).
    ///
    /// Returns the `/Outlines` entry.
    ///
    /// - Returns: The COSValue for the outlines dictionary, or `nil` if not present.
    public var outlines: COSValue? {
        optionalEntry("Outlines")
    }

    /// The document's named destinations (optional).
    ///
    /// Returns the `/Dests` entry.
    ///
    /// - Returns: The COSValue for the destinations dictionary, or `nil` if not present.
    public var dests: COSValue? {
        optionalEntry("Dests")
    }

    /// The document's viewer preferences (optional).
    ///
    /// Returns the `/ViewerPreferences` entry.
    ///
    /// - Returns: The COSValue for the viewer preferences dictionary, or `nil` if not present.
    public var viewerPreferences: COSValue? {
        optionalEntry("ViewerPreferences")
    }

    /// The page mode (optional).
    ///
    /// Returns the `/PageMode` entry which specifies how to display the document
    /// on opening (e.g., "UseNone", "UseOutlines", "UseThumbs").
    ///
    /// - Returns: The page mode name, or `nil` if not present.
    public var pageMode: ASAtom? {
        optionalName("PageMode")
    }

    /// The page layout (optional).
    ///
    /// Returns the `/PageLayout` entry which specifies the page layout
    /// (e.g., "SinglePage", "OneColumn", "TwoColumnLeft").
    ///
    /// - Returns: The page layout name, or `nil` if not present.
    public var pageLayout: ASAtom? {
        optionalName("PageLayout")
    }
}
