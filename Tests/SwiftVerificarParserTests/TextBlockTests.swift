import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

@Suite("TextBlock Tests")
struct TextBlockTests {

    // MARK: - Helper Functions

    private func makePosition(char: String, x: Double, y: Double) -> TextPosition {
        TextPosition(
            character: char,
            unicode: char,
            x: x,
            y: y,
            width: 10.0,
            height: 12.0,
            fontSize: 12.0
        )
    }

    private func makeLine(text: String, x: Double, y: Double) -> TextLine {
        var positions: [TextPosition] = []
        for (i, char) in text.enumerated() {
            positions.append(makePosition(char: String(char), x: x + Double(i * 10), y: y))
        }
        return TextLine(positions: positions)
    }

    // MARK: - Initialization Tests

    @Test("Creates empty text block")
    func testEmptyInitialization() {
        let block = TextBlock()
        #expect(block.isEmpty)
        #expect(block.count == 0)
        #expect(block.text == "")
        #expect(block.lines.isEmpty)
    }

    @Test("Creates text block with lines")
    func testInitializationWithLines() {
        let lines = [
            makeLine(text: "Hello", x: 100, y: 700),
            makeLine(text: "World", x: 100, y: 685)
        ]

        let block = TextBlock(lines: lines)
        #expect(!block.isEmpty)
        #expect(block.count == 2)
        #expect(block.text == "Hello\nWorld")
    }

    @Test("Sorts lines during initialization")
    func testInitializationSortsLines() {
        let lines = [
            makeLine(text: "Second", x: 100, y: 680), // Lower line
            makeLine(text: "First", x: 100, y: 700)   // Higher line
        ]

        let block = TextBlock(lines: lines)
        #expect(block.text == "First\nSecond")
    }

    // MARK: - Text Extraction Tests

    @Test("Extracts text from lines with newlines")
    func testTextExtraction() {
        let lines = [
            makeLine(text: "Line1", x: 100, y: 700),
            makeLine(text: "Line2", x: 100, y: 685),
            makeLine(text: "Line3", x: 100, y: 670)
        ]

        let block = TextBlock(lines: lines)
        #expect(block.text == "Line1\nLine2\nLine3")
    }

    @Test("Handles empty block text extraction")
    func testEmptyBlockText() {
        let block = TextBlock()
        #expect(block.text == "")
    }

    @Test("Handles single line block")
    func testSingleLineText() {
        let block = TextBlock(lines: [
            makeLine(text: "Single", x: 100, y: 700)
        ])
        #expect(block.text == "Single")
    }

    // MARK: - Bounding Box Tests

    @Test("Computes bounding box for single line")
    func testBoundingBoxSingleLine() {
        let line = makeLine(text: "ABC", x: 100, y: 700)
        let block = TextBlock(lines: [line])

        let box = block.boundingBox
        #expect(box.minX == 100.0)
        #expect(box.maxX == 130.0) // 100 + 30 (3 chars * 10)
        #expect(box.width == 30.0)
    }

    @Test("Computes bounding box for multiple lines")
    func testBoundingBoxMultipleLines() {
        let lines = [
            makeLine(text: "AB", x: 100, y: 700),
            makeLine(text: "CD", x: 105, y: 685) // Slightly offset
        ]

        let block = TextBlock(lines: lines)
        let box = block.boundingBox

        #expect(box.minX == 100.0) // Leftmost
        #expect(box.maxX == 125.0) // Rightmost (105 + 20)
    }

    @Test("Empty block has zero bounding box")
    func testEmptyBlockBoundingBox() {
        let block = TextBlock()
        let box = block.boundingBox
        #expect(box == .zero)
    }

    // MARK: - Font Size Tests

    @Test("Computes average font size across lines")
    func testAverageFontSize() {
        let line1 = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12.0)
        ])

        let line2 = TextLine(positions: [
            TextPosition(character: "B", unicode: "B", x: 100, y: 685, width: 10, height: 16, fontSize: 16.0)
        ])

        let block = TextBlock(lines: [line1, line2])
        #expect(block.averageFontSize == 14.0) // (12 + 16) / 2
    }

    @Test("Empty block has zero average font size")
    func testEmptyBlockAverageFontSize() {
        let block = TextBlock()
        #expect(block.averageFontSize == 0.0)
    }

    // MARK: - Line Height Tests

    @Test("Computes average line height")
    func testAverageLineHeight() {
        let line1 = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12)
        ])

        let line2 = TextLine(positions: [
            TextPosition(character: "B", unicode: "B", x: 100, y: 685, width: 10, height: 12, fontSize: 12)
        ])

        let line3 = TextLine(positions: [
            TextPosition(character: "C", unicode: "C", x: 100, y: 670, width: 10, height: 12, fontSize: 12)
        ])

        let block = TextBlock(lines: [line1, line2, line3])
        #expect(block.averageLineHeight == 15.0) // (15 + 15) / 2
    }

    @Test("Single line block uses height as line height")
    func testSingleLineBlockLineHeight() {
        let line = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 14, fontSize: 12)
        ])

        let block = TextBlock(lines: [line])
        #expect(block.averageLineHeight == 14.0)
    }

    // MARK: - Position and Word Aggregation Tests

    @Test("Aggregates all positions from lines")
    func testAllPositions() {
        let lines = [
            makeLine(text: "AB", x: 100, y: 700),
            makeLine(text: "CD", x: 100, y: 685)
        ]

        let block = TextBlock(lines: lines)
        let positions = block.allPositions

        #expect(positions.count == 4)
        #expect(positions.map { $0.character }.joined() == "ABCD")
    }

    @Test("Aggregates all words from lines")
    func testAllWords() {
        let line1 = TextLine(positions: [
            makePosition(char: "H", x: 100, y: 700),
            makePosition(char: "i", x: 110, y: 700),
            makePosition(char: " ", x: 120, y: 700),
            makePosition(char: "A", x: 130, y: 700)
        ])

        let line2 = TextLine(positions: [
            makePosition(char: "B", x: 100, y: 685),
            makePosition(char: "y", x: 110, y: 685),
            makePosition(char: "e", x: 120, y: 685)
        ])

        let block = TextBlock(lines: [line1, line2])
        let words = block.allWords

        #expect(words.count == 3)
        #expect(words == ["Hi", "A", "Bye"])
    }

    // MARK: - Mutation Tests

    @Test("Appends line to block")
    func testAppendLine() {
        var block = TextBlock()
        block.append(makeLine(text: "Hello", x: 100, y: 700))

        #expect(block.count == 1)
        #expect(block.text == "Hello")
    }

    @Test("Appends multiple lines")
    func testAppendMultipleLines() {
        var block = TextBlock()
        block.append(makeLine(text: "Line1", x: 100, y: 700))
        block.append(makeLine(text: "Line2", x: 100, y: 685))

        #expect(block.count == 2)
        #expect(block.text == "Line1\nLine2")
    }

    @Test("Appends lines in sorted order")
    func testAppendMaintainsSorting() {
        var block = TextBlock()
        block.append(makeLine(text: "Second", x: 100, y: 680))
        block.append(makeLine(text: "First", x: 100, y: 700))

        #expect(block.text == "First\nSecond")
    }

    @Test("Appends array of lines")
    func testAppendContentsOf() {
        var block = TextBlock()
        let lines = [
            makeLine(text: "A", x: 100, y: 700),
            makeLine(text: "B", x: 100, y: 685)
        ]

        block.append(contentsOf: lines)
        #expect(block.count == 2)
        #expect(block.text == "A\nB")
    }

    @Test("Removes all lines")
    func testRemoveAll() {
        var block = TextBlock(lines: [
            makeLine(text: "A", x: 100, y: 700),
            makeLine(text: "B", x: 100, y: 685)
        ])

        block.removeAll()
        #expect(block.isEmpty)
        #expect(block.count == 0)
    }

    // MARK: - Merge Tests

    @Test("Should merge vertically adjacent blocks")
    func testShouldMergeAdjacentBlocks() {
        let block1 = TextBlock(lines: [
            makeLine(text: "First", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Second", x: 100, y: 685) // 15pt below, within 2x line height
        ])

        #expect(block1.shouldMerge(with: block2))
    }

    @Test("Should not merge distant blocks")
    func testShouldNotMergeDistantBlocks() {
        let block1 = TextBlock(lines: [
            makeLine(text: "First", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Second", x: 100, y: 650) // 50pt below, too far
        ])

        #expect(!block1.shouldMerge(with: block2))
    }

    @Test("Should not merge horizontally misaligned blocks")
    func testShouldNotMergeHorizontallyMisaligned() {
        let block1 = TextBlock(lines: [
            makeLine(text: "Left", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Right", x: 300, y: 685) // Far to the right
        ])

        #expect(!block1.shouldMerge(with: block2))
    }

    @Test("Empty blocks should not merge")
    func testEmptyBlocksShouldNotMerge() {
        let block1 = TextBlock()
        let block2 = TextBlock()

        #expect(!block1.shouldMerge(with: block2))
    }

    // MARK: - Distance Tests

    @Test("Computes vertical distance between blocks")
    func testVerticalDistance() {
        let block1 = TextBlock(lines: [
            makeLine(text: "Top", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Bottom", x: 100, y: 650)
        ])

        let distance = block1.verticalDistance(to: block2)
        #expect(distance > 0) // Should have positive distance
    }

    @Test("Vertical distance is zero for overlapping blocks")
    func testVerticalDistanceOverlapping() {
        let block1 = TextBlock(lines: [
            makeLine(text: "A", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "B", x: 120, y: 700) // Same vertical position
        ])

        let distance = block1.verticalDistance(to: block2)
        #expect(distance == 0.0)
    }

    @Test("Computes horizontal distance between blocks")
    func testHorizontalDistance() {
        let block1 = TextBlock(lines: [
            makeLine(text: "Left", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Right", x: 200, y: 700)
        ])

        let distance = block1.horizontalDistance(to: block2)
        #expect(distance > 0)
    }

    @Test("Horizontal distance is zero for overlapping blocks")
    func testHorizontalDistanceOverlapping() {
        let block1 = TextBlock(lines: [
            makeLine(text: "A", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "B", x: 100, y: 680) // Same horizontal position
        ])

        let distance = block1.horizontalDistance(to: block2)
        #expect(distance == 0.0)
    }

    // MARK: - Heuristic Tests

    @Test("Identifies likely heading - single line, large font")
    func testIsLikelyHeading() {
        let line = TextLine(positions: [
            TextPosition(character: "H", unicode: "H", x: 100, y: 700, width: 14, height: 18, fontSize: 18.0)
        ])

        let block = TextBlock(lines: [line])
        #expect(block.isLikelyHeading)
    }

    @Test("Single line with small font is not heading")
    func testIsNotLikelyHeadingSmallFont() {
        let line = makeLine(text: "Text", x: 100, y: 700) // fontSize = 12

        let block = TextBlock(lines: [line])
        #expect(!block.isLikelyHeading)
    }

    @Test("Multiple lines is not heading")
    func testIsNotLikelyHeadingMultipleLines() {
        let lines = [
            TextLine(positions: [
                TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 14, height: 18, fontSize: 18.0)
            ]),
            TextLine(positions: [
                TextPosition(character: "B", unicode: "B", x: 100, y: 685, width: 14, height: 18, fontSize: 18.0)
            ])
        ]

        let block = TextBlock(lines: lines)
        #expect(!block.isLikelyHeading)
    }

    @Test("Identifies likely paragraph - multiple lines, consistent font")
    func testIsLikelyParagraph() {
        let lines = [
            TextLine(positions: [
                TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12.0)
            ]),
            TextLine(positions: [
                TextPosition(character: "B", unicode: "B", x: 100, y: 685, width: 10, height: 12, fontSize: 12.0)
            ]),
            TextLine(positions: [
                TextPosition(character: "C", unicode: "C", x: 100, y: 670, width: 10, height: 12, fontSize: 12.0)
            ])
        ]

        let block = TextBlock(lines: lines)
        #expect(block.isLikelyParagraph)
    }

    @Test("Single line is not paragraph")
    func testIsNotLikelyParagraphSingleLine() {
        let block = TextBlock(lines: [
            makeLine(text: "Text", x: 100, y: 700)
        ])
        #expect(!block.isLikelyParagraph)
    }

    @Test("Inconsistent font sizes is not paragraph")
    func testIsNotLikelyParagraphInconsistentFont() {
        let lines = [
            TextLine(positions: [
                TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12.0)
            ]),
            TextLine(positions: [
                TextPosition(character: "B", unicode: "B", x: 100, y: 685, width: 14, height: 18, fontSize: 18.0)
            ])
        ]

        let block = TextBlock(lines: lines)
        #expect(!block.isLikelyParagraph)
    }

    // MARK: - Equatable Tests

    @Test("Identical blocks are equal")
    func testEquality() {
        let lines = [makeLine(text: "Test", x: 100, y: 700)]
        let block1 = TextBlock(lines: lines)
        let block2 = TextBlock(lines: lines)

        #expect(block1 == block2)
    }

    @Test("Different blocks are not equal")
    func testInequality() {
        let block1 = TextBlock(lines: [makeLine(text: "A", x: 100, y: 700)])
        let block2 = TextBlock(lines: [makeLine(text: "B", x: 100, y: 700)])

        #expect(block1 != block2)
    }

    // MARK: - Comparable Tests

    @Test("Sorts blocks by reading order - top to bottom")
    func testSortingTopToBottom() {
        let block1 = TextBlock(lines: [
            makeLine(text: "Top", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Bottom", x: 100, y: 650)
        ])

        #expect(block1 < block2)
    }

    @Test("Sorts blocks by reading order - left to right at same height")
    func testSortingLeftToRight() {
        let block1 = TextBlock(lines: [
            makeLine(text: "Left", x: 100, y: 700)
        ])

        let block2 = TextBlock(lines: [
            makeLine(text: "Right", x: 200, y: 700)
        ])

        #expect(block1 < block2)
    }

    // MARK: - Collection Tests

    @Test("Conforms to RandomAccessCollection")
    func testCollectionConformance() {
        let lines = [
            makeLine(text: "A", x: 100, y: 700),
            makeLine(text: "B", x: 100, y: 685),
            makeLine(text: "C", x: 100, y: 670)
        ]

        let block = TextBlock(lines: lines)

        #expect(block.count == 3)
        #expect(block[0].text == "A")
        #expect(block[1].text == "B")
        #expect(block[2].text == "C")
    }

    @Test("Supports subscripting")
    func testSubscripting() {
        let block = TextBlock(lines: [
            makeLine(text: "X", x: 100, y: 700),
            makeLine(text: "Y", x: 100, y: 685),
            makeLine(text: "Z", x: 100, y: 670)
        ])

        #expect(block[0].text == "X")
        #expect(block[1].text == "Y")
        #expect(block[2].text == "Z")
    }

    @Test("Supports iteration")
    func testIteration() {
        let block = TextBlock(lines: [
            makeLine(text: "A", x: 100, y: 700),
            makeLine(text: "B", x: 100, y: 685)
        ])

        var texts: [String] = []
        for line in block {
            texts.append(line.text)
        }

        #expect(texts == ["A", "B"])
    }

    // MARK: - CustomStringConvertible Tests

    @Test("Produces readable description")
    func testDescription() {
        let block = TextBlock(lines: [
            makeLine(text: "Hello", x: 100, y: 700),
            makeLine(text: "World", x: 100, y: 685)
        ])

        let description = block.description
        #expect(description.contains("TextBlock"))
        #expect(description.contains("2 lines"))
        #expect(description.contains("Hello"))
    }

    @Test("Truncates long text in description")
    func testDescriptionTruncation() {
        var lines: [TextLine] = []
        for i in 0..<20 {
            lines.append(makeLine(text: "Line\(i)", x: 100, y: 700.0 - Double(i * 15)))
        }

        let block = TextBlock(lines: lines)
        let description = block.description

        #expect(description.contains("..."))
        #expect(description.count < 200) // Reasonably short
    }
}
