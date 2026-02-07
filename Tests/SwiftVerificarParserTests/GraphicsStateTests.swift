import Testing
import Foundation
import CoreGraphics
@testable import SwiftVerificarParser

@Suite("GraphicsState Tests")
struct GraphicsStateTests {

    // MARK: - Initialization

    @Test("Default initialization")
    func defaultInitialization() {
        let state = GraphicsState()

        // Coordinate transformation
        #expect(state.ctm == .identity)

        // Line attributes
        #expect(state.lineWidth == 1.0)
        #expect(state.lineCap == 0)
        #expect(state.lineJoin == 0)
        #expect(state.miterLimit == 10.0)
        #expect(state.dashPattern.isEmpty)
        #expect(state.dashPhase == 0.0)

        // Color
        #expect(state.strokeColorSpace == ASAtom("DeviceGray"))
        #expect(state.fillColorSpace == ASAtom("DeviceGray"))
        #expect(state.strokeColor == [0.0])
        #expect(state.fillColor == [0.0])
        #expect(state.strokePattern == nil)
        #expect(state.fillPattern == nil)

        // Rendering
        #expect(state.flatness == 1.0)
        #expect(state.renderingIntent == ASAtom("RelativeColorimetric"))

        // Extended graphics state
        #expect(state.extGStateName == nil)
    }

    // MARK: - Line Attributes

    @Test("Line width modification")
    func lineWidth() {
        var state = GraphicsState()
        #expect(state.lineWidth == 1.0)

        state.lineWidth = 2.5
        #expect(state.lineWidth == 2.5)

        state.lineWidth = 0.1
        #expect(state.lineWidth == 0.1)
    }

    @Test("Line cap modification")
    func lineCap() {
        var state = GraphicsState()
        #expect(state.lineCap == 0) // Default: butt cap

        state.lineCap = 1 // Round cap
        #expect(state.lineCap == 1)

        state.lineCap = 2 // Projecting square cap
        #expect(state.lineCap == 2)
    }

    @Test("Line join modification")
    func lineJoin() {
        var state = GraphicsState()
        #expect(state.lineJoin == 0) // Default: miter join

        state.lineJoin = 1 // Round join
        #expect(state.lineJoin == 1)

        state.lineJoin = 2 // Bevel join
        #expect(state.lineJoin == 2)
    }

    @Test("Miter limit modification")
    func miterLimit() {
        var state = GraphicsState()
        #expect(state.miterLimit == 10.0)

        state.miterLimit = 5.0
        #expect(state.miterLimit == 5.0)
    }

    @Test("Dash pattern modification")
    func dashPattern() {
        var state = GraphicsState()
        #expect(state.dashPattern.isEmpty)
        #expect(state.dashPhase == 0.0)

        // Set dashed line
        state.dashPattern = [3.0, 1.0]
        state.dashPhase = 0.0
        #expect(state.dashPattern == [3.0, 1.0])
        #expect(state.dashPhase == 0.0)

        // Set dash with offset
        state.dashPattern = [5.0, 2.0, 1.0, 2.0]
        state.dashPhase = 2.0
        #expect(state.dashPattern == [5.0, 2.0, 1.0, 2.0])
        #expect(state.dashPhase == 2.0)

        // Back to solid
        state.dashPattern = []
        #expect(state.dashPattern.isEmpty)
    }

    // MARK: - Coordinate Transformation

    @Test("CTM modification")
    func ctmModification() {
        var state = GraphicsState()
        #expect(state.ctm == .identity)

        // Apply translation
        state.ctm = CGAffineTransform(translationX: 10, y: 20)
        #expect(state.ctm.tx == 10)
        #expect(state.ctm.ty == 20)

        // Apply scaling
        state.ctm = CGAffineTransform(scaleX: 2.0, y: 2.0)
        #expect(state.ctm.a == 2.0)
        #expect(state.ctm.d == 2.0)
    }

    @Test("Concatenate matrix")
    func concatMatrix() {
        var state = GraphicsState()

        // Concatenate translation
        let translation = CGAffineTransform(translationX: 10, y: 20)
        state.concatMatrix(translation)
        #expect(state.ctm.tx == 10)
        #expect(state.ctm.ty == 20)

        // Concatenate another translation
        let translation2 = CGAffineTransform(translationX: 5, y: 10)
        state.concatMatrix(translation2)
        #expect(state.ctm.tx == 15)
        #expect(state.ctm.ty == 30)
    }

    @Test("Multiple matrix concatenations")
    func multipleMatrixConcatenations() {
        var state = GraphicsState()

        // Start with translation
        state.concatMatrix(CGAffineTransform(translationX: 100, y: 200))

        // Add scaling
        state.concatMatrix(CGAffineTransform(scaleX: 2.0, y: 2.0))

        // Add rotation
        state.concatMatrix(CGAffineTransform(rotationAngle: .pi / 4))

        // Verify CTM is not identity
        #expect(state.ctm != .identity)
    }

    // MARK: - Color State

    @Test("Stroke grayscale color")
    func strokeGray() {
        var state = GraphicsState()

        state.setStrokeGray(0.5)
        #expect(state.strokeColorSpace == ASAtom("DeviceGray"))
        #expect(state.strokeColor == [0.5])
        #expect(state.strokePattern == nil)

        state.setStrokeGray(1.0) // White
        #expect(state.strokeColor == [1.0])
    }

    @Test("Fill grayscale color")
    func fillGray() {
        var state = GraphicsState()

        state.setFillGray(0.75)
        #expect(state.fillColorSpace == ASAtom("DeviceGray"))
        #expect(state.fillColor == [0.75])
        #expect(state.fillPattern == nil)
    }

    @Test("Stroke RGB color")
    func strokeRGB() {
        var state = GraphicsState()

        state.setStrokeRGB(r: 1.0, g: 0.0, b: 0.0) // Red
        #expect(state.strokeColorSpace == ASAtom("DeviceRGB"))
        #expect(state.strokeColor == [1.0, 0.0, 0.0])
        #expect(state.strokePattern == nil)

        state.setStrokeRGB(r: 0.5, g: 0.5, b: 0.5) // Gray
        #expect(state.strokeColor == [0.5, 0.5, 0.5])
    }

    @Test("Fill RGB color")
    func fillRGB() {
        var state = GraphicsState()

        state.setFillRGB(r: 0.0, g: 1.0, b: 0.0) // Green
        #expect(state.fillColorSpace == ASAtom("DeviceRGB"))
        #expect(state.fillColor == [0.0, 1.0, 0.0])
        #expect(state.fillPattern == nil)
    }

    @Test("Stroke CMYK color")
    func strokeCMYK() {
        var state = GraphicsState()

        state.setStrokeCMYK(c: 1.0, m: 0.0, y: 0.0, k: 0.0) // Cyan
        #expect(state.strokeColorSpace == ASAtom("DeviceCMYK"))
        #expect(state.strokeColor == [1.0, 0.0, 0.0, 0.0])
        #expect(state.strokePattern == nil)

        state.setStrokeCMYK(c: 0.0, m: 1.0, y: 1.0, k: 0.0) // Red in CMYK
        #expect(state.strokeColor == [0.0, 1.0, 1.0, 0.0])
    }

    @Test("Fill CMYK color")
    func fillCMYK() {
        var state = GraphicsState()

        state.setFillCMYK(c: 0.0, m: 0.0, y: 1.0, k: 0.0) // Yellow
        #expect(state.fillColorSpace == ASAtom("DeviceCMYK"))
        #expect(state.fillColor == [0.0, 0.0, 1.0, 0.0])
        #expect(state.fillPattern == nil)
    }

    @Test("Color space changes clear patterns")
    func colorSpaceChangesClearPatterns() {
        var state = GraphicsState()

        // Set a pattern
        state.strokePattern = ASAtom("P1")
        #expect(state.strokePattern != nil)

        // Change color space should clear pattern
        state.setStrokeGray(0.5)
        #expect(state.strokePattern == nil)

        // Same for fill
        state.fillPattern = ASAtom("P2")
        state.setFillRGB(r: 1.0, g: 0.0, b: 0.0)
        #expect(state.fillPattern == nil)
    }

    @Test("Direct color component modification")
    func directColorComponentModification() {
        var state = GraphicsState()

        // Set custom color components
        state.strokeColorSpace = ASAtom("DeviceRGB")
        state.strokeColor = [0.2, 0.4, 0.6]
        #expect(state.strokeColor.count == 3)
        #expect(state.strokeColor[0] == 0.2)
        #expect(state.strokeColor[1] == 0.4)
        #expect(state.strokeColor[2] == 0.6)
    }

    @Test("Pattern with color components")
    func patternWithComponents() {
        var state = GraphicsState()

        // Set pattern with color components
        state.strokeColorSpace = ASAtom("Pattern")
        state.strokeColor = [0.5]
        state.strokePattern = ASAtom("MyPattern")

        #expect(state.strokeColorSpace == ASAtom("Pattern"))
        #expect(state.strokeColor == [0.5])
        #expect(state.strokePattern == ASAtom("MyPattern"))
    }

    // MARK: - Rendering Parameters

    @Test("Flatness tolerance")
    func flatness() {
        var state = GraphicsState()
        #expect(state.flatness == 1.0)

        state.flatness = 0.5
        #expect(state.flatness == 0.5)

        state.flatness = 10.0
        #expect(state.flatness == 10.0)
    }

    @Test("Rendering intent")
    func renderingIntent() {
        var state = GraphicsState()
        #expect(state.renderingIntent == ASAtom("RelativeColorimetric"))

        state.renderingIntent = ASAtom("Perceptual")
        #expect(state.renderingIntent == ASAtom("Perceptual"))

        state.renderingIntent = ASAtom("Saturation")
        #expect(state.renderingIntent == ASAtom("Saturation"))

        state.renderingIntent = ASAtom("AbsoluteColorimetric")
        #expect(state.renderingIntent == ASAtom("AbsoluteColorimetric"))
    }

    // MARK: - Extended Graphics State

    @Test("Extended graphics state name")
    func extGStateName() {
        var state = GraphicsState()
        #expect(state.extGStateName == nil)

        state.extGStateName = ASAtom("GS1")
        #expect(state.extGStateName == ASAtom("GS1"))

        state.extGStateName = nil
        #expect(state.extGStateName == nil)
    }

    // MARK: - Text State

    @Test("Text state embedded in graphics state")
    func textStateEmbedded() {
        var state = GraphicsState()

        // Default text state
        #expect(state.textState.characterSpacing == 0.0)
        #expect(state.textState.fontSize == 0.0)

        // Modify text state
        state.textState.font = ASAtom("F1")
        state.textState.fontSize = 12.0
        state.textState.characterSpacing = 0.5

        #expect(state.textState.font == ASAtom("F1"))
        #expect(state.textState.fontSize == 12.0)
        #expect(state.textState.characterSpacing == 0.5)
    }

    // MARK: - Copy Semantics

    @Test("Graphics state is value type")
    func valueTypeSemantics() {
        var state1 = GraphicsState()
        state1.lineWidth = 2.0
        state1.setStrokeGray(0.5)

        var state2 = state1 // Copy
        state2.lineWidth = 3.0
        state2.setStrokeGray(0.75)

        // Original should be unchanged
        #expect(state1.lineWidth == 2.0)
        #expect(state1.strokeColor == [0.5])

        // Copy should be modified
        #expect(state2.lineWidth == 3.0)
        #expect(state2.strokeColor == [0.75])
    }

    @Test("Graphics state save/restore simulation")
    func saveRestoreSimulation() {
        var state = GraphicsState()

        // Set some values
        state.lineWidth = 2.0
        state.setStrokeRGB(r: 1.0, g: 0.0, b: 0.0)
        state.concatMatrix(CGAffineTransform(translationX: 10, y: 20))

        // Save state (copy)
        let saved = state

        // Modify current state
        state.lineWidth = 5.0
        state.setStrokeGray(0.0)
        state.concatMatrix(CGAffineTransform(scaleX: 2.0, y: 2.0))

        // Restore (assign back)
        state = saved

        // Verify restoration
        #expect(state.lineWidth == 2.0)
        #expect(state.strokeColorSpace == ASAtom("DeviceRGB"))
        #expect(state.strokeColor == [1.0, 0.0, 0.0])
        #expect(state.ctm.tx == 10)
        #expect(state.ctm.ty == 20)
    }

    // MARK: - Equality

    @Test("Graphics state equality")
    func equality() {
        var state1 = GraphicsState()
        var state2 = GraphicsState()

        // Initially equal
        #expect(state1 == state2)

        // Modify one
        state1.lineWidth = 2.0
        #expect(state1 != state2)

        // Make them equal again
        state2.lineWidth = 2.0
        #expect(state1 == state2)

        // Modify color
        state1.setStrokeGray(0.5)
        #expect(state1 != state2)
        state2.setStrokeGray(0.5)
        #expect(state1 == state2)
    }

    @Test("Graphics state equality with CTM")
    func equalityWithCTM() {
        var state1 = GraphicsState()
        var state2 = GraphicsState()

        state1.concatMatrix(CGAffineTransform(translationX: 10, y: 20))
        #expect(state1 != state2)

        state2.concatMatrix(CGAffineTransform(translationX: 10, y: 20))
        #expect(state1 == state2)
    }

    // MARK: - Complex State Changes

    @Test("Complex graphics state modifications")
    func complexStateModifications() {
        var state = GraphicsState()

        // Apply multiple transformations
        state.concatMatrix(CGAffineTransform(translationX: 100, y: 200))
        state.concatMatrix(CGAffineTransform(scaleX: 2.0, y: 2.0))
        state.concatMatrix(CGAffineTransform(rotationAngle: .pi / 4))

        // Set line properties
        state.lineWidth = 3.0
        state.lineCap = 1
        state.lineJoin = 1
        state.miterLimit = 5.0
        state.dashPattern = [5.0, 2.0]
        state.dashPhase = 1.0

        // Set colors
        state.setStrokeRGB(r: 1.0, g: 0.0, b: 0.0)
        state.setFillRGB(r: 0.0, g: 1.0, b: 0.0)

        // Set rendering parameters
        state.flatness = 0.5
        state.renderingIntent = ASAtom("Perceptual")

        // Set extended graphics state
        state.extGStateName = ASAtom("GS1")

        // Set text state
        state.textState.font = ASAtom("F1")
        state.textState.fontSize = 14.0

        // Verify all modifications
        #expect(state.ctm != .identity)
        #expect(state.lineWidth == 3.0)
        #expect(state.lineCap == 1)
        #expect(state.lineJoin == 1)
        #expect(state.strokeColor == [1.0, 0.0, 0.0])
        #expect(state.fillColor == [0.0, 1.0, 0.0])
        #expect(state.extGStateName == ASAtom("GS1"))
        #expect(state.textState.fontSize == 14.0)
    }

    @Test("Graphics state stack simulation")
    func graphicsStateStack() {
        var stack: [GraphicsState] = []
        var current = GraphicsState()

        // Save initial state
        stack.append(current)

        // Modify
        current.lineWidth = 2.0
        current.setStrokeGray(0.5)

        // Save again
        stack.append(current)

        // Modify
        current.lineWidth = 4.0
        current.setStrokeGray(0.0)

        #expect(current.lineWidth == 4.0)
        #expect(current.strokeColor == [0.0])

        // Restore once
        current = stack.removeLast()
        #expect(current.lineWidth == 2.0)
        #expect(current.strokeColor == [0.5])

        // Restore again
        current = stack.removeLast()
        #expect(current.lineWidth == 1.0)
        #expect(current.strokeColor == [0.0])

        #expect(stack.isEmpty)
    }
}
