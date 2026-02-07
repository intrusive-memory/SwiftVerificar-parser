import Foundation
import CoreGraphics

/// Represents a PDF Form XObject.
///
/// Form XObjects are self-contained content streams that can be reused
/// across multiple pages or multiple times on the same page. They are
/// commonly used for repeated graphics, imported pages, and transparency groups.
///
/// This type corresponds to the Java `PDXForm` class from veraPDF-parser.
///
/// ## PDF Specification
/// Form XObjects have `/Type /XObject` and `/Subtype /Form`.
/// The stream content contains graphics operators similar to page content.
///
/// ## Required Entries
/// - `/BBox` - Bounding box in form space coordinates
///
/// ## Optional Entries
/// - `/Matrix` - Transformation matrix from form space to user space
/// - `/Resources` - Resource dictionary for the form content
/// - `/Group` - Transparency group attributes
/// - `/Ref` - Reference XObject (for external content)
/// - `/Metadata` - XMP metadata stream
/// - `/OC` - Optional content group
///
/// ## Usage
/// ```swift
/// let form = try FormXObject(cosObject: formDict)
/// print("BBox: \(form.bBox)")
/// if let resources = form.resources {
///     print("Has resources: \(resources.fonts != nil)")
/// }
/// ```
public struct FormXObject: PDFXObject, Sendable, Hashable {

    // MARK: - Types

    /// Represents a rectangle (bounding box) in PDF coordinates.
    public struct Rectangle: Sendable, Hashable, CustomStringConvertible {
        /// Lower-left x coordinate.
        public let llx: Double
        /// Lower-left y coordinate.
        public let lly: Double
        /// Upper-right x coordinate.
        public let urx: Double
        /// Upper-right y coordinate.
        public let ury: Double

        /// Creates a rectangle from coordinates.
        public init(llx: Double, lly: Double, urx: Double, ury: Double) {
            self.llx = llx
            self.lly = lly
            self.urx = urx
            self.ury = ury
        }

        /// Creates a rectangle from a COS array of 4 numbers.
        public init?(from cosValue: COSValue?) {
            guard let array = cosValue?.arrayValue, array.count >= 4 else {
                return nil
            }

            guard let x1 = array[0].numericValue,
                  let y1 = array[1].numericValue,
                  let x2 = array[2].numericValue,
                  let y2 = array[3].numericValue else {
                return nil
            }

            self.llx = x1
            self.lly = y1
            self.urx = x2
            self.ury = y2
        }

        /// The width of the rectangle.
        public var width: Double {
            urx - llx
        }

        /// The height of the rectangle.
        public var height: Double {
            ury - lly
        }

        /// Creates a CGRect from this rectangle.
        public var cgRect: CGRect {
            CGRect(x: llx, y: lly, width: width, height: height)
        }

        public var description: String {
            "[\(llx), \(lly), \(urx), \(ury)]"
        }
    }

    /// Represents a transformation matrix.
    public struct Matrix: Sendable, Hashable, CustomStringConvertible {
        /// The matrix components [a b c d e f].
        public let a, b, c, d, e, f: Double

        /// The identity matrix.
        public static let identity = Matrix(a: 1, b: 0, c: 0, d: 1, e: 0, f: 0)

        /// Creates a matrix from components.
        public init(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
        }

        /// Creates a matrix from a COS array of 6 numbers.
        public init?(from cosValue: COSValue?) {
            guard let array = cosValue?.arrayValue, array.count >= 6 else {
                return nil
            }

            guard let a = array[0].numericValue,
                  let b = array[1].numericValue,
                  let c = array[2].numericValue,
                  let d = array[3].numericValue,
                  let e = array[4].numericValue,
                  let f = array[5].numericValue else {
                return nil
            }

            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
        }

        /// Creates a CGAffineTransform from this matrix.
        public var cgAffineTransform: CGAffineTransform {
            CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
        }

        /// Whether this is the identity matrix.
        public var isIdentity: Bool {
            a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0
        }

        public var description: String {
            "[\(a), \(b), \(c), \(d), \(e), \(f)]"
        }
    }

    // MARK: - Properties

    /// The underlying COS stream for this form.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a Form XObject from a COS dictionary/stream.
    ///
    /// - Parameter cosObject: The COS object (must be a stream dictionary).
    /// - Throws: `XObjectError` if required entries are missing or invalid.
    public init(cosObject: COSValue) throws {
        // Validate subtype if present
        if let subtype = cosObject[.subtype]?.nameValue {
            guard subtype == .form else {
                throw XObjectError.invalidSubtype(subtype.stringValue)
            }
        }

        // BBox is required
        guard Rectangle(from: cosObject[.bbox]) != nil else {
            throw XObjectError.invalidBBox
        }

        self.cosObject = cosObject
    }

    // MARK: - PDFXObject Protocol

    /// Returns `/Form` as the subtype.
    public var subtype: ASAtom {
        .form
    }

    // MARK: - Form Properties

    /// The bounding box in form coordinate space.
    ///
    /// Defines the clipping region for the form content.
    public var bBox: Rectangle {
        Rectangle(from: cosObject[.bbox])!
    }

    /// The transformation matrix from form space to user space.
    ///
    /// If not specified, defaults to the identity matrix.
    public var matrix: Matrix {
        Matrix(from: cosObject[.matrix]) ?? .identity
    }

    /// The resources dictionary for the form content.
    ///
    /// Contains fonts, XObjects, color spaces, etc. used by the form.
    public var resources: PDFResources? {
        guard let resourcesValue = cosObject[.resources] else {
            return nil
        }
        return try? PDFResources(cosObject: resourcesValue)
    }

    /// The raw resources COSValue.
    public var resourcesValue: COSValue? {
        cosObject[.resources]
    }

    // MARK: - Computed Properties

    /// The width of the bounding box.
    public var width: Double {
        bBox.width
    }

    /// The height of the bounding box.
    public var height: Double {
        bBox.height
    }

    /// The cell size as a CGSize (alias for bBox dimensions).
    public var cellSize: CGSize {
        CGSize(width: width, height: height)
    }

    // MARK: - Transparency Group

    /// The transparency group attributes.
    ///
    /// If present, this form XObject is a transparency group.
    public var group: COSValue? {
        cosObject["Group"]
    }

    /// Whether this form is a transparency group.
    public var isTransparencyGroup: Bool {
        group != nil
    }

    /// The transparency group color space.
    public var groupColorSpace: COSValue? {
        group?[.colorSpace]
    }

    /// Whether the group is isolated.
    public var isIsolated: Bool {
        group?["I"]?.boolValue ?? false
    }

    /// Whether the group is a knockout group.
    public var isKnockout: Bool {
        group?["K"]?.boolValue ?? false
    }

    // MARK: - Reference XObject

    /// The reference XObject dictionary.
    ///
    /// Used for referencing external content (PDF/X, PDF/A).
    public var reference: COSValue? {
        cosObject["Ref"]
    }

    /// Whether this form has a reference to external content.
    public var hasExternalReference: Bool {
        reference != nil
    }

    // MARK: - Optional Content

    /// The optional content group or membership dictionary.
    ///
    /// Controls visibility of this form based on optional content settings.
    public var optionalContent: COSValue? {
        cosObject["OC"]
    }

    // MARK: - Metadata

    /// XMP metadata stream for the form.
    public var metadata: COSValue? {
        cosObject[.metadata]
    }

    /// Process color model for the form (PDF/X).
    public var processColorModel: ASAtom? {
        cosObject["ProcessColorModel"]?.nameValue
    }

    // MARK: - Structural Parent

    /// The structural parent tree key.
    public var structParent: Int? {
        cosObject["StructParent"]?.integerValue.map { Int($0) }
    }

    /// The structural parents array key.
    public var structParents: Int? {
        cosObject["StructParents"]?.integerValue.map { Int($0) }
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

    // MARK: - Form Type

    /// The form type (1 for standard forms).
    ///
    /// Currently only type 1 is defined.
    public var formType: Int {
        Int(cosObject["FormType"]?.integerValue ?? 1)
    }

    // MARK: - Last Modified

    /// The date the form was last modified.
    public var lastModified: COSValue? {
        cosObject["LastModified"]
    }
}
