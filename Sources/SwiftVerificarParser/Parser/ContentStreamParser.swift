import Foundation
import CoreGraphics

/// Parses PDF content streams into operators.
///
/// `ContentStreamParser` processes content streams (sequences of operators and operands)
/// that define how graphical content is rendered on a page. Content streams are found in
/// page content streams, Form XObjects, Type 3 font glyph descriptions, and appearance streams.
///
/// This struct corresponds to the Java `PDFStreamParser` class from veraPDF-parser.
///
/// ## Content Stream Structure
///
/// A content stream is a sequence of operands followed by an operator:
/// ```
/// operand1 operand2 ... operandN operator
/// ```
///
/// For example:
/// ```
/// BT                  % Begin text
/// /F1 12 Tf          % Set font F1 at 12 points
/// 100 700 Td         % Move text position
/// (Hello) Tj         % Show text
/// ET                 % End text
/// ```
///
/// ## Usage
/// ```swift
/// let data = Data(contentStreamBytes)
/// let stream = DataInputStream(data: data)
/// let parser = ContentStreamParser(stream: stream)
///
/// for try await operator in parser {
///     print(operator)
/// }
/// ```
///
/// ## Thread Safety
/// `ContentStreamParser` is `Sendable` but should be used from a single async context.
public struct ContentStreamParser: Sendable {

    // MARK: - Errors

    /// Errors that can occur during content stream parsing.
    public enum ParserError: Error, CustomStringConvertible {
        /// Not enough operands for the operator.
        case insufficientOperands(operator: String, required: Int, found: Int)

        /// Invalid operand type for the operator.
        case invalidOperandType(operator: String, expected: String, found: String)

        /// Unexpected token encountered.
        case unexpectedToken(PDFToken)

        /// Invalid inline image dictionary.
        case invalidInlineImageDictionary

        /// Inline image data not found.
        case inlineImageDataNotFound

        public var description: String {
            switch self {
            case .insufficientOperands(let op, let req, let found):
                return "Insufficient operands for operator '\(op)': required \(req), found \(found)"
            case .invalidOperandType(let op, let expected, let found):
                return "Invalid operand type for operator '\(op)': expected \(expected), found \(found)"
            case .unexpectedToken(let token):
                return "Unexpected token: \(token)"
            case .invalidInlineImageDictionary:
                return "Invalid inline image dictionary"
            case .inlineImageDataNotFound:
                return "Inline image data not found after BI operator"
            }
        }
    }

    // MARK: - Properties

    /// The tokenizer for the content stream.
    private var tokenizer: PDFTokenizer

    /// The operand stack (accumulates operands before operator).
    private var operandStack: [COSValue]

    // MARK: - Initialization

    /// Creates a content stream parser for the given input stream.
    ///
    /// - Parameter stream: A seekable input stream containing content stream data.
    public init(stream: any SeekableStream) {
        self.tokenizer = PDFTokenizer(stream: stream)
        self.operandStack = []
    }

    // MARK: - Parsing

    /// Parses and returns the next operator from the content stream.
    ///
    /// This method accumulates operands until an operator is encountered,
    /// then constructs and returns a `PDFOperator`.
    ///
    /// - Returns: The next `PDFOperator`, or `nil` if the stream is exhausted.
    /// - Throws: `ParserError` if the content stream is malformed.
    public mutating func nextOperator() async throws -> PDFOperator? {
        while let token = try await tokenizer.nextToken() {
            // Skip comments
            if token.isComment {
                continue
            }

            // Check for operator (keyword that's not a literal value)
            if case .keyword(let keyword) = token {
                return try parseOperator(keyword: keyword)
            }

            // Otherwise, push operand onto stack
            let operand = try await convertTokenToOperand(token)
            operandStack.append(operand)
        }

        // End of stream
        return nil
    }

    // MARK: - Private Parsing Methods

    /// Converts a token to a COS operand value.
    private mutating func convertTokenToOperand(_ token: PDFToken) async throws -> COSValue {
        switch token {
        case .keyword(.true):
            return .boolean(true)
        case .keyword(.false):
            return .boolean(false)
        case .keyword(.null):
            return .null
        case .integer(let val):
            return .integer(val)
        case .real(let val):
            return .real(val)
        case .string(let data):
            return .string(COSString(data: data, isHex: false))
        case .hexString(let data):
            return .string(COSString(data: data, isHex: true))
        case .name(let atom):
            return .name(atom)
        case .arrayStart:
            return try await parseArray()
        case .dictionaryStart:
            return try await parseDictionary()
        default:
            throw ParserError.unexpectedToken(token)
        }
    }

    /// Parses an array (already consumed `[`).
    private mutating func parseArray() async throws -> COSValue {
        var elements: [COSValue] = []

        while let token = try await tokenizer.nextToken() {
            if token.isArrayEnd {
                return .array(elements)
            }

            if token.isComment {
                continue
            }

            // Handle nested structures
            let element = try await convertTokenToOperand(token)
            elements.append(element)
        }

        throw PDFTokenizer.TokenizerError.unexpectedEndOfStream
    }

    /// Parses a dictionary (already consumed `<<`).
    private mutating func parseDictionary() async throws -> COSValue {
        var dict: [ASAtom: COSValue] = [:]

        while let token = try await tokenizer.nextToken() {
            if token.isDictionaryEnd {
                return .dictionary(dict)
            }

            if token.isComment {
                continue
            }

            // Expect name as key
            guard case .name(let key) = token else {
                throw ParserError.unexpectedToken(token)
            }

            // Read value
            guard let valueToken = try await tokenizer.nextToken() else {
                throw PDFTokenizer.TokenizerError.unexpectedEndOfStream
            }

            let value = try await convertTokenToOperand(valueToken)
            dict[key] = value
        }

        throw PDFTokenizer.TokenizerError.unexpectedEndOfStream
    }

    /// Parses an operator from the keyword and accumulated operands.
    private mutating func parseOperator(keyword: PDFKeyword) throws -> PDFOperator {
        let operands = operandStack
        operandStack = [] // Clear stack for next operator

        // Map keyword to operator (handle as string for now)
        let opName = keyword.rawValue

        // Parse based on operator name
        switch opName {
        // Graphics state operators
        case "q":
            return .saveState
        case "Q":
            return .restoreState
        case "cm":
            guard operands.count >= 6,
                  let a = operands[0].numericValue,
                  let b = operands[1].numericValue,
                  let c = operands[2].numericValue,
                  let d = operands[3].numericValue,
                  let e = operands[4].numericValue,
                  let f = operands[5].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 6, found: operands.count)
            }
            return .concatMatrix(a: a, b: b, c: c, d: d, e: e, f: f)
        case "w":
            guard let width = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setLineWidth(width)
        case "J":
            guard let cap = operands.first?.integerValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setLineCap(Int(cap))
        case "j":
            guard let join = operands.first?.integerValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setLineJoin(Int(join))
        case "M":
            guard let limit = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setMiterLimit(limit)
        case "d":
            guard operands.count >= 2,
                  case .array(let patternArray) = operands[0],
                  let phase = operands[1].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            let pattern = patternArray.compactMap { $0.numericValue }
            return .setDash(pattern: pattern, phase: phase)
        case "ri":
            guard case .name(let intent) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setRenderingIntent(intent)
        case "i":
            guard let flatness = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setFlatness(flatness)
        case "gs":
            guard case .name(let dictName) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setExtGState(dictName)

        // Path construction operators
        case "m":
            guard operands.count >= 2,
                  let x = operands[0].numericValue,
                  let y = operands[1].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .moveTo(x: x, y: y)
        case "l":
            guard operands.count >= 2,
                  let x = operands[0].numericValue,
                  let y = operands[1].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .lineTo(x: x, y: y)
        case "c":
            guard operands.count >= 6,
                  let x1 = operands[0].numericValue,
                  let y1 = operands[1].numericValue,
                  let x2 = operands[2].numericValue,
                  let y2 = operands[3].numericValue,
                  let x3 = operands[4].numericValue,
                  let y3 = operands[5].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 6, found: operands.count)
            }
            return .curveTo(x1: x1, y1: y1, x2: x2, y2: y2, x3: x3, y3: y3)
        case "v":
            guard operands.count >= 4,
                  let x2 = operands[0].numericValue,
                  let y2 = operands[1].numericValue,
                  let x3 = operands[2].numericValue,
                  let y3 = operands[3].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 4, found: operands.count)
            }
            return .curveToV(x2: x2, y2: y2, x3: x3, y3: y3)
        case "y":
            guard operands.count >= 4,
                  let x1 = operands[0].numericValue,
                  let y1 = operands[1].numericValue,
                  let x3 = operands[2].numericValue,
                  let y3 = operands[3].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 4, found: operands.count)
            }
            return .curveToY(x1: x1, y1: y1, x3: x3, y3: y3)
        case "h":
            return .closePath
        case "re":
            guard operands.count >= 4,
                  let x = operands[0].numericValue,
                  let y = operands[1].numericValue,
                  let width = operands[2].numericValue,
                  let height = operands[3].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 4, found: operands.count)
            }
            return .rectangle(x: x, y: y, width: width, height: height)

        // Path painting operators
        case "S":
            return .stroke
        case "s":
            return .closeAndStroke
        case "f", "F":
            return .fill
        case "f*":
            return .fillEvenOdd
        case "B":
            return .fillAndStroke
        case "B*":
            return .fillAndStrokeEvenOdd
        case "b":
            return .closeFillAndStroke
        case "b*":
            return .closeFillAndStrokeEvenOdd
        case "n":
            return .endPath

        // Clipping operators
        case "W":
            return .clip
        case "W*":
            return .clipEvenOdd

        // Text object operators
        case "BT":
            return .beginText
        case "ET":
            return .endText

        // Text state operators
        case "Tc":
            guard let spacing = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setCharacterSpacing(spacing)
        case "Tw":
            guard let spacing = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setWordSpacing(spacing)
        case "Tz":
            guard let scale = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setHorizontalScaling(scale)
        case "TL":
            guard let leading = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setTextLeading(leading)
        case "Tf":
            guard operands.count >= 2,
                  case .name(let font) = operands[0],
                  let size = operands[1].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .setFont(name: font, size: size)
        case "Tr":
            guard let mode = operands.first?.integerValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setTextRenderingMode(Int(mode))
        case "Ts":
            guard let rise = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setTextRise(rise)

        // Text positioning operators
        case "Td":
            guard operands.count >= 2,
                  let tx = operands[0].numericValue,
                  let ty = operands[1].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .moveText(tx: tx, ty: ty)
        case "TD":
            guard operands.count >= 2,
                  let tx = operands[0].numericValue,
                  let ty = operands[1].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .moveTextSetLeading(tx: tx, ty: ty)
        case "Tm":
            guard operands.count >= 6,
                  let a = operands[0].numericValue,
                  let b = operands[1].numericValue,
                  let c = operands[2].numericValue,
                  let d = operands[3].numericValue,
                  let e = operands[4].numericValue,
                  let f = operands[5].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 6, found: operands.count)
            }
            return .setTextMatrix(a: a, b: b, c: c, d: d, e: e, f: f)
        case "T*":
            return .moveToNextLine

        // Text showing operators
        case "Tj":
            guard case .string(let str) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .showText(str.data)
        case "TJ":
            guard case .array(let array) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            let elements = try array.map { value -> TextArrayElement in
                if case .string(let str) = value {
                    return .text(str.data)
                } else if let num = value.numericValue {
                    return .adjustment(num)
                } else {
                    throw ParserError.invalidOperandType(operator: opName, expected: "string or number", found: "\(value)")
                }
            }
            return .showTextArray(elements)
        case "'":
            guard case .string(let str) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .moveToNextLineAndShowText(str.data)
        case "\"":
            guard operands.count >= 3,
                  let aw = operands[0].numericValue,
                  let ac = operands[1].numericValue,
                  case .string(let str) = operands[2] else {
                throw ParserError.insufficientOperands(operator: opName, required: 3, found: operands.count)
            }
            return .setSpacingMoveToNextLineAndShowText(wordSpacing: aw, charSpacing: ac, text: str.data)

        // Color operators
        case "CS":
            guard case .name(let cs) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setStrokeColorSpace(cs)
        case "cs":
            guard case .name(let cs) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setFillColorSpace(cs)
        case "SC":
            let components = operands.compactMap { $0.numericValue }
            return .setStrokeColor(components)
        case "SCN":
            let components = operands.dropLast().compactMap { $0.numericValue }
            let pattern: ASAtom? = operands.last?.nameValue
            return .setStrokeColorN(Array(components), pattern: pattern)
        case "sc":
            let components = operands.compactMap { $0.numericValue }
            return .setFillColor(components)
        case "scn":
            let components = operands.dropLast().compactMap { $0.numericValue }
            let pattern: ASAtom? = operands.last?.nameValue
            return .setFillColorN(Array(components), pattern: pattern)
        case "G":
            guard let gray = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setStrokeGray(gray)
        case "g":
            guard let gray = operands.first?.numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .setFillGray(gray)
        case "RG":
            guard operands.count >= 3,
                  let r = operands[0].numericValue,
                  let g = operands[1].numericValue,
                  let b = operands[2].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 3, found: operands.count)
            }
            return .setStrokeRGB(r: r, g: g, b: b)
        case "rg":
            guard operands.count >= 3,
                  let r = operands[0].numericValue,
                  let g = operands[1].numericValue,
                  let b = operands[2].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 3, found: operands.count)
            }
            return .setFillRGB(r: r, g: g, b: b)
        case "K":
            guard operands.count >= 4,
                  let c = operands[0].numericValue,
                  let m = operands[1].numericValue,
                  let y = operands[2].numericValue,
                  let k = operands[3].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 4, found: operands.count)
            }
            return .setStrokeCMYK(c: c, m: m, y: y, k: k)
        case "k":
            guard operands.count >= 4,
                  let c = operands[0].numericValue,
                  let m = operands[1].numericValue,
                  let y = operands[2].numericValue,
                  let k = operands[3].numericValue else {
                throw ParserError.insufficientOperands(operator: opName, required: 4, found: operands.count)
            }
            return .setFillCMYK(c: c, m: m, y: y, k: k)

        // Shading operator
        case "sh":
            guard case .name(let name) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .shading(name)

        // XObject operator
        case "Do":
            guard case .name(let name) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .invokeXObject(name)

        // Marked content operators
        case "MP":
            guard case .name(let tag) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .markedContentPoint(tag)
        case "DP":
            guard operands.count >= 2,
                  case .name(let tag) = operands[0] else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .markedContentPointWithProperties(tag: tag, properties: operands[1])
        case "BMC":
            guard case .name(let tag) = operands.first else {
                throw ParserError.insufficientOperands(operator: opName, required: 1, found: operands.count)
            }
            return .beginMarkedContent(tag)
        case "BDC":
            guard operands.count >= 2,
                  case .name(let tag) = operands[0] else {
                throw ParserError.insufficientOperands(operator: opName, required: 2, found: operands.count)
            }
            return .beginMarkedContentWithProperties(tag: tag, properties: operands[1])
        case "EMC":
            return .endMarkedContent

        // Compatibility operators
        case "BX":
            return .beginCompatibility
        case "EX":
            return .endCompatibility

        // Inline image operators (simplified handling)
        case "BI":
            return .beginInlineImage
        case "EI":
            return .endInlineImage

        default:
            // Unknown operator
            return .unknown(operator: opName, operands: operands)
        }
    }
}

// MARK: - AsyncSequence

extension ContentStreamParser: AsyncSequence {
    public typealias Element = PDFOperator

    /// An async iterator for operators.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var parser: ContentStreamParser

        fileprivate init(parser: ContentStreamParser) {
            self.parser = parser
        }

        public mutating func next() async throws -> PDFOperator? {
            try await parser.nextOperator()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(parser: self)
    }
}
