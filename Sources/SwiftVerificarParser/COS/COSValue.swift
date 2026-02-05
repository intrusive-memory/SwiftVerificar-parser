import Foundation

/// Represents any PDF object value in the Carousel Object System (COS) layer.
///
/// `COSValue` is the foundational type of the parser, consolidating 15 Java COS
/// classes (`COSNull`, `COSBoolean`, `COSInteger`, `COSReal`, `COSString`,
/// `COSName`, `COSArray`, `COSDictionary`, and related types) into a single
/// Swift enum with associated values. This eliminates the need for a visitor
/// pattern and enables exhaustive `switch` statements for type-safe handling.
///
/// Each case corresponds to one of the basic PDF object types defined in the
/// PDF specification (ISO 32000):
///
/// - `null` -- The null object
/// - `boolean` -- Boolean values (`true` or `false`)
/// - `integer` -- Integer numbers (stored as `Int64`)
/// - `real` -- Real numbers (stored as `Double`)
/// - `string` -- String objects (literal or hex-encoded)
/// - `name` -- Name objects (interned via `ASAtom`)
/// - `array` -- Ordered collections of PDF objects
/// - `dictionary` -- Key-value maps with name keys
///
/// ## Usage
/// ```swift
/// let value: COSValue = .integer(42)
/// let dict: COSValue = .dictionary([.type: .name(.page)])
/// if case .integer(let n) = value { print(n) }
/// ```
///
/// ## Note on Streams and References
/// `COSStream` and `COSReference` are defined in Sprint 2 and will be added
/// as cases to this enum (or composed with it) at that time. For Sprint 1,
/// this enum covers the eight core PDF value types that do not require
/// stream infrastructure.
public enum COSValue: Sendable, Hashable, CustomStringConvertible {

    /// The PDF null object.
    case null

    /// A PDF boolean value.
    case boolean(Bool)

    /// A PDF integer value (64-bit signed).
    case integer(Int64)

    /// A PDF real (floating-point) value.
    case real(Double)

    /// A PDF string object (literal or hex-encoded).
    case string(COSString)

    /// A PDF name object.
    case name(ASAtom)

    /// A PDF array (ordered collection of values).
    case array([COSValue])

    /// A PDF dictionary (name-keyed map of values).
    case dictionary([ASAtom: COSValue])

    /// An indirect object reference.
    case reference(COSReference)

    // MARK: - Type Checking

    /// Whether this value is `null`.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    /// Whether this value is a boolean.
    public var isBoolean: Bool {
        if case .boolean = self { return true }
        return false
    }

    /// Whether this value is an integer.
    public var isInteger: Bool {
        if case .integer = self { return true }
        return false
    }

    /// Whether this value is a real number.
    public var isReal: Bool {
        if case .real = self { return true }
        return false
    }

    /// Whether this value is a numeric type (integer or real).
    public var isNumeric: Bool {
        isInteger || isReal
    }

    /// Whether this value is a string.
    public var isString: Bool {
        if case .string = self { return true }
        return false
    }

    /// Whether this value is a name.
    public var isName: Bool {
        if case .name = self { return true }
        return false
    }

    /// Whether this value is an array.
    public var isArray: Bool {
        if case .array = self { return true }
        return false
    }

    /// Whether this value is a dictionary.
    public var isDictionary: Bool {
        if case .dictionary = self { return true }
        return false
    }

    /// Whether this value is a reference.
    public var isReference: Bool {
        if case .reference = self { return true }
        return false
    }

    // MARK: - Value Extraction

    /// Extracts the boolean value, if this is a `.boolean` case.
    public var boolValue: Bool? {
        if case .boolean(let v) = self { return v }
        return nil
    }

    /// Extracts the integer value, if this is an `.integer` case.
    public var integerValue: Int64? {
        if case .integer(let v) = self { return v }
        return nil
    }

    /// Extracts the real value, if this is a `.real` case.
    public var realValue: Double? {
        if case .real(let v) = self { return v }
        return nil
    }

    /// Extracts a numeric value as `Double`, accepting both `.integer` and `.real`.
    ///
    /// For `.integer` values, the integer is converted to `Double`.
    /// For `.real` values, the double is returned directly.
    public var numericValue: Double? {
        switch self {
        case .integer(let v): return Double(v)
        case .real(let v): return v
        default: return nil
        }
    }

    /// Extracts the `COSString` value, if this is a `.string` case.
    public var stringValue: COSString? {
        if case .string(let v) = self { return v }
        return nil
    }

    /// Extracts the text content of the string, if this is a `.string` case.
    ///
    /// This decodes the raw bytes using the appropriate encoding (UTF-16BE if
    /// a BOM is present, PDFDocEncoding otherwise).
    public var textValue: String? {
        stringValue?.stringValue
    }

    /// Extracts the `ASAtom` value, if this is a `.name` case.
    public var nameValue: ASAtom? {
        if case .name(let v) = self { return v }
        return nil
    }

    /// Extracts the array, if this is an `.array` case.
    public var arrayValue: [COSValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    /// Extracts the dictionary, if this is a `.dictionary` case.
    public var dictionaryValue: [ASAtom: COSValue]? {
        if case .dictionary(let v) = self { return v }
        return nil
    }

    /// Extracts the reference, if this is a `.reference` case.
    public var referenceValue: COSReference? {
        if case .reference(let v) = self { return v }
        return nil
    }

    // MARK: - Dictionary Access

    /// Accesses a value in a dictionary by name key.
    ///
    /// Returns `nil` if this is not a dictionary or the key is not present.
    ///
    /// - Parameter key: The name key to look up.
    /// - Returns: The value associated with the key, or `nil`.
    public subscript(key: ASAtom) -> COSValue? {
        if case .dictionary(let dict) = self {
            return dict[key]
        }
        return nil
    }

    /// Accesses a value in a dictionary by string key.
    ///
    /// This is a convenience subscript that wraps the string in an `ASAtom`.
    ///
    /// - Parameter key: The string key to look up.
    /// - Returns: The value associated with the key, or `nil`.
    public subscript(key: String) -> COSValue? {
        self[ASAtom(key)]
    }

    // MARK: - Array Access

    /// Accesses a value in an array by index.
    ///
    /// Returns `nil` if this is not an array or the index is out of bounds.
    ///
    /// - Parameter index: The zero-based index.
    /// - Returns: The value at the given index, or `nil`.
    public subscript(index: Int) -> COSValue? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    // MARK: - Dictionary Helpers

    /// Returns the value of the "Type" entry in a dictionary as an `ASAtom`.
    ///
    /// This is a common operation since many PDF dictionaries have a `/Type` entry
    /// that identifies the kind of object.
    public var typeEntry: ASAtom? {
        self[.type]?.nameValue
    }

    /// Returns the value of the "Subtype" entry in a dictionary as an `ASAtom`.
    public var subtypeEntry: ASAtom? {
        self[.subtype]?.nameValue
    }

    /// Returns the number of entries in a dictionary, or elements in an array.
    ///
    /// Returns `nil` for other types.
    public var count: Int? {
        switch self {
        case .array(let arr): return arr.count
        case .dictionary(let dict): return dict.count
        default: return nil
        }
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .null:
            return "null"
        case .boolean(let v):
            return v ? "true" : "false"
        case .integer(let v):
            return String(v)
        case .real(let v):
            // Use a format that avoids unnecessary trailing zeros
            if v == v.rounded() && abs(v) < 1e15 {
                return String(format: "%.1f", v)
            }
            return String(v)
        case .string(let v):
            return v.description
        case .name(let v):
            return v.description
        case .array(let arr):
            let items = arr.map(\.description).joined(separator: " ")
            return "[\(items)]"
        case .dictionary(let dict):
            let entries = dict.sorted { $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }
                .joined(separator: " ")
            return "<<\(entries)>>"
        case .reference(let ref):
            return ref.description
        }
    }
}

// MARK: - Codable

extension COSValue: Codable {

    /// Coding keys for the tagged union representation.
    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    /// Type discriminator values for Codable encoding.
    private enum TypeTag: String, Codable {
        case null, boolean, integer, real, string, name, array, dictionary, reference
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tag = try container.decode(TypeTag.self, forKey: .type)

        switch tag {
        case .null:
            self = .null
        case .boolean:
            self = .boolean(try container.decode(Bool.self, forKey: .value))
        case .integer:
            self = .integer(try container.decode(Int64.self, forKey: .value))
        case .real:
            self = .real(try container.decode(Double.self, forKey: .value))
        case .string:
            self = .string(try container.decode(COSString.self, forKey: .value))
        case .name:
            self = .name(try container.decode(ASAtom.self, forKey: .value))
        case .array:
            self = .array(try container.decode([COSValue].self, forKey: .value))
        case .dictionary:
            // Dictionaries are encoded as arrays of key-value pairs since
            // ASAtom keys need special handling in JSON.
            let pairs = try container.decode([[String: COSValue]].self, forKey: .value)
            var dict: [ASAtom: COSValue] = [:]
            for pair in pairs {
                for (key, value) in pair {
                    dict[ASAtom(key)] = value
                }
            }
            self = .dictionary(dict)
        case .reference:
            self = .reference(try container.decode(COSReference.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .null:
            try container.encode(TypeTag.null, forKey: .type)
        case .boolean(let v):
            try container.encode(TypeTag.boolean, forKey: .type)
            try container.encode(v, forKey: .value)
        case .integer(let v):
            try container.encode(TypeTag.integer, forKey: .type)
            try container.encode(v, forKey: .value)
        case .real(let v):
            try container.encode(TypeTag.real, forKey: .type)
            try container.encode(v, forKey: .value)
        case .string(let v):
            try container.encode(TypeTag.string, forKey: .type)
            try container.encode(v, forKey: .value)
        case .name(let v):
            try container.encode(TypeTag.name, forKey: .type)
            try container.encode(v, forKey: .value)
        case .array(let arr):
            try container.encode(TypeTag.array, forKey: .type)
            try container.encode(arr, forKey: .value)
        case .dictionary(let dict):
            try container.encode(TypeTag.dictionary, forKey: .type)
            let pairs: [[String: COSValue]] = dict.map { entry in
                [entry.key.stringValue: entry.value]
            }
            try container.encode(pairs, forKey: .value)
        case .reference(let ref):
            try container.encode(TypeTag.reference, forKey: .type)
            try container.encode(ref, forKey: .value)
        }
    }
}

// MARK: - ExpressibleBy Literals

extension COSValue: ExpressibleByNilLiteral {
    /// Creates a `.null` value from a nil literal.
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension COSValue: ExpressibleByBooleanLiteral {
    /// Creates a `.boolean` value from a boolean literal.
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension COSValue: ExpressibleByIntegerLiteral {
    /// Creates an `.integer` value from an integer literal.
    public init(integerLiteral value: Int64) {
        self = .integer(value)
    }
}

extension COSValue: ExpressibleByFloatLiteral {
    /// Creates a `.real` value from a floating-point literal.
    public init(floatLiteral value: Double) {
        self = .real(value)
    }
}

extension COSValue: ExpressibleByStringLiteral {
    /// Creates a `.name` value from a string literal.
    ///
    /// This allows writing `.name` values concisely as string literals
    /// in contexts where a `COSValue` is expected. To create a `.string` value
    /// from a literal, use `COSValue.string(COSString(string: "..."))`.
    public init(stringLiteral value: String) {
        self = .name(ASAtom(value))
    }
}

extension COSValue: ExpressibleByArrayLiteral {
    /// Creates an `.array` value from an array literal.
    public init(arrayLiteral elements: COSValue...) {
        self = .array(elements)
    }
}

extension COSValue: ExpressibleByDictionaryLiteral {
    /// Creates a `.dictionary` value from a dictionary literal with `ASAtom` keys.
    public init(dictionaryLiteral elements: (ASAtom, COSValue)...) {
        var dict: [ASAtom: COSValue] = [:]
        dict.reserveCapacity(elements.count)
        for (key, value) in elements {
            dict[key] = value
        }
        self = .dictionary(dict)
    }
}

// MARK: - Hashable Conformance for Double

/// Custom `Hashable` implementation to handle `Double.nan` equality correctly
/// and to canonicalize -0.0 to 0.0 for hashing consistency.
extension COSValue {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null:
            hasher.combine(0)
        case .boolean(let v):
            hasher.combine(1)
            hasher.combine(v)
        case .integer(let v):
            hasher.combine(2)
            hasher.combine(v)
        case .real(let v):
            hasher.combine(3)
            // Canonicalize -0.0 to 0.0 for consistent hashing
            hasher.combine(v == 0.0 ? 0.0 : v)
        case .string(let v):
            hasher.combine(4)
            hasher.combine(v)
        case .name(let v):
            hasher.combine(5)
            hasher.combine(v)
        case .array(let arr):
            hasher.combine(6)
            hasher.combine(arr)
        case .dictionary(let dict):
            hasher.combine(7)
            // Hash the count and sorted keys for deterministic hashing
            hasher.combine(dict.count)
            for key in dict.keys.sorted() {
                hasher.combine(key)
                hasher.combine(dict[key])
            }
        case .reference(let ref):
            hasher.combine(8)
            hasher.combine(ref)
        }
    }
}
