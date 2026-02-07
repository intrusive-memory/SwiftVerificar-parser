import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFToken Tests")
struct PDFTokenTests {

    // MARK: - Token Creation

    @Test("Create keyword token")
    func createKeywordToken() {
        let token = PDFToken.keyword(.obj)
        #expect(token.isKeyword)
        #expect(token.keywordValue == .obj)
    }

    @Test("Create integer token")
    func createIntegerToken() {
        let token = PDFToken.integer(42)
        #expect(token.isInteger)
        #expect(token.integerValue == 42)
    }

    @Test("Create real token")
    func createRealToken() {
        let token = PDFToken.real(3.14)
        #expect(token.isReal)
        #expect(token.realValue == 3.14)
    }

    @Test("Create string token")
    func createStringToken() {
        let data = Data("Hello".utf8)
        let token = PDFToken.string(data)
        #expect(token.isString)
        #expect(token.stringData == data)
    }

    @Test("Create hex string token")
    func createHexStringToken() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
        let token = PDFToken.hexString(data)
        #expect(token.isString)
        #expect(token.stringData == data)
    }

    @Test("Create name token")
    func createNameToken() {
        let token = PDFToken.name(ASAtom("Type"))
        #expect(token.isName)
        #expect(token.nameValue == ASAtom("Type"))
    }

    @Test("Create delimiter tokens")
    func createDelimiterTokens() {
        #expect(PDFToken.arrayStart.isArrayStart)
        #expect(PDFToken.arrayEnd.isArrayEnd)
        #expect(PDFToken.dictionaryStart.isDictionaryStart)
        #expect(PDFToken.dictionaryEnd.isDictionaryEnd)
    }

    @Test("Create comment token")
    func createCommentToken() {
        let token = PDFToken.comment("This is a comment")
        #expect(token.isComment)
        #expect(token.commentValue == "This is a comment")
    }

    @Test("Create end of file token")
    func createEndOfFileToken() {
        let token = PDFToken.endOfFile
        #expect(token.isEndOfFile)
    }

    // MARK: - Token Type Queries

    @Test("isKeyword queries")
    func isKeywordQueries() {
        #expect(PDFToken.keyword(.obj).isKeyword)
        #expect(!PDFToken.integer(42).isKeyword)
        #expect(!PDFToken.real(3.14).isKeyword)
        #expect(!PDFToken.string(Data()).isKeyword)
        #expect(!PDFToken.name(ASAtom("Type")).isKeyword)
        #expect(!PDFToken.arrayStart.isKeyword)
    }

    @Test("isInteger queries")
    func isIntegerQueries() {
        #expect(PDFToken.integer(42).isInteger)
        #expect(!PDFToken.real(3.14).isInteger)
        #expect(!PDFToken.keyword(.obj).isInteger)
        #expect(!PDFToken.string(Data()).isInteger)
    }

    @Test("isReal queries")
    func isRealQueries() {
        #expect(PDFToken.real(3.14).isReal)
        #expect(!PDFToken.integer(42).isReal)
        #expect(!PDFToken.keyword(.obj).isReal)
        #expect(!PDFToken.name(ASAtom("Type")).isReal)
    }

    @Test("isString queries")
    func isStringQueries() {
        #expect(PDFToken.string(Data()).isString)
        #expect(PDFToken.hexString(Data()).isString)
        #expect(!PDFToken.integer(42).isString)
        #expect(!PDFToken.name(ASAtom("Type")).isString)
    }

    @Test("isName queries")
    func isNameQueries() {
        #expect(PDFToken.name(ASAtom("Type")).isName)
        #expect(!PDFToken.string(Data()).isName)
        #expect(!PDFToken.keyword(.obj).isName)
        #expect(!PDFToken.integer(42).isName)
    }

    @Test("isComment queries")
    func isCommentQueries() {
        #expect(PDFToken.comment("test").isComment)
        #expect(!PDFToken.keyword(.obj).isComment)
        #expect(!PDFToken.string(Data()).isComment)
    }

    @Test("Delimiter queries")
    func delimiterQueries() {
        #expect(PDFToken.arrayStart.isArrayStart)
        #expect(!PDFToken.arrayEnd.isArrayStart)
        #expect(PDFToken.arrayEnd.isArrayEnd)
        #expect(!PDFToken.arrayStart.isArrayEnd)
        #expect(PDFToken.dictionaryStart.isDictionaryStart)
        #expect(!PDFToken.dictionaryEnd.isDictionaryStart)
        #expect(PDFToken.dictionaryEnd.isDictionaryEnd)
        #expect(!PDFToken.dictionaryStart.isDictionaryEnd)
    }

    // MARK: - Value Extraction

    @Test("Extract keyword value")
    func extractKeywordValue() {
        let token = PDFToken.keyword(.stream)
        #expect(token.keywordValue == .stream)
        #expect(PDFToken.integer(42).keywordValue == nil)
    }

    @Test("Extract integer value")
    func extractIntegerValue() {
        let token = PDFToken.integer(123)
        #expect(token.integerValue == 123)
        #expect(PDFToken.real(3.14).integerValue == nil)
    }

    @Test("Extract real value")
    func extractRealValue() {
        let token = PDFToken.real(2.718)
        #expect(token.realValue == 2.718)
        #expect(PDFToken.integer(42).realValue == nil)
    }

    @Test("Extract string data")
    func extractStringData() {
        let data = Data("test".utf8)
        let stringToken = PDFToken.string(data)
        #expect(stringToken.stringData == data)

        let hexToken = PDFToken.hexString(data)
        #expect(hexToken.stringData == data)

        #expect(PDFToken.integer(42).stringData == nil)
    }

    @Test("Extract name value")
    func extractNameValue() {
        let atom = ASAtom("Font")
        let token = PDFToken.name(atom)
        #expect(token.nameValue == atom)
        #expect(PDFToken.string(Data()).nameValue == nil)
    }

    @Test("Extract comment value")
    func extractCommentValue() {
        let token = PDFToken.comment("PDF-1.7")
        #expect(token.commentValue == "PDF-1.7")
        #expect(PDFToken.keyword(.obj).commentValue == nil)
    }

    // MARK: - Numeric Conversion

    @Test("asInteger - integer token")
    func asIntegerFromInteger() {
        let token = PDFToken.integer(42)
        #expect(token.asInteger == 42)
    }

    @Test("asInteger - real token")
    func asIntegerFromReal() {
        let token = PDFToken.real(3.14)
        #expect(token.asInteger == 3)

        let token2 = PDFToken.real(99.9)
        #expect(token2.asInteger == 99)
    }

    @Test("asInteger - non-numeric token")
    func asIntegerFromNonNumeric() {
        #expect(PDFToken.keyword(.obj).asInteger == nil)
        #expect(PDFToken.string(Data()).asInteger == nil)
        #expect(PDFToken.name(ASAtom("Type")).asInteger == nil)
    }

    @Test("asReal - real token")
    func asRealFromReal() {
        let token = PDFToken.real(3.14159)
        #expect(token.asReal == 3.14159)
    }

    @Test("asReal - integer token")
    func asRealFromInteger() {
        let token = PDFToken.integer(42)
        #expect(token.asReal == 42.0)

        let token2 = PDFToken.integer(-17)
        #expect(token2.asReal == -17.0)
    }

    @Test("asReal - non-numeric token")
    func asRealFromNonNumeric() {
        #expect(PDFToken.keyword(.true).asReal == nil)
        #expect(PDFToken.string(Data()).asReal == nil)
        #expect(PDFToken.arrayStart.asReal == nil)
    }

    // MARK: - Equality

    @Test("Keyword token equality")
    func keywordTokenEquality() {
        let t1 = PDFToken.keyword(.obj)
        let t2 = PDFToken.keyword(.obj)
        let t3 = PDFToken.keyword(.endobj)
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("Integer token equality")
    func integerTokenEquality() {
        let t1 = PDFToken.integer(42)
        let t2 = PDFToken.integer(42)
        let t3 = PDFToken.integer(43)
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("Real token equality")
    func realTokenEquality() {
        let t1 = PDFToken.real(3.14)
        let t2 = PDFToken.real(3.14)
        let t3 = PDFToken.real(2.718)
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("String token equality")
    func stringTokenEquality() {
        let data1 = Data("hello".utf8)
        let data2 = Data("hello".utf8)
        let data3 = Data("world".utf8)
        let t1 = PDFToken.string(data1)
        let t2 = PDFToken.string(data2)
        let t3 = PDFToken.string(data3)
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("Hex string token equality")
    func hexStringTokenEquality() {
        let data1 = Data([0x01, 0x02, 0x03])
        let data2 = Data([0x01, 0x02, 0x03])
        let data3 = Data([0x04, 0x05])
        let t1 = PDFToken.hexString(data1)
        let t2 = PDFToken.hexString(data2)
        let t3 = PDFToken.hexString(data3)
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("Name token equality")
    func nameTokenEquality() {
        let t1 = PDFToken.name(ASAtom("Type"))
        let t2 = PDFToken.name(ASAtom("Type"))
        let t3 = PDFToken.name(ASAtom("Subtype"))
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("Delimiter token equality")
    func delimiterTokenEquality() {
        #expect(PDFToken.arrayStart == PDFToken.arrayStart)
        #expect(PDFToken.arrayEnd == PDFToken.arrayEnd)
        #expect(PDFToken.dictionaryStart == PDFToken.dictionaryStart)
        #expect(PDFToken.dictionaryEnd == PDFToken.dictionaryEnd)
        #expect(PDFToken.arrayStart != PDFToken.arrayEnd)
        #expect(PDFToken.dictionaryStart != PDFToken.dictionaryEnd)
    }

    @Test("Comment token equality")
    func commentTokenEquality() {
        let t1 = PDFToken.comment("test")
        let t2 = PDFToken.comment("test")
        let t3 = PDFToken.comment("other")
        #expect(t1 == t2)
        #expect(t1 != t3)
    }

    @Test("End of file token equality")
    func endOfFileTokenEquality() {
        #expect(PDFToken.endOfFile == PDFToken.endOfFile)
    }

    @Test("Different token types are not equal")
    func differentTypesNotEqual() {
        #expect(PDFToken.integer(42) != PDFToken.real(42.0))
        #expect(PDFToken.string(Data()) != PDFToken.hexString(Data()))
        #expect(PDFToken.keyword(.true) != PDFToken.integer(1))
        #expect(PDFToken.arrayStart != PDFToken.dictionaryStart)
    }

    // MARK: - CustomStringConvertible

    @Test("Keyword token description")
    func keywordTokenDescription() {
        #expect(PDFToken.keyword(.obj).description == "keyword(obj)")
        #expect(PDFToken.keyword(.stream).description == "keyword(stream)")
    }

    @Test("Integer token description")
    func integerTokenDescription() {
        #expect(PDFToken.integer(42).description == "integer(42)")
        #expect(PDFToken.integer(-17).description == "integer(-17)")
    }

    @Test("Real token description")
    func realTokenDescription() {
        #expect(PDFToken.real(3.14).description == "real(3.14)")
        #expect(PDFToken.real(-0.5).description == "real(-0.5)")
    }

    @Test("String token description")
    func stringTokenDescription() {
        let data = Data("Hello".utf8)
        let token = PDFToken.string(data)
        #expect(token.description.contains("Hello"))
    }

    @Test("Hex string token description")
    func hexStringTokenDescription() {
        let data = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])
        let token = PDFToken.hexString(data)
        #expect(token.description.contains("hexString"))
        #expect(token.description.contains("48656c6c6f"))
    }

    @Test("Name token description")
    func nameTokenDescription() {
        let token = PDFToken.name(ASAtom("Type"))
        #expect(token.description == "name(/Type)")
    }

    @Test("Delimiter token descriptions")
    func delimiterTokenDescriptions() {
        #expect(PDFToken.arrayStart.description == "[")
        #expect(PDFToken.arrayEnd.description == "]")
        #expect(PDFToken.dictionaryStart.description == "<<")
        #expect(PDFToken.dictionaryEnd.description == ">>")
    }

    @Test("Comment token description")
    func commentTokenDescription() {
        let token = PDFToken.comment("PDF-1.7")
        #expect(token.description == "comment(\"PDF-1.7\")")
    }

    @Test("End of file token description")
    func endOfFileTokenDescription() {
        #expect(PDFToken.endOfFile.description == "%%EOF")
    }

    // MARK: - Sendable

    @Test("PDFToken is Sendable")
    func tokenIsSendable() {
        let token = PDFToken.integer(42)
        Task {
            let _ = token
        }
    }

    // MARK: - Edge Cases

    @Test("Zero values")
    func zeroValues() {
        let intToken = PDFToken.integer(0)
        #expect(intToken.integerValue == 0)
        #expect(intToken.asInteger == 0)
        #expect(intToken.asReal == 0.0)

        let realToken = PDFToken.real(0.0)
        #expect(realToken.realValue == 0.0)
        #expect(realToken.asReal == 0.0)
        #expect(realToken.asInteger == 0)
    }

    @Test("Negative values")
    func negativeValues() {
        let intToken = PDFToken.integer(-42)
        #expect(intToken.integerValue == -42)
        #expect(intToken.asInteger == -42)
        #expect(intToken.asReal == -42.0)

        let realToken = PDFToken.real(-3.14)
        #expect(realToken.realValue == -3.14)
        #expect(realToken.asReal == -3.14)
    }

    @Test("Large integer values")
    func largeIntegerValues() {
        let maxInt = Int64.max
        let minInt = Int64.min
        let maxToken = PDFToken.integer(maxInt)
        let minToken = PDFToken.integer(minInt)
        #expect(maxToken.integerValue == maxInt)
        #expect(minToken.integerValue == minInt)
    }

    @Test("Special real values")
    func specialRealValues() {
        let inf = PDFToken.real(.infinity)
        #expect(inf.realValue == .infinity)

        let negInf = PDFToken.real(-.infinity)
        #expect(negInf.realValue == -.infinity)
    }

    @Test("Empty string data")
    func emptyStringData() {
        let stringToken = PDFToken.string(Data())
        #expect(stringToken.stringData?.isEmpty == true)

        let hexToken = PDFToken.hexString(Data())
        #expect(hexToken.stringData?.isEmpty == true)
    }

    @Test("Empty name")
    func emptyName() {
        let token = PDFToken.name(ASAtom(""))
        #expect(token.nameValue?.isEmpty == true)
    }

    @Test("Empty comment")
    func emptyComment() {
        let token = PDFToken.comment("")
        #expect(token.commentValue == "")
    }

    // MARK: - Array of Tokens

    @Test("Store tokens in array")
    func storeTokensInArray() {
        let tokens: [PDFToken] = [
            .integer(1),
            .integer(0),
            .keyword(.R),
            .name(ASAtom("Type")),
            .arrayStart,
            .integer(42),
            .arrayEnd
        ]
        #expect(tokens.count == 7)
        #expect(tokens[0] == .integer(1))
        #expect(tokens[6] == .arrayEnd)
    }

    @Test("Filter tokens by type")
    func filterTokensByType() {
        let tokens: [PDFToken] = [
            .integer(1),
            .real(3.14),
            .integer(2),
            .keyword(.obj),
            .integer(3)
        ]
        let integers = tokens.filter { $0.isInteger }
        #expect(integers.count == 3)
    }
}
