import Foundation

/// Protocol for parsing PDF objects at the COS (Carousel Object System) layer.
///
/// `COSParser` defines the interface for parsers that convert byte streams into
/// COS objects (the low-level PDF object model). Implementations handle tokenization,
/// object parsing, cross-reference table management, and object retrieval.
///
/// This protocol corresponds to the abstract Java `COSParser` class from veraPDF-parser,
/// adapted to Swift's protocol-oriented design.
///
/// ## Responsibilities
///
/// A COS parser is responsible for:
/// - Tokenizing the PDF byte stream
/// - Parsing individual objects (primitives, arrays, dictionaries)
/// - Resolving indirect object references
/// - Managing the cross-reference table
/// - Handling incremental updates
///
/// ## Usage
/// ```swift
/// let parser = someCOSParser
/// let catalog = try await parser.getObject(key: COSObjectKey(objectNumber: 1))
/// ```
public protocol COSParser: Sendable {

    // MARK: - Object Retrieval

    /// Retrieves a PDF object by its object key.
    ///
    /// This method resolves the object reference using the cross-reference table,
    /// seeks to the object's location in the file, and parses it.
    ///
    /// - Parameter key: The object key (object number + generation number).
    /// - Returns: The parsed object value, or `nil` if not found.
    /// - Throws: If an error occurs during parsing.
    func getObject(key: COSObjectKey) async throws -> COSValue?

    /// Retrieves a PDF object by object number (assumes generation 0).
    ///
    /// - Parameter objectNumber: The object number.
    /// - Returns: The parsed object value, or `nil` if not found.
    /// - Throws: If an error occurs during parsing.
    func getObject(objectNumber: Int) async throws -> COSValue?

    // MARK: - Cross-Reference Table

    /// The cross-reference table for this document.
    ///
    /// The xref table maps object numbers to byte offsets in the file.
    var xrefTable: XRefTable { get }

    // MARK: - Document Metadata

    /// The PDF header (version information).
    var header: PDFHeader { get }

    /// The trailer dictionary.
    var trailer: PDFTrailer { get }
}

// MARK: - Default Implementations

extension COSParser {

    /// Default implementation that uses generation 0.
    public func getObject(objectNumber: Int) async throws -> COSValue? {
        try await getObject(key: COSObjectKey(objectNumber: objectNumber, generation: 0))
    }

    /// Convenience method to get the document catalog.
    ///
    /// - Returns: The catalog dictionary, or `nil` if not found.
    /// - Throws: If an error occurs during parsing.
    public func getCatalog() async throws -> COSValue? {
        guard let rootValue = trailer.rootValue else {
            return nil
        }
        // Resolve the reference if it is one
        return try await resolve(rootValue)
    }

    /// Convenience method to get the document info dictionary.
    ///
    /// - Returns: The info dictionary, or `nil` if not found.
    /// - Throws: If an error occurs during parsing.
    public func getInfo() async throws -> COSValue? {
        guard let infoValue = trailer.infoValue else {
            return nil
        }
        // Resolve the reference if it is one
        return try await resolve(infoValue)
    }

    /// Resolves a reference to its value.
    ///
    /// If the value is a reference, this follows the reference and returns the
    /// referenced object. If it's not a reference, returns the value as-is.
    ///
    /// - Parameter value: The value to resolve.
    /// - Returns: The resolved value.
    /// - Throws: If an error occurs during parsing.
    public func resolve(_ value: COSValue) async throws -> COSValue {
        if let ref = value.referenceValue {
            if let resolved = try await getObject(key: ref.key) {
                return resolved
            }
            // Reference points to non-existent object, return null
            return .null
        }
        return value
    }

    /// Recursively resolves all references in a value.
    ///
    /// This follows references transitively (reference to reference to object)
    /// and returns the final dereferenced value.
    ///
    /// - Parameter value: The value to fully resolve.
    /// - Returns: The fully resolved value.
    /// - Throws: If an error occurs during parsing.
    public func fullyResolve(_ value: COSValue) async throws -> COSValue {
        var current = value
        var visited = Set<COSObjectKey>()

        // Follow references until we hit a non-reference or a cycle
        while let ref = current.referenceValue {
            // Detect cycles
            if visited.contains(ref.key) {
                // Circular reference, return null
                return .null
            }
            visited.insert(ref.key)

            // Resolve the reference
            if let resolved = try await getObject(key: ref.key) {
                current = resolved
            } else {
                // Reference points to non-existent object
                return .null
            }
        }

        return current
    }

    /// Resolves a value and returns it as a dictionary.
    ///
    /// - Parameter value: The value to resolve (may be a reference).
    /// - Returns: The dictionary value, or `nil` if not a dictionary.
    /// - Throws: If an error occurs during parsing.
    public func resolveDictionary(_ value: COSValue) async throws -> [ASAtom: COSValue]? {
        let resolved = try await resolve(value)
        return resolved.dictionaryValue
    }

    /// Resolves a value and returns it as an array.
    ///
    /// - Parameter value: The value to resolve (may be a reference).
    /// - Returns: The array value, or `nil` if not an array.
    /// - Throws: If an error occurs during parsing.
    public func resolveArray(_ value: COSValue) async throws -> [COSValue]? {
        let resolved = try await resolve(value)
        return resolved.arrayValue
    }

    /// Resolves a dictionary entry by key.
    ///
    /// This is a convenience method that looks up a key in a dictionary and
    /// resolves the value if it's a reference.
    ///
    /// - Parameters:
    ///   - dictionary: The dictionary to search.
    ///   - key: The key to look up.
    /// - Returns: The resolved value, or `nil` if not found.
    /// - Throws: If an error occurs during parsing.
    public func resolveEntry(_ dictionary: [ASAtom: COSValue], key: ASAtom) async throws -> COSValue? {
        guard let value = dictionary[key] else {
            return nil
        }
        return try await resolve(value)
    }
}
