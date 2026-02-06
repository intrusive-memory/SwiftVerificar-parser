import Foundation
import CoreGraphics

/// Represents a positioned glyph in a PDF with font and positioning information.
///
/// `TextPosition` captures all information about a single character (glyph) as it appears
/// in a PDF content stream, including its:
/// - Unicode representation
/// - Position and size
/// - Font information
/// - Text rendering state
///
/// This is a core building block for text extraction, analogous to Apache PDFBox's
/// `TextPosition` class.
///
/// ## Usage
/// ```swift
/// let position = TextPosition(
///     character: "A",
///     unicode: "A",
///     x: 100.0,
///     y: 700.0,
///     width: 12.0,
///     height: 14.0,
///     fontSize: 12.0,
///     font: ASAtom("F1"),
///     textMatrix: .identity
/// )
/// ```
///
/// ## Thread Safety
/// `TextPosition` is a value type (struct) and is `Sendable`.
public struct TextPosition: Sendable, Equatable, Hashable {

    // MARK: - Character Data

    /// The character as it appears in the content stream (encoded).
    ///
    /// This may be the raw encoded character from the PDF, before ToUnicode mapping.
    public let character: String

    /// The Unicode representation of the character.
    ///
    /// This is the character after applying ToUnicode CMap or other encoding mappings.
    /// For proper text extraction, this should be used rather than `character`.
    public let unicode: String

    // MARK: - Position and Size

    /// The x-coordinate of the character's origin in user space.
    public let x: Double

    /// The y-coordinate of the character's origin (baseline) in user space.
    public let y: Double

    /// The width of the character in user space units.
    ///
    /// This is the advance width (horizontal displacement), not the visual glyph width.
    public let width: Double

    /// The height of the character in user space units.
    ///
    /// Typically the font size multiplied by the vertical scaling.
    public let height: Double

    /// The bounding box of the character in user space.
    ///
    /// Computed from position and size.
    public var boundingBox: CGRect {
        CGRect(x: x, y: y - height, width: width, height: height)
    }

    // MARK: - Font Information

    /// The font size in user space units.
    public let fontSize: Double

    /// The name of the font resource from the content stream.
    public let font: ASAtom?

    /// The horizontal scaling factor (100 = normal, 50 = condensed, 200 = expanded).
    public let horizontalScaling: Double

    /// The character spacing (extra space between characters).
    public let characterSpacing: Double

    /// The word spacing (extra space between words).
    public let wordSpacing: Double

    /// The text rise (vertical offset from baseline).
    public let rise: Double

    // MARK: - Text Matrix

    /// The text matrix at the time this character was rendered.
    ///
    /// This matrix transforms text space coordinates to user space.
    public let textMatrix: CGAffineTransform

    // MARK: - Rendering State

    /// The text rendering mode (0 = fill, 1 = stroke, etc.).
    public let renderingMode: Int

    /// Whether this character is a space character.
    ///
    /// Used for word segmentation during text extraction.
    public var isSpace: Bool {
        unicode == " " || unicode == "\u{00A0}" // Regular space or non-breaking space
    }

    /// Whether this character is whitespace (space, tab, newline, etc.).
    public var isWhitespace: Bool {
        unicode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Initialization

    /// Creates a text position with full positioning and font information.
    ///
    /// - Parameters:
    ///   - character: The character as it appears in the content stream
    ///   - unicode: The Unicode representation of the character
    ///   - x: The x-coordinate in user space
    ///   - y: The y-coordinate (baseline) in user space
    ///   - width: The advance width in user space
    ///   - height: The height in user space
    ///   - fontSize: The font size
    ///   - font: The font resource name
    ///   - horizontalScaling: The horizontal scaling (default: 100.0)
    ///   - characterSpacing: The character spacing (default: 0.0)
    ///   - wordSpacing: The word spacing (default: 0.0)
    ///   - rise: The text rise (default: 0.0)
    ///   - textMatrix: The text matrix (default: identity)
    ///   - renderingMode: The rendering mode (default: 0)
    public init(
        character: String,
        unicode: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        fontSize: Double,
        font: ASAtom? = nil,
        horizontalScaling: Double = 100.0,
        characterSpacing: Double = 0.0,
        wordSpacing: Double = 0.0,
        rise: Double = 0.0,
        textMatrix: CGAffineTransform = .identity,
        renderingMode: Int = 0
    ) {
        self.character = character
        self.unicode = unicode
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.fontSize = fontSize
        self.font = font
        self.horizontalScaling = horizontalScaling
        self.characterSpacing = characterSpacing
        self.wordSpacing = wordSpacing
        self.rise = rise
        self.textMatrix = textMatrix
        self.renderingMode = renderingMode
    }

    // MARK: - Geometric Queries

    /// Returns the horizontal distance from this character to another.
    ///
    /// - Parameter other: Another text position
    /// - Returns: Horizontal distance (positive if `other` is to the right)
    public func horizontalDistance(to other: TextPosition) -> Double {
        other.x - (x + width)
    }

    /// Returns the vertical distance from this character's baseline to another's.
    ///
    /// - Parameter other: Another text position
    /// - Returns: Vertical distance (positive if `other` is above)
    public func verticalDistance(to other: TextPosition) -> Double {
        abs(y - other.y)
    }

    /// Returns whether this character is on the same line as another.
    ///
    /// Characters are considered on the same line if their vertical distance
    /// is less than half the font size.
    ///
    /// - Parameter other: Another text position
    /// - Returns: `true` if on the same line
    public func isOnSameLine(as other: TextPosition) -> Bool {
        verticalDistance(to: other) < fontSize / 2.0
    }

    /// Returns whether this character should be merged with the next character.
    ///
    /// Characters should be merged if they're on the same line and close together
    /// (within 1 character width, accounting for character/word spacing).
    ///
    /// - Parameter other: The next text position
    /// - Returns: `true` if characters should be merged
    public func shouldMerge(with other: TextPosition) -> Bool {
        guard isOnSameLine(as: other) else {
            return false
        }

        let distance = horizontalDistance(to: other)
        let threshold = width * 1.5 // Allow up to 1.5 character widths

        return distance >= 0 && distance < threshold
    }
}

// MARK: - CustomStringConvertible

extension TextPosition: CustomStringConvertible {
    public var description: String {
        "TextPosition('\(unicode)', x: \(String(format: "%.1f", x)), y: \(String(format: "%.1f", y)), " +
        "w: \(String(format: "%.1f", width)), h: \(String(format: "%.1f", height)))"
    }
}

// MARK: - Comparable

extension TextPosition: Comparable {
    /// Compares text positions for reading order.
    ///
    /// Positions are ordered by:
    /// 1. Descending y-coordinate (top to bottom)
    /// 2. Ascending x-coordinate (left to right)
    public static func < (lhs: TextPosition, rhs: TextPosition) -> Bool {
        if abs(lhs.y - rhs.y) < 0.1 { // Same line (within tolerance)
            return lhs.x < rhs.x
        }
        return lhs.y > rhs.y // Higher y comes first (PDF coordinates)
    }
}
