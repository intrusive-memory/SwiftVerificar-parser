import Testing
@testable import SwiftVerificarParser

@Suite("PDFContentStream Tests")
struct PDFContentStreamTests {

    // MARK: - Initialization Tests

    @Test("PDFContentStream accepts reference")
    func acceptsReference() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        #expect(stream.cosObject.isReference)
    }

    @Test("PDFContentStream accepts dictionary")
    func acceptsDictionary() throws {
        let dict: COSValue = [.length: .integer(100)]
        let stream = try PDFContentStream(cosObject: dict)
        #expect(stream.cosObject.isDictionary)
    }

    @Test("PDFContentStream accepts array")
    func acceptsArray() throws {
        let array: COSValue = .array([
            .reference(COSReference(objectNumber: 10)),
            .reference(COSReference(objectNumber: 11))
        ])
        let stream = try PDFContentStream(cosObject: array)
        #expect(stream.cosObject.isArray)
    }

    // MARK: - Type Detection Tests

    @Test("isArray detects array")
    func isArrayDetection() throws {
        let array: COSValue = .array([.reference(COSReference(objectNumber: 10))])
        let stream = try PDFContentStream(cosObject: array)
        #expect(stream.isArray == true)
        #expect(stream.isReference == false)
        #expect(stream.isDictionary == false)
    }

    @Test("isReference detects reference")
    func isReferenceDetection() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        #expect(stream.isArray == false)
        #expect(stream.isReference == true)
        #expect(stream.isDictionary == false)
    }

    @Test("isDictionary detects dictionary")
    func isDictionaryDetection() throws {
        let dict: COSValue = [.length: .integer(100)]
        let stream = try PDFContentStream(cosObject: dict)
        #expect(stream.isArray == false)
        #expect(stream.isReference == false)
        #expect(stream.isDictionary == true)
    }

    // MARK: - Stream Count Tests

    @Test("streamCount returns 1 for single stream")
    func streamCountSingle() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        #expect(stream.streamCount == 1)
    }

    @Test("streamCount returns array length for multiple streams")
    func streamCountMultiple() throws {
        let array: COSValue = .array([
            .reference(COSReference(objectNumber: 10)),
            .reference(COSReference(objectNumber: 11)),
            .reference(COSReference(objectNumber: 12))
        ])
        let stream = try PDFContentStream(cosObject: array)
        #expect(stream.streamCount == 3)
    }

    @Test("streamCount returns 0 for empty array")
    func streamCountEmpty() throws {
        let array: COSValue = .array([])
        let stream = try PDFContentStream(cosObject: array)
        #expect(stream.streamCount == 0)
    }

    // MARK: - Stream Access Tests

    @Test("stream at index returns single stream")
    func streamAtIndexSingle() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        let s = try stream.stream(at: 0)
        #expect(s.referenceValue?.objectNumber == 10)
    }

    @Test("stream at index throws for out of bounds single stream")
    func streamAtIndexOutOfBoundsSingle() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        #expect(throws: (any Error).self) {
            try stream.stream(at: 1)
        }
    }

    @Test("stream at index returns correct stream from array")
    func streamAtIndexArray() throws {
        let array: COSValue = .array([
            .reference(COSReference(objectNumber: 10)),
            .reference(COSReference(objectNumber: 11)),
            .reference(COSReference(objectNumber: 12))
        ])
        let stream = try PDFContentStream(cosObject: array)

        let s0 = try stream.stream(at: 0)
        #expect(s0.referenceValue?.objectNumber == 10)

        let s1 = try stream.stream(at: 1)
        #expect(s1.referenceValue?.objectNumber == 11)

        let s2 = try stream.stream(at: 2)
        #expect(s2.referenceValue?.objectNumber == 12)
    }

    @Test("stream at index throws for out of bounds array")
    func streamAtIndexOutOfBoundsArray() throws {
        let array: COSValue = .array([
            .reference(COSReference(objectNumber: 10)),
            .reference(COSReference(objectNumber: 11))
        ])
        let stream = try PDFContentStream(cosObject: array)
        #expect(throws: (any Error).self) {
            try stream.stream(at: 5)
        }
    }

    // MARK: - All Streams Tests

    @Test("allStreams returns single stream in array")
    func allStreamsSingle() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        let all = stream.allStreams()
        #expect(all.count == 1)
        #expect(all[0].referenceValue?.objectNumber == 10)
    }

    @Test("allStreams returns all streams from array")
    func allStreamsArray() throws {
        let array: COSValue = .array([
            .reference(COSReference(objectNumber: 10)),
            .reference(COSReference(objectNumber: 11)),
            .reference(COSReference(objectNumber: 12))
        ])
        let stream = try PDFContentStream(cosObject: array)
        let all = stream.allStreams()
        #expect(all.count == 3)
        #expect(all[0].referenceValue?.objectNumber == 10)
        #expect(all[1].referenceValue?.objectNumber == 11)
        #expect(all[2].referenceValue?.objectNumber == 12)
    }

    @Test("allStreams returns empty array")
    func allStreamsEmpty() throws {
        let array: COSValue = .array([])
        let stream = try PDFContentStream(cosObject: array)
        let all = stream.allStreams()
        #expect(all.isEmpty)
    }

    // MARK: - Single Stream Object Tests

    @Test("singleStreamObject returns stream for single reference")
    func singleStreamObjectReference() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        let single = try stream.singleStreamObject()
        #expect(single.referenceValue?.objectNumber == 10)
    }

    @Test("singleStreamObject returns stream for dictionary")
    func singleStreamObjectDictionary() throws {
        let dict: COSValue = [.length: .integer(100)]
        let stream = try PDFContentStream(cosObject: dict)
        let single = try stream.singleStreamObject()
        #expect(single.isDictionary)
    }

    @Test("singleStreamObject throws for array")
    func singleStreamObjectThrowsForArray() throws {
        let array: COSValue = .array([
            .reference(COSReference(objectNumber: 10)),
            .reference(COSReference(objectNumber: 11))
        ])
        let stream = try PDFContentStream(cosObject: array)
        #expect(throws: (any Error).self) {
            try stream.singleStreamObject()
        }
    }

    // MARK: - isEmpty Tests

    @Test("isEmpty returns false for single stream")
    func isEmptyFalseSingle() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream = try PDFContentStream(cosObject: ref)
        #expect(stream.isEmpty == false)
    }

    @Test("isEmpty returns false for non-empty array")
    func isEmptyFalseArray() throws {
        let array: COSValue = .array([.reference(COSReference(objectNumber: 10))])
        let stream = try PDFContentStream(cosObject: array)
        #expect(stream.isEmpty == false)
    }

    @Test("isEmpty returns true for empty array")
    func isEmptyTrueArray() throws {
        let array: COSValue = .array([])
        let stream = try PDFContentStream(cosObject: array)
        #expect(stream.isEmpty == true)
    }

    // MARK: - Hashable Tests

    @Test("PDFContentStream is hashable")
    func hashable() throws {
        let ref: COSValue = .reference(COSReference(objectNumber: 10))
        let stream1 = try PDFContentStream(cosObject: ref)
        let stream2 = try PDFContentStream(cosObject: ref)

        #expect(stream1 == stream2)
        #expect(stream1.hashValue == stream2.hashValue)
    }

    @Test("different streams have different hashes")
    func differentStreamsDifferentHashes() throws {
        let ref1: COSValue = .reference(COSReference(objectNumber: 10))
        let ref2: COSValue = .reference(COSReference(objectNumber: 11))
        let stream1 = try PDFContentStream(cosObject: ref1)
        let stream2 = try PDFContentStream(cosObject: ref2)

        #expect(stream1 != stream2)
    }
}
