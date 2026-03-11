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

    /// Cached ToUnicode CMap tables keyed by font name.
    ///
    /// Each entry maps character code bytes (UInt8) to Unicode strings.
    private var toUnicodeMaps: [ASAtom: [UInt8: String]] = [:]

    /// The current page resources (for font lookup).
    private var currentResources: PDFResources?

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

        // Store resources for font lookup during text extraction
        currentResources = resources

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
        toUnicodeMaps = [:]
        currentResources = nil
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
            // Load ToUnicode CMap for this font if not already cached
            if toUnicodeMaps[name] == nil, let resources = currentResources {
                if let cmap = loadToUnicodeCMap(fontName: name, resources: resources) {
                    toUnicodeMaps[name] = cmap
                }
            }

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

        // Retrieve ToUnicode CMap for this font (if available)
        let cmapTable = toUnicodeMaps[font]

        let bytes = Array(data)

        for byte in bytes {
            // Apply ToUnicode CMap mapping if available; otherwise fall back to
            // a simple byte-to-character conversion using the Unicode scalar value.
            let unicode: String
            if let cmap = cmapTable, let mapped = cmap[byte] {
                unicode = mapped
            } else {
                unicode = String(UnicodeScalar(byte))
            }
            let char = unicode

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

    // MARK: - ToUnicode CMap Support

    /// Loads a ToUnicode CMap table for the named font from page resources.
    ///
    /// Returns a mapping from single-byte character codes to Unicode strings, or
    /// `nil` if the font has no `/ToUnicode` entry or the data cannot be parsed.
    ///
    /// - Parameters:
    ///   - fontName: The resource name of the font (e.g., `F1`).
    ///   - resources: The page resources containing the font dictionary.
    /// - Returns: A `[UInt8: String]` mapping, or `nil`.
    private func loadToUnicodeCMap(
        fontName: ASAtom,
        resources: PDFResources
    ) -> [UInt8: String]? {
        // Look up the font dictionary in resources
        guard let fontCOSValue = resources.font(named: fontName) else {
            return nil
        }

        // The ToUnicode entry is a stream in a full PDF, but in the current
        // implementation streams are represented either as a COSString (raw bytes)
        // or as a dictionary with a /ToUnicode key pointing to stream data.
        // We check the dictionary entry directly.
        guard let toUnicodeValue = fontCOSValue[ASAtom("ToUnicode")] else {
            return nil
        }

        // Extract the CMap bytes from whatever form they take
        let cmapData: Data?
        switch toUnicodeValue {
        case .string(let cosStr):
            // Raw CMap bytes stored as a string (unusual but possible)
            cmapData = cosStr.data
        case .dictionary(let dict):
            // The stream's decoded data might be stored under a well-known key;
            // look for a /StreamData or /DecodedData entry (implementation-specific)
            if let streamStr = dict[ASAtom("StreamData")]?.stringValue {
                cmapData = streamStr.data
            } else {
                cmapData = nil
            }
        default:
            cmapData = nil
        }

        guard let data = cmapData else {
            return nil
        }

        return parseCMapData(data)
    }

    /// Parses a ToUnicode CMap byte stream and returns a code-to-Unicode mapping.
    ///
    /// Handles the two CMap mapping sections:
    /// - `beginbfchar` / `endbfchar`: maps individual character codes
    /// - `beginbfrange` / `endbfrange`: maps ranges of character codes
    ///
    /// - Parameter data: The raw CMap program bytes.
    /// - Returns: A `[UInt8: String]` mapping.
    private func parseCMapData(_ data: Data) -> [UInt8: String]? {
        guard let cmapText = String(data: data, encoding: .utf8) ??
                             String(data: data, encoding: .isoLatin1) else {
            return nil
        }

        var mapping: [UInt8: String] = [:]

        // Parse beginbfchar / endbfchar sections
        // Format: <srcCode> <dstCode> per line
        // e.g.:  <20> <0020>   maps byte 0x20 -> U+0020
        for block in extractCMapBlocks(from: cmapText, begin: "beginbfchar", end: "endbfchar") {
            parseBFCharBlock(block, into: &mapping)
        }

        // Parse beginbfrange / endbfrange sections
        // Format: <startCode> <endCode> <dstCode> per line
        // e.g.:  <41> <5A> <0041>  maps 0x41-0x5A -> U+0041-U+005A
        for block in extractCMapBlocks(from: cmapText, begin: "beginbfrange", end: "endbfrange") {
            parseBFRangeBlock(block, into: &mapping)
        }

        return mapping.isEmpty ? nil : mapping
    }

    /// Extracts all blocks delimited by `begin` and `end` keywords from CMap text.
    private func extractCMapBlocks(from text: String, begin: String, end: String) -> [String] {
        var blocks: [String] = []
        var searchStart = text.startIndex

        while searchStart < text.endIndex {
            guard let beginRange = text.range(of: begin, range: searchStart..<text.endIndex) else {
                break
            }
            guard let endRange = text.range(of: end, range: beginRange.upperBound..<text.endIndex) else {
                break
            }
            // Extract the content between begin and end keywords (exclusive)
            let blockContent = String(text[beginRange.upperBound..<endRange.lowerBound])
            blocks.append(blockContent)
            searchStart = endRange.upperBound
        }

        return blocks
    }

    /// Parses a `beginbfchar` block and adds entries to the mapping.
    private func parseBFCharBlock(_ block: String, into mapping: inout [UInt8: String]) {
        // Each line: <srcHex> <dstHex>
        let lines = block.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("<") else { continue }

            let hexValues = extractHexValues(from: trimmed)
            guard hexValues.count >= 2,
                  let srcCode = UInt8(exactly: hexValues[0]),
                  let dstScalar = Unicode.Scalar(hexValues[1]) else {
                continue
            }

            mapping[srcCode] = String(dstScalar)
        }
    }

    /// Parses a `beginbfrange` block and adds entries to the mapping.
    private func parseBFRangeBlock(_ block: String, into mapping: inout [UInt8: String]) {
        // Each line: <startHex> <endHex> <dstHex>
        let lines = block.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("<") else { continue }

            let hexValues = extractHexValues(from: trimmed)
            guard hexValues.count >= 3,
                  let startCode = UInt8(exactly: hexValues[0]),
                  let endCode = UInt8(exactly: hexValues[1]) else {
                continue
            }

            var dstCode = hexValues[2]
            for srcCode in startCode...endCode {
                if let dstScalar = Unicode.Scalar(dstCode) {
                    mapping[srcCode] = String(dstScalar)
                }
                dstCode += 1
            }
        }
    }

    /// Extracts all `<hex>` values from a CMap line as `UInt32` values.
    private func extractHexValues(from line: String) -> [UInt32] {
        var values: [UInt32] = []
        var remaining = line[line.startIndex...]

        while let openAngle = remaining.firstIndex(of: "<") {
            let afterOpen = remaining.index(after: openAngle)
            guard let closeAngle = remaining[afterOpen...].firstIndex(of: ">") else {
                break
            }
            let hexStr = String(remaining[afterOpen..<closeAngle])
            if let value = UInt32(hexStr, radix: 16) {
                values.append(value)
            }
            remaining = remaining[remaining.index(after: closeAngle)...]
        }

        return values
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
