import Foundation
import CoreGraphics

/// DeviceN color space.
///
/// This corresponds to the Java `PDDeviceN` class from veraPDF-parser.
/// DeviceN color spaces are similar to Separation but support multiple colorants.
///
/// ## PDF Specification
/// Specified as an array: `[/DeviceN names alternateSpace tintTransform]`
/// or with attributes: `[/DeviceN names alternateSpace tintTransform attributes]`
///
/// - `names`: Array of colorant names
/// - `alternateSpace`: Color space to use when colorants are not available
/// - `tintTransform`: Function mapping tint values to alternate space
/// - `attributes`: Optional dictionary with colorant information (PDF 1.6+)
///
/// ## Usage
/// ```swift
/// let deviceN = try DeviceNColorSpace(cosObject: arrayValue)
/// let colorants = deviceN.colorantNames
/// let alternate = deviceN.alternateColorSpace
/// ```
public struct DeviceNColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The names of the colorants.
    public let colorantNames: [ASAtom]

    /// The alternate color space for color conversion.
    public let alternateColorSpace: any PDFColorSpace

    /// The tint transformation function (COS object).
    public let tintTransform: COSValue

    /// Optional attributes dictionary (PDF 1.6+).
    public let attributes: COSValue?

    // MARK: - Initialization

    /// Creates a DeviceN color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/DeviceN names alternate tint]` or with attributes.
    /// - Throws: `PDError` if the array format is invalid.
    public init(cosObject: COSValue) throws {
        self.cosObject = cosObject

        guard case .array(let array) = cosObject, array.count >= 4 else {
            throw PDError.invalidColorSpace
        }

        // Parse colorant names (array of names)
        guard case .array(let namesArray) = array[1] else {
            throw PDError.invalidColorSpace
        }

        var names: [ASAtom] = []
        for nameValue in namesArray {
            guard case .name(let name) = nameValue else {
                throw PDError.invalidColorSpace
            }
            names.append(name)
        }

        guard !names.isEmpty else {
            throw PDError.invalidColorSpace
        }
        self.colorantNames = names

        // Parse alternate color space
        self.alternateColorSpace = try PDFColorSpaceFactory.create(from: array[2])

        // Parse tint transform function
        self.tintTransform = array[3]

        // Parse optional attributes dictionary (PDF 1.6+)
        if array.count >= 5 {
            self.attributes = array[4]
        } else {
            self.attributes = nil
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .deviceN
    }

    public var numberOfComponents: Int {
        colorantNames.count
    }

    public var cgColorSpace: CGColorSpace? {
        // DeviceN color spaces cannot be directly represented in CoreGraphics
        // Use alternate color space instead
        return alternateColorSpace.cgColorSpace
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == colorantNames.count else {
            throw PDError.invalidColorComponents(expected: colorantNames.count, got: components.count)
        }

        // Clamp all components to valid range
        let tints = components.map { $0.clamped(to: 0.0...1.0) }

        // In a full implementation, we would evaluate the tint transform function
        // to convert the tint values to the alternate color space.
        // For now, we'll use a simple approximation.

        // Check if this is a special DeviceN space (e.g., DeviceCMYK emulation)
        if colorantNames.count == 4 &&
           colorantNames[0] == ASAtom("Cyan") &&
           colorantNames[1] == ASAtom("Magenta") &&
           colorantNames[2] == ASAtom("Yellow") &&
           colorantNames[3] == ASAtom("Black") {
            // This is essentially CMYK
            let c = tints[0]
            let m = tints[1]
            let y = tints[2]
            let k = tints[3]

            let r = (1.0 - c) * (1.0 - k)
            let g = (1.0 - m) * (1.0 - k)
            let b = (1.0 - y) * (1.0 - k)

            return (r, g, b)
        }

        // For other DeviceN spaces, approximate by averaging tints
        // and converting through alternate space
        let avgTint = tints.reduce(0.0, +) / Double(tints.count)

        let alternateComponents: [Double]
        switch alternateColorSpace.numberOfComponents {
        case 1:  // Gray
            alternateComponents = [1.0 - avgTint]
        case 3:  // RGB - approximate as gray
            let gray = 1.0 - avgTint
            alternateComponents = [gray, gray, gray]
        case 4:  // CMYK - put average tint in K channel
            alternateComponents = [0, 0, 0, avgTint]
        default:
            throw PDError.invalidColorSpace
        }

        return try alternateColorSpace.toRGB(alternateComponents)
    }

    // MARK: - Hashable

    public static func == (lhs: DeviceNColorSpace, rhs: DeviceNColorSpace) -> Bool {
        lhs.cosObject == rhs.cosObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cosObject)
    }
}

// MARK: - Helper

fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
