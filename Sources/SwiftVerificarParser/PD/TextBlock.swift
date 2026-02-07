import Foundation
import CoreGraphics

/// Represents a block of text composed of multiple lines.
///
/// `TextBlock` groups `TextLine` objects that appear in proximity and likely form
/// a semantic unit, such as a paragraph, column, or text region.
///
/// This is analogous to a text region in Apache PDFBox's text extraction model.
///
/// ## Usage
/// ```swift
/// var block = TextBlock()
/// block.append(line1)
/// block.append(line2)
///
/// let text = block.text
/// let bounds = block.boundingBox
/// let lineCount = block.lines.count
/// ```
///
/// ## Thread Safety
/// `TextBlock` is a value type (struct) and is `Sendable`.
public struct TextBlock: Sendable, Equatable {

    // MARK: - Properties

    /// The lines that make up this block, in reading order.
    public private(set) var lines: [TextLine]

    /// Whether the block is empty.
    public var isEmpty: Bool {
        lines.isEmpty
    }

    /// The number of lines in the block.
    public var count: Int {
        lines.count
    }

    /// The extracted text from this block.
    ///
    /// Lines are joined with newline characters.
    public var text: String {
        lines.map { $0.text }.joined(separator: "\n")
    }

    /// The bounding box that encloses all lines in the block.
    public var boundingBox: CGRect {
        guard !lines.isEmpty else {
            return .zero
        }

        let bounds = lines.map { $0.boundingBox }
        let minX = bounds.map { $0.minX }.min() ?? 0
        let maxX = bounds.map { $0.maxX }.max() ?? 0
        let minY = bounds.map { $0.minY }.min() ?? 0
        let maxY = bounds.map { $0.maxY }.max() ?? 0

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// The average font size across all lines in this block.
    public var averageFontSize: Double {
        guard !lines.isEmpty else {
            return 0.0
        }
        return lines.map { $0.averageFontSize }.reduce(0, +) / Double(lines.count)
    }

    /// The average line height (vertical distance between baselines).
    public var averageLineHeight: Double {
        guard lines.count > 1 else {
            return lines.first?.averageHeight ?? 0.0
        }

        var totalHeight = 0.0
        for i in 0..<lines.count - 1 {
            totalHeight += abs(lines[i].baseline - lines[i + 1].baseline)
        }

        return totalHeight / Double(lines.count - 1)
    }

    /// All positions from all lines, in reading order.
    public var allPositions: [TextPosition] {
        lines.flatMap { $0.positions }
    }

    /// All words from all lines, in reading order.
    public var allWords: [String] {
        lines.flatMap { $0.words }
    }

    // MARK: - Initialization

    /// Creates an empty text block.
    public init() {
        self.lines = []
    }

    /// Creates a text block with the given lines.
    ///
    /// - Parameter lines: An array of text lines
    public init(lines: [TextLine]) {
        self.lines = lines.sorted() // Ensure reading order
    }

    // MARK: - Mutating Methods

    /// Appends a line to the block.
    ///
    /// The line is inserted in reading order (by baseline).
    ///
    /// - Parameter line: The line to append
    public mutating func append(_ line: TextLine) {
        lines.append(line)
        lines.sort() // Maintain reading order
    }

    /// Appends multiple lines to the block.
    ///
    /// - Parameter lines: The lines to append
    public mutating func append(contentsOf newLines: [TextLine]) {
        lines.append(contentsOf: newLines)
        lines.sort() // Maintain reading order
    }

    /// Removes all lines from the block.
    public mutating func removeAll() {
        lines.removeAll()
    }

    // MARK: - Queries

    /// Returns whether this block should be merged with another block.
    ///
    /// Blocks should be merged if they are vertically adjacent (within 2x average line height)
    /// and horizontally aligned (within 20% of average width).
    ///
    /// - Parameter other: Another text block
    /// - Returns: `true` if blocks should be merged
    public func shouldMerge(with other: TextBlock) -> Bool {
        guard !isEmpty && !other.isEmpty else {
            return false
        }

        // Check vertical proximity
        let verticalDistance = self.verticalDistance(to: other)
        let maxLineHeight = Swift.max(averageLineHeight, other.averageLineHeight)
        guard verticalDistance < maxLineHeight * 2.0 else {
            return false
        }

        // Check horizontal alignment
        let thisBox = boundingBox
        let otherBox = other.boundingBox

        let horizontalOverlap = Swift.min(thisBox.maxX, otherBox.maxX) - Swift.max(thisBox.minX, otherBox.minX)
        let avgWidth = (thisBox.width + otherBox.width) / 2.0

        return horizontalOverlap > avgWidth * 0.2 // At least 20% overlap
    }

    /// Returns the vertical distance from this block to another.
    ///
    /// Distance is measured from the bottom of one block to the top of the other.
    ///
    /// - Parameter other: Another text block
    /// - Returns: Vertical distance (positive if blocks are separated)
    public func verticalDistance(to other: TextBlock) -> Double {
        guard !isEmpty && !other.isEmpty else {
            return .infinity
        }

        let thisBottom = boundingBox.minY
        let thisTop = boundingBox.maxY
        let otherBottom = other.boundingBox.minY
        let otherTop = other.boundingBox.maxY

        // If blocks overlap vertically, distance is zero
        if thisBottom <= otherTop && otherBottom <= thisTop {
            return 0.0
        }

        // Otherwise, distance from bottom of one to top of other
        if thisTop < otherBottom {
            return otherBottom - thisTop
        } else {
            return thisBottom - otherTop
        }
    }

    /// Returns the horizontal distance from this block to another.
    ///
    /// Distance is measured from the right edge of one block to the left edge of the other.
    ///
    /// - Parameter other: Another text block
    /// - Returns: Horizontal distance (positive if blocks are separated)
    public func horizontalDistance(to other: TextBlock) -> Double {
        guard !isEmpty && !other.isEmpty else {
            return .infinity
        }

        let thisLeft = boundingBox.minX
        let thisRight = boundingBox.maxX
        let otherLeft = other.boundingBox.minX
        let otherRight = other.boundingBox.maxX

        // If blocks overlap horizontally, distance is zero
        if thisLeft <= otherRight && otherLeft <= thisRight {
            return 0.0
        }

        // Otherwise, distance from right of one to left of other
        if thisRight < otherLeft {
            return otherLeft - thisRight
        } else {
            return thisLeft - otherRight
        }
    }

    /// Returns whether this block represents a likely heading.
    ///
    /// Heuristic: Single line with larger-than-average font size.
    public var isLikelyHeading: Bool {
        guard lines.count == 1 else {
            return false
        }

        // Compare to typical body text (12pt)
        let fontSize = lines.first?.averageFontSize ?? 0
        return fontSize > 14.0
    }

    /// Returns whether this block represents a likely paragraph.
    ///
    /// Heuristic: Multiple lines with consistent font size.
    public var isLikelyParagraph: Bool {
        guard lines.count > 1 else {
            return false
        }

        // Check font size consistency
        let fontSizes = lines.map { $0.averageFontSize }
        let avgSize = fontSizes.reduce(0, +) / Double(fontSizes.count)
        let maxDeviation = fontSizes.map { abs($0 - avgSize) }.max() ?? 0

        return maxDeviation < 2.0 // Within 2pt variation
    }
}

// MARK: - CustomStringConvertible

extension TextBlock: CustomStringConvertible {
    public var description: String {
        let lineCount = lines.count
        let preview = text.prefix(60)
        let truncated = text.count > 60 ? "..." : ""
        return "TextBlock(\(lineCount) lines, \"\(preview)\(truncated)\")"
    }
}

// MARK: - Comparable

extension TextBlock: Comparable {
    /// Compares text blocks for reading order.
    ///
    /// Blocks are ordered by:
    /// 1. Descending top edge (top to bottom)
    /// 2. Ascending left edge (left to right)
    public static func < (lhs: TextBlock, rhs: TextBlock) -> Bool {
        let lhsBox = lhs.boundingBox
        let rhsBox = rhs.boundingBox

        if abs(lhsBox.maxY - rhsBox.maxY) < 1.0 { // Same top (within tolerance)
            return lhsBox.minX < rhsBox.minX
        }
        return lhsBox.maxY > rhsBox.maxY // Higher top comes first (PDF coordinates)
    }
}

// MARK: - Collection Conformance

extension TextBlock: RandomAccessCollection {
    public var startIndex: Int {
        lines.startIndex
    }

    public var endIndex: Int {
        lines.endIndex
    }

    public subscript(index: Int) -> TextLine {
        lines[index]
    }
}
