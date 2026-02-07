import Foundation

/// Represents the header of a PDF document, which declares the PDF version.
///
/// Every PDF file begins with a header line of the form:
///
///     %PDF-<major>.<minor>
///
/// For example, `%PDF-1.7` or `%PDF-2.0`. The version determines which
/// PDF features are available in the document.
///
/// This type corresponds to the Java `COSHeader` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let header = PDFHeader(major: 1, minor: 7)
/// print(header.versionString)  // "1.7"
/// print(header.headerString)   // "%PDF-1.7"
/// ```
///
/// ## Version Comparison
/// `PDFHeader` conforms to `Comparable`, ordering by major version first,
/// then by minor version.
public struct PDFHeader: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {

    // MARK: - Properties

    /// The major version number (e.g., 1 for PDF 1.x, 2 for PDF 2.x).
    public let major: Int

    /// The minor version number (e.g., 7 for PDF 1.7).
    public let minor: Int

    /// The byte offset of the header in the file, if known.
    ///
    /// Normally 0, but may be non-zero if the file has leading garbage bytes
    /// before the `%PDF-` marker (some PDF writers produce such files).
    public let headerOffset: Int64

    // MARK: - Initialization

    /// Creates a PDF header with the given version numbers.
    ///
    /// - Parameters:
    ///   - major: The major version number.
    ///   - minor: The minor version number.
    ///   - headerOffset: The byte offset of the header in the file. Defaults to 0.
    public init(major: Int, minor: Int, headerOffset: Int64 = 0) {
        self.major = major
        self.minor = minor
        self.headerOffset = headerOffset
    }

    /// Creates a PDF header by parsing a version string (e.g., "1.7" or "2.0").
    ///
    /// - Parameter versionString: A string in the format "<major>.<minor>".
    /// - Returns: `nil` if the string cannot be parsed as a valid version.
    public init?(versionString: String) {
        let parts = versionString.split(separator: ".")
        guard parts.count == 2,
              let major = Int(parts[0]),
              let minor = Int(parts[1]),
              major >= 0,
              minor >= 0 else {
            return nil
        }
        self.major = major
        self.minor = minor
        self.headerOffset = 0
    }

    /// Creates a PDF header by parsing a full header string (e.g., "%PDF-1.7").
    ///
    /// The string must begin with `%PDF-` followed by `<major>.<minor>`.
    ///
    /// - Parameter headerString: The full PDF header line.
    /// - Returns: `nil` if the string is not a valid PDF header.
    public init?(headerString: String) {
        let prefix = "%PDF-"
        guard headerString.hasPrefix(prefix) else { return nil }
        let versionPart = String(headerString.dropFirst(prefix.count))
        guard let parsed = PDFHeader(versionString: versionPart) else { return nil }
        self = parsed
    }

    // MARK: - Convenience Properties

    /// The version as a string (e.g., "1.7").
    public var versionString: String {
        "\(major).\(minor)"
    }

    /// The full header string (e.g., "%PDF-1.7").
    public var headerString: String {
        "%PDF-\(versionString)"
    }

    /// The version as a `Double` for numeric comparison (e.g., 1.7).
    public var versionNumber: Double {
        Double(major) + Double(minor) / 10.0
    }

    /// Whether this is a PDF 2.0 or later document.
    public var isPDF2: Bool {
        major >= 2
    }

    // MARK: - Common Versions

    /// PDF 1.0
    public static let v1_0 = PDFHeader(major: 1, minor: 0)
    /// PDF 1.1
    public static let v1_1 = PDFHeader(major: 1, minor: 1)
    /// PDF 1.2
    public static let v1_2 = PDFHeader(major: 1, minor: 2)
    /// PDF 1.3
    public static let v1_3 = PDFHeader(major: 1, minor: 3)
    /// PDF 1.4
    public static let v1_4 = PDFHeader(major: 1, minor: 4)
    /// PDF 1.5
    public static let v1_5 = PDFHeader(major: 1, minor: 5)
    /// PDF 1.6
    public static let v1_6 = PDFHeader(major: 1, minor: 6)
    /// PDF 1.7
    public static let v1_7 = PDFHeader(major: 1, minor: 7)
    /// PDF 2.0
    public static let v2_0 = PDFHeader(major: 2, minor: 0)

    // MARK: - Comparable

    public static func < (lhs: PDFHeader, rhs: PDFHeader) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        return lhs.minor < rhs.minor
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        headerString
    }
}
