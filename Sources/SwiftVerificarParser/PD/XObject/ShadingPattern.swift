import Foundation
import CoreGraphics

/// Represents a PDF shading pattern (Pattern Type 2).
///
/// Shading patterns paint smooth color gradients across an area.
/// They reference a Shading dictionary that defines the gradient.
///
/// This type corresponds to the Java `PDShadingPattern` class from veraPDF-parser.
///
/// ## PDF Specification
/// Shading patterns have `/PatternType 2` and contain:
/// - `/Shading` - Reference to a Shading dictionary
/// - `/Matrix` - Optional transformation matrix
/// - `/ExtGState` - Optional extended graphics state
///
/// ## Usage
/// ```swift
/// let pattern = try ShadingPattern(cosObject: patternDict)
/// let shading = try Shading(cosObject: pattern.shadingValue!)
/// print("Shading type: \(shading.shadingType)")
/// ```
public struct ShadingPattern: PDFPattern, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this pattern.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a shading pattern from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary).
    /// - Throws: `PatternError` if required entries are missing or invalid.
    public init(cosObject: COSValue) throws {
        // Validate pattern type
        let patternType = cosObject["PatternType"]?.integerValue ?? 2
        guard patternType == 2 else {
            throw PatternError.invalidPatternType(Int(patternType))
        }

        // Shading is required
        guard cosObject["Shading"] != nil else {
            throw PatternError.invalidShading
        }

        self.cosObject = cosObject
    }

    // MARK: - PDFPattern Protocol

    /// Returns 2 for shading patterns.
    public var patternType: Int {
        2
    }

    /// The transformation matrix from pattern space to user space.
    public var matrix: FormXObject.Matrix {
        FormXObject.Matrix(from: cosObject[.matrix]) ?? .identity
    }

    // MARK: - Shading Pattern Properties

    /// The shading dictionary value.
    public var shadingValue: COSValue? {
        cosObject["Shading"]
    }

    /// Creates and returns the Shading object.
    ///
    /// - Returns: The Shading if valid.
    /// - Throws: Error if the shading is invalid.
    public func shading() throws -> Shading {
        guard let value = shadingValue else {
            throw PatternError.invalidShading
        }
        return try Shading(cosObject: value)
    }

    /// The extended graphics state for rendering.
    ///
    /// Contains additional graphics parameters like opacity.
    public var extGState: COSValue? {
        cosObject[.extGState]
    }

    // MARK: - Convenience Properties

    /// The shading type, if the shading is accessible.
    public var shadingType: Int? {
        shadingValue?["ShadingType"]?.integerValue.map { Int($0) }
    }

    /// The color space of the shading.
    public var colorSpace: COSValue? {
        shadingValue?[.colorSpace]
    }

    /// The color space name if it's a simple color space.
    public var colorSpaceName: ASAtom? {
        if let name = colorSpace?.nameValue {
            return name
        }
        if let array = colorSpace?.arrayValue, !array.isEmpty {
            return array[0].nameValue
        }
        return nil
    }

    /// The background color for areas outside the shading bounds.
    public var background: [Double]? {
        shadingValue?["Background"]?.arrayValue?.compactMap { $0.numericValue }
    }

    /// The bounding box of the shading.
    public var bBox: FormXObject.Rectangle? {
        FormXObject.Rectangle(from: shadingValue?[.bbox])
    }

    /// Whether anti-aliasing is enabled for the shading.
    public var antiAlias: Bool {
        shadingValue?["AntiAlias"]?.boolValue ?? false
    }
}
