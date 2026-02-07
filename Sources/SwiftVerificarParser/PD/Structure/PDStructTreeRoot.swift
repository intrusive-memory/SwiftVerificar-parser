import Foundation

/// Represents the root of the PDF structure tree (tagged PDF).
///
/// The structure tree root is the top-level object in the document's structure hierarchy,
/// defining the logical structure and reading order for accessibility and tagged PDF support.
/// This is critical for PDF/UA (Universal Accessibility) compliance.
///
/// This type corresponds to the Java `PDStructTreeRoot` class from veraPDF-parser.
///
/// ## PDF Specification
/// The structure tree root dictionary is referenced by the `/StructTreeRoot` entry in the
/// document catalog and must have a `/Type` entry with value `/StructTreeRoot`.
///
/// Key entries include:
/// - `/K`: The immediate children (structure elements or element references)
/// - `/RoleMap`: Mapping of custom roles to standard structure types
/// - `/ClassMap`: Mapping of attribute classes to attribute dictionaries
/// - `/ParentTree`: Number tree mapping structure elements to their parent elements
/// - `/IDTree`: Name tree mapping element identifiers to structure elements
///
/// ## Usage
/// ```swift
/// let structRoot = try PDStructTreeRoot(cosObject: structTreeDict)
/// let roleMap = structRoot.roleMap
/// let children = try structRoot.children()
/// ```
public struct PDStructTreeRoot: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this structure tree root.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a structure tree root from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Structure Tree Root Entries

    /// The type entry (should be "StructTreeRoot").
    ///
    /// - Returns: The type name, or `nil` if not present.
    public var type: ASAtom? {
        optionalName(.type)
    }

    /// The immediate children of the structure tree root.
    ///
    /// Returns the `/K` entry which can be either:
    /// - A single structure element dictionary
    /// - An array of structure elements
    ///
    /// - Returns: The COSValue for the children, or `nil` if not present.
    public var k: COSValue? {
        optionalEntry(.k)
    }

    /// The immediate children as an array.
    ///
    /// Normalizes the `/K` entry to always return an array, even if it's a single object.
    ///
    /// - Returns: An array of child structure elements.
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

    /// The role map dictionary (optional).
    ///
    /// Returns the `/RoleMap` entry which maps custom role names to standard
    /// structure types defined in the PDF specification.
    ///
    /// - Returns: The COSValue for the role map dictionary, or `nil` if not present.
    public var roleMap: COSValue? {
        optionalEntry(.roleMap)
    }

    /// The role map as a PDRoleMap object.
    ///
    /// - Returns: The role map object, or `nil` if not present.
    /// - Throws: `PDError` if the role map is malformed.
    public func roleMapObject() throws -> PDRoleMap? {
        guard let rm = roleMap else {
            return nil
        }
        return try PDRoleMap(cosObject: rm)
    }

    /// The class map dictionary (optional).
    ///
    /// Returns the `/ClassMap` entry which maps class names to attribute dictionaries.
    ///
    /// - Returns: The COSValue for the class map dictionary, or `nil` if not present.
    public var classMap: COSValue? {
        optionalEntry(.classMap)
    }

    /// The class map as a PDClassMap object.
    ///
    /// - Returns: The class map object, or `nil` if not present.
    /// - Throws: `PDError` if the class map is malformed.
    public func classMapObject() throws -> PDClassMap? {
        guard let cm = classMap else {
            return nil
        }
        return try PDClassMap(cosObject: cm)
    }

    /// The parent tree (optional).
    ///
    /// Returns the `/ParentTree` entry which is a number tree that maps
    /// structure element MCIDs to their parent structure elements.
    ///
    /// - Returns: The COSValue for the parent tree, or `nil` if not present.
    public var parentTree: COSValue? {
        optionalEntry("ParentTree")
    }

    /// The next key for the parent tree (optional).
    ///
    /// Returns the `/ParentTreeNextKey` entry which indicates the next available
    /// integer key in the parent tree.
    ///
    /// - Returns: The next key value, or `nil` if not present.
    public var parentTreeNextKey: Int64? {
        optionalInteger("ParentTreeNextKey")
    }

    /// The ID tree (optional).
    ///
    /// Returns the `/IDTree` entry which is a name tree that maps element
    /// identifiers to structure elements.
    ///
    /// - Returns: The COSValue for the ID tree, or `nil` if not present.
    public var idTree: COSValue? {
        optionalEntry("IDTree")
    }

    /// Validates that this is a valid structure tree root.
    ///
    /// - Returns: `true` if valid, `false` otherwise.
    public func validate() -> Bool {
        // Optional validation: check that Type is StructTreeRoot if present
        if let typeValue = type {
            return typeValue == .structTreeRoot
        }
        return true
    }
}
