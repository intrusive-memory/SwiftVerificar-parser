import Foundation
import CoreGraphics

/// Represents the text state for PDF content stream text rendering.
///
/// `TextState` tracks text-specific parameters that affect how text operators
/// render their output. It is a component of the graphics state.
///
/// This struct corresponds to the text state parameters defined in
/// PDF 32000-1:2008 § 9.3 "Text State Parameters and Operators".
///
/// ## Text State Parameters
///
/// - **Character spacing**: Extra space between characters
/// - **Word spacing**: Extra space between words
/// - **Horizontal scaling**: Scaling factor for glyph widths
/// - **Leading**: Vertical distance between text lines
/// - **Font and size**: Current font resource and size
/// - **Rendering mode**: How glyphs are rendered (fill, stroke, clip, etc.)
/// - **Rise**: Vertical offset for superscripts/subscripts
/// - **Text matrix**: Position and transformation of text
/// - **Text line matrix**: Position of the current line
///
/// ## Usage
/// ```swift
/// var textState = TextState()
/// textState.font = ASAtom("F1")
/// textState.fontSize = 12.0
/// textState.characterSpacing = 0.5
/// ```
///
/// ## Thread Safety
/// `TextState` is a value type (struct) and is `Sendable`.
public struct TextState: Sendable, Equatable {

    // MARK: - Text State Parameters

    /// Character spacing (Tc).
    ///
    /// Extra horizontal spacing added between characters, in unscaled text space units.
    /// Positive values increase spacing; negative values decrease it.
    /// Default: 0.0
    /// Operator: `Tc`
    public var characterSpacing: Double

    /// Word spacing (Tw).
    ///
    /// Extra horizontal spacing added between words (space characters, ASCII 32),
    /// in unscaled text space units.
    /// Default: 0.0
    /// Operator: `Tw`
    public var wordSpacing: Double

    /// Horizontal scaling (Tz).
    ///
    /// Percentage of normal width (100 = normal, 50 = half width, 200 = double width).
    /// Applies to character spacing, glyph widths, and word spacing.
    /// Default: 100.0
    /// Operator: `Tz`
    public var horizontalScaling: Double

    /// Text leading (TL).
    ///
    /// Vertical distance between baselines of consecutive text lines,
    /// in unscaled text space units.
    /// Default: 0.0
    /// Operator: `TL`
    public var leading: Double

    /// Current font resource name.
    ///
    /// Name of the font in the resource dictionary.
    /// Default: nil (no font set)
    /// Operator: `Tf`
    public var font: ASAtom?

    /// Current font size (Tfs).
    ///
    /// Size of the font in text space units.
    /// Default: 0.0
    /// Operator: `Tf`
    public var fontSize: Double

    /// Text rendering mode (Tmode).
    ///
    /// Determines how glyphs are rendered:
    /// - 0: Fill text
    /// - 1: Stroke text
    /// - 2: Fill, then stroke text
    /// - 3: Neither fill nor stroke (invisible)
    /// - 4: Fill text and add to clipping path
    /// - 5: Stroke text and add to clipping path
    /// - 6: Fill, then stroke text and add to clipping path
    /// - 7: Add text to clipping path (neither fill nor stroke)
    ///
    /// Default: 0
    /// Operator: `Tr`
    public var renderingMode: Int

    /// Text rise (Trise).
    ///
    /// Vertical offset from the baseline, in unscaled text space units.
    /// Positive values move text up; negative values move it down.
    /// Used for superscripts and subscripts.
    /// Default: 0.0
    /// Operator: `Ts`
    public var rise: Double

    // MARK: - Text Positioning

    /// Text matrix (Tm).
    ///
    /// Transformation matrix that maps text space to user space.
    /// Modified by text positioning operators (`Td`, `TD`, `Tm`, `T*`).
    /// Reset to identity at the start of a text object (`BT`).
    /// Operators: `Tm`, `Td`, `TD`, `T*`
    public var textMatrix: CGAffineTransform

    /// Text line matrix (Tlm).
    ///
    /// Transformation matrix that captures the start of the current text line.
    /// Set to the text matrix at the start of each line.
    /// Used by the `T*` operator to move to the next line.
    /// Operators: `Td`, `TD`, `Tm`, `T*`
    public var textLineMatrix: CGAffineTransform

    // MARK: - Initialization

    /// Creates a text state with default values.
    public init() {
        self.characterSpacing = 0.0
        self.wordSpacing = 0.0
        self.horizontalScaling = 100.0
        self.leading = 0.0
        self.font = nil
        self.fontSize = 0.0
        self.renderingMode = 0 // Fill
        self.rise = 0.0
        self.textMatrix = .identity
        self.textLineMatrix = .identity
    }

    // MARK: - Text Positioning Methods

    /// Moves the text position by (tx, ty).
    ///
    /// Updates the text matrix and line matrix.
    /// Operator: `Td`
    public mutating func moveText(tx: Double, ty: Double) {
        let translation = CGAffineTransform(translationX: tx, y: ty)
        textLineMatrix = textLineMatrix.concatenating(translation)
        textMatrix = textLineMatrix
    }

    /// Moves the text position by (tx, ty) and sets the leading to -ty.
    ///
    /// Operator: `TD`
    public mutating func moveTextSetLeading(tx: Double, ty: Double) {
        leading = -ty
        moveText(tx: tx, ty: ty)
    }

    /// Sets the text matrix and line matrix.
    ///
    /// Operator: `Tm`
    public mutating func setTextMatrix(_ matrix: CGAffineTransform) {
        textMatrix = matrix
        textLineMatrix = matrix
    }

    /// Moves to the start of the next line, equivalent to `Td(0, -Tl)`.
    ///
    /// Uses the current leading value.
    /// Operator: `T*`
    public mutating func moveToNextLine() {
        moveText(tx: 0, ty: -leading)
    }

    // MARK: - Validation

    /// Returns whether the text state is valid for rendering text.
    ///
    /// A valid text state has a font set and a positive font size.
    public var isValid: Bool {
        font != nil && fontSize > 0
    }
}
