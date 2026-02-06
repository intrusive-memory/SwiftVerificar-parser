import Foundation

/// Represents the class map for mapping attribute classes to attribute objects.
///
/// The class map allows PDF authors to define reusable sets of attributes
/// (attribute classes) that can be referenced by multiple structure elements.
/// This promotes consistency and reduces redundancy in tagged PDF documents.
///
/// This type corresponds to the Java class map handling in veraPDF-parser.
///
/// ## PDF Specification
/// The class map is a dictionary in the structure tree root (`/ClassMap` entry)
/// that maps class names (name objects) to attribute objects (dictionaries or arrays).
///
/// Structure elements reference attribute classes via the `/C` entry, which can be:
/// - A single class name
/// - An array of class names
///
/// ## Usage
/// ```swift
/// let classMap = try PDClassMap(cosObject: classMapDict)
/// let attrs = classMap.attributesForClass(ASAtom("TableHeader"))
/// let hasClass = classMap.hasClass(ASAtom("Emphasis"))
/// let allClasses = classMap.allClassNames()
/// ```
public struct PDClassMap: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this class map.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a class map from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Class Mapping

    /// Gets the attribute object(s) for a given class name.
    ///
    /// - Parameter className: The class name to look up.
    /// - Returns: The attribute object (dictionary or array), or `nil` if not found.
    public func attributesForClass(_ className: ASAtom) -> COSValue? {
        guard let dict = cosObject.dictionaryValue else {
            return nil
        }
        return dict[className]
    }

    /// Gets the attribute object for a class name as a PDAttributeObject.
    ///
    /// - Parameter className: The class name to look up.
    /// - Returns: The attribute object, or `nil` if not found or malformed.
    /// - Throws: `PDError` if the attribute object is malformed.
    public func attributeObjectForClass(_ className: ASAtom) throws -> PDAttributeObject? {
        guard let attrs = attributesForClass(className) else {
            return nil
        }
        return try PDAttributeObject(cosObject: attrs)
    }

    /// Checks if a class name is defined in this class map.
    ///
    /// - Parameter className: The class name to check.
    /// - Returns: `true` if the class is defined, `false` otherwise.
    public func hasClass(_ className: ASAtom) -> Bool {
        attributesForClass(className) != nil
    }

    /// Gets all class names defined in this class map.
    ///
    /// - Returns: A set of all class names.
    public func allClassNames() -> Set<ASAtom> {
        guard let dict = cosObject.dictionaryValue else {
            return []
        }
        return Set(dict.keys)
    }

    /// Gets all class mappings as a dictionary.
    ///
    /// - Returns: A dictionary mapping class names to attribute objects.
    public func allMappings() -> [ASAtom: COSValue] {
        guard let dict = cosObject.dictionaryValue else {
            return [:]
        }
        return dict
    }

    /// Resolves all attributes for a list of class names.
    ///
    /// When multiple classes are specified, attributes from all classes are combined.
    /// If the same attribute appears in multiple classes, the last one wins
    /// (later classes override earlier ones).
    ///
    /// - Parameter classNames: An array of class names to resolve.
    /// - Returns: A combined attribute object, or `nil` if no classes are found.
    /// - Throws: `PDError` if any attribute object is malformed.
    public func resolveAttributes(forClasses classNames: [ASAtom]) throws -> PDAttributeObject? {
        var combinedAttributes: [ASAtom: COSValue] = [:]

        for className in classNames {
            if let attrs = attributesForClass(className) {
                // If it's a dictionary, merge it
                if let dict = attrs.dictionaryValue {
                    for (key, value) in dict {
                        combinedAttributes[key] = value
                    }
                }
                // If it's an array of dictionaries, merge each one
                else if let array = attrs.arrayValue {
                    for item in array {
                        if let dict = item.dictionaryValue {
                            for (key, value) in dict {
                                combinedAttributes[key] = value
                            }
                        }
                    }
                }
            }
        }

        if combinedAttributes.isEmpty {
            return nil
        }

        return try PDAttributeObject(cosObject: .dictionary(combinedAttributes))
    }
}
