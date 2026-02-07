import Foundation

/// Represents an attribute object for structure elements.
///
/// Attribute objects provide additional information about structure elements,
/// such as layout attributes, styling attributes, table attributes, etc.
/// They enhance the semantic description of document content for accessibility
/// and document structure.
///
/// This type corresponds to the Java attribute handling in veraPDF-parser.
///
/// ## PDF Specification
/// An attribute object is a dictionary with at least an `/O` (owner) entry
/// that identifies the application or standard that defines the attributes.
///
/// Standard attribute owners include:
/// - `/Layout`: Layout attributes (BBox, Placement, etc.)
/// - `/List`: List attributes (ListNumbering)
/// - `/Table`: Table attributes (RowSpan, ColSpan, Headers, etc.)
/// - `/PrintField`: Form field attributes
/// - `/XML-1.00`: XML namespace attributes
/// - `/HTML-3.20`, `/HTML-4.01`, `/HTML-5.00`: HTML attributes
/// - `/CSS-1.00`, `/CSS-2.00`: CSS attributes
///
/// ## Usage
/// ```swift
/// let attrs = try PDAttributeObject(cosObject: attrDict)
/// let owner = try attrs.owner()
/// let bbox = attrs.boundingBox
/// let rowSpan = attrs.integerAttribute(ASAtom("RowSpan"))
/// ```
public struct PDAttributeObject: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this attribute object.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates an attribute object from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Common Attributes

    /// The owner of the attribute object (required).
    ///
    /// Returns the `/O` entry which identifies the application or standard
    /// that defines the attributes in this dictionary.
    ///
    /// - Returns: The owner name.
    /// - Throws: `PDError.missingRequiredEntry` if the `/O` entry is missing.
    public func owner() throws -> ASAtom {
        try requireName(ASAtom("O"))
    }

    /// The namespace for this attribute (PDF 2.0).
    ///
    /// Returns the `/NS` entry which specifies the namespace for the attributes.
    ///
    /// - Returns: The namespace dictionary, or `nil` if not present.
    public var namespace: COSValue? {
        optionalEntry("NS")
    }

    /// Gets an attribute value by name.
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The attribute value, or `nil` if not present.
    public func attribute(_ key: ASAtom) -> COSValue? {
        optionalEntry(key)
    }

    /// Gets a string attribute value.
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The string value, or `nil` if not present or not a string.
    public func stringAttribute(_ key: ASAtom) -> String? {
        attribute(key)?.textValue
    }

    /// Gets an integer attribute value.
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The integer value, or `nil` if not present or not an integer.
    public func integerAttribute(_ key: ASAtom) -> Int64? {
        attribute(key)?.integerValue
    }

    /// Gets a numeric attribute value (integer or real).
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The numeric value, or `nil` if not present or not numeric.
    public func numericAttribute(_ key: ASAtom) -> Double? {
        attribute(key)?.numericValue
    }

    /// Gets a name attribute value.
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The name value, or `nil` if not present or not a name.
    public func nameAttribute(_ key: ASAtom) -> ASAtom? {
        attribute(key)?.nameValue
    }

    /// Gets an array attribute value.
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The array value, or `nil` if not present or not an array.
    public func arrayAttribute(_ key: ASAtom) -> [COSValue]? {
        attribute(key)?.arrayValue
    }

    /// Gets a boolean attribute value.
    ///
    /// - Parameter key: The attribute name.
    /// - Returns: The boolean value, or `nil` if not present or not a boolean.
    public func booleanAttribute(_ key: ASAtom) -> Bool? {
        attribute(key)?.boolValue
    }

    // MARK: - Layout Attributes (Owner: /Layout)

    /// The bounding box for the element (Layout attribute).
    ///
    /// Returns the `/BBox` entry as an array of four numbers [llx, lly, urx, ury].
    ///
    /// - Returns: The bounding box array, or `nil` if not present.
    public var boundingBox: [COSValue]? {
        arrayAttribute(.bbox)
    }

    /// The placement of the element (Layout attribute).
    ///
    /// Returns the `/Placement` entry which specifies the placement:
    /// - `/Block`: Stacked in the block-progression direction
    /// - `/Inline`: Packed in the inline-progression direction
    /// - `/Before`: Placed before the anchor
    /// - `/Start`: Placed at the start of the anchor
    /// - `/End`: Placed at the end of the anchor
    ///
    /// - Returns: The placement name, or `nil` if not present.
    public var placement: ASAtom? {
        nameAttribute("Placement")
    }

    /// The writing mode (Layout attribute).
    ///
    /// Returns the `/WritingMode` entry which specifies the writing mode:
    /// - `/LrTb`: Left-to-right, top-to-bottom
    /// - `/RlTb`: Right-to-left, top-to-bottom
    /// - `/TbRl`: Top-to-bottom, right-to-left
    ///
    /// - Returns: The writing mode name, or `nil` if not present.
    public var writingMode: ASAtom? {
        nameAttribute("WritingMode")
    }

    /// The background color (Layout attribute).
    ///
    /// Returns the `/BackgroundColor` entry as an array of color components.
    ///
    /// - Returns: The color array, or `nil` if not present.
    public var backgroundColor: [COSValue]? {
        arrayAttribute("BackgroundColor")
    }

    /// The border colors (Layout attribute).
    ///
    /// Returns the `/BorderColor` entry which can be an array of color components
    /// or an array of four arrays (for before/after/start/end edges).
    ///
    /// - Returns: The border color value, or `nil` if not present.
    public var borderColor: COSValue? {
        attribute("BorderColor")
    }

    /// The border style (Layout attribute).
    ///
    /// Returns the `/BorderStyle` entry which specifies border style:
    /// - `/None`: No border
    /// - `/Hidden`: Same as None
    /// - `/Dotted`, `/Dashed`, `/Solid`, `/Double`, `/Groove`, `/Ridge`, `/Inset`, `/Outset`
    ///
    /// - Returns: The border style, or `nil` if not present.
    public var borderStyle: COSValue? {
        attribute("BorderStyle")
    }

    /// The border thickness (Layout attribute).
    ///
    /// Returns the `/BorderThickness` entry as a number or array of numbers.
    ///
    /// - Returns: The border thickness, or `nil` if not present.
    public var borderThickness: COSValue? {
        attribute("BorderThickness")
    }

    /// The padding (Layout attribute).
    ///
    /// Returns the `/Padding` entry as a number or array of numbers.
    ///
    /// - Returns: The padding value, or `nil` if not present.
    public var padding: COSValue? {
        attribute("Padding")
    }

    /// The text alignment (Layout attribute).
    ///
    /// Returns the `/TextAlign` entry:
    /// - `/Start`: Aligned with start edge
    /// - `/Center`: Centered
    /// - `/End`: Aligned with end edge
    /// - `/Justify`: Justified
    ///
    /// - Returns: The text alignment name, or `nil` if not present.
    public var textAlign: ASAtom? {
        nameAttribute("TextAlign")
    }

    // MARK: - Table Attributes (Owner: /Table)

    /// The row span for a table cell (Table attribute).
    ///
    /// Returns the `/RowSpan` entry which indicates how many rows the cell spans.
    ///
    /// - Returns: The row span value (default is 1), or `nil` if not present.
    public var rowSpan: Int64? {
        integerAttribute("RowSpan")
    }

    /// The column span for a table cell (Table attribute).
    ///
    /// Returns the `/ColSpan` entry which indicates how many columns the cell spans.
    ///
    /// - Returns: The column span value (default is 1), or `nil` if not present.
    public var colSpan: Int64? {
        integerAttribute("ColSpan")
    }

    /// The headers for a table cell (Table attribute).
    ///
    /// Returns the `/Headers` entry which is an array of IDs of header cells
    /// associated with this cell.
    ///
    /// - Returns: The headers array, or `nil` if not present.
    public var headers: [COSValue]? {
        arrayAttribute("Headers")
    }

    /// The scope of a header cell (Table attribute).
    ///
    /// Returns the `/Scope` entry:
    /// - `/Row`: Header applies to the row
    /// - `/Column`: Header applies to the column
    /// - `/Both`: Header applies to both row and column
    ///
    /// - Returns: The scope name, or `nil` if not present.
    public var scope: ASAtom? {
        nameAttribute("Scope")
    }

    /// The summary of a table (Table attribute).
    ///
    /// Returns the `/Summary` entry which provides a summary of the table's purpose.
    ///
    /// - Returns: The summary text, or `nil` if not present.
    public var summary: String? {
        stringAttribute("Summary")
    }

    // MARK: - List Attributes (Owner: /List)

    /// The list numbering style (List attribute).
    ///
    /// Returns the `/ListNumbering` entry:
    /// - `/None`: No numbering
    /// - `/Disc`, `/Circle`, `/Square`: Bullet styles
    /// - `/Decimal`, `/UpperRoman`, `/LowerRoman`, `/UpperAlpha`, `/LowerAlpha`: Numbering styles
    ///
    /// - Returns: The list numbering name, or `nil` if not present.
    public var listNumbering: ASAtom? {
        nameAttribute("ListNumbering")
    }

    // MARK: - Validation

    /// Validates that this is a valid attribute object.
    ///
    /// - Returns: `true` if valid (has an owner), `false` otherwise.
    public func validate() -> Bool {
        do {
            _ = try owner()
            return true
        } catch {
            return false
        }
    }
}
