import Foundation

/// Represents a structure element in the PDF structure tree.
///
/// Structure elements define the logical structure of a PDF document,
/// organizing content into semantic units like paragraphs, headings, tables,
/// figures, etc. This is essential for accessibility and tagged PDF support.
///
/// This type corresponds to the Java `PDStructElem` class from veraPDF-parser.
///
/// ## PDF Specification
/// A structure element dictionary must have an `/S` entry specifying the
/// structure type (e.g., "P" for paragraph, "H1" for heading level 1).
///
/// Key entries include:
/// - `/S`: The structure type (role)
/// - `/P`: Reference to the parent structure element or tree root
/// - `/K`: The children (content items, marked content references, or child structure elements)
/// - `/Pg`: The page on which content items occur
/// - `/A`: Attributes associated with this element
/// - `/C`: Attribute classes referenced by this element
/// - `/T`: The title or label for this element
/// - `/Lang`: The language for this element
/// - `/Alt`: Alternate description (alternative text)
/// - `/ActualText`: Actual text replacement
/// - `/E`: Expanded form of an abbreviation
///
/// ## Usage
/// ```swift
/// let structElem = try PDStructElement(cosObject: elementDict)
/// let role = try structElem.structureType()
/// let children = try structElem.children()
/// let altText = structElem.alternateDescription
/// ```
public struct PDStructElement: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this structure element.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a structure element from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Structure Element Entries

    /// The structure type (role) of this element (required).
    ///
    /// Returns the `/S` entry which specifies the structure type name
    /// (e.g., "Document", "P", "H1", "Figure", "Table").
    ///
    /// - Returns: The structure type name.
    /// - Throws: `PDError.missingRequiredEntry` if the `/S` entry is missing.
    public func structureType() throws -> ASAtom {
        try requireName(.s)
    }

    /// The parent structure element or tree root (required).
    ///
    /// Returns the `/P` entry which references the immediate parent
    /// in the structure hierarchy.
    ///
    /// - Returns: The COSValue for the parent.
    /// - Throws: `PDError.missingRequiredEntry` if the `/P` entry is missing.
    public func parent() throws -> COSValue {
        try requireEntry(.parent)
    }

    /// The children of this structure element.
    ///
    /// Returns the `/K` entry which can be:
    /// - An integer (marked content identifier)
    /// - A marked content reference dictionary
    /// - An object reference dictionary
    /// - A structure element dictionary
    /// - An array of any combination of the above
    ///
    /// - Returns: The COSValue for the children, or `nil` if not present.
    public var k: COSValue? {
        optionalEntry(.k)
    }

    /// The children as an array.
    ///
    /// Normalizes the `/K` entry to always return an array, even if it's a single value.
    ///
    /// - Returns: An array of child objects.
    /// - Throws: `PDError` if the children are malformed.
    public func children() throws -> [COSValue] {
        guard let kValue = k else {
            return []
        }

        if let array = kValue.arrayValue {
            return array
        } else {
            // Single child - wrap in array
            return [kValue]
        }
    }

    /// The page on which content items occur (optional, may be inherited).
    ///
    /// Returns the `/Pg` entry which references a page object where the
    /// content items for this structure element are located.
    ///
    /// - Returns: The COSValue for the page reference, or `nil` if not present.
    public var page: COSValue? {
        optionalEntry(.pg)
    }

    /// The attributes for this structure element (optional).
    ///
    /// Returns the `/A` entry which can be:
    /// - A single attribute dictionary
    /// - An array of attribute dictionaries
    /// - A revision number followed by attribute dictionaries
    ///
    /// - Returns: The COSValue for the attributes, or `nil` if not present.
    public var attributes: COSValue? {
        optionalEntry("A")
    }

    /// The attribute classes referenced by this element (optional).
    ///
    /// Returns the `/C` entry which can be:
    /// - A single class name
    /// - An array of class names
    /// - A revision number followed by class names
    ///
    /// - Returns: The COSValue for the class references, or `nil` if not present.
    public var attributeClasses: COSValue? {
        optionalEntry("C")
    }

    /// The revision number for attributes (optional).
    ///
    /// Returns the `/R` entry which indicates the revision number for
    /// attributes and classes.
    ///
    /// - Returns: The revision number, or `nil` if not present.
    public var revision: Int64? {
        optionalInteger("R")
    }

    /// The title or label for this element (optional).
    ///
    /// Returns the `/T` entry which provides a descriptive title for
    /// the structure element.
    ///
    /// - Returns: The title string, or `nil` if not present.
    public var title: String? {
        optionalEntry("T")?.textValue
    }

    /// The language for this element (optional).
    ///
    /// Returns the `/Lang` entry which specifies the natural language
    /// for text in this element (e.g., "en-US").
    ///
    /// - Returns: The language string, or `nil` if not present.
    public var language: String? {
        optionalEntry(.lang)?.textValue
    }

    /// The alternate description (alternative text) for this element (optional).
    ///
    /// Returns the `/Alt` entry which provides alternative text for
    /// accessibility (e.g., for images or other non-textual content).
    ///
    /// - Returns: The alternate description string, or `nil` if not present.
    public var alternateDescription: String? {
        optionalEntry(.alt)?.textValue
    }

    /// The actual text replacement for this element (optional).
    ///
    /// Returns the `/ActualText` entry which provides replacement text
    /// for content that is represented in an unusual way.
    ///
    /// - Returns: The actual text string, or `nil` if not present.
    public var actualText: String? {
        optionalEntry(.actualText)?.textValue
    }

    /// The expanded form of an abbreviation (optional).
    ///
    /// Returns the `/E` entry which provides the expanded form of
    /// an abbreviation or acronym.
    ///
    /// - Returns: The expanded form string, or `nil` if not present.
    public var expandedForm: String? {
        optionalEntry(.e)?.textValue
    }

    /// The element identifier (optional).
    ///
    /// Returns the `/ID` entry which provides a unique identifier
    /// for this structure element within the document.
    ///
    /// - Returns: The ID string, or `nil` if not present.
    public var id: String? {
        optionalEntry(.id)?.textValue
    }

    /// Checks if this element has marked content children.
    ///
    /// - Returns: `true` if any children are integers (MCIDs) or marked content references.
    public func hasMarkedContent() throws -> Bool {
        let kids = try children()
        for kid in kids {
            if kid.integerValue != nil {
                return true
            }
            if let dict = kid.dictionaryValue,
               dict[ASAtom("Type")]?.nameValue == ASAtom("MCR") {
                return true
            }
        }
        return false
    }

    /// Validates that this is a valid structure element.
    ///
    /// - Returns: `true` if valid, `false` otherwise.
    public func validate() -> Bool {
        // Must have an S (structure type) entry
        do {
            _ = try structureType()
            return true
        } catch {
            return false
        }
    }
}
