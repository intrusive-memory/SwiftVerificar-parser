import Foundation
import CoreGraphics

/// Represents a line of text composed of positioned glyphs.
///
/// `TextLine` groups `TextPosition` objects that appear on the same horizontal baseline,
/// providing line-level operations like text extraction, bounding box calculation,
/// and word segmentation.
///
/// This is analogous to a text line in Apache PDFBox's text extraction model.
///
/// ## Usage
/// ```swift
/// var line = TextLine()
/// line.append(position1)
/// line.append(position2)
///
/// let text = line.text
/// let bounds = line.boundingBox
/// let words = line.words
/// ```
///
/// ## Thread Safety
/// `TextLine` is a value type (struct) and is `Sendable`.
public struct TextLine: Sendable, Equatable {

    // MARK: - Properties

    /// The positions that make up this line, in reading order.
    public private(set) var positions: [TextPosition]

    /// Whether the line is empty.
    public var isEmpty: Bool {
        positions.isEmpty
    }

    /// The number of positions in the line.
    public var count: Int {
        positions.count
    }

    /// The extracted text from this line.
    ///
    /// Concatenates the Unicode values of all positions.
    public var text: String {
        positions.map { $0.unicode }.joined()
    }

    /// The bounding box that encloses all positions in the line.
    public var boundingBox: CGRect {
        guard !positions.isEmpty else {
            return .zero
        }

        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x + $0.width }.max() ?? 0
        let minY = positions.map { $0.y - $0.height }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// The average font size of positions in this line.
    public var averageFontSize: Double {
        guard !positions.isEmpty else {
            return 0.0
        }
        return positions.map { $0.fontSize }.reduce(0, +) / Double(positions.count)
    }

    /// The average height of positions in this line.
    public var averageHeight: Double {
        guard !positions.isEmpty else {
            return 0.0
        }
        return positions.map { $0.height }.reduce(0, +) / Double(positions.count)
    }

    /// The baseline y-coordinate of the line (average of all position y-coordinates).
    public var baseline: Double {
        guard !positions.isEmpty else {
            return 0.0
        }
        return positions.map { $0.y }.reduce(0, +) / Double(positions.count)
    }

    /// The words in this line, segmented by spaces.
    ///
    /// Returns an array of substrings where each substring is a word.
    public var words: [String] {
        // Split on whitespace positions
        var words: [String] = []
        var currentWord = ""

        for position in positions {
            if position.isWhitespace {
                if !currentWord.isEmpty {
                    words.append(currentWord)
                    currentWord = ""
                }
            } else {
                currentWord.append(position.unicode)
            }
        }

        if !currentWord.isEmpty {
            words.append(currentWord)
        }

        return words
    }

    // MARK: - Initialization

    /// Creates an empty text line.
    public init() {
        self.positions = []
    }

    /// Creates a text line with the given positions.
    ///
    /// - Parameter positions: An array of text positions
    public init(positions: [TextPosition]) {
        self.positions = positions.sorted() // Ensure reading order
    }

    // MARK: - Mutating Methods

    /// Appends a position to the line.
    ///
    /// The position is inserted in reading order (by x-coordinate).
    ///
    /// - Parameter position: The position to append
    public mutating func append(_ position: TextPosition) {
        positions.append(position)
        positions.sort() // Maintain reading order
    }

    /// Appends multiple positions to the line.
    ///
    /// - Parameter positions: The positions to append
    public mutating func append(contentsOf newPositions: [TextPosition]) {
        positions.append(contentsOf: newPositions)
        positions.sort() // Maintain reading order
    }

    /// Removes all positions from the line.
    public mutating func removeAll() {
        positions.removeAll()
    }

    // MARK: - Queries

    /// Returns whether this line should be merged with another line.
    ///
    /// Lines should be merged if they have similar baselines (within half a font size).
    ///
    /// - Parameter other: Another text line
    /// - Returns: `true` if lines should be merged
    public func shouldMerge(with other: TextLine) -> Bool {
        guard !isEmpty && !other.isEmpty else {
            return false
        }

        let threshold = (averageFontSize + other.averageFontSize) / 4.0
        return abs(baseline - other.baseline) < threshold
    }

    /// Returns the horizontal distance from the end of this line to the start of another.
    ///
    /// - Parameter other: Another text line
    /// - Returns: Horizontal distance (positive if `other` is to the right)
    public func horizontalDistance(to other: TextLine) -> Double {
        guard !isEmpty && !other.isEmpty else {
            return .infinity
        }

        let thisEnd = positions.last!.x + positions.last!.width
        let otherStart = other.positions.first!.x

        return otherStart - thisEnd
    }

    /// Returns the vertical distance from this line's baseline to another's.
    ///
    /// - Parameter other: Another text line
    /// - Returns: Vertical distance (always positive)
    public func verticalDistance(to other: TextLine) -> Double {
        abs(baseline - other.baseline)
    }
}

// MARK: - CustomStringConvertible

extension TextLine: CustomStringConvertible {
    public var description: String {
        let posCount = positions.count
        let preview = text.prefix(40)
        let truncated = text.count > 40 ? "..." : ""
        return "TextLine(\(posCount) positions, \"\(preview)\(truncated)\")"
    }
}

// MARK: - Comparable

extension TextLine: Comparable {
    /// Compares text lines for reading order.
    ///
    /// Lines are ordered by:
    /// 1. Descending baseline (top to bottom)
    /// 2. Ascending x-coordinate of first position (left to right)
    public static func < (lhs: TextLine, rhs: TextLine) -> Bool {
        if abs(lhs.baseline - rhs.baseline) < 0.1 { // Same baseline (within tolerance)
            guard let lhsFirst = lhs.positions.first, let rhsFirst = rhs.positions.first else {
                return false
            }
            return lhsFirst.x < rhsFirst.x
        }
        return lhs.baseline > rhs.baseline // Higher baseline comes first (PDF coordinates)
    }
}

// MARK: - Collection Conformance

extension TextLine: RandomAccessCollection {
    public var startIndex: Int {
        positions.startIndex
    }

    public var endIndex: Int {
        positions.endIndex
    }

    public subscript(index: Int) -> TextPosition {
        positions[index]
    }
}
