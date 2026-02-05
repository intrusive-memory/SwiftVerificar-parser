import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `PDFStreamError` enum.
@Suite("PDFStreamError Tests")
struct PDFStreamErrorTests {

    // MARK: - Case Construction

    @Test("streamClosed case")
    func streamClosed() {
        let error = PDFStreamError.streamClosed
        #expect(error.description == "Stream is closed")
    }

    @Test("endOfStream case")
    func endOfStream() {
        let error = PDFStreamError.endOfStream
        #expect(error.description == "End of stream reached")
    }

    @Test("invalidSeekPosition case")
    func invalidSeekPosition() {
        let error = PDFStreamError.invalidSeekPosition(42)
        #expect(error.description == "Invalid seek position: 42")
    }

    @Test("invalidSeekPosition with negative position")
    func invalidSeekPositionNegative() {
        let error = PDFStreamError.invalidSeekPosition(-1)
        #expect(error.description == "Invalid seek position: -1")
    }

    @Test("unsupportedOperation case")
    func unsupportedOperation() {
        let error = PDFStreamError.unsupportedOperation("write")
        #expect(error.description == "Unsupported operation: write")
    }

    @Test("ioError case")
    func ioError() {
        let error = PDFStreamError.ioError("disk full")
        #expect(error.description == "I/O error: disk full")
    }

    @Test("unknownFilter case")
    func unknownFilter() {
        let error = PDFStreamError.unknownFilter("CustomFilter")
        #expect(error.description == "Unknown filter: CustomFilter")
    }

    @Test("filterError case")
    func filterError() {
        let error = PDFStreamError.filterError("invalid data")
        #expect(error.description == "Filter error: invalid data")
    }

    // MARK: - Hashable Conformance

    @Test("equal errors are hashable")
    func hashableConformance() {
        let error1 = PDFStreamError.streamClosed
        let error2 = PDFStreamError.streamClosed
        #expect(error1 == error2)
        #expect(error1.hashValue == error2.hashValue)
    }

    @Test("different errors are not equal")
    func differentErrors() {
        let error1 = PDFStreamError.streamClosed
        let error2 = PDFStreamError.endOfStream
        #expect(error1 != error2)
    }

    @Test("errors with different associated values are not equal")
    func differentAssociatedValues() {
        let error1 = PDFStreamError.invalidSeekPosition(10)
        let error2 = PDFStreamError.invalidSeekPosition(20)
        #expect(error1 != error2)
    }

    @Test("errors can be used in sets")
    func setUsage() {
        let errors: Set<PDFStreamError> = [
            .streamClosed,
            .endOfStream,
            .streamClosed,
        ]
        #expect(errors.count == 2)
    }

    // MARK: - Sendable Conformance

    @Test("PDFStreamError is Sendable")
    func isSendable() {
        let error: any Sendable = PDFStreamError.streamClosed
        #expect(error is PDFStreamError)
    }

    // MARK: - Error Conformance

    @Test("PDFStreamError conforms to Error")
    func conformsToError() {
        let error: any Error = PDFStreamError.ioError("test")
        #expect(error is PDFStreamError)
    }
}
