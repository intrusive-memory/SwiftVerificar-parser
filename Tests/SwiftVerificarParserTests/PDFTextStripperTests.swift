import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

@Suite("PDFTextStripper Tests")
struct PDFTextStripperTests {

    // MARK: - Helper Functions

    private func makeSimpleTextStream() -> Data {
        // Simple content stream: BT /F1 12 Tf 100 700 Td (Hello) Tj ET
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("100 700 Td\n".data(using: .ascii)!)
        stream.append("(Hello) Tj\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)
        return stream
    }

    private func makeMultiLineTextStream() -> Data {
        // BT /F1 12 Tf 100 700 Td (Line1) Tj 0 -15 Td (Line2) Tj ET
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("100 700 Td\n".data(using: .ascii)!)
        stream.append("(Line1) Tj\n".data(using: .ascii)!)
        stream.append("0 -15 Td\n".data(using: .ascii)!)
        stream.append("(Line2) Tj\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)
        return stream
    }

    private func makeResources() -> PDFResources {
        // Create empty resources dictionary
        try! PDFResources(cosObject: .dictionary([:]))
    }

    // MARK: - Initialization Tests

    @Test("Creates text stripper with default configuration")
    func testDefaultInitialization() {
        let stripper = PDFTextStripper()

        #expect(!stripper.preserveCharacterSpacing)
        #expect(stripper.extractLines)
        #expect(stripper.extractBlocks)
        #expect(stripper.spaceThreshold == 0.25)
        #expect(stripper.paragraphThreshold == 1.5)
    }

    @Test("Initializes with empty results")
    func testInitialEmptyResults() {
        let stripper = PDFTextStripper()

        #expect(stripper.textPositions.isEmpty)
        #expect(stripper.textLines.isEmpty)
        #expect(stripper.textBlocks.isEmpty)
    }

    // MARK: - Configuration Tests

    @Test("Can configure character spacing preservation")
    func testConfigureCharacterSpacing() {
        var stripper = PDFTextStripper()
        stripper.preserveCharacterSpacing = true

        #expect(stripper.preserveCharacterSpacing)
    }

    @Test("Can disable line extraction")
    func testDisableLineExtraction() {
        var stripper = PDFTextStripper()
        stripper.extractLines = false

        #expect(!stripper.extractLines)
    }

    @Test("Can disable block extraction")
    func testDisableBlockExtraction() {
        var stripper = PDFTextStripper()
        stripper.extractBlocks = false

        #expect(!stripper.extractBlocks)
    }

    @Test("Can configure space threshold")
    func testConfigureSpaceThreshold() {
        var stripper = PDFTextStripper()
        stripper.spaceThreshold = 0.5

        #expect(stripper.spaceThreshold == 0.5)
    }

    @Test("Can configure paragraph threshold")
    func testConfigureParagraphThreshold() {
        var stripper = PDFTextStripper()
        stripper.paragraphThreshold = 2.0

        #expect(stripper.paragraphThreshold == 2.0)
    }

    // MARK: - Basic Text Extraction Tests

    @Test("Extracts simple text from content stream")
    func testSimpleTextExtraction() async throws {
        let stripper = PDFTextStripper()
        let stream = makeSimpleTextStream()
        let resources = makeResources()

        let text = try await stripper.extractText(from: stream, resources: resources)

        #expect(text.contains("H"))
        #expect(text.contains("e"))
        #expect(text.contains("l"))
        #expect(text.contains("o"))
    }

    @Test("Extracts positions from content stream")
    func testPositionExtraction() async throws {
        let stripper = PDFTextStripper()
        let stream = makeSimpleTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(!stripper.textPositions.isEmpty)
        #expect(stripper.textPositions.count == 5) // "Hello" has 5 characters
    }

    @Test("Extracts lines when enabled")
    func testLineExtraction() async throws {
        let stripper = PDFTextStripper()
        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(!stripper.textLines.isEmpty)
    }

    @Test("Extracts blocks when enabled")
    func testBlockExtraction() async throws {
        let stripper = PDFTextStripper()
        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(!stripper.textBlocks.isEmpty)
    }

    // MARK: - State Management Tests

    @Test("Resets state between extractions")
    func testStateReset() async throws {
        let stripper = PDFTextStripper()
        let stream = makeSimpleTextStream()
        let resources = makeResources()

        // First extraction
        _ = try await stripper.extractText(from: stream, resources: resources)
        let firstPositionCount = stripper.textPositions.count

        // Second extraction should reset
        _ = try await stripper.extractText(from: stream, resources: resources)
        let secondPositionCount = stripper.textPositions.count

        #expect(firstPositionCount == secondPositionCount)
    }

    @Test("Handles empty content stream")
    func testEmptyContentStream() async throws {
        let stripper = PDFTextStripper()
        let stream = Data()
        let resources = makeResources()

        let text = try await stripper.extractText(from: stream, resources: resources)

        #expect(text.isEmpty)
        #expect(stripper.textPositions.isEmpty)
        #expect(stripper.textLines.isEmpty)
        #expect(stripper.textBlocks.isEmpty)
    }

    // MARK: - Graphics State Tests

    @Test("Processes save state operator")
    func testSaveState() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("q\n".data(using: .ascii)!) // Save state
        stream.append("Q\n".data(using: .ascii)!) // Restore state

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes restore state operator")
    func testRestoreState() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("q\n".data(using: .ascii)!)
        stream.append("Q\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes concat matrix operator")
    func testConcatMatrix() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("1 0 0 1 10 20 cm\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    // MARK: - Text State Tests

    @Test("Processes character spacing operator")
    func testCharacterSpacing() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("0.5 Tc\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes word spacing operator")
    func testWordSpacing() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("2.0 Tw\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes horizontal scaling operator")
    func testHorizontalScaling() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("120 Tz\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes text leading operator")
    func testTextLeading() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("14 TL\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes font operator")
    func testFontOperator() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes rendering mode operator")
    func testRenderingMode() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("2 Tr\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes text rise operator")
    func testTextRise() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("3 Ts\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    // MARK: - Text Positioning Tests

    @Test("Processes move text operator")
    func testMoveText() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("100 700 Td\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes set text matrix operator")
    func testSetTextMatrix() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("1 0 0 1 100 700 Tm\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Processes move to next line operator")
    func testMoveToNextLine() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("14 TL\n".data(using: .ascii)!)
        stream.append("T*\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    // MARK: - Text Showing Tests

    @Test("Processes show text operator")
    func testShowText() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("(Test) Tj\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textPositions.count == 4) // "Test" has 4 chars
    }

    @Test("Processes show text array operator")
    func testShowTextArray() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("[(A) -100 (B)] TJ\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textPositions.count == 2) // "AB"
    }

    @Test("Processes move and show text operator")
    func testMoveAndShowText() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("14 TL\n".data(using: .ascii)!)
        stream.append("(Line1) '\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textPositions.count == 5) // "Line1"
    }

    @Test("Processes set spacing and show text operator")
    func testSetSpacingAndShowText() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("/F1 12 Tf\n".data(using: .ascii)!)
        stream.append("14 TL\n".data(using: .ascii)!)
        stream.append("2 0.5 (Text) \"\n".data(using: .ascii)!)
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textPositions.count == 4) // "Text"
    }

    // MARK: - Hierarchy Building Tests

    @Test("Builds lines from positions")
    func testLineBuilding() async throws {
        let stripper = PDFTextStripper()
        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should have built lines
        #expect(!stripper.textLines.isEmpty)
    }

    @Test("Does not build lines when disabled")
    func testNoBuildLinesWhenDisabled() async throws {
        var stripper = PDFTextStripper()
        stripper.extractLines = false

        let stream = makeSimpleTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textLines.isEmpty)
    }

    @Test("Builds blocks from lines")
    func testBlockBuilding() async throws {
        let stripper = PDFTextStripper()
        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should have built blocks
        #expect(!stripper.textBlocks.isEmpty)
    }

    @Test("Does not build blocks when disabled")
    func testNoBuildBlocksWhenDisabled() async throws {
        var stripper = PDFTextStripper()
        stripper.extractBlocks = false

        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textBlocks.isEmpty)
    }

    @Test("Requires lines for block building")
    func testBlocksRequireLines() async throws {
        var stripper = PDFTextStripper()
        stripper.extractLines = false
        stripper.extractBlocks = true

        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textBlocks.isEmpty) // No blocks without lines
    }

    // MARK: - Output Format Tests

    @Test("Returns text from blocks when enabled")
    func testOutputFromBlocks() async throws {
        let stripper = PDFTextStripper()
        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        let text = try await stripper.extractText(from: stream, resources: resources)

        // Blocks join with double newlines
        #expect(!text.isEmpty)
    }

    @Test("Returns text from lines when blocks disabled")
    func testOutputFromLines() async throws {
        var stripper = PDFTextStripper()
        stripper.extractBlocks = false

        let stream = makeMultiLineTextStream()
        let resources = makeResources()

        let text = try await stripper.extractText(from: stream, resources: resources)

        // Lines join with single newlines
        #expect(!text.isEmpty)
    }

    @Test("Returns text from positions when lines and blocks disabled")
    func testOutputFromPositions() async throws {
        var stripper = PDFTextStripper()
        stripper.extractLines = false
        stripper.extractBlocks = false

        let stream = makeSimpleTextStream()
        let resources = makeResources()

        let text = try await stripper.extractText(from: stream, resources: resources)

        // Raw character concatenation
        #expect(!text.isEmpty)
    }

    // MARK: - Edge Cases

    @Test("Handles text without font set")
    func testTextWithoutFont() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT\n".data(using: .ascii)!)
        stream.append("(NoFont) Tj\n".data(using: .ascii)!) // No Tf operator
        stream.append("ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should skip text without font
        #expect(stripper.textPositions.isEmpty)
    }

    @Test("Handles multiple text objects")
    func testMultipleTextObjects() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("BT /F1 12 Tf (A) Tj ET\n".data(using: .ascii)!)
        stream.append("BT /F1 12 Tf (B) Tj ET\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        #expect(stripper.textPositions.count == 2) // "AB"
    }

    @Test("Handles nested graphics state")
    func testNestedGraphicsState() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("q\n".data(using: .ascii)!)
        stream.append("q\n".data(using: .ascii)!)
        stream.append("Q\n".data(using: .ascii)!)
        stream.append("Q\n".data(using: .ascii)!)

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should not throw
    }

    @Test("Handles restore without save")
    func testRestoreWithoutSave() async throws {
        let stripper = PDFTextStripper()
        var stream = Data()
        stream.append("Q\n".data(using: .ascii)!) // Restore without save

        let resources = makeResources()
        _ = try await stripper.extractText(from: stream, resources: resources)

        // Should handle gracefully (no crash)
    }
}
