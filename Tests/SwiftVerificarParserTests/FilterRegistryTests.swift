import Testing
import Foundation
@testable import SwiftVerificarParser

/// A test-only mock filter factory.
private struct TestFilterFactory: PDFFilterFactory, Sendable {
    let name: String
    let supportedFilters: Set<PDFFilterName>
    let transformByte: UInt8

    func supportsFilter(_ filterName: PDFFilterName) -> Bool {
        supportedFilters.contains(filterName)
    }

    func decode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard supportsFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }
        return Data(data.map { $0 ^ transformByte })
    }

    func encode(data: Data, filterName: PDFFilterName, parameters: COSValue?) throws -> Data {
        guard supportsFilter(filterName) else {
            throw PDFStreamError.unknownFilter(filterName.description)
        }
        return Data(data.map { $0 ^ transformByte })
    }
}

/// Tests for `FilterRegistry` actor.
@Suite("FilterRegistry Tests")
struct FilterRegistryTests {

    // MARK: - Initialization

    @Test("init with default factory")
    func initDefault() async {
        let registry = FilterRegistry()
        let count = await registry.customFactoryCount
        #expect(count == 0)
    }

    @Test("init with custom default factory")
    func initCustomDefault() async {
        let custom = TestFilterFactory(
            name: "custom",
            supportedFilters: [.flateDecode],
            transformByte: 0xFF
        )
        let registry = FilterRegistry(defaultFactory: custom)
        let supports = await registry.supportsFilter(.flateDecode)
        #expect(supports == true)
    }

    // MARK: - Factory Registration

    @Test("register custom factory")
    func registerFactory() async {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("TestFilter")],
            transformByte: 0xAA
        )
        await registry.registerFactory(custom)
        let count = await registry.customFactoryCount
        #expect(count == 1)
    }

    @Test("register multiple factories")
    func registerMultiple() async {
        let registry = FilterRegistry()
        let f1 = TestFilterFactory(
            name: "f1",
            supportedFilters: [.custom("Filter1")],
            transformByte: 0x01
        )
        let f2 = TestFilterFactory(
            name: "f2",
            supportedFilters: [.custom("Filter2")],
            transformByte: 0x02
        )
        await registry.registerFactory(f1)
        await registry.registerFactory(f2)
        let count = await registry.customFactoryCount
        #expect(count == 2)
    }

    @Test("remove all custom factories")
    func removeAllCustom() async {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("TestFilter")],
            transformByte: 0xAA
        )
        await registry.registerFactory(custom)
        await registry.removeAllCustomFactories()
        let count = await registry.customFactoryCount
        #expect(count == 0)
    }

    @Test("set default factory")
    func setDefaultFactory() async {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "new-default",
            supportedFilters: [.custom("Special")],
            transformByte: 0xBB
        )
        await registry.setDefaultFactory(custom)
        let supports = await registry.supportsFilter(.custom("Special"))
        #expect(supports == true)
    }

    @Test("get default factory")
    func getDefaultFactory() async {
        let registry = FilterRegistry()
        let factory = await registry.getDefaultFactory()
        #expect(factory is DefaultFilterFactory)
    }

    // MARK: - Filter Lookup

    @Test("supports standard filter via default factory")
    func supportsStandardFilter() async {
        let registry = FilterRegistry()
        let supports = await registry.supportsFilter(.flateDecode)
        #expect(supports == true)
    }

    @Test("does not support unknown custom filter")
    func doesNotSupportUnknown() async {
        let registry = FilterRegistry()
        let supports = await registry.supportsFilter(.custom("UnknownFilter"))
        #expect(supports == false)
    }

    @Test("custom factory takes priority over default")
    func customPriority() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "custom-flate",
            supportedFilters: [.flateDecode],
            transformByte: 0xCC
        )
        await registry.registerFactory(custom)

        // The custom factory should handle FlateDecode
        let data = Data([0x01, 0x02, 0x03])
        let result = try await registry.decode(
            data: data,
            filterName: .flateDecode,
            parameters: nil
        )
        let expected = Data(data.map { $0 ^ 0xCC })
        #expect(result == expected)
    }

    @Test("factory for filter returns custom factory first")
    func factoryForFilterCustomFirst() async {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "custom",
            supportedFilters: [.flateDecode],
            transformByte: 0xDD
        )
        await registry.registerFactory(custom)
        let factory = await registry.factoryForFilter(.flateDecode)
        #expect(factory != nil)
    }

    @Test("factory for filter falls back to default")
    func factoryForFilterFallback() async {
        let registry = FilterRegistry()
        let factory = await registry.factoryForFilter(.flateDecode)
        #expect(factory != nil)
    }

    @Test("factory for filter returns nil for unsupported")
    func factoryForFilterNil() async {
        let registry = FilterRegistry()
        let factory = await registry.factoryForFilter(.custom("Nope"))
        #expect(factory == nil)
    }

    // MARK: - Decode / Encode

    @Test("decode with custom factory")
    func decodeWithCustom() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0xFF
        )
        await registry.registerFactory(custom)

        let data = Data([0x00, 0xFF, 0xAA])
        let decoded = try await registry.decode(
            data: data,
            filterName: .custom("XOR"),
            parameters: nil
        )
        #expect(decoded == Data([0xFF, 0x00, 0x55]))
    }

    @Test("encode with custom factory")
    func encodeWithCustom() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0xFF
        )
        await registry.registerFactory(custom)

        let data = Data([0x01, 0x02, 0x03])
        let encoded = try await registry.encode(
            data: data,
            filterName: .custom("XOR"),
            parameters: nil
        )
        #expect(encoded == Data([0xFE, 0xFD, 0xFC]))
    }

    @Test("decode throws for unsupported filter")
    func decodeUnsupported() async {
        let registry = FilterRegistry()
        do {
            _ = try await registry.decode(
                data: Data(),
                filterName: .custom("Nonexistent"),
                parameters: nil
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as PDFStreamError {
            if case .unknownFilter(let name) = error {
                #expect(name == "Nonexistent")
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    @Test("encode throws for unsupported filter")
    func encodeUnsupported() async {
        let registry = FilterRegistry()
        do {
            _ = try await registry.encode(
                data: Data(),
                filterName: .custom("Nonexistent"),
                parameters: nil
            )
            #expect(Bool(false), "Should have thrown")
        } catch let error as PDFStreamError {
            if case .unknownFilter(let name) = error {
                #expect(name == "Nonexistent")
            } else {
                #expect(Bool(false), "Wrong error case: \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }

    // MARK: - Decode Pipeline

    @Test("decode pipeline with single filter")
    func decodePipelineSingle() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0xAA
        )
        await registry.registerFactory(custom)

        let data = Data([0x00, 0x11])
        let decoded = try await registry.decodePipeline(
            data: data,
            filters: [.custom("XOR")],
            parameterSets: nil
        )
        #expect(decoded == Data([0xAA, 0xBB]))
    }

    @Test("decode pipeline with multiple filters from different factories")
    func decodePipelineMultiple() async throws {
        let registry = FilterRegistry()
        let f1 = TestFilterFactory(
            name: "f1",
            supportedFilters: [.custom("XOR1")],
            transformByte: 0x01
        )
        let f2 = TestFilterFactory(
            name: "f2",
            supportedFilters: [.custom("XOR2")],
            transformByte: 0x02
        )
        await registry.registerFactory(f1)
        await registry.registerFactory(f2)

        let data = Data([0x00])
        let decoded = try await registry.decodePipeline(
            data: data,
            filters: [.custom("XOR1"), .custom("XOR2")],
            parameterSets: nil
        )
        // 0x00 XOR 0x01 = 0x01, then 0x01 XOR 0x02 = 0x03
        #expect(decoded == Data([0x03]))
    }

    @Test("decode pipeline with empty filter list")
    func decodePipelineEmpty() async throws {
        let registry = FilterRegistry()
        let data = Data([0x01, 0x02, 0x03])
        let result = try await registry.decodePipeline(
            data: data,
            filters: [],
            parameterSets: nil
        )
        #expect(result == data)
    }

    // MARK: - Decode Stream

    @Test("decode stream with no filters returns encoded data")
    func decodeStreamNoFilters() async throws {
        let registry = FilterRegistry()
        let stream = COSStream(
            dictionary: [.length: .integer(3)],
            encodedData: Data([0x01, 0x02, 0x03])
        )
        let decoded = try await registry.decodeStream(stream)
        #expect(decoded == Data([0x01, 0x02, 0x03]))
    }

    @Test("decode stream with single filter")
    func decodeStreamSingleFilter() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0xFF
        )
        await registry.registerFactory(custom)

        let stream = COSStream(
            dictionary: [
                .filter: .name(ASAtom("XOR")),
                .length: .integer(2),
            ],
            encodedData: Data([0xAA, 0xBB])
        )
        let decoded = try await registry.decodeStream(stream)
        #expect(decoded == Data([0x55, 0x44]))
    }

    @Test("decode stream with filter array")
    func decodeStreamFilterArray() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0xFF
        )
        await registry.registerFactory(custom)

        let stream = COSStream(
            dictionary: [
                .filter: .array([.name(ASAtom("XOR")), .name(ASAtom("XOR"))]),
                .length: .integer(1),
            ],
            encodedData: Data([0xAA])
        )
        let decoded = try await registry.decodeStream(stream)
        // XOR twice with 0xFF is identity
        #expect(decoded == Data([0xAA]))
    }

    @Test("decode stream with decode parameters dictionary")
    func decodeStreamWithParams() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0x01
        )
        await registry.registerFactory(custom)

        let stream = COSStream(
            dictionary: [
                .filter: .name(ASAtom("XOR")),
                .decodeParms: .dictionary([.predictor: .integer(15)]),
                .length: .integer(1),
            ],
            encodedData: Data([0x10])
        )
        let decoded = try await registry.decodeStream(stream)
        #expect(decoded == Data([0x11]))
    }

    @Test("decode stream with null decode parameter in array")
    func decodeStreamWithNullParams() async throws {
        let registry = FilterRegistry()
        let custom = TestFilterFactory(
            name: "test",
            supportedFilters: [.custom("XOR")],
            transformByte: 0x01
        )
        await registry.registerFactory(custom)

        let stream = COSStream(
            dictionary: [
                .filter: .array([.name(ASAtom("XOR"))]),
                .decodeParms: .array([.null]),
                .length: .integer(1),
            ],
            encodedData: Data([0x10])
        )
        let decoded = try await registry.decodeStream(stream)
        #expect(decoded == Data([0x11]))
    }
}
