import Foundation
import CoreGraphics

/// Represents the graphics state for PDF content stream rendering.
///
/// `GraphicsState` tracks the complete graphics state as defined in PDF 32000-1:2008 § 8.4.
/// The graphics state is a collection of parameters that affect how graphics operators
/// render their output. It includes transformation matrices, line styles, colors, and more.
///
/// The graphics state is modified by various operators and can be saved/restored
/// using the `q` and `Q` operators.
///
/// ## Graphics State Components
///
/// - **Coordinate transformation**: Current transformation matrix (CTM)
/// - **Line attributes**: Width, cap, join, miter limit, dash pattern
/// - **Color spaces and colors**: Stroking and nonstroking colors
/// - **Text state**: Font, size, rendering mode (see `TextState`)
/// - **Clipping path**: Current clipping region
/// - **Other parameters**: Flatness, rendering intent, alpha, blend mode
///
/// ## Usage
/// ```swift
/// var state = GraphicsState()
/// state.lineWidth = 2.0
/// state.strokeColor = [1.0, 0.0, 0.0] // Red
/// let saved = state // Save state
/// state.lineWidth = 5.0
/// state = saved // Restore state
/// ```
///
/// ## Thread Safety
/// `GraphicsState` is a value type (struct) and is `Sendable`.
public struct GraphicsState: Sendable, Equatable {

    // MARK: - Coordinate Transformation

    /// Current transformation matrix (CTM).
    ///
    /// Maps coordinates from user space to device space.
    /// Modified by the `cm` operator.
    public var ctm: CGAffineTransform

    // MARK: - Line Attributes

    /// Line width in user space units.
    ///
    /// Default: 1.0
    /// Operator: `w`
    public var lineWidth: Double

    /// Line cap style.
    ///
    /// - 0: Butt cap (default)
    /// - 1: Round cap
    /// - 2: Projecting square cap
    ///
    /// Operator: `J`
    public var lineCap: Int

    /// Line join style.
    ///
    /// - 0: Miter join (default)
    /// - 1: Round join
    /// - 2: Bevel join
    ///
    /// Operator: `j`
    public var lineJoin: Int

    /// Miter limit.
    ///
    /// Maximum ratio of miter length to line width for mitered line joins.
    /// Default: 10.0
    /// Operator: `M`
    public var miterLimit: Double

    /// Line dash pattern.
    ///
    /// Array of dash and gap lengths, plus a phase offset.
    /// Empty array means solid line (default).
    /// Operator: `d`
    public var dashPattern: [Double]

    /// Line dash phase.
    ///
    /// Distance into the dash pattern to start the line.
    /// Default: 0.0
    /// Operator: `d`
    public var dashPhase: Double

    // MARK: - Color

    /// Current stroking color space name.
    ///
    /// Default: DeviceGray
    /// Operators: `CS`
    public var strokeColorSpace: ASAtom

    /// Current nonstroking color space name.
    ///
    /// Default: DeviceGray
    /// Operators: `cs`
    public var fillColorSpace: ASAtom

    /// Current stroking color components.
    ///
    /// Number of components depends on the color space.
    /// Default: [0.0] (black in DeviceGray)
    /// Operators: `SC`, `SCN`, `G`, `RG`, `K`
    public var strokeColor: [Double]

    /// Current nonstroking color components.
    ///
    /// Number of components depends on the color space.
    /// Default: [0.0] (black in DeviceGray)
    /// Operators: `sc`, `scn`, `g`, `rg`, `k`
    public var fillColor: [Double]

    /// Current stroking pattern name (if any).
    ///
    /// Operator: `SCN`
    public var strokePattern: ASAtom?

    /// Current nonstroking pattern name (if any).
    ///
    /// Operator: `scn`
    public var fillPattern: ASAtom?

    // MARK: - Rendering Parameters

    /// Flatness tolerance.
    ///
    /// Maximum distance (in device pixels) between the mathematically correct path
    /// and the approximated path. Lower values produce more accurate curves.
    /// Default: 1.0
    /// Operator: `i`
    public var flatness: Double

    /// Color rendering intent.
    ///
    /// Specifies how colors should be rendered on output devices.
    /// Possible values: RelativeColorimetric, AbsoluteColorimetric, Saturation, Perceptual
    /// Default: RelativeColorimetric
    /// Operator: `ri`
    public var renderingIntent: ASAtom

    // MARK: - Text State

    /// Current text state.
    ///
    /// Embedded structure containing text-specific parameters like font, size, and spacing.
    public var textState: TextState

    // MARK: - Extended Graphics State

    /// Name of the current extended graphics state dictionary (if set via `gs` operator).
    public var extGStateName: ASAtom?

    // MARK: - Initialization

    /// Creates a graphics state with default values.
    public init() {
        // Coordinate transformation
        self.ctm = .identity

        // Line attributes
        self.lineWidth = 1.0
        self.lineCap = 0 // Butt cap
        self.lineJoin = 0 // Miter join
        self.miterLimit = 10.0
        self.dashPattern = []
        self.dashPhase = 0.0

        // Color
        self.strokeColorSpace = ASAtom("DeviceGray")
        self.fillColorSpace = ASAtom("DeviceGray")
        self.strokeColor = [0.0] // Black
        self.fillColor = [0.0] // Black
        self.strokePattern = nil
        self.fillPattern = nil

        // Rendering
        self.flatness = 1.0
        self.renderingIntent = ASAtom("RelativeColorimetric")

        // Text state
        self.textState = TextState()

        // Extended graphics state
        self.extGStateName = nil
    }

    // MARK: - Convenience Methods

    /// Concatenates a transformation matrix to the current CTM.
    ///
    /// This multiplies the given matrix with the current CTM.
    /// Operator: `cm`
    public mutating func concatMatrix(_ matrix: CGAffineTransform) {
        ctm = ctm.concatenating(matrix)
    }

    /// Sets the stroking color to a grayscale value.
    ///
    /// Operator: `G`
    public mutating func setStrokeGray(_ gray: Double) {
        strokeColorSpace = ASAtom("DeviceGray")
        strokeColor = [gray]
        strokePattern = nil
    }

    /// Sets the nonstroking color to a grayscale value.
    ///
    /// Operator: `g`
    public mutating func setFillGray(_ gray: Double) {
        fillColorSpace = ASAtom("DeviceGray")
        fillColor = [gray]
        fillPattern = nil
    }

    /// Sets the stroking color to an RGB value.
    ///
    /// Operator: `RG`
    public mutating func setStrokeRGB(r: Double, g: Double, b: Double) {
        strokeColorSpace = ASAtom("DeviceRGB")
        strokeColor = [r, g, b]
        strokePattern = nil
    }

    /// Sets the nonstroking color to an RGB value.
    ///
    /// Operator: `rg`
    public mutating func setFillRGB(r: Double, g: Double, b: Double) {
        fillColorSpace = ASAtom("DeviceRGB")
        fillColor = [r, g, b]
        fillPattern = nil
    }

    /// Sets the stroking color to a CMYK value.
    ///
    /// Operator: `K`
    public mutating func setStrokeCMYK(c: Double, m: Double, y: Double, k: Double) {
        strokeColorSpace = ASAtom("DeviceCMYK")
        strokeColor = [c, m, y, k]
        strokePattern = nil
    }

    /// Sets the nonstroking color to a CMYK value.
    ///
    /// Operator: `k`
    public mutating func setFillCMYK(c: Double, m: Double, y: Double, k: Double) {
        fillColorSpace = ASAtom("DeviceCMYK")
        fillColor = [c, m, y, k]
        fillPattern = nil
    }
}
