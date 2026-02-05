import Foundation

/// Represents a PDF resources dictionary.
///
/// A resources dictionary contains named resources required by a content stream,
/// including fonts, XObjects, color spaces, patterns, shadings, and graphics states.
///
/// This type corresponds to the Java `PDResources` class from veraPDF-parser.
///
/// ## PDF Specification
/// Resources dictionaries are associated with pages, form XObjects, Type 3 fonts,
/// and patterns. They provide the resource objects referenced by name in content streams.
///
/// ## Usage
/// ```swift
/// let resources = try PDFResources(cosObject: resourcesDict)
/// let fonts = resources.fonts
/// let xObjects = resources.xObjects
/// ```
public struct PDFResources: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this resources object.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a resources object from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Resource Dictionaries

    /// The font resources dictionary (optional).
    ///
    /// Returns the `/Font` entry which is a dictionary mapping font names
    /// to font dictionaries.
    ///
    /// - Returns: The COSValue for the font dictionary, or `nil` if not present.
    public var fonts: COSValue? {
        optionalEntry(.font)
    }

    /// The XObject resources dictionary (optional).
    ///
    /// Returns the `/XObject` entry which is a dictionary mapping XObject names
    /// to XObject streams (images, forms, or PostScript objects).
    ///
    /// - Returns: The COSValue for the XObject dictionary, or `nil` if not present.
    public var xObjects: COSValue? {
        optionalEntry(.xObject)
    }

    /// The color space resources dictionary (optional).
    ///
    /// Returns the `/ColorSpace` entry which is a dictionary mapping color space names
    /// to color space definitions.
    ///
    /// - Returns: The COSValue for the color space dictionary, or `nil` if not present.
    public var colorSpaces: COSValue? {
        optionalEntry(.colorSpace)
    }

    /// The pattern resources dictionary (optional).
    ///
    /// Returns the `/Pattern` entry which is a dictionary mapping pattern names
    /// to pattern dictionaries.
    ///
    /// - Returns: The COSValue for the pattern dictionary, or `nil` if not present.
    public var patterns: COSValue? {
        optionalEntry(.pattern)
    }

    /// The shading resources dictionary (optional).
    ///
    /// Returns the `/Shading` entry which is a dictionary mapping shading names
    /// to shading dictionaries.
    ///
    /// - Returns: The COSValue for the shading dictionary, or `nil` if not present.
    public var shadings: COSValue? {
        optionalEntry("Shading")
    }

    /// The extended graphics state resources dictionary (optional).
    ///
    /// Returns the `/ExtGState` entry which is a dictionary mapping graphics state names
    /// to extended graphics state dictionaries.
    ///
    /// - Returns: The COSValue for the ExtGState dictionary, or `nil` if not present.
    public var extGStates: COSValue? {
        optionalEntry(.extGState)
    }

    /// The properties (marked content) resources dictionary (optional).
    ///
    /// Returns the `/Properties` entry which is a dictionary mapping property names
    /// to property dictionaries (used for marked content).
    ///
    /// - Returns: The COSValue for the properties dictionary, or `nil` if not present.
    public var properties: COSValue? {
        optionalEntry(.properties)
    }

    /// The procedure set array (optional, deprecated in PDF 2.0).
    ///
    /// Returns the `/ProcSet` entry which is an array of procedure set names
    /// (e.g., `/PDF`, `/Text`, `/ImageB`, `/ImageC`, `/ImageI`).
    ///
    /// This entry is obsolete and should not be used in new documents.
    ///
    /// - Returns: The COSValue for the ProcSet array, or `nil` if not present.
    public var procSet: [COSValue]? {
        optionalArray("ProcSet")
    }

    // MARK: - Resource Lookup

    /// Looks up a named font resource.
    ///
    /// - Parameter name: The font name (e.g., `/F1`).
    /// - Returns: The COSValue for the font dictionary, or `nil` if not found.
    public func font(named name: ASAtom) -> COSValue? {
        fonts?[name]
    }

    /// Looks up a named XObject resource.
    ///
    /// - Parameter name: The XObject name (e.g., `/Im1`).
    /// - Returns: The COSValue for the XObject, or `nil` if not found.
    public func xObject(named name: ASAtom) -> COSValue? {
        xObjects?[name]
    }

    /// Looks up a named color space resource.
    ///
    /// - Parameter name: The color space name (e.g., `/CS1`).
    /// - Returns: The COSValue for the color space, or `nil` if not found.
    public func colorSpace(named name: ASAtom) -> COSValue? {
        colorSpaces?[name]
    }

    /// Looks up a named pattern resource.
    ///
    /// - Parameter name: The pattern name (e.g., `/P1`).
    /// - Returns: The COSValue for the pattern, or `nil` if not found.
    public func pattern(named name: ASAtom) -> COSValue? {
        patterns?[name]
    }

    /// Looks up a named shading resource.
    ///
    /// - Parameter name: The shading name (e.g., `/Sh1`).
    /// - Returns: The COSValue for the shading, or `nil` if not found.
    public func shading(named name: ASAtom) -> COSValue? {
        shadings?[name]
    }

    /// Looks up a named extended graphics state resource.
    ///
    /// - Parameter name: The graphics state name (e.g., `/GS1`).
    /// - Returns: The COSValue for the ExtGState dictionary, or `nil` if not found.
    public func extGState(named name: ASAtom) -> COSValue? {
        extGStates?[name]
    }

    /// Looks up a named property resource.
    ///
    /// - Parameter name: The property name (e.g., `/MC1`).
    /// - Returns: The COSValue for the property dictionary, or `nil` if not found.
    public func property(named name: ASAtom) -> COSValue? {
        properties?[name]
    }
}
