import Foundation

/// Represents a PDF stream object, which is a dictionary combined with
/// a sequence of encoded bytes.
///
/// In PDF, a stream object consists of:
/// 1. A **dictionary** containing metadata about the stream (e.g., `/Length`,
///    `/Filter`, `/DecodeParms`).
/// 2. The **encoded data** (the raw bytes between `stream` and `endstream`
///    keywords in the PDF file).
///
/// Streams are used for page content, images, fonts, ICC profiles, XMP
/// metadata, and other large or binary data in PDF files.
///
/// This type corresponds to the Java `COSStream` class from veraPDF-parser.
/// Unlike the Java version, which extends `COSDictionary`, this Swift type
/// uses composition: it stores both a dictionary and its data payload as
/// separate fields.
///
/// ## Usage
/// ```swift
/// let stream = COSStream(
///     dictionary: [.length: .integer(42), .filter: .name(.flateDecode)],
///     encodedData: compressedBytes
/// )
/// ```
///
/// ## Note on Decoding
/// This struct stores the **encoded** (compressed/encrypted) stream data.
/// Decoding (decompression, decryption) is handled by the filter system
/// defined in Sprint 3. The `decodedData` property provides a placeholder
/// for decoded data set externally.
public struct COSStream: Sendable, Hashable, Codable, CustomStringConvertible {

    // MARK: - Properties

    /// The stream dictionary containing metadata such as `/Length`, `/Filter`,
    /// and `/DecodeParms`.
    public let dictionary: [ASAtom: COSValue]

    /// The raw encoded stream data (before any filter decoding).
    public let encodedData: Data

    /// The decoded stream data (after filter decoding), if available.
    ///
    /// This is `nil` until the stream has been decoded by the filter system.
    /// Once decoded, this holds the uncompressed/decrypted data.
    public let decodedData: Data?

    // MARK: - Initialization

    /// Creates a stream object with the given dictionary and encoded data.
    ///
    /// - Parameters:
    ///   - dictionary: The stream dictionary with metadata entries.
    ///   - encodedData: The raw encoded stream bytes. Defaults to empty data.
    ///   - decodedData: The decoded stream bytes, if already available. Defaults to `nil`.
    public init(
        dictionary: [ASAtom: COSValue],
        encodedData: Data = Data(),
        decodedData: Data? = nil
    ) {
        self.dictionary = dictionary
        self.encodedData = encodedData
        self.decodedData = decodedData
    }

    // MARK: - Dictionary Access

    /// Accesses a value in the stream dictionary by name key.
    ///
    /// - Parameter key: The name key to look up.
    /// - Returns: The value associated with the key, or `nil` if not found.
    public subscript(key: ASAtom) -> COSValue? {
        dictionary[key]
    }

    /// Accesses a value in the stream dictionary by string key.
    ///
    /// - Parameter key: The string key to look up.
    /// - Returns: The value associated with the key, or `nil` if not found.
    public subscript(key: String) -> COSValue? {
        dictionary[ASAtom(key)]
    }

    // MARK: - Convenience Properties

    /// The declared length of the encoded data, from the `/Length` entry.
    ///
    /// Returns `nil` if the `/Length` entry is missing or not an integer.
    public var declaredLength: Int64? {
        dictionary[.length]?.integerValue
    }

    /// The filter(s) applied to the stream data.
    ///
    /// Returns a single-element array for a single filter name, the full array
    /// for an array of filter names, or an empty array if no filters are specified.
    public var filters: [ASAtom] {
        guard let filterValue = dictionary[.filter] else {
            return []
        }
        switch filterValue {
        case .name(let atom):
            return [atom]
        case .array(let arr):
            return arr.compactMap(\.nameValue)
        default:
            return []
        }
    }

    /// The decode parameters for the stream filters.
    ///
    /// Returns `nil` if no `/DecodeParms` entry is present.
    public var decodeParameters: COSValue? {
        dictionary[.decodeParms]
    }

    /// Whether this stream has any filters applied.
    public var isFiltered: Bool {
        !filters.isEmpty
    }

    /// The number of entries in the stream dictionary.
    public var dictionaryCount: Int {
        dictionary.count
    }

    /// The size of the encoded data in bytes.
    public var encodedSize: Int {
        encodedData.count
    }

    /// The size of the decoded data in bytes, if available.
    public var decodedSize: Int? {
        decodedData?.count
    }

    /// Returns a new `COSStream` with the decoded data set.
    ///
    /// Since `COSStream` is a value type, this creates a copy with the
    /// decoded data attached.
    ///
    /// - Parameter data: The decoded (decompressed/decrypted) data.
    /// - Returns: A new stream with the decoded data.
    public func withDecodedData(_ data: Data) -> COSStream {
        COSStream(
            dictionary: dictionary,
            encodedData: encodedData,
            decodedData: data
        )
    }

    /// Returns a new `COSStream` with an additional dictionary entry.
    ///
    /// - Parameters:
    ///   - key: The dictionary key to set.
    ///   - value: The value to associate with the key.
    /// - Returns: A new stream with the updated dictionary.
    public func settingDictionaryValue(_ value: COSValue, forKey key: ASAtom) -> COSStream {
        var newDict = dictionary
        newDict[key] = value
        return COSStream(
            dictionary: newDict,
            encodedData: encodedData,
            decodedData: decodedData
        )
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        let filterDesc: String
        if filters.isEmpty {
            filterDesc = "none"
        } else {
            filterDesc = filters.map(\.stringValue).joined(separator: ", ")
        }
        return "stream(dict: \(dictionary.count) entries, encoded: \(encodedData.count) bytes, filters: \(filterDesc))"
    }
}
