import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Represents a single page in a PDF document.
///
/// A page object describes a single page of the document, including its dimensions,
/// resources, content streams, and other page-level attributes.
///
/// This type corresponds to the Java `PDPage` class from veraPDF-parser.
///
/// ## PDF Specification
/// A page dictionary must have `/Type` = `/Page` and must be part of the page tree.
/// It inherits certain attributes from its parent page tree nodes if not specified
/// locally (e.g., MediaBox, Resources, Rotate).
///
/// ## Usage
/// ```swift
/// let page = try PDFPage(cosObject: pageDict)
/// let mediaBox = try page.mediaBox()
/// let resources = page.resources
/// ```
public struct PDFPage: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this page.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a page from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Page Attributes

    /// The parent page tree node (required).
    ///
    /// Returns the `/Parent` entry which references the immediate parent
    /// in the page tree.
    ///
    /// - Returns: The COSValue for the parent node.
    /// - Throws: `PDError.missingRequiredEntry` if the `/Parent` entry is missing.
    public func parent() throws -> COSValue {
        try requireEntry(.parent)
    }

    /// The page's media box (required, may be inherited).
    ///
    /// Returns the `/MediaBox` entry as an array of four numbers defining
    /// the boundaries of the physical medium [llx, lly, urx, ury].
    ///
    /// If not present in this page dictionary, it must be inherited from
    /// an ancestor node in the page tree.
    ///
    /// - Returns: The media box array.
    /// - Throws: `PDError.missingRequiredEntry` if not present and not inherited.
    public func mediaBox() throws -> [COSValue] {
        try requireArray(.mediaBox)
    }

    /// The page's media box as a CGRect (if CoreGraphics is available).
    ///
    /// - Returns: The media box rectangle, or `nil` if the array is malformed.
    /// - Throws: `PDError.missingRequiredEntry` if the media box is not present.
    #if canImport(CoreGraphics)
    public func mediaBoxRect() throws -> CGRect? {
        let box = try mediaBox()
        guard box.count == 4,
              let llx = box[0].numericValue,
              let lly = box[1].numericValue,
              let urx = box[2].numericValue,
              let ury = box[3].numericValue else {
            return nil
        }
        return CGRect(x: llx, y: lly, width: urx - llx, height: ury - lly)
    }
    #endif

    /// The page's crop box (optional, may be inherited).
    ///
    /// Returns the `/CropBox` entry. If not present, defaults to the MediaBox.
    ///
    /// - Returns: The crop box array, or `nil` if not present.
    public var cropBox: [COSValue]? {
        optionalArray(.cropBox)
    }

    /// The page's resources dictionary (optional, may be inherited).
    ///
    /// Returns the `/Resources` entry which contains resource dictionaries
    /// for fonts, XObjects, color spaces, etc.
    ///
    /// - Returns: The COSValue for the resources dictionary, or `nil` if not present.
    public var resources: COSValue? {
        optionalEntry(.resources)
    }

    /// The page's resources as a PDFResources object.
    ///
    /// - Returns: The resources object, or `nil` if not present.
    /// - Throws: `PDError` if the resources dictionary is malformed.
    public func resourcesObject() throws -> PDFResources? {
        guard let res = resources else {
            return nil
        }
        return try PDFResources(cosObject: res)
    }

    /// The page's content stream(s) (optional).
    ///
    /// Returns the `/Contents` entry which can be either a single stream
    /// or an array of streams containing the page's content operators.
    ///
    /// - Returns: The COSValue for the contents, or `nil` if not present.
    public var contents: COSValue? {
        optionalEntry(.contents)
    }

    /// The page's rotation angle (optional, may be inherited).
    ///
    /// Returns the `/Rotate` entry as an integer multiple of 90 degrees
    /// (0, 90, 180, or 270).
    ///
    /// - Returns: The rotation angle in degrees, or `nil` if not present.
    public var rotate: Int64? {
        optionalInteger("Rotate")
    }

    /// The page's annotation array (optional).
    ///
    /// Returns the `/Annots` entry which is an array of annotation dictionaries.
    ///
    /// - Returns: The COSValue for the annotations array, or `nil` if not present.
    public var annots: [COSValue]? {
        optionalArray(.annots)
    }

    /// The page's thumbnail image (optional).
    ///
    /// Returns the `/Thumb` entry which references an image XObject.
    ///
    /// - Returns: The COSValue for the thumbnail, or `nil` if not present.
    public var thumb: COSValue? {
        optionalEntry("Thumb")
    }

    /// The page's bleed box (optional).
    ///
    /// Returns the `/BleedBox` entry.
    ///
    /// - Returns: The bleed box array, or `nil` if not present.
    public var bleedBox: [COSValue]? {
        optionalArray("BleedBox")
    }

    /// The page's trim box (optional).
    ///
    /// Returns the `/TrimBox` entry.
    ///
    /// - Returns: The trim box array, or `nil` if not present.
    public var trimBox: [COSValue]? {
        optionalArray("TrimBox")
    }

    /// The page's art box (optional).
    ///
    /// Returns the `/ArtBox` entry.
    ///
    /// - Returns: The art box array, or `nil` if not present.
    public var artBox: [COSValue]? {
        optionalArray("ArtBox")
    }

    /// The page's user unit (optional).
    ///
    /// Returns the `/UserUnit` entry which specifies the size of default user
    /// space units (default is 1.0 = 1/72 inch).
    ///
    /// - Returns: The user unit as a numeric value, or `nil` if not present.
    public var userUnit: Double? {
        optionalEntry("UserUnit")?.numericValue
    }
}
