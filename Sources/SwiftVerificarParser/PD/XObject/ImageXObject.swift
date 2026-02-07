import Foundation
import CoreGraphics

/// Represents a PDF Image XObject.
///
/// Image XObjects contain raster image data that can be painted onto a page
/// using the `Do` operator. They support various color spaces, compression
/// filters, and optional features like masks and soft masks.
///
/// This type corresponds to the Java `PDXImage` class from veraPDF-parser.
///
/// ## PDF Specification
/// Image XObjects have `/Type /XObject` and `/Subtype /Image`.
/// They contain the image data as the stream content.
///
/// ## Required Entries
/// - `/Width` - Image width in pixels
/// - `/Height` - Image height in pixels
/// - `/ColorSpace` - Color space for sample values (or `/ImageMask true`)
/// - `/BitsPerComponent` - Bits per color component (or `/ImageMask true`)
///
/// ## Optional Entries
/// - `/Filter` - Compression filter(s) for stream data
/// - `/Decode` - Decoding array for color values
/// - `/Interpolate` - Whether to interpolate when scaling
/// - `/ImageMask` - Whether this is a stencil mask
/// - `/Mask` - Hard mask or color key mask
/// - `/SMask` - Soft mask (alpha channel)
/// - `/Intent` - Rendering intent
///
/// ## Usage
/// ```swift
/// let image = try ImageXObject(cosObject: imageDict)
/// print("Size: \(image.width) x \(image.height)")
/// print("Color space: \(image.colorSpaceName)")
/// print("Bits per component: \(image.bitsPerComponent)")
/// ```
public struct ImageXObject: PDFXObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS stream for this image.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates an Image XObject from a COS dictionary/stream.
    ///
    /// - Parameter cosObject: The COS object (must be a stream dictionary).
    /// - Throws: `XObjectError` if required entries are missing or invalid.
    public init(cosObject: COSValue) throws {
        // Validate subtype
        if let subtype = cosObject[.subtype]?.nameValue {
            guard subtype == .image else {
                throw XObjectError.invalidSubtype(subtype.stringValue)
            }
        }

        // For non-ImageMask images, width and height are required
        let isImageMask = cosObject["ImageMask"]?.boolValue ?? false

        guard let widthValue = cosObject[.width]?.integerValue else {
            throw XObjectError.missingRequiredEntry(key: "Width")
        }

        guard let heightValue = cosObject[.height]?.integerValue else {
            throw XObjectError.missingRequiredEntry(key: "Height")
        }

        // Validate dimensions
        guard widthValue > 0 && heightValue > 0 else {
            throw XObjectError.invalidImageDimensions(
                width: Int(widthValue),
                height: Int(heightValue)
            )
        }

        // Non-image-masks require ColorSpace
        if !isImageMask {
            if cosObject[.colorSpace] == nil {
                throw XObjectError.invalidColorSpace("missing ColorSpace for non-ImageMask image")
            }
        }

        self.cosObject = cosObject
    }

    // MARK: - PDFXObject Protocol

    /// Returns `/Image` as the subtype.
    public var subtype: ASAtom {
        .image
    }

    // MARK: - Image Properties

    /// The width of the image in pixels.
    public var width: Int {
        Int(cosObject[.width]?.integerValue ?? 0)
    }

    /// The height of the image in pixels.
    public var height: Int {
        Int(cosObject[.height]?.integerValue ?? 0)
    }

    /// The number of bits per color component.
    ///
    /// Valid values are 1, 2, 4, 8, or 16 (and 32 for some color spaces in PDF 2.0).
    /// For image masks, this is always 1.
    public var bitsPerComponent: Int {
        if isImageMask {
            return 1
        }
        return Int(cosObject[.bitsPerComponent]?.integerValue ?? 8)
    }

    /// The color space for the image samples.
    ///
    /// Returns the raw COS value for the color space. Use `PDFColorSpaceFactory`
    /// to create a concrete color space instance.
    public var colorSpace: COSValue? {
        cosObject[.colorSpace]
    }

    /// The color space name, if it's a simple device color space.
    ///
    /// Returns the name if the color space is specified as a name (e.g., `/DeviceRGB`),
    /// or the first element if it's an array-based color space.
    public var colorSpaceName: ASAtom? {
        if let name = colorSpace?.nameValue {
            return name
        }
        if let array = colorSpace?.arrayValue, !array.isEmpty {
            return array[0].nameValue
        }
        return nil
    }

    /// Whether this image is an image mask (stencil).
    ///
    /// Image masks have 1-bit samples where 0 paints the current color
    /// and 1 is transparent.
    public var isImageMask: Bool {
        cosObject["ImageMask"]?.boolValue ?? false
    }

    /// The hard mask or color key mask for this image.
    ///
    /// This can be:
    /// - A reference to another Image XObject (stencil mask)
    /// - An array of color key values for masking
    public var mask: COSValue? {
        cosObject["Mask"]
    }

    /// The soft mask (alpha channel) for this image.
    ///
    /// References another Image XObject that provides alpha values.
    public var softMask: COSValue? {
        cosObject["SMask"]
    }

    /// Whether to interpolate when scaling the image.
    public var interpolate: Bool {
        cosObject["Interpolate"]?.boolValue ?? false
    }

    /// The decode array for mapping sample values to color values.
    ///
    /// If not specified, the default decode array depends on the color space.
    public var decode: [Double]? {
        guard let array = cosObject["Decode"]?.arrayValue else {
            return nil
        }
        return array.compactMap { $0.numericValue }
    }

    /// The rendering intent for color conversion.
    ///
    /// One of: `/AbsoluteColorimetric`, `/RelativeColorimetric`,
    /// `/Saturation`, `/Perceptual`.
    public var intent: ASAtom? {
        cosObject["Intent"]?.nameValue
    }

    /// The compression filter(s) applied to the stream data.
    public var filter: COSValue? {
        cosObject[.filter]
    }

    /// The filter name if a single filter is used.
    public var filterName: ASAtom? {
        filter?.nameValue
    }

    /// The decode parameters for the filter(s).
    public var decodeParms: COSValue? {
        cosObject[.decodeParms]
    }

    // MARK: - Image Characteristics

    /// The number of color components based on the color space.
    ///
    /// This is a convenience property that examines the color space name.
    /// For precise component counts, use `PDFColorSpaceFactory`.
    public var numberOfComponents: Int {
        guard let name = colorSpaceName else {
            return isImageMask ? 1 : 3
        }

        switch name {
        case .deviceGray, .calGray:
            return 1
        case .deviceRGB, .calRGB, .lab:
            return 3
        case .deviceCMYK:
            return 4
        case .indexed:
            return 1
        default:
            return 3 // Default assumption
        }
    }

    /// Whether this image uses JPEG (DCT) compression.
    public var isJPEG: Bool {
        filterName == .dctDecode
    }

    /// Whether this image uses JPEG 2000 compression.
    public var isJPEG2000: Bool {
        filterName == .jpxDecode
    }

    /// Whether this image uses CCITT fax compression.
    public var isCCITT: Bool {
        filterName == .ccittFaxDecode
    }

    /// The total number of samples in the image.
    public var sampleCount: Int {
        width * height
    }

    /// The estimated uncompressed data size in bytes.
    public var estimatedDataSize: Int {
        let bitsPerSample = bitsPerComponent * numberOfComponents
        return (sampleCount * bitsPerSample + 7) / 8
    }

    // MARK: - Metadata

    /// Optional metadata stream for the image.
    public var metadata: COSValue? {
        cosObject[.metadata]
    }

    /// Optional alternate images array.
    public var alternates: [COSValue]? {
        cosObject["Alternates"]?.arrayValue
    }

    /// Optional structural parent tree key.
    public var structParent: Int? {
        cosObject["StructParent"]?.integerValue.map { Int($0) }
    }
}
