import Foundation
import CoreGraphics

/// Protocol for all PDF color space types.
///
/// This protocol corresponds to the Java `PDColorSpace` abstract class from veraPDF-parser.
/// Color spaces define how color values are interpreted and displayed in PDF documents.
///
/// ## Color Space Families
/// - **Device color spaces**: DeviceGray, DeviceRGB, DeviceCMYK
/// - **CIE-based color spaces**: CalGray, CalRGB, Lab, ICCBased
/// - **Special color spaces**: Indexed, Separation, DeviceN, Pattern
///
/// ## PDF Specification
/// Color spaces can be specified as:
/// - A name (e.g., `/DeviceRGB`)
/// - An array `[/Name parameters...]` (e.g., `[/ICCBased streamRef]`)
///
/// ## CoreGraphics Integration
/// Where possible, color spaces provide a `CGColorSpace` representation for
/// rendering and color conversion using Apple's graphics frameworks.
///
/// ## Usage
/// ```swift
/// let colorSpace = try PDFColorSpace.create(from: cosValue)
/// let components = colorSpace.numberOfComponents
/// let cgSpace = colorSpace.cgColorSpace
/// ```
public protocol PDFColorSpace: PDObject {

    /// The color space family name.
    ///
    /// Returns the identifying name such as "DeviceRGB", "CalGray", "ICCBased", etc.
    var name: ASAtom { get }

    /// The number of color components required by this color space.
    ///
    /// - DeviceGray, CalGray: 1
    /// - DeviceRGB, CalRGB, Lab: 3
    /// - DeviceCMYK: 4
    /// - Indexed: 1
    /// - Separation: tint value (1)
    /// - DeviceN: number of colorants
    var numberOfComponents: Int { get }

    /// The CoreGraphics color space representation, if available.
    ///
    /// Returns `nil` for color spaces that cannot be directly represented
    /// in CoreGraphics (e.g., Separation, DeviceN with custom functions).
    var cgColorSpace: CGColorSpace? { get }

    /// Converts color component values to RGB.
    ///
    /// - Parameter components: Array of color component values (0.0...1.0).
    /// - Returns: RGB values as a tuple (r, g, b) each in range 0.0...1.0.
    /// - Throws: `PDError.invalidColorComponents` if component count is wrong.
    func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double)
}

// MARK: - Factory Method

/// Factory for creating color space instances.
public enum PDFColorSpaceFactory {

    /// Creates a color space from a COS value.
    ///
    /// - Parameter cosObject: The COS value (name or array).
    /// - Returns: A concrete color space instance.
    /// - Throws: `PDError` if the color space is invalid or unsupported.
    ///
    /// ## Supported Formats
    /// - Name: `/DeviceGray`, `/DeviceRGB`, `/DeviceCMYK`, `/Pattern`
    /// - Array: `[/CalGray dict]`, `[/ICCBased stream]`, `[/Indexed ...]`, etc.
    public static func create(from cosObject: COSValue) throws -> any PDFColorSpace {
        // Handle name-based color spaces
        if case .name(let name) = cosObject {
            switch name {
            case .deviceGray:
                return DeviceGrayColorSpace(cosObject: cosObject)
            case .deviceRGB:
                return DeviceRGBColorSpace(cosObject: cosObject)
            case .deviceCMYK:
                return DeviceCMYKColorSpace(cosObject: cosObject)
            case .pattern:
                return PatternColorSpace(cosObject: cosObject)
            default:
                throw PDError.unsupportedColorSpace(name.stringValue)
            }
        }

        // Handle array-based color spaces
        guard case .array(let array) = cosObject, !array.isEmpty else {
            throw PDError.invalidColorSpace
        }

        guard case .name(let familyName) = array[0] else {
            throw PDError.invalidColorSpace
        }

        switch familyName {
        case .calGray:
            return try CalGrayColorSpace(cosObject: cosObject)
        case .calRGB:
            return try CalRGBColorSpace(cosObject: cosObject)
        case .lab:
            return try LabColorSpace(cosObject: cosObject)
        case .iccBased:
            return try ICCBasedColorSpace(cosObject: cosObject)
        case .indexed:
            return try IndexedColorSpace(cosObject: cosObject)
        case .separation:
            return try SeparationColorSpace(cosObject: cosObject)
        case .deviceN:
            return try DeviceNColorSpace(cosObject: cosObject)
        case .pattern:
            return PatternColorSpace(cosObject: cosObject)
        default:
            throw PDError.unsupportedColorSpace(familyName.stringValue)
        }
    }
}
