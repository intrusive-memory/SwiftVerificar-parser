import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

@Suite("TextState Tests")
struct TextStateTests {

    // MARK: - Initialization

    @Test("Default initialization")
    func defaultInitialization() {
        let state = TextState()

        // Text state parameters
        #expect(state.characterSpacing == 0.0)
        #expect(state.wordSpacing == 0.0)
        #expect(state.horizontalScaling == 100.0)
        #expect(state.leading == 0.0)
        #expect(state.font == nil)
        #expect(state.fontSize == 0.0)
        #expect(state.renderingMode == 0)
        #expect(state.rise == 0.0)

        // Text positioning
        #expect(state.textMatrix == .identity)
        #expect(state.textLineMatrix == .identity)

        // Validation
        #expect(!state.isValid) // No font set
    }

    // MARK: - Text State Parameters

    @Test("Character spacing")
    func characterSpacing() {
        var state = TextState()
        #expect(state.characterSpacing == 0.0)

        state.characterSpacing = 0.5
        #expect(state.characterSpacing == 0.5)

        state.characterSpacing = -0.2
        #expect(state.characterSpacing == -0.2)
    }

    @Test("Word spacing")
    func wordSpacing() {
        var state = TextState()
        #expect(state.wordSpacing == 0.0)

        state.wordSpacing = 1.0
        #expect(state.wordSpacing == 1.0)

        state.wordSpacing = -0.5
        #expect(state.wordSpacing == -0.5)
    }

    @Test("Horizontal scaling")
    func horizontalScaling() {
        var state = TextState()
        #expect(state.horizontalScaling == 100.0)

        state.horizontalScaling = 120.0 // 120%
        #expect(state.horizontalScaling == 120.0)

        state.horizontalScaling = 50.0 // 50%
        #expect(state.horizontalScaling == 50.0)

        state.horizontalScaling = 200.0 // 200%
        #expect(state.horizontalScaling == 200.0)
    }

    @Test("Leading")
    func leading() {
        var state = TextState()
        #expect(state.leading == 0.0)

        state.leading = 14.0
        #expect(state.leading == 14.0)

        state.leading = -14.0 // Negative for downward movement
        #expect(state.leading == -14.0)
    }

    @Test("Font and size")
    func fontAndSize() {
        var state = TextState()
        #expect(state.font == nil)
        #expect(state.fontSize == 0.0)
        #expect(!state.isValid)

        state.font = ASAtom("F1")
        state.fontSize = 12.0
        #expect(state.font == ASAtom("F1"))
        #expect(state.fontSize == 12.0)
        #expect(state.isValid) // Now valid

        state.font = ASAtom("Helvetica")
        state.fontSize = 24.0
        #expect(state.font == ASAtom("Helvetica"))
        #expect(state.fontSize == 24.0)
    }

    @Test("Rendering mode")
    func renderingMode() {
        var state = TextState()
        #expect(state.renderingMode == 0) // Default: fill

        state.renderingMode = 1 // Stroke
        #expect(state.renderingMode == 1)

        state.renderingMode = 2 // Fill then stroke
        #expect(state.renderingMode == 2)

        state.renderingMode = 3 // Invisible
        #expect(state.renderingMode == 3)

        state.renderingMode = 4 // Fill and clip
        #expect(state.renderingMode == 4)

        state.renderingMode = 7 // Add to clip
        #expect(state.renderingMode == 7)
    }

    @Test("Text rise")
    func textRise() {
        var state = TextState()
        #expect(state.rise == 0.0)

        state.rise = 5.0 // Superscript
        #expect(state.rise == 5.0)

        state.rise = -3.0 // Subscript
        #expect(state.rise == -3.0)
    }

    // MARK: - Text Positioning

    @Test("Move text")
    func moveText() {
        var state = TextState()
        #expect(state.textMatrix == .identity)
        #expect(state.textLineMatrix == .identity)

        state.moveText(tx: 10.0, ty: 20.0)

        #expect(state.textMatrix.tx == 10.0)
        #expect(state.textMatrix.ty == 20.0)
        #expect(state.textLineMatrix.tx == 10.0)
        #expect(state.textLineMatrix.ty == 20.0)
    }

    @Test("Multiple move text operations")
    func multipleMoveText() {
        var state = TextState()

        state.moveText(tx: 10.0, ty: 20.0)
        #expect(state.textMatrix.tx == 10.0)
        #expect(state.textMatrix.ty == 20.0)

        state.moveText(tx: 5.0, ty: 10.0)
        #expect(state.textMatrix.tx == 15.0)
        #expect(state.textMatrix.ty == 30.0)
    }

    @Test("Move text and set leading")
    func moveTextSetLeading() {
        var state = TextState()
        #expect(state.leading == 0.0)

        state.moveTextSetLeading(tx: 0.0, ty: -14.0)

        #expect(state.leading == 14.0) // Leading is -ty
        #expect(state.textMatrix.tx == 0.0)
        #expect(state.textMatrix.ty == -14.0)
        #expect(state.textLineMatrix == state.textMatrix)
    }

    @Test("Set text matrix")
    func setTextMatrix() {
        var state = TextState()

        let matrix = CGAffineTransform(a: 1.0, b: 0.0, c: 0.0, d: 1.0, tx: 100.0, ty: 700.0)
        state.setTextMatrix(matrix)

        #expect(state.textMatrix == matrix)
        #expect(state.textLineMatrix == matrix)
    }

    @Test("Move to next line")
    func moveToNextLine() {
        var state = TextState()
        state.leading = 14.0
        state.setTextMatrix(CGAffineTransform(translationX: 100, y: 700))

        state.moveToNextLine()

        #expect(state.textMatrix.tx == 100.0)
        #expect(state.textMatrix.ty == 686.0) // 700 - 14
    }

    @Test("Move to next line with zero leading")
    func moveToNextLineZeroLeading() {
        var state = TextState()
        state.leading = 0.0
        state.setTextMatrix(CGAffineTransform(translationX: 100, y: 700))

        state.moveToNextLine()

        #expect(state.textMatrix.tx == 100.0)
        #expect(state.textMatrix.ty == 700.0) // No change
    }

    @Test("Text positioning sequence")
    func textPositioningSequence() {
        var state = TextState()

        // Set initial matrix
        state.setTextMatrix(CGAffineTransform(translationX: 100, y: 700))
        #expect(state.textMatrix.tx == 100.0)
        #expect(state.textMatrix.ty == 700.0)

        // Set leading and move down
        state.leading = 14.0
        state.moveToNextLine()
        #expect(state.textMatrix.ty == 686.0)

        // Move again
        state.moveToNextLine()
        #expect(state.textMatrix.ty == 672.0)

        // Adjust position
        state.moveText(tx: 10.0, ty: 0.0)
        #expect(state.textMatrix.tx == 110.0)
        #expect(state.textMatrix.ty == 672.0)
    }

    // MARK: - Validation

    @Test("Text state validation - no font")
    func validationNoFont() {
        var state = TextState()
        #expect(!state.isValid)

        state.fontSize = 12.0
        #expect(!state.isValid) // Still invalid, no font

        state.font = ASAtom("F1")
        #expect(state.isValid) // Now valid
    }

    @Test("Text state validation - zero font size")
    func validationZeroFontSize() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = 0.0
        #expect(!state.isValid) // Invalid, zero size

        state.fontSize = 12.0
        #expect(state.isValid) // Valid
    }

    @Test("Text state validation - negative font size")
    func validationNegativeFontSize() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = -12.0
        #expect(!state.isValid) // Invalid, negative size
    }

    // MARK: - Copy Semantics

    @Test("Text state is value type")
    func valueTypeSemantics() {
        var state1 = TextState()
        state1.font = ASAtom("F1")
        state1.fontSize = 12.0
        state1.characterSpacing = 0.5

        var state2 = state1 // Copy
        state2.font = ASAtom("F2")
        state2.fontSize = 14.0
        state2.characterSpacing = 1.0

        // Original should be unchanged
        #expect(state1.font == ASAtom("F1"))
        #expect(state1.fontSize == 12.0)
        #expect(state1.characterSpacing == 0.5)

        // Copy should be modified
        #expect(state2.font == ASAtom("F2"))
        #expect(state2.fontSize == 14.0)
        #expect(state2.characterSpacing == 1.0)
    }

    @Test("Text state reset on begin text")
    func resetOnBeginText() {
        var state = TextState()

        // Set some values
        state.font = ASAtom("F1")
        state.fontSize = 12.0
        state.characterSpacing = 1.0
        state.setTextMatrix(CGAffineTransform(translationX: 100, y: 700))

        // Simulate BT (begin text) - reset positioning
        state.textMatrix = .identity
        state.textLineMatrix = .identity

        // Font and spacing should remain
        #expect(state.font == ASAtom("F1"))
        #expect(state.fontSize == 12.0)
        #expect(state.characterSpacing == 1.0)

        // But matrices should be reset
        #expect(state.textMatrix == .identity)
        #expect(state.textLineMatrix == .identity)
    }

    // MARK: - Equality

    @Test("Text state equality")
    func equality() {
        var state1 = TextState()
        var state2 = TextState()

        // Initially equal
        #expect(state1 == state2)

        // Modify one
        state1.font = ASAtom("F1")
        state1.fontSize = 12.0
        #expect(state1 != state2)

        // Make them equal again
        state2.font = ASAtom("F1")
        state2.fontSize = 12.0
        #expect(state1 == state2)

        // Modify spacing
        state1.characterSpacing = 0.5
        #expect(state1 != state2)
        state2.characterSpacing = 0.5
        #expect(state1 == state2)
    }

    @Test("Text state equality with matrices")
    func equalityWithMatrices() {
        var state1 = TextState()
        var state2 = TextState()

        state1.setTextMatrix(CGAffineTransform(translationX: 100, y: 700))
        #expect(state1 != state2)

        state2.setTextMatrix(CGAffineTransform(translationX: 100, y: 700))
        #expect(state1 == state2)
    }

    // MARK: - Complex Text Operations

    @Test("Complex text state modifications")
    func complexTextStateModifications() {
        var state = TextState()

        // Set font
        state.font = ASAtom("Helvetica")
        state.fontSize = 14.0

        // Set spacing
        state.characterSpacing = 0.5
        state.wordSpacing = 1.0
        state.horizontalScaling = 110.0

        // Set positioning
        state.leading = 16.0
        state.setTextMatrix(CGAffineTransform(translationX: 50, y: 750))

        // Set rendering mode and rise
        state.renderingMode = 0 // Fill
        state.rise = 0.0

        // Verify all modifications
        #expect(state.font == ASAtom("Helvetica"))
        #expect(state.fontSize == 14.0)
        #expect(state.characterSpacing == 0.5)
        #expect(state.wordSpacing == 1.0)
        #expect(state.horizontalScaling == 110.0)
        #expect(state.leading == 16.0)
        #expect(state.textMatrix.tx == 50)
        #expect(state.textMatrix.ty == 750)
        #expect(state.renderingMode == 0)
        #expect(state.rise == 0.0)
        #expect(state.isValid)
    }

    @Test("Text state for superscript")
    func superscript() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = 12.0
        state.rise = 5.0 // Raise text

        #expect(state.rise > 0)
        #expect(state.isValid)
    }

    @Test("Text state for subscript")
    func subscriptText() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = 12.0
        state.rise = -3.0 // Lower text

        #expect(state.rise < 0)
        #expect(state.isValid)
    }

    @Test("Text state with rotated matrix")
    func rotatedTextMatrix() {
        var state = TextState()

        let rotated = CGAffineTransform(rotationAngle: .pi / 4)
            .translatedBy(x: 100, y: 700)
        state.setTextMatrix(rotated)

        #expect(state.textMatrix != .identity)
        #expect(state.textLineMatrix == state.textMatrix)
    }

    @Test("Text state with scaled matrix")
    func scaledTextMatrix() {
        var state = TextState()

        let scaled = CGAffineTransform(scaleX: 2.0, y: 2.0)
            .translatedBy(x: 100, y: 700)
        state.setTextMatrix(scaled)

        #expect(state.textMatrix != .identity)
        #expect(state.textLineMatrix == state.textMatrix)
    }

    @Test("Text rendering modes")
    func allRenderingModes() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = 12.0

        let modes = [0, 1, 2, 3, 4, 5, 6, 7]
        for mode in modes {
            state.renderingMode = mode
            #expect(state.renderingMode == mode)
            #expect(state.isValid)
        }
    }

    @Test("Text state line breaking simulation")
    func lineBreakingSimulation() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = 12.0
        state.leading = 14.0

        // Start at origin
        state.setTextMatrix(CGAffineTransform(translationX: 50, y: 750))
        #expect(state.textMatrix.ty == 750)

        // Move to next line (line 2)
        state.moveToNextLine()
        #expect(state.textMatrix.ty == 736) // 750 - 14

        // Move to next line (line 3)
        state.moveToNextLine()
        #expect(state.textMatrix.ty == 722) // 736 - 14

        // Move to next line (line 4)
        state.moveToNextLine()
        #expect(state.textMatrix.ty == 708) // 722 - 14
    }

    @Test("Text state with adjusted leading")
    func adjustedLeading() {
        var state = TextState()
        state.font = ASAtom("F1")
        state.fontSize = 12.0

        // Set position
        state.setTextMatrix(CGAffineTransform(translationX: 50, y: 750))

        // Use TD operator to move and set leading
        state.moveTextSetLeading(tx: 0.0, ty: -18.0)

        #expect(state.leading == 18.0)
        #expect(state.textMatrix.ty == 732.0) // 750 - 18
    }
}
