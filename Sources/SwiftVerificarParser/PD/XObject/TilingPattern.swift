import Foundation
import CoreGraphics

/// Represents a PDF tiling pattern (Pattern Type 1).
///
/// Tiling patterns consist of a pattern cell that is replicated at fixed
/// horizontal and vertical intervals to fill an area. The pattern cell
/// is defined by a content stream.
///
/// This type corresponds to the Java `PDTilingPattern` class from veraPDF-parser.
///
/// ## PDF Specification
/// Tiling patterns have `/PatternType 1` and contain:
/// - `/PaintType` - How to paint the pattern (1: colored, 2: uncolored)
/// - `/TilingType` - How to adjust spacing (1-3)
/// - `/BBox` - Bounding box in pattern space
/// - `/XStep` - Horizontal spacing between cells
/// - `/YStep` - Vertical spacing between cells
///
/// ## Paint Types
/// - **1 (Colored)**: Pattern specifies its own colors
/// - **2 (Uncolored)**: Pattern is a stencil; colors come from current color space
///
/// ## Tiling Types
/// - **1 (Constant spacing)**: Pattern cells are spaced consistently
/// - **2 (No distortion)**: Cells maintain aspect ratio; spacing may vary slightly
/// - **3 (Faster tiling)**: Cells may be distorted; spacing is constant
///
/// ## Usage
/// ```swift
/// let pattern = try TilingPattern(cosObject: patternDict)
/// print("Paint type: \(pattern.paintType)")
/// print("BBox: \(pattern.bBox)")
/// print("Step: \(pattern.xStep) x \(pattern.yStep)")
/// ```
public struct TilingPattern: PDFPattern, Sendable, Hashable {

    // MARK: - Paint Type

    /// The paint type for a tiling pattern.
    public enum PaintType: Int, Sendable, Hashable, CaseIterable {
        /// Colored pattern - specifies its own colors.
        case colored = 1

        /// Uncolored pattern - uses current color from graphics state.
        case uncolored = 2
    }

    /// The tiling type for a tiling pattern.
    public enum TilingType: Int, Sendable, Hashable, CaseIterable {
        /// Constant spacing - cells are spaced consistently.
        case constantSpacing = 1

        /// No distortion - cells maintain aspect ratio.
        case noDistortion = 2

        /// Constant spacing and faster tiling - cells may be distorted.
        case fasterTiling = 3
    }

    // MARK: - Properties

    /// The underlying COS stream for this pattern.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a tiling pattern from a COS dictionary/stream.
    ///
    /// - Parameter cosObject: The COS object (must be a stream dictionary).
    /// - Throws: `PatternError` if required entries are missing or invalid.
    public init(cosObject: COSValue) throws {
        // Validate pattern type
        let patternType = cosObject["PatternType"]?.integerValue ?? 1
        guard patternType == 1 else {
            throw PatternError.invalidPatternType(Int(patternType))
        }

        // Validate paint type
        guard let paintTypeValue = cosObject["PaintType"]?.integerValue else {
            throw PatternError.missingRequiredEntry(key: "PaintType")
        }
        guard PaintType(rawValue: Int(paintTypeValue)) != nil else {
            throw PatternError.invalidPaintType(Int(paintTypeValue))
        }

        // Validate tiling type
        guard let tilingTypeValue = cosObject["TilingType"]?.integerValue else {
            throw PatternError.missingRequiredEntry(key: "TilingType")
        }
        guard TilingType(rawValue: Int(tilingTypeValue)) != nil else {
            throw PatternError.invalidTilingType(Int(tilingTypeValue))
        }

        // Validate BBox
        guard FormXObject.Rectangle(from: cosObject[.bbox]) != nil else {
            throw PatternError.invalidBBox
        }

        // Validate XStep and YStep
        guard cosObject["XStep"]?.numericValue != nil else {
            throw PatternError.missingRequiredEntry(key: "XStep")
        }
        guard cosObject["YStep"]?.numericValue != nil else {
            throw PatternError.missingRequiredEntry(key: "YStep")
        }

        self.cosObject = cosObject
    }

    // MARK: - PDFPattern Protocol

    /// Returns 1 for tiling patterns.
    public var patternType: Int {
        1
    }

    /// The transformation matrix from pattern space to user space.
    public var matrix: FormXObject.Matrix {
        FormXObject.Matrix(from: cosObject[.matrix]) ?? .identity
    }

    // MARK: - Tiling Pattern Properties

    /// The paint type.
    public var paintType: PaintType {
        PaintType(rawValue: Int(cosObject["PaintType"]!.integerValue!))!
    }

    /// The paint type as an integer.
    public var paintTypeValue: Int {
        Int(cosObject["PaintType"]!.integerValue!)
    }

    /// Whether this is a colored pattern.
    public var isColored: Bool {
        paintType == .colored
    }

    /// Whether this is an uncolored pattern.
    public var isUncolored: Bool {
        paintType == .uncolored
    }

    /// The tiling type.
    public var tilingType: TilingType {
        TilingType(rawValue: Int(cosObject["TilingType"]!.integerValue!))!
    }

    /// The tiling type as an integer.
    public var tilingTypeValue: Int {
        Int(cosObject["TilingType"]!.integerValue!)
    }

    /// The bounding box in pattern coordinate space.
    public var bBox: FormXObject.Rectangle {
        FormXObject.Rectangle(from: cosObject[.bbox])!
    }

    /// The horizontal spacing between pattern cells.
    public var xStep: Double {
        cosObject["XStep"]!.numericValue!
    }

    /// The vertical spacing between pattern cells.
    public var yStep: Double {
        cosObject["YStep"]!.numericValue!
    }

    // MARK: - Resources

    /// The resources dictionary for the pattern content.
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

    /// The cell size as a CGSize.
    public var cellSize: CGSize {
        CGSize(width: width, height: height)
    }

    /// The step size as a CGSize.
    public var stepSize: CGSize {
        CGSize(width: xStep, height: yStep)
    }

    /// Whether the pattern cells overlap (step smaller than BBox).
    public var hasOverlap: Bool {
        xStep < width || yStep < height
    }

    /// Whether there are gaps between pattern cells (step larger than BBox).
    public var hasGaps: Bool {
        xStep > width || yStep > height
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
}
