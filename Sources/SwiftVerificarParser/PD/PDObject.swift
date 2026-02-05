import Foundation

/// Base protocol for all PD (Page Description) layer objects.
///
/// The PD layer provides a high-level, typed API for working with PDF document
/// structures, built on top of the low-level COS (Carousel Object System) layer.
///
/// This protocol corresponds to the Java `PDObject` interface from veraPDF-parser.
/// Every PD object wraps one or more COS objects and provides type-safe accessors
/// for PDF-specific data structures like catalogs, pages, resources, fonts, etc.
///
/// ## Design Notes
/// - PD objects are typically structs (value types) for immutability and thread safety
/// - Each PD object holds a reference to its underlying `COSValue`
/// - The protocol uses associated types where needed for type safety
public protocol PDObject: Sendable {

    /// The underlying COS object that this PD object wraps.
    ///
    /// This is typically a `.dictionary`, but could be other types
    /// (e.g., `.stream` for content streams, `.array` for page trees).
    var cosObject: COSValue { get }

    /// Creates a PD object from a COS object.
    ///
    /// - Parameter cosObject: The COS object to wrap.
    /// - Throws: `PDError` if the COS object is malformed or has an incorrect type.
    init(cosObject: COSValue) throws
}

// MARK: - Default Implementations

extension PDObject {

    /// Accesses a required dictionary entry by name.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The value if present.
    /// - Throws: `PDError.missingRequiredEntry` if the entry is not found.
    func requireEntry(_ key: ASAtom) throws -> COSValue {
        guard let value = cosObject[key] else {
            throw PDError.missingRequiredEntry(key: key.stringValue)
        }
        return value
    }

    /// Accesses an optional dictionary entry by name.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The value if present, or `nil` otherwise.
    func optionalEntry(_ key: ASAtom) -> COSValue? {
        cosObject[key]
    }

    /// Accesses a required name entry and returns it as an `ASAtom`.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The name value.
    /// - Throws: `PDError.missingRequiredEntry` or `PDError.incorrectType` if the entry
    ///   is missing or not a name.
    func requireName(_ key: ASAtom) throws -> ASAtom {
        let value = try requireEntry(key)
        guard let name = value.nameValue else {
            throw PDError.incorrectType(key: key.stringValue, expected: "name", actual: String(describing: value))
        }
        return name
    }

    /// Accesses an optional name entry and returns it as an `ASAtom`.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The name value if present and valid, or `nil` otherwise.
    func optionalName(_ key: ASAtom) -> ASAtom? {
        optionalEntry(key)?.nameValue
    }

    /// Accesses a required integer entry.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The integer value.
    /// - Throws: `PDError.missingRequiredEntry` or `PDError.incorrectType`.
    func requireInteger(_ key: ASAtom) throws -> Int64 {
        let value = try requireEntry(key)
        guard let int = value.integerValue else {
            throw PDError.incorrectType(key: key.stringValue, expected: "integer", actual: String(describing: value))
        }
        return int
    }

    /// Accesses an optional integer entry.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The integer value if present and valid, or `nil` otherwise.
    func optionalInteger(_ key: ASAtom) -> Int64? {
        optionalEntry(key)?.integerValue
    }

    /// Accesses a required array entry.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The array value.
    /// - Throws: `PDError.missingRequiredEntry` or `PDError.incorrectType`.
    func requireArray(_ key: ASAtom) throws -> [COSValue] {
        let value = try requireEntry(key)
        guard let array = value.arrayValue else {
            throw PDError.incorrectType(key: key.stringValue, expected: "array", actual: String(describing: value))
        }
        return array
    }

    /// Accesses an optional array entry.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The array value if present and valid, or `nil` otherwise.
    func optionalArray(_ key: ASAtom) -> [COSValue]? {
        optionalEntry(key)?.arrayValue
    }

    /// Accesses a required dictionary entry.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The dictionary value.
    /// - Throws: `PDError.missingRequiredEntry` or `PDError.incorrectType`.
    func requireDictionary(_ key: ASAtom) throws -> [ASAtom: COSValue] {
        let value = try requireEntry(key)
        guard let dict = value.dictionaryValue else {
            throw PDError.incorrectType(key: key.stringValue, expected: "dictionary", actual: String(describing: value))
        }
        return dict
    }

    /// Accesses an optional dictionary entry.
    ///
    /// - Parameter key: The dictionary key to look up.
    /// - Returns: The dictionary value if present and valid, or `nil` otherwise.
    func optionalDictionary(_ key: ASAtom) -> [ASAtom: COSValue]? {
        optionalEntry(key)?.dictionaryValue
    }
}

// MARK: - PD Layer Errors

/// Errors that can occur in the PD layer.
public enum PDError: Error, Sendable, Equatable, CustomStringConvertible {

    /// A required dictionary entry is missing.
    case missingRequiredEntry(key: String)

    /// A dictionary entry has an incorrect type.
    case incorrectType(key: String, expected: String, actual: String)

    /// The COS object is not a dictionary when one is required.
    case notADictionary

    /// The COS object is not an array when one is required.
    case notAnArray

    /// The page index is out of bounds.
    case pageIndexOutOfBounds(index: Int, count: Int)

    /// Invalid page tree structure.
    case invalidPageTree(reason: String)

    /// Invalid document structure.
    case invalidDocument(reason: String)

    public var description: String {
        switch self {
        case .missingRequiredEntry(let key):
            return "Missing required entry: \(key)"
        case .incorrectType(let key, let expected, let actual):
            return "Incorrect type for entry '\(key)': expected \(expected), got \(actual)"
        case .notADictionary:
            return "COS object is not a dictionary"
        case .notAnArray:
            return "COS object is not an array"
        case .pageIndexOutOfBounds(let index, let count):
            return "Page index \(index) out of bounds (count: \(count))"
        case .invalidPageTree(let reason):
            return "Invalid page tree: \(reason)"
        case .invalidDocument(let reason):
            return "Invalid document: \(reason)"
        }
    }
}
