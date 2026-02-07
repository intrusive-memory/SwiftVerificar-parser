import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFOperator Tests")
struct PDFOperatorTests {

    // MARK: - Graphics State Operators

    @Test("Save and restore state operators")
    func saveRestoreState() {
        let save = PDFOperator.saveState
        let restore = PDFOperator.restoreState

        #expect(save.operatorName == "q")
        #expect(restore.operatorName == "Q")
        #expect(!save.isTextOperator)
        #expect(!restore.isTextOperator)
    }

    @Test("Concatenate matrix operator")
    func concatMatrix() {
        let op = PDFOperator.concatMatrix(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 10.0, f: 20.0)
        #expect(op.operatorName == "cm")
        #expect(!op.isTextOperator)
        #expect(!op.isPathOperator)
    }

    @Test("Line width operator")
    func lineWidth() {
        let op = PDFOperator.setLineWidth(2.5)
        #expect(op.operatorName == "w")
        #expect(!op.isTextOperator)
    }

    @Test("Line cap operator")
    func lineCap() {
        let butt = PDFOperator.setLineCap(0)
        let round = PDFOperator.setLineCap(1)
        let square = PDFOperator.setLineCap(2)

        #expect(butt.operatorName == "J")
        #expect(round.operatorName == "J")
        #expect(square.operatorName == "J")
    }

    @Test("Line join operator")
    func lineJoin() {
        let miter = PDFOperator.setLineJoin(0)
        let round = PDFOperator.setLineJoin(1)
        let bevel = PDFOperator.setLineJoin(2)

        #expect(miter.operatorName == "j")
        #expect(round.operatorName == "j")
        #expect(bevel.operatorName == "j")
    }

    @Test("Miter limit operator")
    func miterLimit() {
        let op = PDFOperator.setMiterLimit(10.0)
        #expect(op.operatorName == "M")
    }

    @Test("Dash pattern operator")
    func dashPattern() {
        let solid = PDFOperator.setDash(pattern: [], phase: 0.0)
        let dashed = PDFOperator.setDash(pattern: [3.0, 1.0], phase: 0.0)
        let offset = PDFOperator.setDash(pattern: [3.0, 1.0], phase: 2.0)

        #expect(solid.operatorName == "d")
        #expect(dashed.operatorName == "d")
        #expect(offset.operatorName == "d")
    }

    @Test("Rendering intent operator")
    func renderingIntent() {
        let op = PDFOperator.setRenderingIntent(ASAtom("Perceptual"))
        #expect(op.operatorName == "ri")
    }

    @Test("Flatness operator")
    func flatness() {
        let op = PDFOperator.setFlatness(0.5)
        #expect(op.operatorName == "i")
    }

    @Test("Extended graphics state operator")
    func extGState() {
        let op = PDFOperator.setExtGState(ASAtom("GS1"))
        #expect(op.operatorName == "gs")
    }

    // MARK: - Path Construction Operators

    @Test("Move to operator")
    func moveTo() {
        let op = PDFOperator.moveTo(x: 100.0, y: 200.0)
        #expect(op.operatorName == "m")
        #expect(op.isPathOperator)
        #expect(!op.isTextOperator)
    }

    @Test("Line to operator")
    func lineTo() {
        let op = PDFOperator.lineTo(x: 150.0, y: 250.0)
        #expect(op.operatorName == "l")
        #expect(op.isPathOperator)
    }

    @Test("Curve to operator")
    func curveTo() {
        let op = PDFOperator.curveTo(x1: 10.0, y1: 20.0, x2: 30.0, y2: 40.0, x3: 50.0, y3: 60.0)
        #expect(op.operatorName == "c")
        #expect(op.isPathOperator)
    }

    @Test("Curve to V operator")
    func curveToV() {
        let op = PDFOperator.curveToV(x2: 30.0, y2: 40.0, x3: 50.0, y3: 60.0)
        #expect(op.operatorName == "v")
        #expect(op.isPathOperator)
    }

    @Test("Curve to Y operator")
    func curveToY() {
        let op = PDFOperator.curveToY(x1: 10.0, y1: 20.0, x3: 50.0, y3: 60.0)
        #expect(op.operatorName == "y")
        #expect(op.isPathOperator)
    }

    @Test("Close path operator")
    func closePath() {
        let op = PDFOperator.closePath
        #expect(op.operatorName == "h")
        #expect(op.isPathOperator)
    }

    @Test("Rectangle operator")
    func rectangle() {
        let op = PDFOperator.rectangle(x: 10.0, y: 20.0, width: 100.0, height: 50.0)
        #expect(op.operatorName == "re")
        #expect(op.isPathOperator)
    }

    // MARK: - Path Painting Operators

    @Test("Stroke operator")
    func stroke() {
        let op = PDFOperator.stroke
        #expect(op.operatorName == "S")
        #expect(op.isPaintingOperator)
        #expect(!op.isTextOperator)
    }

    @Test("Close and stroke operator")
    func closeAndStroke() {
        let op = PDFOperator.closeAndStroke
        #expect(op.operatorName == "s")
        #expect(op.isPaintingOperator)
    }

    @Test("Fill operator")
    func fill() {
        let op = PDFOperator.fill
        #expect(op.operatorName == "f")
        #expect(op.isPaintingOperator)
    }

    @Test("Fill even-odd operator")
    func fillEvenOdd() {
        let op = PDFOperator.fillEvenOdd
        #expect(op.operatorName == "f*")
        #expect(op.isPaintingOperator)
    }

    @Test("Fill and stroke operator")
    func fillAndStroke() {
        let op = PDFOperator.fillAndStroke
        #expect(op.operatorName == "B")
        #expect(op.isPaintingOperator)
    }

    @Test("Fill and stroke even-odd operator")
    func fillAndStrokeEvenOdd() {
        let op = PDFOperator.fillAndStrokeEvenOdd
        #expect(op.operatorName == "B*")
        #expect(op.isPaintingOperator)
    }

    @Test("Close, fill and stroke operator")
    func closeFillAndStroke() {
        let op = PDFOperator.closeFillAndStroke
        #expect(op.operatorName == "b")
        #expect(op.isPaintingOperator)
    }

    @Test("Close, fill and stroke even-odd operator")
    func closeFillAndStrokeEvenOdd() {
        let op = PDFOperator.closeFillAndStrokeEvenOdd
        #expect(op.operatorName == "b*")
        #expect(op.isPaintingOperator)
    }

    @Test("End path operator")
    func endPath() {
        let op = PDFOperator.endPath
        #expect(op.operatorName == "n")
        #expect(op.isPaintingOperator)
    }

    // MARK: - Clipping Operators

    @Test("Clip operator")
    func clip() {
        let op = PDFOperator.clip
        #expect(op.operatorName == "W")
    }

    @Test("Clip even-odd operator")
    func clipEvenOdd() {
        let op = PDFOperator.clipEvenOdd
        #expect(op.operatorName == "W*")
    }

    // MARK: - Text Object Operators

    @Test("Begin text operator")
    func beginText() {
        let op = PDFOperator.beginText
        #expect(op.operatorName == "BT")
        #expect(op.isTextOperator)
    }

    @Test("End text operator")
    func endText() {
        let op = PDFOperator.endText
        #expect(op.operatorName == "ET")
        #expect(op.isTextOperator)
    }

    // MARK: - Text State Operators

    @Test("Character spacing operator")
    func characterSpacing() {
        let op = PDFOperator.setCharacterSpacing(0.5)
        #expect(op.operatorName == "Tc")
        #expect(op.isTextOperator)
    }

    @Test("Word spacing operator")
    func wordSpacing() {
        let op = PDFOperator.setWordSpacing(1.0)
        #expect(op.operatorName == "Tw")
        #expect(op.isTextOperator)
    }

    @Test("Horizontal scaling operator")
    func horizontalScaling() {
        let op = PDFOperator.setHorizontalScaling(120.0)
        #expect(op.operatorName == "Tz")
        #expect(op.isTextOperator)
    }

    @Test("Text leading operator")
    func textLeading() {
        let op = PDFOperator.setTextLeading(14.0)
        #expect(op.operatorName == "TL")
        #expect(op.isTextOperator)
    }

    @Test("Font operator")
    func font() {
        let op = PDFOperator.setFont(name: ASAtom("F1"), size: 12.0)
        #expect(op.operatorName == "Tf")
        #expect(op.isTextOperator)
    }

    @Test("Text rendering mode operator")
    func textRenderingMode() {
        let fill = PDFOperator.setTextRenderingMode(0)
        let stroke = PDFOperator.setTextRenderingMode(1)
        let fillStroke = PDFOperator.setTextRenderingMode(2)
        let invisible = PDFOperator.setTextRenderingMode(3)

        #expect(fill.operatorName == "Tr")
        #expect(stroke.operatorName == "Tr")
        #expect(fillStroke.operatorName == "Tr")
        #expect(invisible.operatorName == "Tr")
        #expect(fill.isTextOperator)
    }

    @Test("Text rise operator")
    func textRise() {
        let op = PDFOperator.setTextRise(5.0)
        #expect(op.operatorName == "Ts")
        #expect(op.isTextOperator)
    }

    // MARK: - Text Positioning Operators

    @Test("Move text operator")
    func moveText() {
        let op = PDFOperator.moveText(tx: 10.0, ty: 20.0)
        #expect(op.operatorName == "Td")
        #expect(op.isTextOperator)
    }

    @Test("Move text and set leading operator")
    func moveTextSetLeading() {
        let op = PDFOperator.moveTextSetLeading(tx: 0.0, ty: -14.0)
        #expect(op.operatorName == "TD")
        #expect(op.isTextOperator)
    }

    @Test("Set text matrix operator")
    func setTextMatrix() {
        let op = PDFOperator.setTextMatrix(a: 1.0, b: 0.0, c: 0.0, d: 1.0, e: 100.0, f: 700.0)
        #expect(op.operatorName == "Tm")
        #expect(op.isTextOperator)
    }

    @Test("Move to next line operator")
    func moveToNextLine() {
        let op = PDFOperator.moveToNextLine
        #expect(op.operatorName == "T*")
        #expect(op.isTextOperator)
    }

    // MARK: - Text Showing Operators

    @Test("Show text operator")
    func showText() {
        let text = "Hello, World!".data(using: .utf8)!
        let op = PDFOperator.showText(text)
        #expect(op.operatorName == "Tj")
        #expect(op.isTextOperator)
    }

    @Test("Show text array operator")
    func showTextArray() {
        let elements: [TextArrayElement] = [
            .text("Hello".data(using: .utf8)!),
            .adjustment(-100.0),
            .text("World".data(using: .utf8)!),
        ]
        let op = PDFOperator.showTextArray(elements)
        #expect(op.operatorName == "TJ")
        #expect(op.isTextOperator)
    }

    @Test("Move to next line and show text operator")
    func moveToNextLineAndShowText() {
        let text = "Next line".data(using: .utf8)!
        let op = PDFOperator.moveToNextLineAndShowText(text)
        #expect(op.operatorName == "'")
        #expect(op.isTextOperator)
    }

    @Test("Set spacing, move to next line and show text operator")
    func setSpacingMoveToNextLineAndShowText() {
        let text = "Spaced text".data(using: .utf8)!
        let op = PDFOperator.setSpacingMoveToNextLineAndShowText(wordSpacing: 1.0, charSpacing: 0.5, text: text)
        #expect(op.operatorName == "\"")
        #expect(op.isTextOperator)
    }

    // MARK: - Color Operators

    @Test("Stroke color space operator")
    func strokeColorSpace() {
        let op = PDFOperator.setStrokeColorSpace(ASAtom("DeviceRGB"))
        #expect(op.operatorName == "CS")
        #expect(op.isColorOperator)
    }

    @Test("Fill color space operator")
    func fillColorSpace() {
        let op = PDFOperator.setFillColorSpace(ASAtom("DeviceCMYK"))
        #expect(op.operatorName == "cs")
        #expect(op.isColorOperator)
    }

    @Test("Stroke color operator")
    func strokeColor() {
        let op = PDFOperator.setStrokeColor([1.0, 0.0, 0.0])
        #expect(op.operatorName == "SC")
        #expect(op.isColorOperator)
    }

    @Test("Stroke color with pattern operator")
    func strokeColorN() {
        let withPattern = PDFOperator.setStrokeColorN([1.0, 0.0], pattern: ASAtom("P1"))
        let withoutPattern = PDFOperator.setStrokeColorN([1.0, 0.0, 0.0], pattern: nil)

        #expect(withPattern.operatorName == "SCN")
        #expect(withoutPattern.operatorName == "SCN")
        #expect(withPattern.isColorOperator)
    }

    @Test("Fill color operator")
    func fillColor() {
        let op = PDFOperator.setFillColor([0.0, 1.0, 0.0])
        #expect(op.operatorName == "sc")
        #expect(op.isColorOperator)
    }

    @Test("Fill color with pattern operator")
    func fillColorN() {
        let op = PDFOperator.setFillColorN([0.5], pattern: ASAtom("P2"))
        #expect(op.operatorName == "scn")
        #expect(op.isColorOperator)
    }

    @Test("Stroke gray operator")
    func strokeGray() {
        let black = PDFOperator.setStrokeGray(0.0)
        let gray = PDFOperator.setStrokeGray(0.5)
        let white = PDFOperator.setStrokeGray(1.0)

        #expect(black.operatorName == "G")
        #expect(gray.operatorName == "G")
        #expect(white.operatorName == "G")
        #expect(black.isColorOperator)
    }

    @Test("Fill gray operator")
    func fillGray() {
        let op = PDFOperator.setFillGray(0.75)
        #expect(op.operatorName == "g")
        #expect(op.isColorOperator)
    }

    @Test("Stroke RGB operator")
    func strokeRGB() {
        let red = PDFOperator.setStrokeRGB(r: 1.0, g: 0.0, b: 0.0)
        let green = PDFOperator.setStrokeRGB(r: 0.0, g: 1.0, b: 0.0)
        let blue = PDFOperator.setStrokeRGB(r: 0.0, g: 0.0, b: 1.0)

        #expect(red.operatorName == "RG")
        #expect(green.operatorName == "RG")
        #expect(blue.operatorName == "RG")
        #expect(red.isColorOperator)
    }

    @Test("Fill RGB operator")
    func fillRGB() {
        let op = PDFOperator.setFillRGB(r: 0.5, g: 0.5, b: 0.5)
        #expect(op.operatorName == "rg")
        #expect(op.isColorOperator)
    }

    @Test("Stroke CMYK operator")
    func strokeCMYK() {
        let op = PDFOperator.setStrokeCMYK(c: 1.0, m: 0.0, y: 0.0, k: 0.0)
        #expect(op.operatorName == "K")
        #expect(op.isColorOperator)
    }

    @Test("Fill CMYK operator")
    func fillCMYK() {
        let op = PDFOperator.setFillCMYK(c: 0.0, m: 1.0, y: 1.0, k: 0.0)
        #expect(op.operatorName == "k")
        #expect(op.isColorOperator)
    }

    // MARK: - Shading Operator

    @Test("Shading operator")
    func shading() {
        let op = PDFOperator.shading(ASAtom("Sh1"))
        #expect(op.operatorName == "sh")
    }

    // MARK: - Inline Image Operators

    @Test("Inline image operators")
    func inlineImage() {
        let begin = PDFOperator.beginInlineImage
        let end = PDFOperator.endInlineImage

        #expect(begin.operatorName == "BI")
        #expect(end.operatorName == "EI")
    }

    @Test("Inline image data operator")
    func inlineImageData() {
        let dict: [ASAtom: COSValue] = [
            ASAtom("W"): .integer(10),
            ASAtom("H"): .integer(10)
        ]
        let data = Data([0xFF, 0x00, 0xFF])
        let op = PDFOperator.inlineImageData(dictionary: dict, data: data)
        #expect(op.operatorName == "ID")
    }

    // MARK: - XObject Operator

    @Test("Invoke XObject operator")
    func invokeXObject() {
        let op = PDFOperator.invokeXObject(ASAtom("Im1"))
        #expect(op.operatorName == "Do")
    }

    // MARK: - Marked Content Operators

    @Test("Marked content point operator")
    func markedContentPoint() {
        let op = PDFOperator.markedContentPoint(ASAtom("Artifact"))
        #expect(op.operatorName == "MP")
    }

    @Test("Marked content point with properties operator")
    func markedContentPointWithProperties() {
        let props = COSValue.dictionary([ASAtom("Type"): .name(ASAtom("Layout"))])
        let op = PDFOperator.markedContentPointWithProperties(tag: ASAtom("Artifact"), properties: props)
        #expect(op.operatorName == "DP")
    }

    @Test("Begin marked content operator")
    func beginMarkedContent() {
        let op = PDFOperator.beginMarkedContent(ASAtom("Span"))
        #expect(op.operatorName == "BMC")
    }

    @Test("Begin marked content with properties operator")
    func beginMarkedContentWithProperties() {
        let props = COSValue.name(ASAtom("P1"))
        let op = PDFOperator.beginMarkedContentWithProperties(tag: ASAtom("Span"), properties: props)
        #expect(op.operatorName == "BDC")
    }

    @Test("End marked content operator")
    func endMarkedContent() {
        let op = PDFOperator.endMarkedContent
        #expect(op.operatorName == "EMC")
    }

    // MARK: - Compatibility Operators

    @Test("Compatibility operators")
    func compatibility() {
        let begin = PDFOperator.beginCompatibility
        let end = PDFOperator.endCompatibility

        #expect(begin.operatorName == "BX")
        #expect(end.operatorName == "EX")
    }

    // MARK: - Unknown Operator

    @Test("Unknown operator")
    func unknownOperator() {
        let op = PDFOperator.unknown(operator: "CustomOp", operands: [.integer(42)])
        #expect(op.operatorName == "CustomOp")
        #expect(!op.isTextOperator)
        #expect(!op.isPathOperator)
        #expect(!op.isPaintingOperator)
        #expect(!op.isColorOperator)
    }

    // MARK: - Text Array Element

    @Test("Text array element - text")
    func textArrayElementText() {
        let text = "Hello".data(using: .utf8)!
        let element = TextArrayElement.text(text)

        if case .text(let data) = element {
            #expect(data == text)
        } else {
            Issue.record("Expected text element")
        }
    }

    @Test("Text array element - adjustment")
    func textArrayElementAdjustment() {
        let element = TextArrayElement.adjustment(-100.0)

        if case .adjustment(let value) = element {
            #expect(value == -100.0)
        } else {
            Issue.record("Expected adjustment element")
        }
    }

    @Test("Text array element equality")
    func textArrayElementEquality() {
        let text1 = TextArrayElement.text("Test".data(using: .utf8)!)
        let text2 = TextArrayElement.text("Test".data(using: .utf8)!)
        let text3 = TextArrayElement.text("Other".data(using: .utf8)!)
        let adj1 = TextArrayElement.adjustment(-50.0)
        let adj2 = TextArrayElement.adjustment(-50.0)
        let adj3 = TextArrayElement.adjustment(100.0)

        #expect(text1 == text2)
        #expect(text1 != text3)
        #expect(adj1 == adj2)
        #expect(adj1 != adj3)
        #expect(text1 != adj1)
    }

    // MARK: - Operator Categories

    @Test("Operator category - text operators")
    func textOperatorCategories() {
        let textOps: [PDFOperator] = [
            .beginText, .endText, .setCharacterSpacing(0.5), .setFont(name: ASAtom("F1"), size: 12),
            .showText(Data()), .moveToNextLine
        ]

        for op in textOps {
            #expect(op.isTextOperator, "Expected \(op.operatorName) to be a text operator")
        }

        let nonTextOps: [PDFOperator] = [
            .saveState, .moveTo(x: 0, y: 0), .stroke, .setStrokeGray(0.5)
        ]

        for op in nonTextOps {
            #expect(!op.isTextOperator, "Expected \(op.operatorName) to NOT be a text operator")
        }
    }

    @Test("Operator category - path operators")
    func pathOperatorCategories() {
        let pathOps: [PDFOperator] = [
            .moveTo(x: 0, y: 0), .lineTo(x: 10, y: 10), .curveTo(x1: 0, y1: 0, x2: 5, y2: 5, x3: 10, y3: 10),
            .closePath, .rectangle(x: 0, y: 0, width: 100, height: 100)
        ]

        for op in pathOps {
            #expect(op.isPathOperator, "Expected \(op.operatorName) to be a path operator")
        }
    }

    @Test("Operator category - painting operators")
    func paintingOperatorCategories() {
        let paintingOps: [PDFOperator] = [
            .stroke, .fill, .fillEvenOdd, .fillAndStroke, .endPath
        ]

        for op in paintingOps {
            #expect(op.isPaintingOperator, "Expected \(op.operatorName) to be a painting operator")
        }
    }

    @Test("Operator category - color operators")
    func colorOperatorCategories() {
        let colorOps: [PDFOperator] = [
            .setStrokeGray(0.5), .setFillRGB(r: 1, g: 0, b: 0), .setStrokeCMYK(c: 0, m: 1, y: 1, k: 0),
            .setStrokeColorSpace(ASAtom("DeviceRGB"))
        ]

        for op in colorOps {
            #expect(op.isColorOperator, "Expected \(op.operatorName) to be a color operator")
        }
    }

    // MARK: - Equality Tests

    @Test("Operator equality")
    func operatorEquality() {
        let op1 = PDFOperator.setLineWidth(2.0)
        let op2 = PDFOperator.setLineWidth(2.0)
        let op3 = PDFOperator.setLineWidth(3.0)

        #expect(op1 == op2)
        #expect(op1 != op3)

        let text1 = PDFOperator.showText("Hello".data(using: .utf8)!)
        let text2 = PDFOperator.showText("Hello".data(using: .utf8)!)
        let text3 = PDFOperator.showText("World".data(using: .utf8)!)

        #expect(text1 == text2)
        #expect(text1 != text3)
    }
}
