import Foundation

/// Represents an inline image from a PDF content stream.
///
/// Inline images are embedded directly in content streams using the
/// `BI` (begin image), `ID` (image data), and `EI` (end image) operators.
/// They are typically used for small images to avoid the overhead of
/// creating separate XObjects.
///
/// This type corresponds to the Java `PDInlineImage` class from veraPDF-parser.
///
/// ## Content Stream Syntax
/// ```
/// BI
///   /W 100
///   /H 50
///   /BPC 8
///   /CS /DeviceRGB
/// ID
/// <image data bytes>
/// EI
/// ```
///
/// ## Abbreviated Key Names
/// Inline images use abbreviated key names:
/// - `/W` for `/Width`
/// - `/H` for `/Height`
/// - `/BPC` for `/BitsPerComponent`
/// - `/CS` for `/ColorSpace`
/// - `/D` for `/Decode`
/// - `/DP` for `/DecodeParms`
/// - `/F` for `/Filter`
/// - `/IM` for `/ImageMask`
/// - `/I` for `/Interpolate`
///
/// ## Usage
/// ```swift
/// let inlineImage = InlineImage(
///     width: 100,
///     height: 50,
///     bitsPerComponent: 8,
///     colorSpace: .name(.deviceRGB),
///     data: imageData
/// )
/// print("Size: \(inlineImage.width) x \(inlineImage.height)")
/// ```
public struct InlineImage: Sendable, Hashable {

    // MARK: - Properties

    /// The width of the image in pixels.
    public let width: Int

    /// The height of the image in pixels.
    public let height: Int

    /// The number of bits per color component.
    public let bitsPerComponent: Int

    /// The color space for the image samples.
    ///
    /// This can be:
    /// - A name (e.g., `/DeviceRGB`, `/G` for DeviceGray)
    /// - An array for complex color spaces
    public let colorSpace: COSValue?

    /// Whether this is an image mask (stencil).
    public let isImageMask: Bool

    /// Whether to interpolate when scaling.
    public let interpolate: Bool

    /// The decode array for color value mapping.
    public let decode: [Double]?

    /// The filter(s) applied to the image data.
    public let filter: COSValue?

    /// The decode parameters for the filter(s).
    public let decodeParms: COSValue?

    /// The raw image data bytes.
    public let data: Data

    /// Additional dictionary entries from the inline image.
    public let additionalEntries: [ASAtom: COSValue]

    // MARK: - Initialization

    /// Creates an inline image with explicit properties.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    ///   - bitsPerComponent: Bits per color component.
    ///   - colorSpace: Color space specification.
    ///   - isImageMask: Whether this is a stencil mask.
    ///   - interpolate: Whether to interpolate when scaling.
    ///   - decode: Decode array for color mapping.
    ///   - filter: Compression filter(s).
    ///   - decodeParms: Filter parameters.
    ///   - data: Raw image data.
    ///   - additionalEntries: Any other dictionary entries.
    public init(
        width: Int,
        height: Int,
        bitsPerComponent: Int = 8,
        colorSpace: COSValue? = nil,
        isImageMask: Bool = false,
        interpolate: Bool = false,
        decode: [Double]? = nil,
        filter: COSValue? = nil,
        decodeParms: COSValue? = nil,
        data: Data,
        additionalEntries: [ASAtom: COSValue] = [:]
    ) {
        self.width = width
        self.height = height
        self.bitsPerComponent = isImageMask ? 1 : bitsPerComponent
        self.colorSpace = colorSpace
        self.isImageMask = isImageMask
        self.interpolate = interpolate
        self.decode = decode
        self.filter = filter
        self.decodeParms = decodeParms
        self.data = data
        self.additionalEntries = additionalEntries
    }

    /// Creates an inline image from a dictionary of abbreviated keys and image data.
    ///
    /// - Parameters:
    ///   - dictionary: Dictionary with abbreviated or full key names.
    ///   - data: The raw image data.
    /// - Throws: `XObjectError` if required entries are missing.
    public init(dictionary: [ASAtom: COSValue], data: Data) throws {
        // Extract width (W or Width)
        guard let widthValue = dictionary[ASAtom("W")]?.integerValue
                ?? dictionary[.width]?.integerValue else {
            throw XObjectError.missingRequiredEntry(key: "Width/W")
        }

        // Extract height (H or Height)
        guard let heightValue = dictionary[ASAtom("H")]?.integerValue
                ?? dictionary[.height]?.integerValue else {
            throw XObjectError.missingRequiredEntry(key: "Height/H")
        }

        let width = Int(widthValue)
        let height = Int(heightValue)

        guard width > 0 && height > 0 else {
            throw XObjectError.invalidImageDimensions(width: width, height: height)
        }

        // Extract image mask (IM or ImageMask)
        let isImageMask = dictionary[ASAtom("IM")]?.boolValue
            ?? dictionary["ImageMask"]?.boolValue ?? false

        // Extract bits per component (BPC or BitsPerComponent)
        let bpc: Int
        if isImageMask {
            bpc = 1
        } else {
            bpc = Int(dictionary[ASAtom("BPC")]?.integerValue
                ?? dictionary[.bitsPerComponent]?.integerValue ?? 8)
        }

        // Extract color space (CS or ColorSpace)
        let colorSpace = dictionary[ASAtom("CS")] ?? dictionary[.colorSpace]

        // Extract interpolate (I or Interpolate)
        let interpolate = dictionary[ASAtom("I")]?.boolValue
            ?? dictionary["Interpolate"]?.boolValue ?? false

        // Extract decode (D or Decode)
        let decodeValue = dictionary[ASAtom("D")] ?? dictionary["Decode"]
        let decode = decodeValue?.arrayValue?.compactMap { $0.numericValue }

        // Extract filter (F or Filter)
        let filter = dictionary[ASAtom("F")] ?? dictionary[.filter]

        // Extract decode params (DP or DecodeParms)
        let decodeParms = dictionary[ASAtom("DP")] ?? dictionary[.decodeParms]

        // Collect additional entries
        let knownKeys: Set<ASAtom> = [
            ASAtom("W"), .width,
            ASAtom("H"), .height,
            ASAtom("BPC"), .bitsPerComponent,
            ASAtom("CS"), .colorSpace,
            ASAtom("IM"), ASAtom("ImageMask"),
            ASAtom("I"), ASAtom("Interpolate"),
            ASAtom("D"), ASAtom("Decode"),
            ASAtom("F"), .filter,
            ASAtom("DP"), .decodeParms
        ]

        var additional: [ASAtom: COSValue] = [:]
        for (key, value) in dictionary {
            if !knownKeys.contains(key) {
                additional[key] = value
            }
        }

        self.width = width
        self.height = height
        self.bitsPerComponent = bpc
        self.colorSpace = colorSpace
        self.isImageMask = isImageMask
        self.interpolate = interpolate
        self.decode = decode
        self.filter = filter
        self.decodeParms = decodeParms
        self.data = data
        self.additionalEntries = additional
    }

    // MARK: - Color Space Properties

    /// The color space name if specified as a simple name.
    ///
    /// Handles abbreviated color space names:
    /// - `/G` -> DeviceGray
    /// - `/RGB` -> DeviceRGB
    /// - `/CMYK` -> DeviceCMYK
    /// - `/I` -> Indexed
    public var colorSpaceName: ASAtom? {
        guard let cs = colorSpace else {
            return nil
        }

        if let name = cs.nameValue {
            // Expand abbreviated names
            switch name.stringValue {
            case "G":
                return .deviceGray
            case "RGB":
                return .deviceRGB
            case "CMYK":
                return .deviceCMYK
            case "I":
                return .indexed
            default:
                return name
            }
        }

        // For array-based color spaces, return the first element
        if let array = cs.arrayValue, !array.isEmpty {
            if let name = array[0].nameValue {
                switch name.stringValue {
                case "I":
                    return .indexed
                default:
                    return name
                }
            }
        }

        return nil
    }

    /// The number of color components.
    public var numberOfComponents: Int {
        if isImageMask {
            return 1
        }

        guard let name = colorSpaceName else {
            return 3
        }

        switch name {
        case .deviceGray, .calGray, ASAtom("G"):
            return 1
        case .deviceRGB, .calRGB, ASAtom("RGB"):
            return 3
        case .deviceCMYK, ASAtom("CMYK"):
            return 4
        case .indexed, ASAtom("I"):
            return 1
        default:
            return 3
        }
    }

    // MARK: - Filter Properties

    /// The filter name if a single filter is used.
    public var filterName: ASAtom? {
        filter?.nameValue
    }

    /// Expands abbreviated filter names.
    ///
    /// - `/AHx` -> ASCIIHexDecode
    /// - `/A85` -> ASCII85Decode
    /// - `/LZW` -> LZWDecode
    /// - `/Fl` -> FlateDecode
    /// - `/RL` -> RunLengthDecode
    /// - `/CCF` -> CCITTFaxDecode
    /// - `/DCT` -> DCTDecode
    public var expandedFilterName: ASAtom? {
        guard let name = filterName else {
            return nil
        }

        switch name.stringValue {
        case "AHx":
            return .asciiHexDecode
        case "A85":
            return .ascii85Decode
        case "LZW":
            return .lzwDecode
        case "Fl":
            return .flateDecode
        case "RL":
            return .runLengthDecode
        case "CCF":
            return .ccittFaxDecode
        case "DCT":
            return .dctDecode
        default:
            return name
        }
    }

    // MARK: - Data Properties

    /// The raw data size in bytes.
    public var dataSize: Int {
        data.count
    }

    /// The estimated uncompressed data size.
    public var estimatedUncompressedSize: Int {
        let bitsPerSample = bitsPerComponent * numberOfComponents
        return (width * height * bitsPerSample + 7) / 8
    }

    /// Whether the image data appears to be compressed.
    public var isCompressed: Bool {
        filter != nil
    }
}

// MARK: - CustomStringConvertible

extension InlineImage: CustomStringConvertible {
    public var description: String {
        var parts: [String] = ["InlineImage(\(width)x\(height)"]

        if let cs = colorSpaceName {
            parts.append("cs:\(cs.stringValue)")
        }

        parts.append("bpc:\(bitsPerComponent)")

        if isImageMask {
            parts.append("mask")
        }

        if let filter = expandedFilterName {
            parts.append("filter:\(filter.stringValue)")
        }

        parts.append("data:\(dataSize) bytes")

        return parts.joined(separator: ", ") + ")"
    }
}
