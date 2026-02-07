import Foundation

/// Protocol for all PDF XObject types.
///
/// XObjects are PDF objects that can be reused or referenced from content streams.
/// They represent self-contained graphics that can be rendered at any position.
///
/// This protocol corresponds to the Java `PDXObject` abstract class from veraPDF-parser.
///
/// ## XObject Types
/// - **Image XObject**: Raster image data
/// - **Form XObject**: Reusable content stream (vector graphics)
/// - **PostScript XObject**: Embedded PostScript code (deprecated in PDF 2.0)
///
/// ## PDF Specification
/// XObjects are stored in the `/XObject` subdictionary of the page resources.
/// They are invoked via the `Do` operator in content streams.
///
/// ## Usage
/// ```swift
/// let xObject = try PDFXObjectFactory.create(from: cosValue)
/// switch xObject {
/// case let image as ImageXObject:
///     print("Image: \(image.width) x \(image.height)")
/// case let form as FormXObject:
///     print("Form XObject with BBox: \(form.bBox)")
/// default:
///     break
/// }
/// ```
public protocol PDFXObject: PDObject {

    /// The XObject subtype.
    ///
    /// Returns the `/Subtype` entry which identifies the XObject type:
    /// - `/Image` for image XObjects
    /// - `/Form` for form XObjects
    /// - `/PS` for PostScript XObjects
    var subtype: ASAtom { get }
}

// MARK: - XObject Errors

/// Errors specific to XObject operations.
public enum XObjectError: Error, Sendable, Equatable, CustomStringConvertible {

    /// The XObject dictionary is missing a required entry.
    case missingRequiredEntry(key: String)

    /// The XObject has an invalid or unsupported subtype.
    case invalidSubtype(String?)

    /// The XObject stream cannot be decoded.
    case streamDecodingFailed(String)

    /// Invalid image dimensions.
    case invalidImageDimensions(width: Int, height: Int)

    /// Invalid bits per component value.
    case invalidBitsPerComponent(Int)

    /// Missing or invalid color space for image.
    case invalidColorSpace(String)

    /// The inline image data is malformed.
    case malformedInlineImage(String)

    /// The Form XObject has an invalid BBox.
    case invalidBBox

    /// The pattern has an invalid type.
    case invalidPatternType(Int?)

    /// The shading has an invalid type.
    case invalidShadingType(Int?)

    public var description: String {
        switch self {
        case .missingRequiredEntry(let key):
            return "XObject missing required entry: \(key)"
        case .invalidSubtype(let subtype):
            return "Invalid XObject subtype: \(subtype ?? "nil")"
        case .streamDecodingFailed(let reason):
            return "Failed to decode XObject stream: \(reason)"
        case .invalidImageDimensions(let width, let height):
            return "Invalid image dimensions: \(width) x \(height)"
        case .invalidBitsPerComponent(let bpc):
            return "Invalid bits per component: \(bpc)"
        case .invalidColorSpace(let reason):
            return "Invalid color space: \(reason)"
        case .malformedInlineImage(let reason):
            return "Malformed inline image: \(reason)"
        case .invalidBBox:
            return "Invalid or missing BBox for Form XObject"
        case .invalidPatternType(let type):
            if let t = type {
                return "Invalid pattern type: \(t)"
            }
            return "Missing pattern type"
        case .invalidShadingType(let type):
            if let t = type {
                return "Invalid shading type: \(t)"
            }
            return "Missing shading type"
        }
    }
}

// MARK: - XObject Factory

/// Factory for creating XObject instances from COS values.
public enum PDFXObjectFactory {

    /// Creates an XObject from a COS dictionary or stream.
    ///
    /// - Parameter cosObject: The COS value representing the XObject.
    /// - Returns: A concrete XObject instance based on the `/Subtype`.
    /// - Throws: `XObjectError` if the XObject is invalid or unsupported.
    ///
    /// ## Supported Subtypes
    /// - `/Image` creates an `ImageXObject`
    /// - `/Form` creates a `FormXObject`
    /// - `/PS` creates a `PostScriptXObject`
    public static func create(from cosObject: COSValue) throws -> any PDFXObject {
        // Get the subtype
        guard let subtypeValue = cosObject[.subtype] else {
            throw XObjectError.missingRequiredEntry(key: "Subtype")
        }

        guard let subtype = subtypeValue.nameValue else {
            throw XObjectError.invalidSubtype(nil)
        }

        switch subtype {
        case .image:
            return try ImageXObject(cosObject: cosObject)
        case .form:
            return try FormXObject(cosObject: cosObject)
        case ASAtom("PS"):
            return try PostScriptXObject(cosObject: cosObject)
        default:
            throw XObjectError.invalidSubtype(subtype.stringValue)
        }
    }
}
