import Foundation

/// A PDF content stream operator.
///
/// `PDFOperator` represents the operators found in PDF content streams,
/// which define how graphical content (text, paths, images, etc.) is rendered.
/// Content streams are sequences of operands followed by operators.
///
/// This enum corresponds to the Java `Operator` class from veraPDF-parser,
/// consolidating operator types and their operands into a single Swift enum
/// with associated values.
///
/// ## Operator Categories
///
/// PDF operators are organized into functional groups:
///
/// - **Graphics State**: `q`, `Q`, `cm`, `w`, `J`, `j`, `M`, `d`, `ri`, `i`, `gs`
/// - **Path Construction**: `m`, `l`, `c`, `v`, `y`, `h`, `re`
/// - **Path Painting**: `S`, `s`, `f`, `F`, `f*`, `B`, `B*`, `b`, `b*`, `n`
/// - **Clipping**: `W`, `W*`
/// - **Text Objects**: `BT`, `ET`
/// - **Text State**: `Tc`, `Tw`, `Tz`, `TL`, `Tf`, `Tr`, `Ts`
/// - **Text Positioning**: `Td`, `TD`, `Tm`, `T*`
/// - **Text Showing**: `Tj`, `TJ`, `'`, `"`
/// - **Color**: `CS`, `cs`, `SC`, `SCN`, `sc`, `scn`, `G`, `g`, `RG`, `rg`, `K`, `k`
/// - **Shading**: `sh`
/// - **Inline Images**: `BI`, `ID`, `EI`
/// - **XObjects**: `Do`
/// - **Marked Content**: `MP`, `DP`, `BMC`, `BDC`, `EMC`
/// - **Compatibility**: `BX`, `EX`
///
/// ## Usage
/// ```swift
/// let operators: [PDFOperator] = [
///     .beginText,
///     .setFont(ASAtom("F1"), 12.0),
///     .showText(Data("Hello".utf8)),
///     .endText
/// ]
/// ```
///
/// ## Reference
/// PDF 32000-1:2008 § 9 "Text" and Appendix A "Operator Summary"
public enum PDFOperator: Sendable, Equatable {

    // MARK: - Graphics State Operators

    /// Save graphics state (`q`).
    case saveState

    /// Restore graphics state (`Q`).
    case restoreState

    /// Concatenate matrix to current transformation matrix (`cm`).
    case concatMatrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Set line width (`w`).
    case setLineWidth(Double)

    /// Set line cap style (`J`).
    /// - 0: Butt cap
    /// - 1: Round cap
    /// - 2: Projecting square cap
    case setLineCap(Int)

    /// Set line join style (`j`).
    /// - 0: Miter join
    /// - 1: Round join
    /// - 2: Bevel join
    case setLineJoin(Int)

    /// Set miter limit (`M`).
    case setMiterLimit(Double)

    /// Set line dash pattern (`d`).
    /// First array is the dash array, second value is the dash phase.
    case setDash(pattern: [Double], phase: Double)

    /// Set color rendering intent (`ri`).
    case setRenderingIntent(ASAtom)

    /// Set flatness tolerance (`i`).
    case setFlatness(Double)

    /// Set graphics state from parameter dictionary (`gs`).
    case setExtGState(ASAtom)

    // MARK: - Path Construction Operators

    /// Begin new subpath (`m`).
    case moveTo(x: Double, y: Double)

    /// Append straight line segment (`l`).
    case lineTo(x: Double, y: Double)

    /// Append cubic Bézier curve (`c`).
    case curveTo(x1: Double, y1: Double, x2: Double, y2: Double, x3: Double, y3: Double)

    /// Append cubic Bézier curve with initial point replicated (`v`).
    case curveToV(x2: Double, y2: Double, x3: Double, y3: Double)

    /// Append cubic Bézier curve with final point replicated (`y`).
    case curveToY(x1: Double, y1: Double, x3: Double, y3: Double)

    /// Close current subpath (`h`).
    case closePath

    /// Append rectangle (`re`).
    case rectangle(x: Double, y: Double, width: Double, height: Double)

    // MARK: - Path Painting Operators

    /// Stroke path (`S`).
    case stroke

    /// Close and stroke path (`s`).
    case closeAndStroke

    /// Fill path using nonzero winding rule (`f` or `F`).
    case fill

    /// Fill path using even-odd rule (`f*`).
    case fillEvenOdd

    /// Fill and stroke path using nonzero winding rule (`B`).
    case fillAndStroke

    /// Fill and stroke path using even-odd rule (`B*`).
    case fillAndStrokeEvenOdd

    /// Close, fill, and stroke path using nonzero winding rule (`b`).
    case closeFillAndStroke

    /// Close, fill, and stroke path using even-odd rule (`b*`).
    case closeFillAndStrokeEvenOdd

    /// End path without filling or stroking (`n`).
    case endPath

    // MARK: - Clipping Path Operators

    /// Set clipping path using nonzero winding rule (`W`).
    case clip

    /// Set clipping path using even-odd rule (`W*`).
    case clipEvenOdd

    // MARK: - Text Object Operators

    /// Begin text object (`BT`).
    case beginText

    /// End text object (`ET`).
    case endText

    // MARK: - Text State Operators

    /// Set character spacing (`Tc`).
    case setCharacterSpacing(Double)

    /// Set word spacing (`Tw`).
    case setWordSpacing(Double)

    /// Set horizontal text scaling (`Tz`).
    case setHorizontalScaling(Double)

    /// Set text leading (`TL`).
    case setTextLeading(Double)

    /// Set text font and size (`Tf`).
    case setFont(name: ASAtom, size: Double)

    /// Set text rendering mode (`Tr`).
    /// - 0: Fill
    /// - 1: Stroke
    /// - 2: Fill then stroke
    /// - 3: Invisible
    /// - 4: Fill and add to clipping path
    /// - 5: Stroke and add to clipping path
    /// - 6: Fill, stroke, and add to clipping path
    /// - 7: Add to clipping path
    case setTextRenderingMode(Int)

    /// Set text rise (`Ts`).
    case setTextRise(Double)

    // MARK: - Text Positioning Operators

    /// Move text position (`Td`).
    case moveText(tx: Double, ty: Double)

    /// Move text position and set leading (`TD`).
    case moveTextSetLeading(tx: Double, ty: Double)

    /// Set text matrix and text line matrix (`Tm`).
    case setTextMatrix(a: Double, b: Double, c: Double, d: Double, e: Double, f: Double)

    /// Move to start of next text line (`T*`).
    case moveToNextLine

    // MARK: - Text Showing Operators

    /// Show text string (`Tj`).
    case showText(Data)

    /// Show text string with individual glyph positioning (`TJ`).
    /// Array contains either Data (text strings) or Double (adjustments in thousandths of text space).
    case showTextArray([TextArrayElement])

    /// Move to next line and show text (`'`).
    case moveToNextLineAndShowText(Data)

    /// Set spacing, move to next line, and show text (`"`).
    case setSpacingMoveToNextLineAndShowText(wordSpacing: Double, charSpacing: Double, text: Data)

    // MARK: - Color Operators

    /// Set stroking color space (`CS`).
    case setStrokeColorSpace(ASAtom)

    /// Set nonstroking color space (`cs`).
    case setFillColorSpace(ASAtom)

    /// Set stroking color (`SC`).
    case setStrokeColor([Double])

    /// Set stroking color with pattern (`SCN`).
    case setStrokeColorN([Double], pattern: ASAtom?)

    /// Set nonstroking color (`sc`).
    case setFillColor([Double])

    /// Set nonstroking color with pattern (`scn`).
    case setFillColorN([Double], pattern: ASAtom?)

    /// Set stroking gray level (`G`).
    case setStrokeGray(Double)

    /// Set nonstroking gray level (`g`).
    case setFillGray(Double)

    /// Set stroking RGB color (`RG`).
    case setStrokeRGB(r: Double, g: Double, b: Double)

    /// Set nonstroking RGB color (`rg`).
    case setFillRGB(r: Double, g: Double, b: Double)

    /// Set stroking CMYK color (`K`).
    case setStrokeCMYK(c: Double, m: Double, y: Double, k: Double)

    /// Set nonstroking CMYK color (`k`).
    case setFillCMYK(c: Double, m: Double, y: Double, k: Double)

    // MARK: - Shading Operator

    /// Paint shading (`sh`).
    case shading(ASAtom)

    // MARK: - Inline Image Operators

    /// Begin inline image (`BI`).
    case beginInlineImage

    /// Begin inline image data (`ID`).
    case inlineImageData(dictionary: [ASAtom: COSValue], data: Data)

    /// End inline image (`EI`).
    case endInlineImage

    // MARK: - XObject Operator

    /// Invoke named XObject (`Do`).
    case invokeXObject(ASAtom)

    // MARK: - Marked Content Operators

    /// Designate marked-content point (`MP`).
    case markedContentPoint(ASAtom)

    /// Designate marked-content point with properties (`DP`).
    case markedContentPointWithProperties(tag: ASAtom, properties: COSValue)

    /// Begin marked-content sequence (`BMC`).
    case beginMarkedContent(ASAtom)

    /// Begin marked-content sequence with properties (`BDC`).
    case beginMarkedContentWithProperties(tag: ASAtom, properties: COSValue)

    /// End marked-content sequence (`EMC`).
    case endMarkedContent

    // MARK: - Compatibility Operators

    /// Begin compatibility section (`BX`).
    case beginCompatibility

    /// End compatibility section (`EX`).
    case endCompatibility

    // MARK: - Unknown Operator

    /// An unknown or custom operator.
    case unknown(operator: String, operands: [COSValue])
}

// MARK: - Text Array Element

/// An element in a text array for the `TJ` operator.
///
/// Text arrays can contain text strings (to be shown) and numeric adjustments
/// (to adjust spacing between glyphs or words).
public enum TextArrayElement: Sendable, Equatable {
    /// A text string to show.
    case text(Data)

    /// A position adjustment (in thousandths of a unit of text space).
    /// Positive values move to the left or up; negative values move right or down.
    case adjustment(Double)
}

// MARK: - Operator Name Mapping

extension PDFOperator {

    /// The PDF operator name (e.g., "q", "Q", "cm", "Tf").
    public var operatorName: String {
        switch self {
        case .saveState: return "q"
        case .restoreState: return "Q"
        case .concatMatrix: return "cm"
        case .setLineWidth: return "w"
        case .setLineCap: return "J"
        case .setLineJoin: return "j"
        case .setMiterLimit: return "M"
        case .setDash: return "d"
        case .setRenderingIntent: return "ri"
        case .setFlatness: return "i"
        case .setExtGState: return "gs"
        case .moveTo: return "m"
        case .lineTo: return "l"
        case .curveTo: return "c"
        case .curveToV: return "v"
        case .curveToY: return "y"
        case .closePath: return "h"
        case .rectangle: return "re"
        case .stroke: return "S"
        case .closeAndStroke: return "s"
        case .fill: return "f"
        case .fillEvenOdd: return "f*"
        case .fillAndStroke: return "B"
        case .fillAndStrokeEvenOdd: return "B*"
        case .closeFillAndStroke: return "b"
        case .closeFillAndStrokeEvenOdd: return "b*"
        case .endPath: return "n"
        case .clip: return "W"
        case .clipEvenOdd: return "W*"
        case .beginText: return "BT"
        case .endText: return "ET"
        case .setCharacterSpacing: return "Tc"
        case .setWordSpacing: return "Tw"
        case .setHorizontalScaling: return "Tz"
        case .setTextLeading: return "TL"
        case .setFont: return "Tf"
        case .setTextRenderingMode: return "Tr"
        case .setTextRise: return "Ts"
        case .moveText: return "Td"
        case .moveTextSetLeading: return "TD"
        case .setTextMatrix: return "Tm"
        case .moveToNextLine: return "T*"
        case .showText: return "Tj"
        case .showTextArray: return "TJ"
        case .moveToNextLineAndShowText: return "'"
        case .setSpacingMoveToNextLineAndShowText: return "\""
        case .setStrokeColorSpace: return "CS"
        case .setFillColorSpace: return "cs"
        case .setStrokeColor: return "SC"
        case .setStrokeColorN: return "SCN"
        case .setFillColor: return "sc"
        case .setFillColorN: return "scn"
        case .setStrokeGray: return "G"
        case .setFillGray: return "g"
        case .setStrokeRGB: return "RG"
        case .setFillRGB: return "rg"
        case .setStrokeCMYK: return "K"
        case .setFillCMYK: return "k"
        case .shading: return "sh"
        case .beginInlineImage: return "BI"
        case .inlineImageData: return "ID"
        case .endInlineImage: return "EI"
        case .invokeXObject: return "Do"
        case .markedContentPoint: return "MP"
        case .markedContentPointWithProperties: return "DP"
        case .beginMarkedContent: return "BMC"
        case .beginMarkedContentWithProperties: return "BDC"
        case .endMarkedContent: return "EMC"
        case .beginCompatibility: return "BX"
        case .endCompatibility: return "EX"
        case .unknown(let op, _): return op
        }
    }

    /// Returns whether this is a text-related operator.
    public var isTextOperator: Bool {
        switch self {
        case .beginText, .endText,
             .setCharacterSpacing, .setWordSpacing, .setHorizontalScaling,
             .setTextLeading, .setFont, .setTextRenderingMode, .setTextRise,
             .moveText, .moveTextSetLeading, .setTextMatrix, .moveToNextLine,
             .showText, .showTextArray, .moveToNextLineAndShowText,
             .setSpacingMoveToNextLineAndShowText:
            return true
        default:
            return false
        }
    }

    /// Returns whether this is a path-related operator.
    public var isPathOperator: Bool {
        switch self {
        case .moveTo, .lineTo, .curveTo, .curveToV, .curveToY,
             .closePath, .rectangle:
            return true
        default:
            return false
        }
    }

    /// Returns whether this is a painting operator.
    public var isPaintingOperator: Bool {
        switch self {
        case .stroke, .closeAndStroke, .fill, .fillEvenOdd,
             .fillAndStroke, .fillAndStrokeEvenOdd,
             .closeFillAndStroke, .closeFillAndStrokeEvenOdd, .endPath:
            return true
        default:
            return false
        }
    }

    /// Returns whether this is a color-related operator.
    public var isColorOperator: Bool {
        switch self {
        case .setStrokeColorSpace, .setFillColorSpace,
             .setStrokeColor, .setStrokeColorN, .setFillColor, .setFillColorN,
             .setStrokeGray, .setFillGray, .setStrokeRGB, .setFillRGB,
             .setStrokeCMYK, .setFillCMYK:
            return true
        default:
            return false
        }
    }
}
