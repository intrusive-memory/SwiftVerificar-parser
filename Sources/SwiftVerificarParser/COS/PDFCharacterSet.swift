import Foundation

/// Character classification tables for PDF parsing.
///
/// PDF defines specific character categories used by the tokenizer and parser
/// to determine how to interpret bytes in a PDF file. These categories are
/// defined in ISO 32000-1, Table 1:
///
/// - **White-space characters**: NUL, HT, LF, FF, CR, SP (0, 9, 10, 12, 13, 32)
/// - **Delimiter characters**: `(`, `)`, `<`, `>`, `[`, `]`, `{`, `}`, `/`, `%`
/// - **Regular characters**: All other characters (everything not white-space or delimiter)
///
/// This enum corresponds to the Java `CharTable` class from veraPDF-parser.
///
/// ## Usage
/// ```swift
/// let isWhitespace = PDFCharacterSet.isWhitespace(0x20)  // true (SP)
/// let isDelimiter = PDFCharacterSet.isDelimiter(0x28)     // true ((  )
/// let isRegular = PDFCharacterSet.isRegular(0x41)         // true (A)
/// ```
public enum PDFCharacterSet: Sendable {

    // MARK: - Character Categories

    /// The category of a byte in PDF syntax.
    public enum Category: Sendable, Hashable {
        /// White-space character (NUL, HT, LF, FF, CR, SP).
        case whitespace
        /// Delimiter character: `(`, `)`, `<`, `>`, `[`, `]`, `{`, `}`, `/`, `%`.
        case delimiter
        /// Regular character (everything else).
        case regular
    }

    // MARK: - White-space Characters

    /// PDF white-space character codes as defined in ISO 32000-1, Table 1.
    ///
    /// These are: NUL (0x00), HT (0x09), LF (0x0A), FF (0x0C), CR (0x0D), SP (0x20).
    public static let whitespaceBytes: Set<UInt8> = [
        0x00,  // NUL - Null
        0x09,  // HT  - Horizontal Tab
        0x0A,  // LF  - Line Feed
        0x0C,  // FF  - Form Feed
        0x0D,  // CR  - Carriage Return
        0x20,  // SP  - Space
    ]

    // MARK: - Delimiter Characters

    /// PDF delimiter character codes as defined in ISO 32000-1, Table 1.
    ///
    /// These are: `(`, `)`, `<`, `>`, `[`, `]`, `{`, `}`, `/`, `%`.
    public static let delimiterBytes: Set<UInt8> = [
        0x28,  // (  - Left Parenthesis
        0x29,  // )  - Right Parenthesis
        0x3C,  // <  - Less-Than Sign
        0x3E,  // >  - Greater-Than Sign
        0x5B,  // [  - Left Square Bracket
        0x5D,  // ]  - Right Square Bracket
        0x7B,  // {  - Left Curly Bracket
        0x7D,  // }  - Right Curly Bracket
        0x2F,  // /  - Solidus (Name delimiter)
        0x25,  // %  - Percent Sign (Comment delimiter)
    ]

    // MARK: - End of Line Markers

    /// Line feed byte (LF, 0x0A).
    public static let lineFeed: UInt8 = 0x0A

    /// Carriage return byte (CR, 0x0D).
    public static let carriageReturn: UInt8 = 0x0D

    // MARK: - Special Byte Constants

    /// Null byte (0x00).
    public static let nul: UInt8 = 0x00

    /// Horizontal tab byte (0x09).
    public static let tab: UInt8 = 0x09

    /// Form feed byte (0x0C).
    public static let formFeed: UInt8 = 0x0C

    /// Space byte (0x20).
    public static let space: UInt8 = 0x20

    // MARK: - Delimiter Byte Constants

    /// Left parenthesis `(` (0x28).
    public static let leftParen: UInt8 = 0x28

    /// Right parenthesis `)` (0x29).
    public static let rightParen: UInt8 = 0x29

    /// Less-than sign `<` (0x3C).
    public static let lessThan: UInt8 = 0x3C

    /// Greater-than sign `>` (0x3E).
    public static let greaterThan: UInt8 = 0x3E

    /// Left square bracket `[` (0x5B).
    public static let leftBracket: UInt8 = 0x5B

    /// Right square bracket `]` (0x5D).
    public static let rightBracket: UInt8 = 0x5D

    /// Left curly bracket `{` (0x7B).
    public static let leftBrace: UInt8 = 0x7B

    /// Right curly bracket `}` (0x7D).
    public static let rightBrace: UInt8 = 0x7D

    /// Solidus (forward slash) `/` (0x2F).
    public static let solidus: UInt8 = 0x2F

    /// Percent sign `%` (0x25).
    public static let percent: UInt8 = 0x25

    // MARK: - Number Characters

    /// Numeric digit bytes (0x30-0x39, i.e., '0'-'9').
    public static let digitBytes: ClosedRange<UInt8> = 0x30...0x39

    /// Plus sign `+` (0x2B).
    public static let plus: UInt8 = 0x2B

    /// Minus sign/hyphen `-` (0x2D).
    public static let minus: UInt8 = 0x2D

    /// Decimal point `.` (0x2E).
    public static let period: UInt8 = 0x2E

    // MARK: - Hex Characters

    /// Uppercase hex letter bytes (0x41-0x46, i.e., 'A'-'F').
    public static let uppercaseHexLetters: ClosedRange<UInt8> = 0x41...0x46

    /// Lowercase hex letter bytes (0x61-0x66, i.e., 'a'-'f').
    public static let lowercaseHexLetters: ClosedRange<UInt8> = 0x61...0x66

    // MARK: - Escape Characters

    /// Backslash `\` (0x5C).
    public static let backslash: UInt8 = 0x5C

    // MARK: - Classification Methods

    /// Returns the category of a byte in PDF syntax.
    ///
    /// - Parameter byte: The byte to classify.
    /// - Returns: The character category (`.whitespace`, `.delimiter`, or `.regular`).
    public static func category(of byte: UInt8) -> Category {
        if whitespaceBytes.contains(byte) {
            return .whitespace
        }
        if delimiterBytes.contains(byte) {
            return .delimiter
        }
        return .regular
    }

    /// Whether the byte is a PDF white-space character.
    ///
    /// PDF white-space characters are: NUL (0), HT (9), LF (10), FF (12), CR (13), SP (32).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is a PDF white-space character.
    public static func isWhitespace(_ byte: UInt8) -> Bool {
        whitespaceBytes.contains(byte)
    }

    /// Whether the byte is a PDF delimiter character.
    ///
    /// PDF delimiters are: `(`, `)`, `<`, `>`, `[`, `]`, `{`, `}`, `/`, `%`.
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is a PDF delimiter character.
    public static func isDelimiter(_ byte: UInt8) -> Bool {
        delimiterBytes.contains(byte)
    }

    /// Whether the byte is a PDF regular character.
    ///
    /// A regular character is anything that is not white-space and not a delimiter.
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is a regular character.
    public static func isRegular(_ byte: UInt8) -> Bool {
        !isWhitespace(byte) && !isDelimiter(byte)
    }

    /// Whether the byte is a decimal digit (0-9).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is in the range 0x30-0x39.
    public static func isDigit(_ byte: UInt8) -> Bool {
        digitBytes.contains(byte)
    }

    /// Whether the byte is a valid hexadecimal digit (0-9, a-f, A-F).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is a hex digit.
    public static func isHexDigit(_ byte: UInt8) -> Bool {
        digitBytes.contains(byte)
            || uppercaseHexLetters.contains(byte)
            || lowercaseHexLetters.contains(byte)
    }

    /// Whether the byte is a numeric sign or decimal point (+, -, .).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is `+`, `-`, or `.`.
    public static func isNumericPunctuation(_ byte: UInt8) -> Bool {
        byte == plus || byte == minus || byte == period
    }

    /// Whether the byte starts a valid number token.
    ///
    /// A number can start with a digit, a sign (+/-), or a decimal point.
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte could be the start of a number.
    public static func isNumberStart(_ byte: UInt8) -> Bool {
        isDigit(byte) || isNumericPunctuation(byte)
    }

    /// Whether the byte is an end-of-line marker (LF or CR).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is LF (0x0A) or CR (0x0D).
    public static func isEndOfLine(_ byte: UInt8) -> Bool {
        byte == lineFeed || byte == carriageReturn
    }

    /// Converts a hex digit byte to its numeric value (0-15).
    ///
    /// - Parameter byte: A hex digit byte (0-9, a-f, A-F).
    /// - Returns: The numeric value (0-15), or `nil` if the byte is not a hex digit.
    public static func hexValue(of byte: UInt8) -> UInt8? {
        if digitBytes.contains(byte) {
            return byte - 0x30
        }
        if uppercaseHexLetters.contains(byte) {
            return byte - 0x41 + 10
        }
        if lowercaseHexLetters.contains(byte) {
            return byte - 0x61 + 10
        }
        return nil
    }

    /// Converts a numeric value (0-15) to its uppercase hex digit byte.
    ///
    /// - Parameter value: A value in the range 0-15.
    /// - Returns: The hex digit byte, or `nil` if the value is out of range.
    public static func hexByte(for value: UInt8) -> UInt8? {
        if value < 10 {
            return 0x30 + value
        }
        if value < 16 {
            return 0x41 + value - 10
        }
        return nil
    }

    /// Converts an octal digit byte to its numeric value (0-7).
    ///
    /// - Parameter byte: An octal digit byte ('0'-'7').
    /// - Returns: The numeric value (0-7), or `nil` if the byte is not an octal digit.
    public static func octalValue(of byte: UInt8) -> UInt8? {
        if byte >= 0x30 && byte <= 0x37 {
            return byte - 0x30
        }
        return nil
    }

    /// Whether the byte is an octal digit (0-7).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is in the range 0x30-0x37.
    public static func isOctalDigit(_ byte: UInt8) -> Bool {
        byte >= 0x30 && byte <= 0x37
    }

    /// Whether the byte is an ASCII alphabetic character (a-z, A-Z).
    ///
    /// - Parameter byte: The byte to check.
    /// - Returns: `true` if the byte is an ASCII letter.
    public static func isAlphabetic(_ byte: UInt8) -> Bool {
        (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
    }
}
