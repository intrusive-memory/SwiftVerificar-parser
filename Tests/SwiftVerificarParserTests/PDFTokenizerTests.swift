import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFTokenizer Tests")
struct PDFTokenizerTests {

    // MARK: - Helper Methods

    func tokenize(_ string: String) async throws -> [PDFToken] {
        let data = Data(string.utf8)
        let stream = DataInputStream(data: data)
        var tokenizer = PDFTokenizer(stream: stream)
        var tokens: [PDFToken] = []
        while let token = try await tokenizer.nextToken() {
            tokens.append(token)
        }
        return tokens
    }

    // MARK: - Basic Tokens

    @Test("Tokenize integers")
    func tokenizeIntegers() async throws {
        let tokens = try await tokenize("42 0 -17 +99")
        #expect(tokens.count == 4)
        #expect(tokens[0] == .integer(42))
        #expect(tokens[1] == .integer(0))
        #expect(tokens[2] == .integer(-17))
        #expect(tokens[3] == .integer(99))
    }

    @Test("Tokenize real numbers")
    func tokenizeRealNumbers() async throws {
        let tokens = try await tokenize("3.14 -0.5 +1.0 .25 0.0")
        #expect(tokens.count == 5)
        #expect(tokens[0] == .real(3.14))
        #expect(tokens[1] == .real(-0.5))
        #expect(tokens[2] == .real(1.0))
        #expect(tokens[3] == .real(0.25))
        #expect(tokens[4] == .real(0.0))
    }

    @Test("Tokenize names")
    func tokenizeNames() async throws {
        let tokens = try await tokenize("/Type /Font /BBox /DeviceRGB")
        #expect(tokens.count == 4)
        #expect(tokens[0] == .name(ASAtom("Type")))
        #expect(tokens[1] == .name(ASAtom("Font")))
        #expect(tokens[2] == .name(ASAtom("BBox")))
        #expect(tokens[3] == .name(ASAtom("DeviceRGB")))
    }

    @Test("Tokenize empty name")
    func tokenizeEmptyName() async throws {
        let tokens = try await tokenize("/")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .name(ASAtom("")))
    }

    @Test("Tokenize names with hex escapes")
    func tokenizeNamesWithHexEscapes() async throws {
        let tokens = try await tokenize("/Name#20With#20Spaces")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .name(ASAtom("Name With Spaces")))
    }

    @Test("Tokenize keywords")
    func tokenizeKeywords() async throws {
        let tokens = try await tokenize("obj endobj stream endstream xref trailer startxref true false null R")
        #expect(tokens.count == 11)
        #expect(tokens[0] == .keyword(.obj))
        #expect(tokens[1] == .keyword(.endobj))
        #expect(tokens[2] == .keyword(.stream))
        #expect(tokens[3] == .keyword(.endstream))
        #expect(tokens[4] == .keyword(.xref))
        #expect(tokens[5] == .keyword(.trailer))
        #expect(tokens[6] == .keyword(.startxref))
        #expect(tokens[7] == .keyword(.true))
        #expect(tokens[8] == .keyword(.false))
        #expect(tokens[9] == .keyword(.null))
        #expect(tokens[10] == .keyword(.R))
    }

    // MARK: - String Tokens

    @Test("Tokenize literal strings")
    func tokenizeLiteralStrings() async throws {
        let tokens = try await tokenize("(Hello) (World) ()")
        #expect(tokens.count == 3)
        #expect(tokens[0] == .string(Data("Hello".utf8)))
        #expect(tokens[1] == .string(Data("World".utf8)))
        #expect(tokens[2] == .string(Data()))
    }

    @Test("Tokenize string with escape sequences")
    func tokenizeStringWithEscapes() async throws {
        let tokens = try await tokenize(#"(Line 1\nLine 2\rLine 3\tTabbed)"#)
        #expect(tokens.count == 1)
        if case .string(let data) = tokens[0] {
            let bytes = [UInt8](data)
            #expect(bytes.contains(0x0A)) // LF
            #expect(bytes.contains(0x0D)) // CR
            #expect(bytes.contains(0x09)) // TAB
        }
    }

    @Test("Tokenize string with nested parentheses")
    func tokenizeStringWithNestedParens() async throws {
        let tokens = try await tokenize("(Hello (nested) world)")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .string(Data("Hello (nested) world".utf8)))
    }

    @Test("Tokenize string with escaped parentheses")
    func tokenizeStringWithEscapedParens() async throws {
        let tokens = try await tokenize(#"(\(escaped\))"#)
        #expect(tokens.count == 1)
        #expect(tokens[0] == .string(Data("(escaped)".utf8)))
    }

    @Test("Tokenize string with octal escapes")
    func tokenizeStringWithOctalEscapes() async throws {
        let tokens = try await tokenize(#"(\101\102\103)"#) // ABC in octal
        #expect(tokens.count == 1)
        if case .string(let data) = tokens[0] {
            #expect(data == Data([0x41, 0x42, 0x43])) // ABC
        }
    }

    @Test("Tokenize hex strings")
    func tokenizeHexStrings() async throws {
        let tokens = try await tokenize("<48656C6C6F> <> <48656C6C6F>")
        #expect(tokens.count == 3)
        #expect(tokens[0] == .hexString(Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]))) // "Hello"
        #expect(tokens[1] == .hexString(Data()))
        #expect(tokens[2] == .hexString(Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])))
    }

    @Test("Tokenize hex string with whitespace")
    func tokenizeHexStringWithWhitespace() async throws {
        let tokens = try await tokenize("<48 65 6C 6C 6F>")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .hexString(Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])))
    }

    @Test("Tokenize hex string with odd length")
    func tokenizeHexStringOddLength() async throws {
        let tokens = try await tokenize("<123>") // Should pad with 0 -> 0x12, 0x30
        #expect(tokens.count == 1)
        if case .hexString(let data) = tokens[0] {
            #expect(data.count == 2)
            #expect(data[0] == 0x12)
            #expect(data[1] == 0x30)
        }
    }

    // MARK: - Delimiters

    @Test("Tokenize array delimiters")
    func tokenizeArrayDelimiters() async throws {
        let tokens = try await tokenize("[ ]")
        #expect(tokens.count == 2)
        #expect(tokens[0] == .arrayStart)
        #expect(tokens[1] == .arrayEnd)
    }

    @Test("Tokenize dictionary delimiters")
    func tokenizeDictionaryDelimiters() async throws {
        let tokens = try await tokenize("<< >>")
        #expect(tokens.count == 2)
        #expect(tokens[0] == .dictionaryStart)
        #expect(tokens[1] == .dictionaryEnd)
    }

    @Test("Tokenize array with content")
    func tokenizeArrayWithContent() async throws {
        let tokens = try await tokenize("[ 1 2 3 ]")
        #expect(tokens.count == 5)
        #expect(tokens[0] == .arrayStart)
        #expect(tokens[1] == .integer(1))
        #expect(tokens[2] == .integer(2))
        #expect(tokens[3] == .integer(3))
        #expect(tokens[4] == .arrayEnd)
    }

    @Test("Tokenize dictionary with content")
    func tokenizeDictionaryWithContent() async throws {
        let tokens = try await tokenize("<< /Type /Page >>")
        #expect(tokens.count == 4)
        #expect(tokens[0] == .dictionaryStart)
        #expect(tokens[1] == .name(ASAtom("Type")))
        #expect(tokens[2] == .name(ASAtom("Page")))
        #expect(tokens[3] == .dictionaryEnd)
    }

    // MARK: - Comments

    @Test("Tokenize comments")
    func tokenizeComments() async throws {
        let tokens = try await tokenize("% This is a comment\n42")
        #expect(tokens.count == 2)
        #expect(tokens[0] == .comment(" This is a comment"))
        #expect(tokens[1] == .integer(42))
    }

    @Test("Tokenize EOF marker")
    func tokenizeEOFMarker() async throws {
        let tokens = try await tokenize("%%EOF")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .endOfFile)
    }

    @Test("Tokenize comment with CRLF")
    func tokenizeCommentWithCRLF() async throws {
        let input = "% Comment\r\n42"
        let tokens = try await tokenize(input)
        #expect(tokens.count == 2)
        #expect(tokens[0] == .comment(" Comment"))
        #expect(tokens[1] == .integer(42))
    }

    // MARK: - Whitespace Handling

    @Test("Skip leading whitespace")
    func skipLeadingWhitespace() async throws {
        let tokens = try await tokenize("   \t\n\r  42")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .integer(42))
    }

    @Test("Skip whitespace between tokens")
    func skipWhitespaceBetweenTokens() async throws {
        let tokens = try await tokenize("1  \t\n  2  \r\n  3")
        #expect(tokens.count == 3)
        #expect(tokens[0] == .integer(1))
        #expect(tokens[1] == .integer(2))
        #expect(tokens[2] == .integer(3))
    }

    @Test("Handle all whitespace characters")
    func handleAllWhitespaceCharacters() async throws {
        // NUL (0x00), HT (0x09), LF (0x0A), FF (0x0C), CR (0x0D), SP (0x20)
        let whitespace = "\u{0000}\u{0009}\u{000A}\u{000C}\u{000D}\u{0020}"
        let tokens = try await tokenize("\(whitespace)42\(whitespace)")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .integer(42))
    }

    // MARK: - Complex Structures

    @Test("Tokenize indirect object definition")
    func tokenizeIndirectObjectDefinition() async throws {
        let tokens = try await tokenize("1 0 obj << /Type /Page >> endobj")
        #expect(tokens.count == 8)
        #expect(tokens[0] == .integer(1))
        #expect(tokens[1] == .integer(0))
        #expect(tokens[2] == .keyword(.obj))
        #expect(tokens[3] == .dictionaryStart)
        #expect(tokens[4] == .name(ASAtom("Type")))
        #expect(tokens[5] == .name(ASAtom("Page")))
        #expect(tokens[6] == .dictionaryEnd)
        #expect(tokens[7] == .keyword(.endobj))
    }

    @Test("Tokenize indirect reference")
    func tokenizeIndirectReference() async throws {
        let tokens = try await tokenize("1 0 R")
        #expect(tokens.count == 3)
        #expect(tokens[0] == .integer(1))
        #expect(tokens[1] == .integer(0))
        #expect(tokens[2] == .keyword(.R))
    }

    @Test("Tokenize stream object header")
    func tokenizeStreamObjectHeader() async throws {
        // Note: Actual stream data parsing requires special handling
        // after the 'stream' keyword, as the data is raw bytes, not tokens
        let input = "<< /Length 5 >>\nstream"
        let tokens = try await tokenize(input)
        #expect(tokens.count == 5)
        #expect(tokens[0] == .dictionaryStart)
        #expect(tokens[1] == .name(ASAtom("Length")))
        #expect(tokens[2] == .integer(5))
        #expect(tokens[3] == .dictionaryEnd)
        #expect(tokens[4] == .keyword(.stream))
    }

    @Test("Tokenize nested structures")
    func tokenizeNestedStructures() async throws {
        let tokens = try await tokenize("[ << /Key /Value >> [ 1 2 ] ]")
        #expect(tokens[0] == .arrayStart)
        #expect(tokens[1] == .dictionaryStart)
        #expect(tokens[6] == .arrayStart)
        #expect(tokens[9] == .arrayEnd)
        #expect(tokens[10] == .arrayEnd)
    }

    // MARK: - Edge Cases

    @Test("Empty input")
    func emptyInput() async throws {
        let tokens = try await tokenize("")
        #expect(tokens.isEmpty)
    }

    @Test("Only whitespace")
    func onlyWhitespace() async throws {
        let tokens = try await tokenize("   \t\n\r  ")
        #expect(tokens.isEmpty)
    }

    @Test("Only comments")
    func onlyComments() async throws {
        let tokens = try await tokenize("% Comment 1\n% Comment 2\n")
        #expect(tokens.count == 2)
        #expect(tokens[0] == .comment(" Comment 1"))
        #expect(tokens[1] == .comment(" Comment 2"))
    }

    @Test("Numbers at edge of valid range")
    func numbersAtEdge() async throws {
        let maxInt = String(Int64.max)
        let minInt = String(Int64.min)
        let tokens = try await tokenize("\(maxInt) \(minInt)")
        #expect(tokens.count == 2)
        #expect(tokens[0] == .integer(Int64.max))
        #expect(tokens[1] == .integer(Int64.min))
    }

    @Test("Very long name")
    func veryLongName() async throws {
        let longName = String(repeating: "a", count: 1000)
        let tokens = try await tokenize("/\(longName)")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .name(ASAtom(longName)))
    }

    @Test("Tokens without whitespace separation")
    func tokensWithoutWhitespace() async throws {
        // PDF allows tokens to be separated by delimiters
        let tokens = try await tokenize("/Type/Font[1 2]/Name")
        #expect(tokens[0] == .name(ASAtom("Type")))
        #expect(tokens[1] == .name(ASAtom("Font")))
        #expect(tokens[2] == .arrayStart)
        #expect(tokens[5] == .arrayEnd)
        #expect(tokens[6] == .name(ASAtom("Name")))
    }

    // MARK: - Error Cases

    @Test("Unterminated string throws error")
    func unterminatedString() async throws {
        await #expect(throws: PDFTokenizer.TokenizerError.self) {
            _ = try await tokenize("(unterminated")
        }
    }

    @Test("Unterminated hex string throws error")
    func unterminatedHexString() async throws {
        await #expect(throws: PDFTokenizer.TokenizerError.self) {
            _ = try await tokenize("<48656C6C6F")
        }
    }

    @Test("Invalid hex digit in hex string throws error")
    func invalidHexDigit() async throws {
        await #expect(throws: PDFTokenizer.TokenizerError.self) {
            _ = try await tokenize("<48G5>")
        }
    }

    @Test("Unknown keyword throws error")
    func unknownKeyword() async throws {
        await #expect(throws: PDFTokenizer.TokenizerError.self) {
            _ = try await tokenize("unknownkeyword")
        }
    }

    @Test("Invalid token character throws error")
    func invalidTokenCharacter() async throws {
        await #expect(throws: PDFTokenizer.TokenizerError.self) {
            _ = try await tokenize(">")
        }
    }

    // MARK: - Real-World Examples

    @Test("Tokenize PDF header")
    func tokenizePDFHeader() async throws {
        let tokens = try await tokenize("%PDF-1.7\n")
        #expect(tokens.count == 1)
        #expect(tokens[0] == .comment("PDF-1.7"))
    }

    @Test("Tokenize xref subsection header")
    func tokenizeXRefSubsectionHeader() async throws {
        let tokens = try await tokenize("0 6")
        #expect(tokens.count == 2)
        #expect(tokens[0] == .integer(0))
        #expect(tokens[1] == .integer(6))
    }

    @Test("Tokenize trailer dictionary")
    func tokenizeTrailerDictionary() async throws {
        let input = """
        trailer
        << /Size 6 /Root 1 0 R >>
        """
        let tokens = try await tokenize(input)
        #expect(tokens[0] == .keyword(.trailer))
        #expect(tokens[1] == .dictionaryStart)
        #expect(tokens[2] == .name(ASAtom("Size")))
        #expect(tokens[3] == .integer(6))
        #expect(tokens[4] == .name(ASAtom("Root")))
        #expect(tokens[5] == .integer(1))
        #expect(tokens[6] == .integer(0))
        #expect(tokens[7] == .keyword(.R))
        #expect(tokens[8] == .dictionaryEnd)
    }

    @Test("Tokenize font dictionary")
    func tokenizeFontDictionary() async throws {
        let input = """
        << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
        """
        let tokens = try await tokenize(input)
        #expect(tokens[0] == .dictionaryStart)
        #expect(tokens[1] == .name(ASAtom("Type")))
        #expect(tokens[2] == .name(ASAtom("Font")))
        #expect(tokens[3] == .name(ASAtom("Subtype")))
        #expect(tokens[4] == .name(ASAtom("Type1")))
        #expect(tokens[5] == .name(ASAtom("BaseFont")))
        #expect(tokens[6] == .name(ASAtom("Helvetica")))
        #expect(tokens[7] == .dictionaryEnd)
    }

    // MARK: - AsyncSequence

    @Test("Tokenizer as AsyncSequence")
    func tokenizerAsyncSequence() async throws {
        let data = Data("1 2 3".utf8)
        let stream = DataInputStream(data: data)
        let tokenizer = PDFTokenizer(stream: stream)

        var tokens: [PDFToken] = []
        for try await token in tokenizer {
            tokens.append(token)
        }

        #expect(tokens.count == 3)
        #expect(tokens[0] == .integer(1))
        #expect(tokens[1] == .integer(2))
        #expect(tokens[2] == .integer(3))
    }

    // MARK: - Performance

    @Test("Tokenize large input")
    func tokenizeLargeInput() async throws {
        // Generate a large array of integers
        var input = "["
        for i in 0..<1000 {
            input += "\(i) "
        }
        input += "]"

        let tokens = try await tokenize(input)
        #expect(tokens.count == 1002) // [ + 1000 integers + ]
        #expect(tokens[0] == .arrayStart)
        #expect(tokens[1001] == .arrayEnd)
    }

    @Test("Tokenize deeply nested structures")
    func tokenizeDeeplyNestedStructures() async throws {
        var input = ""
        let depth = 100
        for _ in 0..<depth {
            input += "["
        }
        for _ in 0..<depth {
            input += "]"
        }

        let tokens = try await tokenize(input)
        #expect(tokens.count == depth * 2)
        #expect(tokens[0] == .arrayStart)
        #expect(tokens[depth] == .arrayEnd)
        #expect(tokens[tokens.count - 1] == .arrayEnd)
    }
}
