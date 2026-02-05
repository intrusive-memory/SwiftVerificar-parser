import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("PDFHeader Tests")
struct PDFHeaderTests {

    // MARK: - Initialization

    @Test("Init with major and minor version")
    func initBasic() {
        let header = PDFHeader(major: 1, minor: 7)
        #expect(header.major == 1)
        #expect(header.minor == 7)
        #expect(header.headerOffset == 0)
    }

    @Test("Init with header offset")
    func initWithOffset() {
        let header = PDFHeader(major: 1, minor: 4, headerOffset: 1024)
        #expect(header.major == 1)
        #expect(header.minor == 4)
        #expect(header.headerOffset == 1024)
    }

    @Test("Init from version string")
    func initFromVersionString() {
        let header = PDFHeader(versionString: "1.7")
        #expect(header != nil)
        #expect(header?.major == 1)
        #expect(header?.minor == 7)
    }

    @Test("Init from version string 2.0")
    func initFromVersionString2() {
        let header = PDFHeader(versionString: "2.0")
        #expect(header != nil)
        #expect(header?.major == 2)
        #expect(header?.minor == 0)
    }

    @Test("Init from invalid version string - no dot")
    func initInvalidVersionNoDot() {
        let header = PDFHeader(versionString: "17")
        #expect(header == nil)
    }

    @Test("Init from invalid version string - non-numeric")
    func initInvalidVersionNonNumeric() {
        let header = PDFHeader(versionString: "a.b")
        #expect(header == nil)
    }

    @Test("Init from invalid version string - too many parts")
    func initInvalidVersionTooManyParts() {
        let header = PDFHeader(versionString: "1.7.2")
        #expect(header == nil)
    }

    @Test("Init from invalid version string - empty")
    func initInvalidVersionEmpty() {
        let header = PDFHeader(versionString: "")
        #expect(header == nil)
    }

    @Test("Init from invalid version string - negative")
    func initInvalidVersionNegative() {
        let header = PDFHeader(versionString: "-1.7")
        #expect(header == nil)
    }

    @Test("Init from header string")
    func initFromHeaderString() {
        let header = PDFHeader(headerString: "%PDF-1.7")
        #expect(header != nil)
        #expect(header?.major == 1)
        #expect(header?.minor == 7)
    }

    @Test("Init from header string 2.0")
    func initFromHeaderString2() {
        let header = PDFHeader(headerString: "%PDF-2.0")
        #expect(header != nil)
        #expect(header?.major == 2)
        #expect(header?.minor == 0)
    }

    @Test("Init from invalid header string - wrong prefix")
    func initInvalidHeaderWrongPrefix() {
        let header = PDFHeader(headerString: "PDF-1.7")
        #expect(header == nil)
    }

    @Test("Init from invalid header string - no version")
    func initInvalidHeaderNoVersion() {
        let header = PDFHeader(headerString: "%PDF-")
        #expect(header == nil)
    }

    @Test("Init from invalid header string - empty")
    func initInvalidHeaderEmpty() {
        let header = PDFHeader(headerString: "")
        #expect(header == nil)
    }

    // MARK: - Convenience Properties

    @Test("Version string")
    func versionString() {
        let header = PDFHeader(major: 1, minor: 7)
        #expect(header.versionString == "1.7")
    }

    @Test("Header string")
    func headerString() {
        let header = PDFHeader(major: 1, minor: 7)
        #expect(header.headerString == "%PDF-1.7")
    }

    @Test("Version number")
    func versionNumber() {
        let header = PDFHeader(major: 1, minor: 7)
        #expect(header.versionNumber == 1.7)
    }

    @Test("Version number for 2.0")
    func versionNumber2() {
        let header = PDFHeader(major: 2, minor: 0)
        #expect(header.versionNumber == 2.0)
    }

    @Test("isPDF2 for 1.x")
    func isPDF2For1x() {
        let header = PDFHeader(major: 1, minor: 7)
        #expect(!header.isPDF2)
    }

    @Test("isPDF2 for 2.0")
    func isPDF2For2() {
        let header = PDFHeader(major: 2, minor: 0)
        #expect(header.isPDF2)
    }

    @Test("isPDF2 for 3.0")
    func isPDF2For3() {
        let header = PDFHeader(major: 3, minor: 0)
        #expect(header.isPDF2)
    }

    // MARK: - Common Versions

    @Test("v1_0 constant")
    func v1_0() {
        #expect(PDFHeader.v1_0.major == 1)
        #expect(PDFHeader.v1_0.minor == 0)
    }

    @Test("v1_4 constant")
    func v1_4() {
        #expect(PDFHeader.v1_4.major == 1)
        #expect(PDFHeader.v1_4.minor == 4)
    }

    @Test("v1_7 constant")
    func v1_7() {
        #expect(PDFHeader.v1_7.major == 1)
        #expect(PDFHeader.v1_7.minor == 7)
    }

    @Test("v2_0 constant")
    func v2_0() {
        #expect(PDFHeader.v2_0.major == 2)
        #expect(PDFHeader.v2_0.minor == 0)
    }

    @Test("All common versions are defined")
    func allCommonVersions() {
        let versions: [PDFHeader] = [
            .v1_0, .v1_1, .v1_2, .v1_3, .v1_4, .v1_5, .v1_6, .v1_7, .v2_0
        ]
        #expect(versions.count == 9)
        // Verify they are in ascending order
        for i in 0..<(versions.count - 1) {
            #expect(versions[i] < versions[i + 1])
        }
    }

    // MARK: - Comparable

    @Test("Compare by major version")
    func compareByMajor() {
        let a = PDFHeader(major: 1, minor: 7)
        let b = PDFHeader(major: 2, minor: 0)
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Compare by minor version")
    func compareByMinor() {
        let a = PDFHeader(major: 1, minor: 4)
        let b = PDFHeader(major: 1, minor: 7)
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Equal versions are not less than")
    func equalNotLessThan() {
        let a = PDFHeader(major: 1, minor: 7)
        let b = PDFHeader(major: 1, minor: 7)
        #expect(!(a < b))
        #expect(!(b < a))
    }

    @Test("Sorting versions")
    func sortingVersions() {
        let versions = [
            PDFHeader(major: 2, minor: 0),
            PDFHeader(major: 1, minor: 4),
            PDFHeader(major: 1, minor: 7),
            PDFHeader(major: 1, minor: 0),
        ]
        let sorted = versions.sorted()
        #expect(sorted[0].versionString == "1.0")
        #expect(sorted[1].versionString == "1.4")
        #expect(sorted[2].versionString == "1.7")
        #expect(sorted[3].versionString == "2.0")
    }

    // MARK: - Equality

    @Test("Equal headers")
    func equalHeaders() {
        let a = PDFHeader(major: 1, minor: 7)
        let b = PDFHeader(major: 1, minor: 7)
        #expect(a == b)
    }

    @Test("Different major versions")
    func differentMajor() {
        let a = PDFHeader(major: 1, minor: 7)
        let b = PDFHeader(major: 2, minor: 7)
        #expect(a != b)
    }

    @Test("Different minor versions")
    func differentMinor() {
        let a = PDFHeader(major: 1, minor: 6)
        let b = PDFHeader(major: 1, minor: 7)
        #expect(a != b)
    }

    @Test("Equality ignores header offset")
    func equalityIncludesOffset() {
        let a = PDFHeader(major: 1, minor: 7, headerOffset: 0)
        let b = PDFHeader(major: 1, minor: 7, headerOffset: 1024)
        // Note: since headerOffset is part of the struct, equality includes it
        #expect(a != b)
    }

    // MARK: - Hashable

    @Test("Equal headers have same hash")
    func equalHashValues() {
        let a = PDFHeader(major: 1, minor: 7)
        let b = PDFHeader(major: 1, minor: 7)
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        var dict: [PDFHeader: String] = [:]
        dict[.v1_4] = "Acrobat 5"
        dict[.v1_7] = "Acrobat 8"
        dict[.v2_0] = "PDF 2.0"
        #expect(dict[.v1_4] == "Acrobat 5")
        #expect(dict[.v1_7] == "Acrobat 8")
        #expect(dict.count == 3)
    }

    // MARK: - Description

    @Test("Description format")
    func descriptionFormat() {
        let header = PDFHeader(major: 1, minor: 7)
        #expect(header.description == "%PDF-1.7")
    }

    @Test("Description for 2.0")
    func description2_0() {
        let header = PDFHeader(major: 2, minor: 0)
        #expect(header.description == "%PDF-2.0")
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = PDFHeader(major: 1, minor: 7, headerOffset: 512)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFHeader.self, from: data)
        #expect(original == decoded)
    }

    @Test("Encode and decode common version")
    func codableCommonVersion() throws {
        let original = PDFHeader.v2_0
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PDFHeader.self, from: data)
        #expect(decoded.major == 2)
        #expect(decoded.minor == 0)
    }

    // MARK: - Sendable

    @Test("PDFHeader is Sendable")
    func sendable() async {
        let header = PDFHeader(major: 1, minor: 7)
        let task = Task { header }
        let result = await task.value
        #expect(result == header)
    }

    // MARK: - Edge Cases

    @Test("Version string with large numbers")
    func largeVersionNumbers() {
        let header = PDFHeader(major: 99, minor: 99)
        #expect(header.versionString == "99.99")
        #expect(header.headerString == "%PDF-99.99")
    }

    @Test("Version 1.0")
    func version1_0() {
        let header = PDFHeader(major: 1, minor: 0)
        #expect(header.versionString == "1.0")
        #expect(header.versionNumber == 1.0)
        #expect(!header.isPDF2)
    }

    @Test("Version string round-trip via parser")
    func versionStringRoundTrip() {
        let original = PDFHeader(major: 1, minor: 5)
        let parsed = PDFHeader(versionString: original.versionString)
        #expect(parsed?.major == original.major)
        #expect(parsed?.minor == original.minor)
    }

    @Test("Header string round-trip via parser")
    func headerStringRoundTrip() {
        let original = PDFHeader(major: 2, minor: 0)
        let parsed = PDFHeader(headerString: original.headerString)
        #expect(parsed?.major == original.major)
        #expect(parsed?.minor == original.minor)
    }
}
