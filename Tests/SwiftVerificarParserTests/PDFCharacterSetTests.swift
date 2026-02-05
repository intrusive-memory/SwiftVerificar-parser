import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFCharacterSet Tests")
struct PDFCharacterSetTests {

    // MARK: - White-space Classification

    @Test("NUL is whitespace")
    func nulIsWhitespace() {
        #expect(PDFCharacterSet.isWhitespace(0x00))
        #expect(PDFCharacterSet.category(of: 0x00) == .whitespace)
    }

    @Test("HT (tab) is whitespace")
    func tabIsWhitespace() {
        #expect(PDFCharacterSet.isWhitespace(0x09))
        #expect(PDFCharacterSet.category(of: 0x09) == .whitespace)
    }

    @Test("LF (line feed) is whitespace")
    func lfIsWhitespace() {
        #expect(PDFCharacterSet.isWhitespace(0x0A))
        #expect(PDFCharacterSet.category(of: 0x0A) == .whitespace)
    }

    @Test("FF (form feed) is whitespace")
    func ffIsWhitespace() {
        #expect(PDFCharacterSet.isWhitespace(0x0C))
        #expect(PDFCharacterSet.category(of: 0x0C) == .whitespace)
    }

    @Test("CR (carriage return) is whitespace")
    func crIsWhitespace() {
        #expect(PDFCharacterSet.isWhitespace(0x0D))
        #expect(PDFCharacterSet.category(of: 0x0D) == .whitespace)
    }

    @Test("SP (space) is whitespace")
    func spaceIsWhitespace() {
        #expect(PDFCharacterSet.isWhitespace(0x20))
        #expect(PDFCharacterSet.category(of: 0x20) == .whitespace)
    }

    @Test("Whitespace set has exactly 6 members")
    func whitespaceCount() {
        #expect(PDFCharacterSet.whitespaceBytes.count == 6)
    }

    @Test("Non-whitespace bytes are not whitespace")
    func nonWhitespace() {
        #expect(!PDFCharacterSet.isWhitespace(0x41))  // 'A'
        #expect(!PDFCharacterSet.isWhitespace(0x28))  // '('
        #expect(!PDFCharacterSet.isWhitespace(0x01))  // SOH
    }

    // MARK: - Delimiter Classification

    @Test("Left parenthesis is delimiter")
    func leftParenIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x28))
        #expect(PDFCharacterSet.category(of: 0x28) == .delimiter)
    }

    @Test("Right parenthesis is delimiter")
    func rightParenIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x29))
        #expect(PDFCharacterSet.category(of: 0x29) == .delimiter)
    }

    @Test("Less-than is delimiter")
    func lessThanIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x3C))
        #expect(PDFCharacterSet.category(of: 0x3C) == .delimiter)
    }

    @Test("Greater-than is delimiter")
    func greaterThanIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x3E))
        #expect(PDFCharacterSet.category(of: 0x3E) == .delimiter)
    }

    @Test("Left bracket is delimiter")
    func leftBracketIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x5B))
        #expect(PDFCharacterSet.category(of: 0x5B) == .delimiter)
    }

    @Test("Right bracket is delimiter")
    func rightBracketIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x5D))
        #expect(PDFCharacterSet.category(of: 0x5D) == .delimiter)
    }

    @Test("Left brace is delimiter")
    func leftBraceIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x7B))
        #expect(PDFCharacterSet.category(of: 0x7B) == .delimiter)
    }

    @Test("Right brace is delimiter")
    func rightBraceIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x7D))
        #expect(PDFCharacterSet.category(of: 0x7D) == .delimiter)
    }

    @Test("Solidus is delimiter")
    func solidusIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x2F))
        #expect(PDFCharacterSet.category(of: 0x2F) == .delimiter)
    }

    @Test("Percent is delimiter")
    func percentIsDelimiter() {
        #expect(PDFCharacterSet.isDelimiter(0x25))
        #expect(PDFCharacterSet.category(of: 0x25) == .delimiter)
    }

    @Test("Delimiter set has exactly 10 members")
    func delimiterCount() {
        #expect(PDFCharacterSet.delimiterBytes.count == 10)
    }

    // MARK: - Regular Classification

    @Test("Letter A is regular")
    func letterAIsRegular() {
        #expect(PDFCharacterSet.isRegular(0x41))
        #expect(PDFCharacterSet.category(of: 0x41) == .regular)
    }

    @Test("Digit 0 is regular")
    func digit0IsRegular() {
        #expect(PDFCharacterSet.isRegular(0x30))
        #expect(PDFCharacterSet.category(of: 0x30) == .regular)
    }

    @Test("Hyphen is regular")
    func hyphenIsRegular() {
        #expect(PDFCharacterSet.isRegular(0x2D))
        #expect(PDFCharacterSet.category(of: 0x2D) == .regular)
    }

    @Test("Plus is regular")
    func plusIsRegular() {
        #expect(PDFCharacterSet.isRegular(0x2B))
    }

    @Test("Period is regular")
    func periodIsRegular() {
        #expect(PDFCharacterSet.isRegular(0x2E))
    }

    @Test("High bytes are regular")
    func highBytesAreRegular() {
        #expect(PDFCharacterSet.isRegular(0x80))
        #expect(PDFCharacterSet.isRegular(0xFF))
    }

    @Test("Regular is neither whitespace nor delimiter")
    func regularExclusive() {
        let byte: UInt8 = 0x41  // 'A'
        #expect(!PDFCharacterSet.isWhitespace(byte))
        #expect(!PDFCharacterSet.isDelimiter(byte))
        #expect(PDFCharacterSet.isRegular(byte))
    }

    // MARK: - Digit Classification

    @Test("Digits 0-9 are digits")
    func digitsAreDigits() {
        for byte: UInt8 in 0x30...0x39 {
            #expect(PDFCharacterSet.isDigit(byte))
        }
    }

    @Test("Non-digit is not a digit")
    func nonDigitIsNotDigit() {
        #expect(!PDFCharacterSet.isDigit(0x41))  // 'A'
        #expect(!PDFCharacterSet.isDigit(0x20))  // SP
        #expect(!PDFCharacterSet.isDigit(0x2F))  // '/' (just before '0')
        #expect(!PDFCharacterSet.isDigit(0x3A))  // ':' (just after '9')
    }

    // MARK: - Hex Digit Classification

    @Test("Digits 0-9 are hex digits")
    func digitsAreHexDigits() {
        for byte: UInt8 in 0x30...0x39 {
            #expect(PDFCharacterSet.isHexDigit(byte))
        }
    }

    @Test("Uppercase A-F are hex digits")
    func uppercaseHexDigits() {
        for byte: UInt8 in 0x41...0x46 {
            #expect(PDFCharacterSet.isHexDigit(byte))
        }
    }

    @Test("Lowercase a-f are hex digits")
    func lowercaseHexDigits() {
        for byte: UInt8 in 0x61...0x66 {
            #expect(PDFCharacterSet.isHexDigit(byte))
        }
    }

    @Test("G is not a hex digit")
    func gNotHexDigit() {
        #expect(!PDFCharacterSet.isHexDigit(0x47))  // 'G'
        #expect(!PDFCharacterSet.isHexDigit(0x67))  // 'g'
    }

    // MARK: - Hex Value Conversion

    @Test("Hex value of digit 0")
    func hexValueOf0() {
        #expect(PDFCharacterSet.hexValue(of: 0x30) == 0)
    }

    @Test("Hex value of digit 9")
    func hexValueOf9() {
        #expect(PDFCharacterSet.hexValue(of: 0x39) == 9)
    }

    @Test("Hex value of uppercase A")
    func hexValueOfA() {
        #expect(PDFCharacterSet.hexValue(of: 0x41) == 10)
    }

    @Test("Hex value of uppercase F")
    func hexValueOfF() {
        #expect(PDFCharacterSet.hexValue(of: 0x46) == 15)
    }

    @Test("Hex value of lowercase a")
    func hexValueOfLowercaseA() {
        #expect(PDFCharacterSet.hexValue(of: 0x61) == 10)
    }

    @Test("Hex value of lowercase f")
    func hexValueOfLowercaseF() {
        #expect(PDFCharacterSet.hexValue(of: 0x66) == 15)
    }

    @Test("Hex value of non-hex digit is nil")
    func hexValueOfNonHex() {
        #expect(PDFCharacterSet.hexValue(of: 0x47) == nil)  // 'G'
        #expect(PDFCharacterSet.hexValue(of: 0x20) == nil)  // SP
        #expect(PDFCharacterSet.hexValue(of: 0x2F) == nil)  // '/'
    }

    // MARK: - Hex Byte Conversion

    @Test("Hex byte for values 0-9")
    func hexByteForDigits() {
        #expect(PDFCharacterSet.hexByte(for: 0) == 0x30)  // '0'
        #expect(PDFCharacterSet.hexByte(for: 9) == 0x39)  // '9'
    }

    @Test("Hex byte for values 10-15")
    func hexByteForLetters() {
        #expect(PDFCharacterSet.hexByte(for: 10) == 0x41)  // 'A'
        #expect(PDFCharacterSet.hexByte(for: 15) == 0x46)  // 'F'
    }

    @Test("Hex byte for out of range value is nil")
    func hexByteOutOfRange() {
        #expect(PDFCharacterSet.hexByte(for: 16) == nil)
        #expect(PDFCharacterSet.hexByte(for: 255) == nil)
    }

    @Test("Hex value and hex byte round-trip")
    func hexRoundTrip() {
        for value: UInt8 in 0..<16 {
            let byte = PDFCharacterSet.hexByte(for: value)
            #expect(byte != nil)
            if let byte {
                #expect(PDFCharacterSet.hexValue(of: byte) == value)
            }
        }
    }

    // MARK: - Octal Classification

    @Test("Octal digits 0-7 are octal digits")
    func octalDigits() {
        for byte: UInt8 in 0x30...0x37 {
            #expect(PDFCharacterSet.isOctalDigit(byte))
        }
    }

    @Test("Digit 8 is not an octal digit")
    func digit8NotOctal() {
        #expect(!PDFCharacterSet.isOctalDigit(0x38))  // '8'
    }

    @Test("Digit 9 is not an octal digit")
    func digit9NotOctal() {
        #expect(!PDFCharacterSet.isOctalDigit(0x39))  // '9'
    }

    @Test("Octal value of digits 0-7")
    func octalValues() {
        for i: UInt8 in 0...7 {
            #expect(PDFCharacterSet.octalValue(of: 0x30 + i) == i)
        }
    }

    @Test("Octal value of non-octal digit is nil")
    func octalValueNonOctal() {
        #expect(PDFCharacterSet.octalValue(of: 0x38) == nil)  // '8'
        #expect(PDFCharacterSet.octalValue(of: 0x41) == nil)  // 'A'
    }

    // MARK: - Numeric Punctuation

    @Test("Plus is numeric punctuation")
    func plusIsNumericPunctuation() {
        #expect(PDFCharacterSet.isNumericPunctuation(0x2B))
    }

    @Test("Minus is numeric punctuation")
    func minusIsNumericPunctuation() {
        #expect(PDFCharacterSet.isNumericPunctuation(0x2D))
    }

    @Test("Period is numeric punctuation")
    func periodIsNumericPunctuation() {
        #expect(PDFCharacterSet.isNumericPunctuation(0x2E))
    }

    @Test("Digit is not numeric punctuation")
    func digitIsNotNumericPunctuation() {
        #expect(!PDFCharacterSet.isNumericPunctuation(0x30))
    }

    // MARK: - Number Start

    @Test("Digit is number start")
    func digitIsNumberStart() {
        #expect(PDFCharacterSet.isNumberStart(0x30))  // '0'
        #expect(PDFCharacterSet.isNumberStart(0x39))  // '9'
    }

    @Test("Plus is number start")
    func plusIsNumberStart() {
        #expect(PDFCharacterSet.isNumberStart(0x2B))
    }

    @Test("Minus is number start")
    func minusIsNumberStart() {
        #expect(PDFCharacterSet.isNumberStart(0x2D))
    }

    @Test("Period is number start")
    func periodIsNumberStart() {
        #expect(PDFCharacterSet.isNumberStart(0x2E))
    }

    @Test("Letter is not number start")
    func letterNotNumberStart() {
        #expect(!PDFCharacterSet.isNumberStart(0x41))  // 'A'
    }

    // MARK: - End of Line

    @Test("LF is end of line")
    func lfIsEndOfLine() {
        #expect(PDFCharacterSet.isEndOfLine(0x0A))
    }

    @Test("CR is end of line")
    func crIsEndOfLine() {
        #expect(PDFCharacterSet.isEndOfLine(0x0D))
    }

    @Test("Space is not end of line")
    func spaceNotEndOfLine() {
        #expect(!PDFCharacterSet.isEndOfLine(0x20))
    }

    @Test("NUL is not end of line")
    func nulNotEndOfLine() {
        #expect(!PDFCharacterSet.isEndOfLine(0x00))
    }

    // MARK: - Special Byte Constants

    @Test("Special byte constants have correct values")
    func specialByteConstants() {
        #expect(PDFCharacterSet.nul == 0x00)
        #expect(PDFCharacterSet.tab == 0x09)
        #expect(PDFCharacterSet.lineFeed == 0x0A)
        #expect(PDFCharacterSet.formFeed == 0x0C)
        #expect(PDFCharacterSet.carriageReturn == 0x0D)
        #expect(PDFCharacterSet.space == 0x20)
    }

    @Test("Delimiter byte constants have correct values")
    func delimiterByteConstants() {
        #expect(PDFCharacterSet.leftParen == 0x28)
        #expect(PDFCharacterSet.rightParen == 0x29)
        #expect(PDFCharacterSet.lessThan == 0x3C)
        #expect(PDFCharacterSet.greaterThan == 0x3E)
        #expect(PDFCharacterSet.leftBracket == 0x5B)
        #expect(PDFCharacterSet.rightBracket == 0x5D)
        #expect(PDFCharacterSet.leftBrace == 0x7B)
        #expect(PDFCharacterSet.rightBrace == 0x7D)
        #expect(PDFCharacterSet.solidus == 0x2F)
        #expect(PDFCharacterSet.percent == 0x25)
    }

    @Test("Number-related byte constants have correct values")
    func numberByteConstants() {
        #expect(PDFCharacterSet.plus == 0x2B)
        #expect(PDFCharacterSet.minus == 0x2D)
        #expect(PDFCharacterSet.period == 0x2E)
    }

    @Test("Backslash constant has correct value")
    func backslashConstant() {
        #expect(PDFCharacterSet.backslash == 0x5C)
    }

    // MARK: - Category Exhaustive Coverage

    @Test("Every byte has exactly one category")
    func everythingIsClassified() {
        for byte: UInt16 in 0...255 {
            let b = UInt8(byte)
            let cat = PDFCharacterSet.category(of: b)
            switch cat {
            case .whitespace:
                #expect(PDFCharacterSet.isWhitespace(b))
                #expect(!PDFCharacterSet.isDelimiter(b))
                #expect(!PDFCharacterSet.isRegular(b))
            case .delimiter:
                #expect(!PDFCharacterSet.isWhitespace(b))
                #expect(PDFCharacterSet.isDelimiter(b))
                #expect(!PDFCharacterSet.isRegular(b))
            case .regular:
                #expect(!PDFCharacterSet.isWhitespace(b))
                #expect(!PDFCharacterSet.isDelimiter(b))
                #expect(PDFCharacterSet.isRegular(b))
            }
        }
    }

    @Test("Digit range constants are correct")
    func digitRange() {
        #expect(PDFCharacterSet.digitBytes == 0x30...0x39)
    }

    @Test("Uppercase hex range constants are correct")
    func uppercaseHexRange() {
        #expect(PDFCharacterSet.uppercaseHexLetters == 0x41...0x46)
    }

    @Test("Lowercase hex range constants are correct")
    func lowercaseHexRange() {
        #expect(PDFCharacterSet.lowercaseHexLetters == 0x61...0x66)
    }

    // MARK: - Category Enum

    @Test("Category enum cases are distinct")
    func categoryDistinct() {
        let whitespace = PDFCharacterSet.Category.whitespace
        let delimiter = PDFCharacterSet.Category.delimiter
        let regular = PDFCharacterSet.Category.regular
        #expect(whitespace != delimiter)
        #expect(delimiter != regular)
        #expect(whitespace != regular)
    }

    @Test("Category enum is Hashable")
    func categoryHashable() {
        let set: Set<PDFCharacterSet.Category> = [.whitespace, .delimiter, .regular, .whitespace]
        #expect(set.count == 3)
    }
}
