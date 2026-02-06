import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

@Suite("TextPosition Tests")
struct TextPositionTests {

    // MARK: - Initialization Tests

    @Test("Creates text position with basic properties")
    func testBasicInitialization() {
        let pos = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos.character == "A")
        #expect(pos.unicode == "A")
        #expect(pos.x == 100.0)
        #expect(pos.y == 700.0)
        #expect(pos.width == 12.0)
        #expect(pos.height == 14.0)
        #expect(pos.fontSize == 12.0)
        #expect(pos.font == nil)
        #expect(pos.horizontalScaling == 100.0)
        #expect(pos.characterSpacing == 0.0)
        #expect(pos.wordSpacing == 0.0)
        #expect(pos.rise == 0.0)
        #expect(pos.textMatrix == .identity)
        #expect(pos.renderingMode == 0)
    }

    @Test("Creates text position with full properties")
    func testFullInitialization() {
        let font = ASAtom("F1")
        let matrix = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 10, ty: 20)

        let pos = TextPosition(
            character: "B",
            unicode: "B",
            x: 50.0,
            y: 600.0,
            width: 10.0,
            height: 12.0,
            fontSize: 10.0,
            font: font,
            horizontalScaling: 120.0,
            characterSpacing: 0.5,
            wordSpacing: 2.0,
            rise: 3.0,
            textMatrix: matrix,
            renderingMode: 2
        )

        #expect(pos.character == "B")
        #expect(pos.unicode == "B")
        #expect(pos.font == font)
        #expect(pos.horizontalScaling == 120.0)
        #expect(pos.characterSpacing == 0.5)
        #expect(pos.wordSpacing == 2.0)
        #expect(pos.rise == 3.0)
        #expect(pos.textMatrix == matrix)
        #expect(pos.renderingMode == 2)
    }

    // MARK: - Bounding Box Tests

    @Test("Computes bounding box correctly")
    func testBoundingBox() {
        let pos = TextPosition(
            character: "X",
            unicode: "X",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let box = pos.boundingBox
        #expect(box.origin.x == 100.0)
        #expect(box.origin.y == 700.0 - 14.0) // y - height
        #expect(box.size.width == 12.0)
        #expect(box.size.height == 14.0)
    }

    // MARK: - Character Type Tests

    @Test("Identifies regular space")
    func testIsSpace() {
        let space = TextPosition(
            character: " ",
            unicode: " ",
            x: 0, y: 0, width: 5, height: 12, fontSize: 12
        )
        #expect(space.isSpace)
    }

    @Test("Identifies non-breaking space")
    func testIsNonBreakingSpace() {
        let nbsp = TextPosition(
            character: "\u{00A0}",
            unicode: "\u{00A0}",
            x: 0, y: 0, width: 5, height: 12, fontSize: 12
        )
        #expect(nbsp.isSpace)
    }

    @Test("Non-space character returns false for isSpace")
    func testNonSpace() {
        let char = TextPosition(
            character: "A",
            unicode: "A",
            x: 0, y: 0, width: 10, height: 12, fontSize: 12
        )
        #expect(!char.isSpace)
    }

    @Test("Identifies whitespace characters")
    func testIsWhitespace() {
        let space = TextPosition(
            character: " ",
            unicode: " ",
            x: 0, y: 0, width: 5, height: 12, fontSize: 12
        )
        #expect(space.isWhitespace)

        let newline = TextPosition(
            character: "\n",
            unicode: "\n",
            x: 0, y: 0, width: 0, height: 12, fontSize: 12
        )
        #expect(newline.isWhitespace)

        let tab = TextPosition(
            character: "\t",
            unicode: "\t",
            x: 0, y: 0, width: 10, height: 12, fontSize: 12
        )
        #expect(tab.isWhitespace)
    }

    @Test("Non-whitespace returns false")
    func testNonWhitespace() {
        let char = TextPosition(
            character: "A",
            unicode: "A",
            x: 0, y: 0, width: 10, height: 12, fontSize: 12
        )
        #expect(!char.isWhitespace)
    }

    // MARK: - Distance Tests

    @Test("Computes horizontal distance correctly")
    func testHorizontalDistance() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 115.0, // 100 + 12 + 3 (gap of 3)
            y: 700.0,
            width: 10.0,
            height: 14.0,
            fontSize: 12.0
        )

        let distance = pos1.horizontalDistance(to: pos2)
        #expect(distance == 3.0)
    }

    @Test("Horizontal distance is negative if positions overlap")
    func testNegativeHorizontalDistance() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 110.0, // Overlaps with pos1
            y: 700.0,
            width: 10.0,
            height: 14.0,
            fontSize: 12.0
        )

        let distance = pos1.horizontalDistance(to: pos2)
        #expect(distance == -2.0) // 110 - (100 + 12)
    }

    @Test("Computes vertical distance correctly")
    func testVerticalDistance() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 100.0,
            y: 680.0, // 20 points below
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let distance = pos1.verticalDistance(to: pos2)
        #expect(distance == 20.0)
    }

    // MARK: - Same Line Tests

    @Test("Identifies positions on same line")
    func testIsOnSameLine() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 120.0,
            y: 701.0, // Slight variation (within threshold)
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos1.isOnSameLine(as: pos2))
    }

    @Test("Identifies positions on different lines")
    func testIsNotOnSameLine() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 100.0,
            y: 680.0, // 20 points below (more than threshold)
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(!pos1.isOnSameLine(as: pos2))
    }

    // MARK: - Merge Tests

    @Test("Should merge adjacent positions on same line")
    func testShouldMerge() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 113.0, // Close to pos1 (within threshold)
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos1.shouldMerge(with: pos2))
    }

    @Test("Should not merge distant positions")
    func testShouldNotMergeDistant() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 200.0, // Far from pos1
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(!pos1.shouldMerge(with: pos2))
    }

    @Test("Should not merge positions on different lines")
    func testShouldNotMergeDifferentLines() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 113.0,
            y: 680.0, // Different line
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(!pos1.shouldMerge(with: pos2))
    }

    // MARK: - Equatable Tests

    @Test("Identical positions are equal")
    func testEquality() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos1 == pos2)
    }

    @Test("Different positions are not equal")
    func testInequality() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos1 != pos2)
    }

    // MARK: - Comparable Tests

    @Test("Sorts positions by reading order - left to right")
    func testSortingLeftToRight() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 120.0,
            y: 700.0, // Same line
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos1 < pos2)
        #expect(!(pos2 < pos1))
    }

    @Test("Sorts positions by reading order - top to bottom")
    func testSortingTopToBottom() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0, // Higher y (top)
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 100.0,
            y: 680.0, // Lower y (bottom)
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        #expect(pos1 < pos2) // pos1 is higher (comes first)
    }

    @Test("Sorts array of positions correctly")
    func testArraySorting() {
        let positions = [
            TextPosition(character: "C", unicode: "C", x: 130, y: 700, width: 10, height: 12, fontSize: 12),
            TextPosition(character: "A", unicode: "A", x: 100, y: 700, width: 10, height: 12, fontSize: 12),
            TextPosition(character: "B", unicode: "B", x: 115, y: 700, width: 10, height: 12, fontSize: 12),
        ]

        let sorted = positions.sorted()
        #expect(sorted[0].character == "A")
        #expect(sorted[1].character == "B")
        #expect(sorted[2].character == "C")
    }

    // MARK: - Hashable Tests

    @Test("Positions can be used in Set")
    func testHashable() {
        let pos1 = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let pos2 = TextPosition(
            character: "B",
            unicode: "B",
            x: 120.0,
            y: 700.0,
            width: 12.0,
            height: 14.0,
            fontSize: 12.0
        )

        let set: Set = [pos1, pos2]
        #expect(set.count == 2)
        #expect(set.contains(pos1))
        #expect(set.contains(pos2))
    }

    // MARK: - CustomStringConvertible Tests

    @Test("Produces readable description")
    func testDescription() {
        let pos = TextPosition(
            character: "A",
            unicode: "A",
            x: 100.5,
            y: 700.25,
            width: 12.75,
            height: 14.0,
            fontSize: 12.0
        )

        let description = pos.description
        #expect(description.contains("TextPosition"))
        #expect(description.contains("A"))
        #expect(description.contains("100.5"))
        #expect(description.contains("700.2")) // Rounded
    }
}
