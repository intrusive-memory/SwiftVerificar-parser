import Testing
import Foundation
@testable import SwiftVerificarParser

/// Tests for `PDFFilterName` enum, `PDFFilterFactory` protocol, and
/// `DefaultFilterFactory` struct.
@Suite("PDFFilterFactory Tests")
struct PDFFilterFactoryTests {

    // MARK: - PDFFilterName Initialization

    @Test("PDFFilterName from ASAtom - standard filters")
    func filterNameFromAtom() {
        #expect(PDFFilterName(atom: .flateDecode) == .flateDecode)
        #expect(PDFFilterName(atom: .lzwDecode) == .lzwDecode)
        #expect(PDFFilterName(atom: .ascii85Decode) == .ascii85Decode)
        #expect(PDFFilterName(atom: .asciiHexDecode) == .asciiHexDecode)
        #expect(PDFFilterName(atom: .runLengthDecode) == .runLengthDecode)
        #expect(PDFFilterName(atom: .dctDecode) == .dctDecode)
        #expect(PDFFilterName(atom: .jpxDecode) == .jpxDecode)
        #expect(PDFFilterName(atom: .ccittFaxDecode) == .ccittFaxDecode)
        #expect(PDFFilterName(atom: .crypt) == .crypt)
    }

    @Test("PDFFilterName from unknown ASAtom creates custom case")
    func filterNameFromUnknownAtom() {
        let atom = ASAtom("MyCustomFilter")
        let name = PDFFilterName(atom: atom)
        if case .custom(let str) = name {
            #expect(str == "MyCustomFilter")
        } else {
            #expect(Bool(false), "Expected .custom case")
        }
    }

    // MARK: - PDFFilterName to ASAtom

    @Test("PDFFilterName converts back to ASAtom")
    func filterNameToAtom() {
        #expect(PDFFilterName.flateDecode.atom == .flateDecode)
        #expect(PDFFilterName.lzwDecode.atom == .lzwDecode)
        #expect(PDFFilterName.ascii85Decode.atom == .ascii85Decode)
        #expect(PDFFilterName.asciiHexDecode.atom == .asciiHexDecode)
        #expect(PDFFilterName.runLengthDecode.atom == .runLengthDecode)
        #expect(PDFFilterName.dctDecode.atom == .dctDecode)
        #expect(PDFFilterName.jpxDecode.atom == .jpxDecode)
        #expect(PDFFilterName.ccittFaxDecode.atom == .ccittFaxDecode)
        #expect(PDFFilterName.crypt.atom == .crypt)
    }

    @Test("PDFFilterName custom case converts to ASAtom")
    func filterNameCustomToAtom() {
        let name = PDFFilterName.custom("MyFilter")
        #expect(name.atom == ASAtom("MyFilter"))
    }

    // MARK: - PDFFilterName Description

    @Test("PDFFilterName description matches filter name")
    func filterNameDescription() {
        #expect(PDFFilterName.flateDecode.description == "FlateDecode")
        #expect(PDFFilterName.lzwDecode.description == "LZWDecode")
        #expect(PDFFilterName.custom("Test").description == "Test")
    }

    // MARK: - PDFFilterName Hashable

    @Test("PDFFilterName equality")
    func filterNameEquality() {
        #expect(PDFFilterName.flateDecode == PDFFilterName.flateDecode)
        #expect(PDFFilterName.flateDecode != PDFFilterName.lzwDecode)
        #expect(PDFFilterName.custom("A") == PDFFilterName.custom("A"))
        #expect(PDFFilterName.custom("A") != PDFFilterName.custom("B"))
    }

    @Test("PDFFilterName can be used in sets")
    func filterNameSet() {
        let filters: Set<PDFFilterName> = [
            .flateDecode,
            .lzwDecode,
            .flateDecode,  // duplicate
        ]
        #expect(filters.count == 2)
    }

    // MARK: - PDFFilterName Sendable

    @Test("PDFFilterName is Sendable")
    func filterNameSendable() {
        let name: any Sendable = PDFFilterName.flateDecode
        #expect(name is PDFFilterName)
    }

    // MARK: - DefaultFilterFactory

    @Test("DefaultFilterFactory supports standard filters")
    func defaultFactorySupportsStandard() {
        let factory = DefaultFilterFactory()
        #expect(factory.supportsFilter(.flateDecode))
        #expect(factory.supportsFilter(.lzwDecode))
        #expect(factory.supportsFilter(.ascii85Decode))
        #expect(factory.supportsFilter(.asciiHexDecode))
        #expect(factory.supportsFilter(.runLengthDecode))
        #expect(factory.supportsFilter(.dctDecode))
        #expect(factory.supportsFilter(.jpxDecode))
        #expect(factory.supportsFilter(.ccittFaxDecode))
        #expect(factory.supportsFilter(.crypt))
    }

    @Test("DefaultFilterFactory does not support custom filters")
    func defaultFactoryDoesNotSupportCustom() {
        let factory = DefaultFilterFactory()
        #expect(!factory.supportsFilter(.custom("MyFilter")))
    }

    @Test("DefaultFilterFactory decode throws for unknown filter")
    func defaultFactoryDecodeUnknown() {
        let factory = DefaultFilterFactory()
        #expect(throws: PDFStreamError.unknownFilter("MyFilter")) {
            _ = try factory.decode(
                data: Data(),
                filterName: .custom("MyFilter"),
                parameters: nil
            )
        }
    }

    @Test("DefaultFilterFactory encode throws for unknown filter")
    func defaultFactoryEncodeUnknown() {
        let factory = DefaultFilterFactory()
        #expect(throws: PDFStreamError.unknownFilter("MyFilter")) {
            _ = try factory.encode(
                data: Data(),
                filterName: .custom("MyFilter"),
                parameters: nil
            )
        }
    }

    @Test("DefaultFilterFactory decode throws for unimplemented filter")
    func defaultFactoryDecodeUnimplemented() {
        let factory = DefaultFilterFactory()
        // CCITTFaxDecode is recognized but not yet implemented
        #expect(throws: (any Error).self) {
            _ = try factory.decode(
                data: Data([0x01, 0x02]),
                filterName: .ccittFaxDecode,
                parameters: nil
            )
        }
    }

    @Test("DefaultFilterFactory encode throws for unimplemented filter")
    func defaultFactoryEncodeUnimplemented() {
        let factory = DefaultFilterFactory()
        // CCITTFaxDecode is recognized but not yet implemented
        #expect(throws: (any Error).self) {
            _ = try factory.encode(
                data: Data([0x01, 0x02]),
                filterName: .ccittFaxDecode,
                parameters: nil
            )
        }
    }

    // MARK: - DefaultFilterFactory Hashable

    @Test("DefaultFilterFactory equality")
    func defaultFactoryEquality() {
        let factory1 = DefaultFilterFactory()
        let factory2 = DefaultFilterFactory()
        #expect(factory1 == factory2)
    }

    // MARK: - DefaultFilterFactory Sendable

    @Test("DefaultFilterFactory is Sendable")
    func defaultFactorySendable() {
        let factory: any Sendable = DefaultFilterFactory()
        #expect(factory is DefaultFilterFactory)
    }

    // MARK: - Pipeline

    @Test("decodePipeline with empty filter list returns data unchanged")
    func decodePipelineEmpty() throws {
        let factory = DefaultFilterFactory()
        let data = Data([0x01, 0x02, 0x03])
        let result = try factory.decodePipeline(data: data, filters: [], parameterSets: nil)
        #expect(result == data)
    }

    @Test("decodePipeline with nil parameters")
    func decodePipelineNilParams() {
        let factory = DefaultFilterFactory()
        // Pipeline with an actual filter will throw since not implemented
        #expect(throws: (any Error).self) {
            _ = try factory.decodePipeline(
                data: Data([0x01]),
                filters: [.flateDecode],
                parameterSets: nil
            )
        }
    }
}

// MARK: - Mock Filter Factory for Protocol Tests

/// A simple mock filter factory for testing the `PDFFilterFactory` protocol.
private struct MockFilterFactory: PDFFilterFactory, Sendable {
    let supportedFilter: PDFFilterName
    let transformByte: UInt8

    func supportsFilter(_ filterName: PDFFilterName) -> Bool {
        filterName == supportedFilter
    }

    func decode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard supportsFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }
        // Simple transform: XOR each byte
        return Data(data.map { $0 ^ transformByte })
    }

    func encode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard supportsFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }
        return Data(data.map { $0 ^ transformByte })
    }
}

/// Tests for the `PDFFilterFactory` protocol using a mock implementation.
@Suite("PDFFilterFactory Protocol Tests")
struct PDFFilterFactoryProtocolTests {

    @Test("mock factory decode and encode are inverse")
    func mockRoundTrip() throws {
        let factory = MockFilterFactory(supportedFilter: .flateDecode, transformByte: 0xFF)
        let original = Data([0x01, 0x02, 0x03])
        let encoded = try factory.encode(data: original, filterName: .flateDecode, parameters: nil)
        let decoded = try factory.decode(data: encoded, filterName: .flateDecode, parameters: nil)
        #expect(decoded == original)
    }

    @Test("mock factory pipeline with multiple filters")
    func mockPipeline() throws {
        let factory = MockFilterFactory(supportedFilter: .flateDecode, transformByte: 0xFF)
        let original = Data([0x01, 0x02])
        // Two passes of XOR 0xFF is identity
        let result = try factory.decodePipeline(
            data: original,
            filters: [.flateDecode, .flateDecode],
            parameterSets: nil
        )
        #expect(result == original)
    }

    @Test("mock factory rejects unsupported filter")
    func mockUnsupported() {
        let factory = MockFilterFactory(supportedFilter: .flateDecode, transformByte: 0xFF)
        #expect(throws: PDFStreamError.unknownFilter("LZWDecode")) {
            _ = try factory.decode(data: Data(), filterName: .lzwDecode, parameters: nil)
        }
    }

    @Test("pipeline with parameters passes to each filter")
    func pipelineWithParameters() throws {
        let factory = MockFilterFactory(supportedFilter: .flateDecode, transformByte: 0xAA)
        let data = Data([0x00])
        let params: [COSValue?] = [.integer(42)]
        let result = try factory.decodePipeline(
            data: data,
            filters: [.flateDecode],
            parameterSets: params
        )
        #expect(result == Data([0xAA]))
    }
}
