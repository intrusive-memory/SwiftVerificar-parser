import Foundation

/// Represents a PDF PostScript XObject.
///
/// PostScript XObjects contain PostScript language code that can be
/// executed when the XObject is rendered. They are deprecated in PDF 2.0
/// and were primarily used for printer-specific features.
///
/// This type corresponds to the Java `PDXPostScript` class from veraPDF-parser.
///
/// ## PDF Specification
/// PostScript XObjects have `/Type /XObject` and `/Subtype /PS`.
/// The stream content contains PostScript language code.
///
/// ## PDF Version Notes
/// - PostScript XObjects were introduced in PDF 1.1
/// - They are deprecated as of PDF 2.0
/// - Not all PDF viewers support PostScript XObjects
///
/// ## Optional Entries
/// - `/Level1` - PostScript language level 1 alternative stream
///
/// ## Usage
/// ```swift
/// let psXObject = try PostScriptXObject(cosObject: psDict)
/// if psXObject.hasLevel1Alternative {
///     print("Has Level 1 alternative")
/// }
/// ```
public struct PostScriptXObject: PDFXObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS stream for this PostScript XObject.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a PostScript XObject from a COS dictionary/stream.
    ///
    /// - Parameter cosObject: The COS object (must be a stream dictionary).
    /// - Throws: `XObjectError` if the subtype is not `/PS`.
    public init(cosObject: COSValue) throws {
        // Validate subtype if present
        if let subtype = cosObject[.subtype]?.nameValue {
            guard subtype == ASAtom("PS") else {
                throw XObjectError.invalidSubtype(subtype.stringValue)
            }
        }

        self.cosObject = cosObject
    }

    // MARK: - PDFXObject Protocol

    /// Returns `/PS` as the subtype.
    public var subtype: ASAtom {
        ASAtom("PS")
    }

    // MARK: - PostScript Properties

    /// The Level 1 alternative stream.
    ///
    /// If present, this stream contains PostScript language level 1 code
    /// that can be used instead of the main stream when the target device
    /// only supports level 1.
    public var level1: COSValue? {
        cosObject["Level1"]
    }

    /// Whether a Level 1 alternative is present.
    public var hasLevel1Alternative: Bool {
        level1 != nil
    }

    // MARK: - Stream Properties

    /// The compression filter(s) for the stream data.
    public var filter: COSValue? {
        cosObject[.filter]
    }

    /// The stream length.
    public var length: Int? {
        cosObject[.length]?.integerValue.map { Int($0) }
    }

    /// The decode parameters for the filter(s).
    public var decodeParms: COSValue? {
        cosObject[.decodeParms]
    }

    // MARK: - Deprecation Information

    /// Whether this XObject type is deprecated.
    ///
    /// PostScript XObjects are deprecated in PDF 2.0.
    public static var isDeprecated: Bool {
        true
    }

    /// The PDF version where this type was deprecated.
    public static var deprecatedInVersion: String {
        "2.0"
    }
}
