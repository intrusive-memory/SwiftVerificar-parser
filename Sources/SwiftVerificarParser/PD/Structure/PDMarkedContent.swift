import Foundation

/// Represents marked content in a PDF content stream.
///
/// Marked content provides a way to identify portions of a content stream
/// for purposes such as tagged PDF structure, accessibility, and logical
/// document structure. It is delimited by marked content operators in the
/// content stream.
///
/// This type corresponds to the Java marked content handling in veraPDF-parser.
///
/// ## PDF Specification
/// Marked content is identified by two types of operators:
/// - `BMC` / `EMC`: Begin/End Marked Content (with tag only)
/// - `BDC` / `EMC`: Begin/End Marked Content with properties dictionary
///
/// The tag identifies the role or type of the marked content.
/// An optional properties dictionary can provide additional information.
///
/// ## Usage
/// ```swift
/// // Simple marked content (BMC/EMC)
/// let mc1 = PDMarkedContent(tag: ASAtom("Artifact"))
///
/// // Marked content with properties (BDC/EMC)
/// let mc2 = PDMarkedContent(tag: ASAtom("Span"), mcid: 5)
///
/// // Check if it's a structure element reference
/// if let mcid = mc2.mcid {
///     print("MCID: \(mcid)")
/// }
/// ```
public struct PDMarkedContent: Sendable, Hashable {

    // MARK: - Properties

    /// The tag identifying the role or type of the marked content.
    ///
    /// Common tags include:
    /// - Standard structure types: "P", "H1", "Figure", "Table", etc.
    /// - "Artifact": Content that is not part of the logical structure
    /// - "Span": Generic inline content with properties
    public let tag: ASAtom

    /// The properties dictionary (optional).
    ///
    /// For `BDC` operators, this contains the properties dictionary which
    /// may include:
    /// - `/MCID`: Marked content identifier (integer) linking to structure tree
    /// - `/Lang`: Language specification
    /// - `/ActualText`: Replacement text for accessibility
    /// - `/Alt`: Alternative description
    /// - `/E`: Expanded form of abbreviation
    public let properties: COSValue?

    /// The marked content identifier (MCID) if present.
    ///
    /// The MCID is used to link marked content in the content stream to
    /// structure elements in the structure tree.
    public var mcid: Int64? {
        properties?[ASAtom("MCID")]?.integerValue
    }

    /// The language specification for this marked content (optional).
    public var language: String? {
        properties?[.lang]?.textValue
    }

    /// The actual text replacement for this marked content (optional).
    public var actualText: String? {
        properties?[.actualText]?.textValue
    }

    /// The alternate description for this marked content (optional).
    public var alternateDescription: String? {
        properties?[.alt]?.textValue
    }

    /// The expanded form of abbreviation for this marked content (optional).
    public var expandedForm: String? {
        properties?[.e]?.textValue
    }

    // MARK: - Initialization

    /// Creates marked content with a tag only (BMC style).
    ///
    /// - Parameter tag: The marked content tag.
    public init(tag: ASAtom) {
        self.tag = tag
        self.properties = nil
    }

    /// Creates marked content with a tag and properties (BDC style).
    ///
    /// - Parameters:
    ///   - tag: The marked content tag.
    ///   - properties: The properties dictionary (or inline dictionary).
    public init(tag: ASAtom, properties: COSValue?) {
        self.tag = tag
        self.properties = properties
    }

    /// Creates marked content with a tag and MCID.
    ///
    /// This is a convenience initializer for the common case of marked content
    /// with just an MCID property.
    ///
    /// - Parameters:
    ///   - tag: The marked content tag.
    ///   - mcid: The marked content identifier.
    public init(tag: ASAtom, mcid: Int64) {
        self.tag = tag
        self.properties = .dictionary([ASAtom("MCID"): .integer(mcid)])
    }

    // MARK: - Properties

    /// Checks if this is an artifact (non-structural content).
    ///
    /// Artifacts are page content items that are not part of the document's
    /// logical structure (e.g., headers, footers, page numbers, decorative elements).
    ///
    /// - Returns: `true` if the tag is "Artifact", `false` otherwise.
    public var isArtifact: Bool {
        tag == ASAtom("Artifact")
    }

    /// Checks if this marked content has a properties dictionary.
    ///
    /// - Returns: `true` if properties are present (BDC style), `false` if not (BMC style).
    public var hasProperties: Bool {
        properties != nil
    }

    /// Checks if this marked content references a structure element.
    ///
    /// - Returns: `true` if an MCID is present, `false` otherwise.
    public var isStructureReference: Bool {
        mcid != nil
    }
}

// MARK: - Marked Content Reference

/// Represents a marked content reference in a structure element's children.
///
/// A marked content reference (MCR) is a dictionary that identifies a sequence
/// of marked content in a content stream. It's used in the `/K` entry of
/// structure elements to reference content on a page.
///
/// ## PDF Specification
/// An MCR dictionary has:
/// - `/Type`: Must be "MCR"
/// - `/Pg`: Reference to the page containing the marked content (optional if inherited)
/// - `/MCID`: The marked content identifier (required)
/// - `/Stm`: Reference to the content stream (optional)
/// - `/StmOwn`: Reference to the parent content stream (optional)
public struct PDMarkedContentReference: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this marked content reference.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a marked content reference from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - MCR Entries

    /// The type entry (should be "MCR").
    ///
    /// - Returns: The type name, or `nil` if not present.
    public var type: ASAtom? {
        optionalName(.type)
    }

    /// The page on which the marked content occurs (optional, may be inherited).
    ///
    /// - Returns: The COSValue for the page reference, or `nil` if not present.
    public var page: COSValue? {
        optionalEntry(.pg)
    }

    /// The marked content identifier (required).
    ///
    /// - Returns: The MCID value.
    /// - Throws: `PDError.missingRequiredEntry` if the MCID is missing.
    public func mcid() throws -> Int64 {
        try requireInteger(ASAtom("MCID"))
    }

    /// The content stream containing the marked content (optional).
    ///
    /// - Returns: The COSValue for the stream reference, or `nil` if not present.
    public var stream: COSValue? {
        optionalEntry("Stm")
    }

    /// The parent content stream (optional).
    ///
    /// Used when the marked content is in a nested content stream (e.g., in a Form XObject).
    ///
    /// - Returns: The COSValue for the parent stream reference, or `nil` if not present.
    public var streamOwner: COSValue? {
        optionalEntry("StmOwn")
    }

    /// Validates that this is a valid marked content reference.
    ///
    /// - Returns: `true` if valid, `false` otherwise.
    public func validate() -> Bool {
        // Must have an MCID
        do {
            _ = try mcid()
            return true
        } catch {
            return false
        }
    }
}
