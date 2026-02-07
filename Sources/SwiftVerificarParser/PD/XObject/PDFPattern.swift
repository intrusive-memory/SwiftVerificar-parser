import Foundation
import CoreGraphics

/// Protocol for all PDF pattern types.
///
/// Patterns define how areas are filled or stroked with repeating graphics
/// or smooth color gradients. They are used with the Pattern color space.
///
/// This protocol corresponds to the Java `PDPattern` abstract class from veraPDF-parser.
///
/// ## Pattern Types
/// - **Type 1 (Tiling)**: Repeating pattern cell painted at regular intervals
/// - **Type 2 (Shading)**: Smooth color gradient defined by a shading dictionary
///
/// ## PDF Specification
/// Patterns are stored in the `/Pattern` subdictionary of resources.
/// They are selected via the `cs` or `CS` operators and painted via `scn`/`SCN`.
///
/// ## Usage
/// ```swift
/// let pattern = try PDFPatternFactory.create(from: patternDict)
/// switch pattern.patternType {
/// case 1:
///     let tiling = pattern as! TilingPattern
/// case 2:
///     let shading = pattern as! ShadingPattern
/// default:
///     break
/// }
/// ```
public protocol PDFPattern: PDObject {

    /// The pattern type.
    ///
    /// - 1: Tiling pattern
    /// - 2: Shading pattern
    var patternType: Int { get }

    /// The transformation matrix from pattern space to user space.
    var matrix: FormXObject.Matrix { get }
}

// MARK: - Pattern Errors

/// Errors specific to pattern operations.
public enum PatternError: Error, Sendable, Equatable, CustomStringConvertible {

    /// Missing required pattern type.
    case missingPatternType

    /// Invalid pattern type value.
    case invalidPatternType(Int)

    /// Missing required entry in pattern dictionary.
    case missingRequiredEntry(key: String)

    /// Invalid paint type for tiling pattern.
    case invalidPaintType(Int?)

    /// Invalid tiling type.
    case invalidTilingType(Int?)

    /// Invalid bounding box.
    case invalidBBox

    /// Invalid shading reference.
    case invalidShading

    public var description: String {
        switch self {
        case .missingPatternType:
            return "Pattern missing required PatternType entry"
        case .invalidPatternType(let type):
            return "Invalid pattern type: \(type)"
        case .missingRequiredEntry(let key):
            return "Pattern missing required entry: \(key)"
        case .invalidPaintType(let type):
            if let t = type {
                return "Invalid paint type: \(t)"
            }
            return "Missing paint type"
        case .invalidTilingType(let type):
            if let t = type {
                return "Invalid tiling type: \(t)"
            }
            return "Missing tiling type"
        case .invalidBBox:
            return "Invalid or missing pattern BBox"
        case .invalidShading:
            return "Invalid or missing Shading in shading pattern"
        }
    }
}

// MARK: - Pattern Factory

/// Factory for creating pattern instances from COS values.
public enum PDFPatternFactory {

    /// Creates a pattern from a COS dictionary or stream.
    ///
    /// - Parameter cosObject: The COS value representing the pattern.
    /// - Returns: A concrete pattern instance based on the `/PatternType`.
    /// - Throws: `PatternError` if the pattern is invalid or unsupported.
    ///
    /// ## Pattern Types
    /// - Type 1 creates a `TilingPattern`
    /// - Type 2 creates a `ShadingPattern`
    public static func create(from cosObject: COSValue) throws -> any PDFPattern {
        // Get the pattern type
        guard let patternTypeValue = cosObject["PatternType"]?.integerValue else {
            throw PatternError.missingPatternType
        }

        let patternType = Int(patternTypeValue)

        switch patternType {
        case 1:
            return try TilingPattern(cosObject: cosObject)
        case 2:
            return try ShadingPattern(cosObject: cosObject)
        default:
            throw PatternError.invalidPatternType(patternType)
        }
    }
}
