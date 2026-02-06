import Foundation
import CoreGraphics

/// Separation color space.
///
/// This corresponds to the Java `PDSeparation` class from veraPDF-parser.
/// Separation color spaces provide a means for specifying additional colorants
/// (such as metallic inks or spot colors) or for isolating the control of individual
/// process colorants.
///
/// ## PDF Specification
/// Specified as an array: `[/Separation name alternateSpace tintTransform]`
///
/// - `name`: Name of the colorant (e.g., `/PANTONE 185 CV`)
/// - `alternateSpace`: Color space to use when the separation is not available
/// - `tintTransform`: Function mapping tint values (0.0-1.0) to alternate space
///
/// ## Usage
/// ```swift
/// let separation = try SeparationColorSpace(cosObject: arrayValue)
/// let colorantName = separation.colorantName
/// let alternate = separation.alternateColorSpace
/// ```
public struct SeparationColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The name of the colorant.
    public let colorantName: ASAtom

    /// The alternate color space for color conversion.
    public let alternateColorSpace: any PDFColorSpace

    /// The tint transformation function (COS object).
    public let tintTransform: COSValue

    // MARK: - Initialization

    /// Creates a Separation color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/Separation name alternate tint]`.
    /// - Throws: `PDError` if the array format is invalid.
    public init(cosObject: COSValue) throws {
        self.cosObject = cosObject

        guard case .array(let array) = cosObject, array.count == 4 else {
            throw PDError.invalidColorSpace
        }

        // Parse colorant name
        guard case .name(let name) = array[1] else {
            throw PDError.invalidColorSpace
        }
        self.colorantName = name

        // Parse alternate color space
        self.alternateColorSpace = try PDFColorSpaceFactory.create(from: array[2])

        // Parse tint transform function
        // Could be a function dictionary, stream, or name
        self.tintTransform = array[3]
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .separation
    }

    public var numberOfComponents: Int {
        1  // Single tint value (0.0 to 1.0)
    }

    public var cgColorSpace: CGColorSpace? {
        // Separation color spaces cannot be directly represented in CoreGraphics
        // Use alternate color space instead
        return alternateColorSpace.cgColorSpace
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 1 else {
            throw PDError.invalidColorComponents(expected: 1, got: components.count)
        }

        let tint = components[0].clamped(to: 0.0...1.0)

        // In a full implementation, we would evaluate the tint transform function
        // to convert the tint value to the alternate color space.
        // For now, we'll use a simple approximation: map tint to grayscale
        // and convert through alternate space.

        // Special handling for common special colorants
        if colorantName == .all {
            // /All colorant - used for creating black
            let alternateComponents = Array(
                repeating: 1.0 - tint,
                count: alternateColorSpace.numberOfComponents
            )
            return try alternateColorSpace.toRGB(alternateComponents)
        } else if colorantName == .none {
            // /None colorant - creates no output
            return (1.0, 1.0, 1.0)  // white
        }

        // For other colorants, approximate by converting tint to alternate space
        // Typically, 0.0 = no ink (white), 1.0 = full ink
        let alternateComponents: [Double]
        switch alternateColorSpace.numberOfComponents {
        case 1:  // Gray
            alternateComponents = [1.0 - tint]
        case 3:  // RGB - approximate as gray
            let gray = 1.0 - tint
            alternateComponents = [gray, gray, gray]
        case 4:  // CMYK - put all tint in K channel
            alternateComponents = [0, 0, 0, tint]
        default:
            throw PDError.invalidColorSpace
        }

        return try alternateColorSpace.toRGB(alternateComponents)
    }

    // MARK: - Hashable

    public static func == (lhs: SeparationColorSpace, rhs: SeparationColorSpace) -> Bool {
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

// MARK: - ASAtom Extension

fileprivate extension ASAtom {
    static let all = ASAtom("All")
    static let none = ASAtom("None")
}
