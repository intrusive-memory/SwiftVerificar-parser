import Foundation

/// Represents the role map for mapping custom structure types to standard types.
///
/// The role map allows PDF authors to use custom structure types (roles) while
/// maintaining compatibility with standard structure types defined in the PDF
/// specification. This is essential for extensibility while preserving accessibility.
///
/// This type corresponds to the Java role map handling in veraPDF-parser.
///
/// ## PDF Specification
/// The role map is a dictionary in the structure tree root (`/RoleMap` entry)
/// that maps custom role names to standard structure types or other custom roles.
///
/// Standard structure types include:
/// - Document elements: "Document", "Part", "Art", "Sect", "Div"
/// - Paragraphs: "P"
/// - Headings: "H", "H1"-"H6"
/// - Lists: "L", "LI", "Lbl", "LBody"
/// - Tables: "Table", "TR", "TH", "TD"
/// - Inline: "Span", "Quote", "Note", "Reference"
/// - Illustrations: "Figure", "Formula", "Form"
///
/// ## Usage
/// ```swift
/// let roleMap = try PDRoleMap(cosObject: roleMapDict)
/// let standardType = roleMap.mapToStandard(ASAtom("Heading1"))  // → "H1"
/// let isMapped = roleMap.hasMappingFor(ASAtom("CustomPara"))    // → true/false
/// ```
public struct PDRoleMap: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this role map.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a role map from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Role Mapping

    /// Maps a custom role to its standard structure type.
    ///
    /// This method follows the mapping chain until a standard type is found
    /// or a cycle is detected.
    ///
    /// - Parameter customRole: The custom role name to map.
    /// - Returns: The standard structure type, or the original role if no mapping exists.
    public func mapToStandard(_ customRole: ASAtom) -> ASAtom {
        var currentRole = customRole
        var visited: Set<ASAtom> = []

        // Follow the mapping chain
        while let mappedRole = directMapping(for: currentRole) {
            // Check for cycles
            if visited.contains(currentRole) {
                // Cycle detected - return the current role
                return currentRole
            }

            visited.insert(currentRole)
            currentRole = mappedRole
        }

        return currentRole
    }

    /// Gets the direct mapping for a role (one level only).
    ///
    /// - Parameter role: The role to look up.
    /// - Returns: The directly mapped role, or `nil` if no mapping exists.
    public func directMapping(for role: ASAtom) -> ASAtom? {
        guard let dict = cosObject.dictionaryValue else {
            return nil
        }
        return dict[role]?.nameValue
    }

    /// Checks if a mapping exists for the given role.
    ///
    /// - Parameter role: The role to check.
    /// - Returns: `true` if a mapping exists, `false` otherwise.
    public func hasMappingFor(_ role: ASAtom) -> Bool {
        directMapping(for: role) != nil
    }

    /// Gets all custom roles defined in this role map.
    ///
    /// - Returns: A set of all custom role names.
    public func allCustomRoles() -> Set<ASAtom> {
        guard let dict = cosObject.dictionaryValue else {
            return []
        }
        return Set(dict.keys)
    }

    /// Gets all mappings as a dictionary.
    ///
    /// - Returns: A dictionary mapping custom roles to standard types.
    public func allMappings() -> [ASAtom: ASAtom] {
        guard let dict = cosObject.dictionaryValue else {
            return [:]
        }

        var mappings: [ASAtom: ASAtom] = [:]
        for (key, value) in dict {
            if let nameValue = value.nameValue {
                mappings[key] = nameValue
            }
        }
        return mappings
    }

    /// Checks if the given role is a standard structure type.
    ///
    /// This checks against the list of standard structure types defined in
    /// PDF 1.7 (ISO 32000-1:2008) and PDF 2.0 (ISO 32000-2:2020).
    ///
    /// - Parameter role: The role to check.
    /// - Returns: `true` if the role is a standard type, `false` otherwise.
    public static func isStandardType(_ role: ASAtom) -> Bool {
        standardStructureTypes.contains(role)
    }

    // MARK: - Standard Structure Types

    /// The set of standard structure types defined in the PDF specification.
    ///
    /// This includes types from PDF 1.7 and PDF 2.0.
    public static let standardStructureTypes: Set<ASAtom> = [
        // Grouping elements
        ASAtom("Document"),
        ASAtom("Part"),
        ASAtom("Art"),
        ASAtom("Sect"),
        ASAtom("Div"),
        ASAtom("BlockQuote"),
        ASAtom("Caption"),
        ASAtom("TOC"),
        ASAtom("TOCI"),
        ASAtom("Index"),
        ASAtom("NonStruct"),
        ASAtom("Private"),

        // Paragraph-like elements
        ASAtom("P"),
        ASAtom("H"),
        ASAtom("H1"),
        ASAtom("H2"),
        ASAtom("H3"),
        ASAtom("H4"),
        ASAtom("H5"),
        ASAtom("H6"),

        // List elements
        ASAtom("L"),
        ASAtom("LI"),
        ASAtom("Lbl"),
        ASAtom("LBody"),

        // Table elements
        ASAtom("Table"),
        ASAtom("TR"),
        ASAtom("TH"),
        ASAtom("TD"),
        ASAtom("THead"),
        ASAtom("TBody"),
        ASAtom("TFoot"),

        // Inline elements
        ASAtom("Span"),
        ASAtom("Quote"),
        ASAtom("Note"),
        ASAtom("Reference"),
        ASAtom("BibEntry"),
        ASAtom("Code"),
        ASAtom("Link"),
        ASAtom("Annot"),

        // Ruby (for East Asian text)
        ASAtom("Ruby"),
        ASAtom("RB"),
        ASAtom("RT"),
        ASAtom("RP"),

        // Warichu (for East Asian text)
        ASAtom("Warichu"),
        ASAtom("WT"),
        ASAtom("WP"),

        // Illustration elements
        ASAtom("Figure"),
        ASAtom("Formula"),
        ASAtom("Form"),

        // PDF 2.0 additions
        ASAtom("Artifact"),
        ASAtom("DocumentFragment"),
        ASAtom("Aside"),
        ASAtom("Title"),
        ASAtom("FENote"),
        ASAtom("Sub"),
        ASAtom("Em"),
        ASAtom("Strong"),
    ]
}
