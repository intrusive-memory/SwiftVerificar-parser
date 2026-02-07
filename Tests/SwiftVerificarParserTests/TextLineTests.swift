import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

@Suite("TextLine Tests")
struct TextLineTests {

    // MARK: - Helper Functions

    private func makePosition(char: String, x: Double, y: Double = 700.0) -> TextPosition {
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

    // MARK: - Initialization Tests

    @Test("Creates empty text line")
    func testEmptyInitialization() {
        let line = TextLine()
        #expect(line.isEmpty)
        #expect(line.count == 0)
        #expect(line.text == "")
        #expect(line.positions.isEmpty)
    }

    @Test("Creates text line with positions")
    func testInitializationWithPositions() {
        let positions = [
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110),
            makePosition(char: "C", x: 120)
        ]

        let line = TextLine(positions: positions)
        #expect(!line.isEmpty)
        #expect(line.count == 3)
        #expect(line.text == "ABC")
    }

    @Test("Sorts positions during initialization")
    func testInitializationSortsPositions() {
        let positions = [
            makePosition(char: "C", x: 120),
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110)
        ]

        let line = TextLine(positions: positions)
        #expect(line.text == "ABC") // Should be sorted
    }

    // MARK: - Text Extraction Tests

    @Test("Extracts text from positions")
    func testTextExtraction() {
        let positions = [
            makePosition(char: "H", x: 100),
            makePosition(char: "e", x: 110),
            makePosition(char: "l", x: 120),
            makePosition(char: "l", x: 130),
            makePosition(char: "o", x: 140)
        ]

        let line = TextLine(positions: positions)
        #expect(line.text == "Hello")
    }

    @Test("Handles empty line text extraction")
    func testEmptyLineText() {
        let line = TextLine()
        #expect(line.text == "")
    }

    // MARK: - Bounding Box Tests

    @Test("Computes bounding box for single position")
    func testBoundingBoxSinglePosition() {
        let position = makePosition(char: "A", x: 100)
        let line = TextLine(positions: [position])

        let box = line.boundingBox
        #expect(box.minX == 100.0)
        #expect(box.maxX == 110.0) // x + width
        #expect(box.minY == 688.0) // y - height (700 - 12)
        #expect(box.maxY == 700.0)
    }

    @Test("Computes bounding box for multiple positions")
    func testBoundingBoxMultiplePositions() {
        let positions = [
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110),
            makePosition(char: "C", x: 120)
        ]

        let line = TextLine(positions: positions)
        let box = line.boundingBox

        #expect(box.minX == 100.0)
        #expect(box.maxX == 130.0) // 120 + 10
        #expect(box.width == 30.0)
        #expect(box.height == 12.0)
    }

    @Test("Empty line has zero bounding box")
    func testEmptyLineBoundingBox() {
        let line = TextLine()
        let box = line.boundingBox
        #expect(box == .zero)
    }

    // MARK: - Font Size Tests

    @Test("Computes average font size")
    func testAverageFontSize() {
        let positions = [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12.0),
            TextPosition(character: "B", unicode: "B", x: 110, y: 700, width: 10, height: 14, fontSize: 14.0),
            TextPosition(character: "C", unicode: "C", x: 120, y: 700, width: 10, height: 16, fontSize: 16.0)
        ]

        let line = TextLine(positions: positions)
        #expect(line.averageFontSize == 14.0) // (12 + 14 + 16) / 3
    }

    @Test("Empty line has zero average font size")
    func testEmptyLineAverageFontSize() {
        let line = TextLine()
        #expect(line.averageFontSize == 0.0)
    }

    // MARK: - Height Tests

    @Test("Computes average height")
    func testAverageHeight() {
        let positions = [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 10.0, fontSize: 12.0),
            TextPosition(character: "B", unicode: "B", x: 110, y: 700, width: 10, height: 12.0, fontSize: 12.0),
            TextPosition(character: "C", unicode: "C", x: 120, y: 700, width: 10, height: 14.0, fontSize: 12.0)
        ]

        let line = TextLine(positions: positions)
        #expect(line.averageHeight == 12.0) // (10 + 12 + 14) / 3
    }

    // MARK: - Baseline Tests

    @Test("Computes baseline from positions")
    func testBaseline() {
        let positions = [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12),
            TextPosition(character: "B", unicode: "B", x: 110, y: 701, width: 10, height: 12, fontSize: 12),
            TextPosition(character: "C", unicode: "C", x: 120, y: 699, width: 10, height: 12, fontSize: 12)
        ]

        let line = TextLine(positions: positions)
        #expect(line.baseline == 700.0) // (700 + 701 + 699) / 3
    }

    // MARK: - Word Segmentation Tests

    @Test("Segments words on spaces")
    func testWordSegmentation() {
        let positions = [
            makePosition(char: "H", x: 100),
            makePosition(char: "e", x: 110),
            makePosition(char: "l", x: 120),
            makePosition(char: "l", x: 130),
            makePosition(char: "o", x: 140),
            makePosition(char: " ", x: 150),
            makePosition(char: "W", x: 160),
            makePosition(char: "o", x: 170),
            makePosition(char: "r", x: 180),
            makePosition(char: "l", x: 190),
            makePosition(char: "d", x: 200)
        ]

        let line = TextLine(positions: positions)
        let words = line.words

        #expect(words.count == 2)
        #expect(words[0] == "Hello")
        #expect(words[1] == "World")
    }

    @Test("Handles multiple spaces")
    func testMultipleSpaces() {
        let positions = [
            makePosition(char: "A", x: 100),
            makePosition(char: " ", x: 110),
            makePosition(char: " ", x: 120),
            makePosition(char: "B", x: 130)
        ]

        let line = TextLine(positions: positions)
        let words = line.words

        #expect(words.count == 2)
        #expect(words[0] == "A")
        #expect(words[1] == "B")
    }

    @Test("Handles leading and trailing spaces")
    func testLeadingTrailingSpaces() {
        let positions = [
            makePosition(char: " ", x: 90),
            makePosition(char: "A", x: 100),
            makePosition(char: " ", x: 110)
        ]

        let line = TextLine(positions: positions)
        let words = line.words

        #expect(words.count == 1)
        #expect(words[0] == "A")
    }

    @Test("Empty line has no words")
    func testEmptyLineWords() {
        let line = TextLine()
        #expect(line.words.isEmpty)
    }

    // MARK: - Mutation Tests

    @Test("Appends position to line")
    func testAppendPosition() {
        var line = TextLine()
        line.append(makePosition(char: "A", x: 100))

        #expect(line.count == 1)
        #expect(line.text == "A")
    }

    @Test("Appends multiple positions")
    func testAppendMultiplePositions() {
        var line = TextLine()
        line.append(makePosition(char: "A", x: 100))
        line.append(makePosition(char: "B", x: 110))
        line.append(makePosition(char: "C", x: 120))

        #expect(line.count == 3)
        #expect(line.text == "ABC")
    }

    @Test("Appends positions in sorted order")
    func testAppendMaintainsSorting() {
        var line = TextLine()
        line.append(makePosition(char: "C", x: 120))
        line.append(makePosition(char: "A", x: 100))
        line.append(makePosition(char: "B", x: 110))

        #expect(line.text == "ABC") // Should be sorted
    }

    @Test("Appends array of positions")
    func testAppendContentsOf() {
        var line = TextLine()
        let positions = [
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110)
        ]

        line.append(contentsOf: positions)
        #expect(line.count == 2)
        #expect(line.text == "AB")
    }

    @Test("Removes all positions")
    func testRemoveAll() {
        var line = TextLine(positions: [
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110)
        ])

        line.removeAll()
        #expect(line.isEmpty)
        #expect(line.count == 0)
    }

    // MARK: - Merge Tests

    @Test("Should merge lines with similar baselines")
    func testShouldMerge() {
        let line1 = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12)
        ])

        let line2 = TextLine(positions: [
            TextPosition(character: "B", unicode: "B", x: 120, y: 701, width: 10, height: 12, fontSize: 12)
        ])

        #expect(line1.shouldMerge(with: line2))
    }

    @Test("Should not merge lines with different baselines")
    func testShouldNotMerge() {
        let line1 = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12)
        ])

        let line2 = TextLine(positions: [
            TextPosition(character: "B", unicode: "B", x: 100, y: 680, width: 10, height: 12, fontSize: 12)
        ])

        #expect(!line1.shouldMerge(with: line2))
    }

    @Test("Empty lines should not merge")
    func testEmptyLinesShouldNotMerge() {
        let line1 = TextLine()
        let line2 = TextLine()

        #expect(!line1.shouldMerge(with: line2))
    }

    // MARK: - Distance Tests

    @Test("Computes horizontal distance between lines")
    func testHorizontalDistance() {
        let line1 = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12)
        ])

        let line2 = TextLine(positions: [
            TextPosition(character: "B", unicode: "B", x: 120, y: 700, width: 10, height: 12, fontSize: 12)
        ])

        let distance = line1.horizontalDistance(to: line2)
        #expect(distance == 10.0) // 120 - (100 + 10)
    }

    @Test("Computes vertical distance between lines")
    func testVerticalDistance() {
        let line1 = TextLine(positions: [
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12)
        ])

        let line2 = TextLine(positions: [
            TextPosition(character: "B", unicode: "B", x: 100, y: 680, width: 10, height: 12, fontSize: 12)
        ])

        let distance = line1.verticalDistance(to: line2)
        #expect(distance == 20.0)
    }

    // MARK: - Equatable Tests

    @Test("Identical lines are equal")
    func testEquality() {
        let positions = [makePosition(char: "A", x: 100)]
        let line1 = TextLine(positions: positions)
        let line2 = TextLine(positions: positions)

        #expect(line1 == line2)
    }

    @Test("Different lines are not equal")
    func testInequality() {
        let line1 = TextLine(positions: [makePosition(char: "A", x: 100)])
        let line2 = TextLine(positions: [makePosition(char: "B", x: 100)])

        #expect(line1 != line2)
    }

    // MARK: - Comparable Tests

    @Test("Sorts lines by reading order - top to bottom")
    func testSortingTopToBottom() {
        let line1 = TextLine(positions: [
            makePosition(char: "A", x: 100, y: 700) // Higher
        ])

        let line2 = TextLine(positions: [
            makePosition(char: "B", x: 100, y: 680) // Lower
        ])

        #expect(line1 < line2)
    }

    @Test("Sorts lines by reading order - left to right on same baseline")
    func testSortingLeftToRight() {
        let line1 = TextLine(positions: [
            makePosition(char: "A", x: 100, y: 700)
        ])

        let line2 = TextLine(positions: [
            makePosition(char: "B", x: 120, y: 700)
        ])

        #expect(line1 < line2)
    }

    // MARK: - Collection Tests

    @Test("Conforms to RandomAccessCollection")
    func testCollectionConformance() {
        let positions = [
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110),
            makePosition(char: "C", x: 120)
        ]

        let line = TextLine(positions: positions)

        #expect(line.count == 3)
        #expect(line[0].character == "A")
        #expect(line[1].character == "B")
        #expect(line[2].character == "C")
    }

    @Test("Supports subscripting")
    func testSubscripting() {
        let line = TextLine(positions: [
            makePosition(char: "X", x: 100),
            makePosition(char: "Y", x: 110),
            makePosition(char: "Z", x: 120)
        ])

        #expect(line[0].character == "X")
        #expect(line[1].character == "Y")
        #expect(line[2].character == "Z")
    }

    @Test("Supports iteration")
    func testIteration() {
        let line = TextLine(positions: [
            makePosition(char: "A", x: 100),
            makePosition(char: "B", x: 110),
            makePosition(char: "C", x: 120)
        ])

        var chars = ""
        for position in line {
            chars.append(position.character)
        }

        #expect(chars == "ABC")
    }

    // MARK: - CustomStringConvertible Tests

    @Test("Produces readable description")
    func testDescription() {
        let line = TextLine(positions: [
            makePosition(char: "H", x: 100),
            makePosition(char: "e", x: 110),
            makePosition(char: "l", x: 120),
            makePosition(char: "l", x: 130),
            makePosition(char: "o", x: 140)
        ])

        let description = line.description
        #expect(description.contains("TextLine"))
        #expect(description.contains("5 positions"))
        #expect(description.contains("Hello"))
    }

    @Test("Truncates long text in description")
    func testDescriptionTruncation() {
        var positions: [TextPosition] = []
        let longText = String(repeating: "A", count: 100)
        for (i, char) in longText.enumerated() {
            positions.append(makePosition(char: String(char), x: Double(i * 10)))
        }

        let line = TextLine(positions: positions)
        let description = line.description

        #expect(description.contains("..."))
        #expect(description.count < longText.count + 50) // Reasonably short
    }
}
