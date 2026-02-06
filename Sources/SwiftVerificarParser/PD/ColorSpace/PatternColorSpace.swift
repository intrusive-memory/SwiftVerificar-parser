import Foundation
import CoreGraphics

/// Pattern color space.
///
/// This corresponds to pattern color space handling from veraPDF-parser.
/// Pattern color spaces are used for tiling patterns and shading patterns.
///
/// ## PDF Specification
/// Specified as:
/// - The name `/Pattern` (uncolored patterns)
/// - Array `[/Pattern baseColorSpace]` (colored patterns with underlying space)
///
/// Pattern color spaces don't define colors directly but reference pattern objects
/// that define repeating graphical elements or smooth shadings.
///
/// ## Usage
/// ```swift
/// let pattern = PatternColorSpace(cosObject: .name(.pattern))
/// let hasBase = pattern.underlyingColorSpace != nil
/// ```
public struct PatternColorSpace: PDFColorSpace, Sendable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The underlying color space for uncolored patterns (optional).
    ///
    /// When present, this is the color space in which pattern colors are specified.
    /// For colored patterns, this is `nil`.
    public let underlyingColorSpace: (any PDFColorSpace)?

    // MARK: - Initialization

    /// Creates a Pattern color space.
    ///
    /// - Parameter cosObject: Either `.name(.pattern)` or `[/Pattern baseSpace]`.
    public init(cosObject: COSValue) {
        self.cosObject = cosObject

        // Check if it's an array with underlying color space
        if case .array(let array) = cosObject, array.count == 2 {
            self.underlyingColorSpace = try? PDFColorSpaceFactory.create(from: array[1])
        } else {
            self.underlyingColorSpace = nil
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .pattern
    }

    public var numberOfComponents: Int {
        // Pattern color spaces are special - they don't have a fixed number of components.
        // For uncolored patterns with an underlying space, the number of components
        // is that of the underlying space. For colored patterns, it's 0.
        underlyingColorSpace?.numberOfComponents ?? 0
    }

    public var cgColorSpace: CGColorSpace? {
        // Pattern color spaces cannot be directly represented as CGColorSpace
        // The underlying space might have a representation though
        return underlyingColorSpace?.cgColorSpace
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        // For patterns with an underlying color space, convert through that space
        if let underlying = underlyingColorSpace {
            return try underlying.toRGB(components)
        }

        // For colored patterns, color is defined by the pattern itself
        // Return white as a default
        return (1.0, 1.0, 1.0)
    }
}

// MARK: - Hashable

extension PatternColorSpace: Hashable {
    public static func == (lhs: PatternColorSpace, rhs: PatternColorSpace) -> Bool {
        lhs.cosObject == rhs.cosObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cosObject)
    }
}
