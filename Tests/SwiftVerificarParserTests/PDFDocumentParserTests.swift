import Testing
import Foundation
@testable import SwiftVerificarParser

/// Test suite for PDFDocumentParser.
@Suite("PDFDocumentParser Tests")
struct PDFDocumentParserTests {

    // MARK: - Helper Methods

    /// Creates a minimal valid PDF document as Data with correct byte offsets.
    func createMinimalPDF() -> Data {
        var pdf = Data()

        // Header
        pdf.append("%PDF-1.7\n".data(using: .utf8)!)

        // Track object offsets for the xref table
        let obj1Offset = pdf.count
        pdf.append("1 0 obj\n".data(using: .utf8)!)
        pdf.append("<< /Type /Catalog /Pages 2 0 R >>\n".data(using: .utf8)!)
        pdf.append("endobj\n".data(using: .utf8)!)

        let obj2Offset = pdf.count
        pdf.append("2 0 obj\n".data(using: .utf8)!)
        pdf.append("<< /Type /Pages /Count 0 /Kids [] >>\n".data(using: .utf8)!)
        pdf.append("endobj\n".data(using: .utf8)!)

        // Save xref position
        let xrefPosition = pdf.count

        // Cross-reference table with dynamically computed offsets
        pdf.append("xref\n".data(using: .utf8)!)
        pdf.append("0 3\n".data(using: .utf8)!)
        pdf.append("0000000000 65535 f \n".data(using: .utf8)!)
        pdf.append(String(format: "%010d 00000 n \n", obj1Offset).data(using: .utf8)!)
        pdf.append(String(format: "%010d 00000 n \n", obj2Offset).data(using: .utf8)!)

        // Trailer
        pdf.append("trailer\n".data(using: .utf8)!)
        pdf.append("<< /Size 3 /Root 1 0 R >>\n".data(using: .utf8)!)

        // Startxref
        pdf.append("startxref\n".data(using: .utf8)!)
        pdf.append("\(xrefPosition)\n".data(using: .utf8)!)
        pdf.append("%%EOF\n".data(using: .utf8)!)

        return pdf
    }

    // MARK: - Header Parsing Tests

    @Test("Parse PDF 1.7 header")
    func parsePDF17Header() async throws {
        let data = Data("%PDF-1.7\n".utf8)
        let stream = DataInputStream(data: data)

        let header = try await PDFDocumentParser.parseHeader(from: stream)
        #expect(header.versionString == "1.7")
    }

    @Test("Parse PDF 1.4 header")
    func parsePDF14Header() async throws {
        let data = Data("%PDF-1.4\n".utf8)
        let stream = DataInputStream(data: data)

        let header = try await PDFDocumentParser.parseHeader(from: stream)
        #expect(header.versionString == "1.4")
    }

    @Test("Parse PDF 2.0 header")
    func parsePDF20Header() async throws {
        let data = Data("%PDF-2.0\n".utf8)
        let stream = DataInputStream(data: data)

        let header = try await PDFDocumentParser.parseHeader(from: stream)
        #expect(header.versionString == "2.0")
    }

    @Test("Fail on invalid header magic")
    func failOnInvalidHeaderMagic() async throws {
        let data = Data("NOT-PDF-1.7\n".utf8)
        let stream = DataInputStream(data: data)

        await #expect(throws: PDFDocumentParser.DocumentError.self) {
            _ = try await PDFDocumentParser.parseHeader(from: stream)
        }
    }

    @Test("Fail on too short header")
    func failOnTooShortHeader() async throws {
        let data = Data("%PDF".utf8)
        let stream = DataInputStream(data: data)

        await #expect(throws: PDFDocumentParser.DocumentError.self) {
            _ = try await PDFDocumentParser.parseHeader(from: stream)
        }
    }

    // MARK: - StartXRef Parsing Tests

    @Test("Find startxref offset")
    func findStartxrefOffset() async throws {
        let pdfString = "%PDF-1.7\nstartxref\n42\n%%EOF\n"
        let pdfData = Data(pdfString.utf8)

        let stream = DataInputStream(data: pdfData)
        let offset = try await PDFDocumentParser.findStartXRef(in: stream)
        #expect(offset == 42)
    }

    @Test("Find startxref with larger offset")
    func findStartxrefWithLargerOffset() async throws {
        let pdfString = "%PDF-1.7\nstartxref\n123456\n%%EOF\n"
        let pdfData = Data(pdfString.utf8)

        let stream = DataInputStream(data: pdfData)
        let offset = try await PDFDocumentParser.findStartXRef(in: stream)
        #expect(offset == 123456)
    }

    @Test("Fail on missing startxref")
    func failOnMissingStartxref() async throws {
        let pdfData = Data("""
        %PDF-1.7
        trailer
        << /Size 2 /Root 1 0 R >>
        %%EOF
        """.utf8)

        let stream = DataInputStream(data: pdfData)

        await #expect(throws: PDFDocumentParser.DocumentError.self) {
            _ = try await PDFDocumentParser.findStartXRef(in: stream)
        }
    }

    // MARK: - Document Parser Integration Tests

    @Test("Parse minimal PDF document")
    func parseMinimalPDFDocument() async throws {
        let pdfData = createMinimalPDF()
        let stream = DataInputStream(data: pdfData)

        let parser = try await PDFDocumentParser(stream: stream)
        #expect(parser.header.versionString == "1.7")
        #expect(parser.trailer.size == 3)
    }

    // MARK: - Object Retrieval Tests

    @Test("getObject retrieves cached object")
    func getObjectRetrievesCachedObject() async throws {
        let pdfData = createMinimalPDF()
        let stream = DataInputStream(data: pdfData)
        let parser = try await PDFDocumentParser(stream: stream)

        // Object 1 should be the catalog dictionary
        let key = COSObjectKey(objectNumber: 1, generation: 0)
        let value = try await parser.getObject(key: key)
        #expect(value != nil)
        #expect(value?.isDictionary == true)
        #expect(value?.dictionaryValue?[.type]?.nameValue == ASAtom("Catalog"))
    }

    @Test("getObject returns nil for missing object")
    func getObjectReturnsNilForMissingObject() async throws {
        let pdfData = createMinimalPDF()
        let stream = DataInputStream(data: pdfData)
        let parser = try await PDFDocumentParser(stream: stream)

        // Object 999 does not exist in the xref table
        let key = COSObjectKey(objectNumber: 999, generation: 0)
        let value = try await parser.getObject(key: key)
        #expect(value == nil)
    }

    // MARK: - Error Handling Tests

    @Test("Parser errors describe failures clearly")
    func parserErrorsDescribeFailures() {
        let error1 = PDFDocumentParser.DocumentError.invalidHeader
        #expect(error1.description.contains("header"))

        let error2 = PDFDocumentParser.DocumentError.missingXRefTable
        #expect(error2.description.contains("Cross-reference"))

        let key = COSObjectKey(objectNumber: 42, generation: 0)
        let error3 = PDFDocumentParser.DocumentError.objectNotFound(key)
        #expect(error3.description.contains("42"))

        let error4 = PDFDocumentParser.DocumentError.circularReference(key)
        #expect(error4.description.contains("Circular"))
    }

    // MARK: - Property Access Tests

    @Test("COSParser conformance provides header access")
    func cosParserConformanceProvidesHeaderAccess() async throws {
        let pdfData = createMinimalPDF()
        let stream = DataInputStream(data: pdfData)
        let parser: any COSParser = try await PDFDocumentParser(stream: stream)

        #expect(parser.header.versionString == "1.7")
        #expect(parser.header.major == 1)
        #expect(parser.header.minor == 7)
    }

    @Test("COSParser conformance provides xrefTable access")
    func cosParserConformanceProvidesXRefTableAccess() async throws {
        let pdfData = createMinimalPDF()
        let stream = DataInputStream(data: pdfData)
        let parser: any COSParser = try await PDFDocumentParser(stream: stream)

        #expect(parser.xrefTable.subsectionCount == 1)
        #expect(parser.xrefTable.totalEntryCount == 3)
        #expect(parser.xrefTable.isInUse(objectNumber: 1))
        #expect(parser.xrefTable.isInUse(objectNumber: 2))
        #expect(parser.xrefTable.isFree(objectNumber: 0))
    }

    @Test("COSParser conformance provides trailer access")
    func cosParserConformanceProvidesTrailerAccess() async throws {
        let pdfData = createMinimalPDF()
        let stream = DataInputStream(data: pdfData)
        let parser: any COSParser = try await PDFDocumentParser(stream: stream)

        #expect(parser.trailer.size == 3)
        #expect(parser.trailer.rootValue != nil)
    }
}
