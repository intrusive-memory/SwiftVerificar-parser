import Foundation
import CoreGraphics

/// Extracts text from PDF content streams with positioning information.
///
/// `PDFTextStripper` processes PDF content streams and builds a hierarchy of
/// text extraction objects:
/// - `TextPosition`: Individual glyphs
/// - `TextLine`: Lines of text
/// - `TextBlock`: Blocks/paragraphs of text
///
/// This is analogous to Apache PDFBox's `PDFTextStripper` class.
///
/// ## Usage
/// ```swift
/// let stripper = PDFTextStripper()
/// let text = try await stripper.extractText(from: contentStream, resources: resources)
/// let positions = stripper.textPositions
/// let lines = stripper.textLines
/// let blocks = stripper.textBlocks
/// ```
///
/// ## Thread Safety
/// `PDFTextStripper` is not thread-safe. Create separate instances for concurrent extraction.
public final class PDFTextStripper {

    // MARK: - Configuration

    /// Whether to preserve character spacing in extracted text.
    public var preserveCharacterSpacing: Bool

    /// Whether to group text into lines.
    public var extractLines: Bool

    /// Whether to group lines into blocks.
    public var extractBlocks: Bool

    /// The minimum horizontal distance (in points) to consider a space.
    ///
    /// If two characters are separated by more than this distance,
    /// a space will be inserted between them.
    public var spaceThreshold: Double

    /// The minimum vertical distance (in line heights) to consider a new paragraph.
    public var paragraphThreshold: Double

    // MARK: - Extraction Results

    /// All extracted text positions, in reading order.
    public private(set) var textPositions: [TextPosition] = []

    /// Extracted text lines (if `extractLines` is enabled).
    public private(set) var textLines: [TextLine] = []

    /// Extracted text blocks (if `extractBlocks` is enabled).
    public private(set) var textBlocks: [TextBlock] = []

    // MARK: - Internal State

    /// Graphics state stack for processing.
    private var graphicsStateStack: [GraphicsState] = []

    /// Current graphics state.
    private var currentGraphicsState: GraphicsState

    /// Current text state.
    private var currentTextState: TextState

    // MARK: - Initialization

    /// Creates a text stripper with default configuration.
    public init() {
        self.preserveCharacterSpacing = false
        self.extractLines = true
        self.extractBlocks = true
        self.spaceThreshold = 0.25 // 0.25em
        self.paragraphThreshold = 1.5 // 1.5 line heights

        self.currentGraphicsState = GraphicsState()
        self.currentTextState = TextState()
    }

    // MARK: - Text Extraction

    /// Extracts text from a content stream with the given resources.
    ///
    /// - Parameters:
    ///   - stream: The content stream data
    ///   - resources: The resource dictionary (for font lookup)
    /// - Returns: The extracted text as a string
    /// - Throws: If parsing or extraction fails
    public func extractText(
        from stream: Data,
        resources: PDFResources
    ) async throws -> String {
        // Reset state
        reset()

        // Parse content stream
        let inputStream = DataInputStream(data: stream)
        var parser = ContentStreamParser(stream: inputStream)

        // Process operators
        while let op = try await parser.nextOperator() {
            try processOperator(op, resources: resources)
        }

        // Build hierarchy
        if extractLines {
            buildLines()
        }

        if extractBlocks && extractLines {
            buildBlocks()
        }

        // Return plain text
        if extractBlocks {
            return textBlocks.map { $0.text }.joined(separator: "\n\n")
        } else if extractLines {
            return textLines.map { $0.text }.joined(separator: "\n")
        } else {
            return textPositions.map { $0.unicode }.joined()
        }
    }

    // MARK: - Private Methods

    /// Resets the extraction state.
    private func reset() {
        textPositions = []
        textLines = []
        textBlocks = []
        graphicsStateStack = []
        currentGraphicsState = GraphicsState()
        currentTextState = TextState()
    }

    /// Processes a single content stream operator.
    private func processOperator(
        _ op: PDFOperator,
        resources: PDFResources
    ) throws {
        switch op {
        // Graphics state operators
        case .saveState:
            graphicsStateStack.append(currentGraphicsState)

        case .restoreState:
            if let state = graphicsStateStack.popLast() {
                currentGraphicsState = state
            }

        case .concatMatrix(let a, let b, let c, let d, let e, let f):
            let matrix = CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
            currentGraphicsState.ctm = currentGraphicsState.ctm.concatenating(matrix)

        // Text object operators
        case .beginText:
            currentTextState = TextState()

        case .endText:
            break

        // Text state operators
        case .setCharacterSpacing(let spacing):
            currentTextState.characterSpacing = spacing

        case .setWordSpacing(let spacing):
            currentTextState.wordSpacing = spacing

        case .setHorizontalScaling(let scale):
            currentTextState.horizontalScaling = scale

        case .setTextLeading(let leading):
            currentTextState.leading = leading

        case .setFont(let name, let size):
            currentTextState.font = name
            currentTextState.fontSize = size

        case .setTextRenderingMode(let mode):
            currentTextState.renderingMode = mode

        case .setTextRise(let rise):
            currentTextState.rise = rise

        // Text positioning operators
        case .moveText(let tx, let ty):
            currentTextState.moveText(tx: tx, ty: ty)

        case .moveTextSetLeading(let tx, let ty):
            currentTextState.moveTextSetLeading(tx: tx, ty: ty)

        case .setTextMatrix(let a, let b, let c, let d, let e, let f):
            let matrix = CGAffineTransform(a: a, b: b, c: c, d: d, tx: e, ty: f)
            currentTextState.setTextMatrix(matrix)

        case .moveToNextLine:
            currentTextState.moveToNextLine()

        // Text showing operators
        case .showText(let data):
            try showText(data)

        case .showTextArray(let elements):
            for element in elements {
                switch element {
                case .text(let data):
                    try showText(data)
                case .adjustment(let offset):
                    // Adjust text position by offset (in thousandths of an em)
                    let adjustment = -(offset / 1000.0) * currentTextState.fontSize
                    let scaledAdjustment = adjustment * currentTextState.horizontalScaling / 100.0
                    currentTextState.textMatrix = currentTextState.textMatrix.translatedBy(x: scaledAdjustment, y: 0)
                }
            }

        case .moveToNextLineAndShowText(let data):
            currentTextState.moveToNextLine()
            try showText(data)

        case .setSpacingMoveToNextLineAndShowText(let wordSpacing, let charSpacing, let data):
            currentTextState.wordSpacing = wordSpacing
            currentTextState.characterSpacing = charSpacing
            currentTextState.moveToNextLine()
            try showText(data)

        default:
            // Ignore other operators for text extraction
            break
        }
    }

    /// Processes text showing and creates text positions.
    private func showText(_ data: Data) throws {
        guard let font = currentTextState.font else {
            // No font set, skip text
            return
        }

        // For now, do simple byte-to-character conversion
        // In a full implementation, this would use font encoding and ToUnicode CMap
        let bytes = Array(data)

        for byte in bytes {
            // Simple ASCII conversion (full implementation would use font encoding)
            let char = String(UnicodeScalar(byte))
            let unicode = char // TODO: Apply ToUnicode mapping

            // Calculate glyph width
            // Full implementation would look up width from font
            let glyphWidth = currentTextState.fontSize * 0.5 // Simplified

            // Calculate position in user space
            let tm = currentTextState.textMatrix
            let x = tm.tx
            let y = tm.ty

            // Apply CTM
            let point = CGPoint(x: x, y: y).applying(currentGraphicsState.ctm)

            // Calculate total width including spacing
            var totalWidth = glyphWidth
            if char == " " {
                totalWidth += currentTextState.wordSpacing
            }
            totalWidth += currentTextState.characterSpacing
            totalWidth *= currentTextState.horizontalScaling / 100.0

            // Create text position
            let position = TextPosition(
                character: char,
                unicode: unicode,
                x: point.x,
                y: point.y,
                width: totalWidth,
                height: currentTextState.fontSize,
                fontSize: currentTextState.fontSize,
                font: font,
                horizontalScaling: currentTextState.horizontalScaling,
                characterSpacing: currentTextState.characterSpacing,
                wordSpacing: currentTextState.wordSpacing,
                rise: currentTextState.rise,
                textMatrix: currentTextState.textMatrix,
                renderingMode: currentTextState.renderingMode
            )

            textPositions.append(position)

            // Advance text matrix
            currentTextState.textMatrix = currentTextState.textMatrix.translatedBy(x: totalWidth, y: 0)
        }
    }

    /// Builds text lines from positions.
    private func buildLines() {
        guard !textPositions.isEmpty else {
            return
        }

        // Sort positions by reading order
        let sorted = textPositions.sorted()

        var currentLine = TextLine()
        var previousPosition: TextPosition?

        for position in sorted {
            if let prev = previousPosition {
                // Check if we should start a new line
                if !prev.isOnSameLine(as: position) {
                    // New line
                    if !currentLine.isEmpty {
                        textLines.append(currentLine)
                    }
                    currentLine = TextLine()
                } else if !preserveCharacterSpacing {
                    // Check if we need to insert a space
                    let distance = prev.horizontalDistance(to: position)
                    let threshold = prev.width * spaceThreshold

                    if distance > threshold && !prev.isSpace {
                        // Insert artificial space
                        let spacePos = TextPosition(
                            character: " ",
                            unicode: " ",
                            x: prev.x + prev.width,
                            y: prev.y,
                            width: distance,
                            height: prev.height,
                            fontSize: prev.fontSize,
                            font: prev.font
                        )
                        currentLine.append(spacePos)
                    }
                }
            }

            currentLine.append(position)
            previousPosition = position
        }

        // Add final line
        if !currentLine.isEmpty {
            textLines.append(currentLine)
        }

        // Sort lines by reading order
        textLines.sort()
    }

    /// Builds text blocks from lines.
    private func buildBlocks() {
        guard !textLines.isEmpty else {
            return
        }

        var currentBlock = TextBlock()
        var previousLine: TextLine?

        for line in textLines {
            if let prev = previousLine {
                // Check if we should start a new block
                let verticalDistance = prev.verticalDistance(to: line)
                let threshold = prev.averageHeight * paragraphThreshold

                if verticalDistance > threshold {
                    // New block
                    if !currentBlock.isEmpty {
                        textBlocks.append(currentBlock)
                    }
                    currentBlock = TextBlock()
                }
            }

            currentBlock.append(line)
            previousLine = line
        }

        // Add final block
        if !currentBlock.isEmpty {
            textBlocks.append(currentBlock)
        }

        // Sort blocks by reading order
        textBlocks.sort()
    }
}
