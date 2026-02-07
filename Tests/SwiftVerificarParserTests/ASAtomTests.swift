import Testing
import Foundation
@testable import SwiftVerificarParser

@Suite("ASAtom Tests")
struct ASAtomTests {

    // MARK: - Initialization

    @Test("Init from string")
    func initFromString() {
        let atom = ASAtom("Type")
        #expect(atom.stringValue == "Type")
    }

    @Test("Init from string literal")
    func initFromStringLiteral() {
        let atom: ASAtom = "Subtype"
        #expect(atom.stringValue == "Subtype")
    }

    @Test("Init from raw value")
    func initFromRawValue() {
        let atom = ASAtom(rawValue: "Font")
        #expect(atom.rawValue == "Font")
    }

    @Test("Empty atom")
    func emptyAtom() {
        let atom = ASAtom("")
        #expect(atom.isEmpty)
        #expect(atom.stringValue == "")
    }

    @Test("Non-empty atom")
    func nonEmptyAtom() {
        let atom = ASAtom("Type")
        #expect(!atom.isEmpty)
    }

    // MARK: - Equality

    @Test("Identical atoms are equal")
    func identicalAtomsEqual() {
        let a = ASAtom("Type")
        let b = ASAtom("Type")
        #expect(a == b)
    }

    @Test("Different atoms are not equal")
    func differentAtomsNotEqual() {
        let a = ASAtom("Type")
        let b = ASAtom("Subtype")
        #expect(a != b)
    }

    @Test("String literal equality")
    func stringLiteralEquality() {
        let atom = ASAtom("Type")
        let literal: ASAtom = "Type"
        #expect(atom == literal)
    }

    @Test("Predefined atom equals manually created")
    func predefinedEqualsManual() {
        #expect(ASAtom.type == ASAtom("Type"))
        #expect(ASAtom.subtype == ASAtom("Subtype"))
        #expect(ASAtom.bbox == ASAtom("BBox"))
        #expect(ASAtom.font == ASAtom("Font"))
    }

    // MARK: - Hashable

    @Test("Equal atoms have same hash")
    func equalAtomsHaveSameHash() {
        let a = ASAtom("Type")
        let b = ASAtom("Type")
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Can be used as dictionary key")
    func dictionaryKey() {
        var dict: [ASAtom: String] = [:]
        dict[.type] = "Type"
        dict[.subtype] = "Subtype"
        #expect(dict[.type] == "Type")
        #expect(dict[.subtype] == "Subtype")
        #expect(dict.count == 2)
    }

    @Test("Can be stored in a Set")
    func storedInSet() {
        let set: Set<ASAtom> = [.type, .subtype, .type, .font]
        #expect(set.count == 3)
        #expect(set.contains(.type))
        #expect(set.contains(.subtype))
        #expect(set.contains(.font))
    }

    // MARK: - Comparable

    @Test("Comparable ordering")
    func comparableOrdering() {
        let a = ASAtom("Apple")
        let b = ASAtom("Banana")
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test("Sorting atoms")
    func sortingAtoms() {
        let atoms: [ASAtom] = ["Zebra", "Apple", "Mango"]
        let sorted = atoms.sorted()
        #expect(sorted.map(\.stringValue) == ["Apple", "Mango", "Zebra"])
    }

    // MARK: - Description

    @Test("Description includes leading slash")
    func descriptionHasSlash() {
        let atom = ASAtom("Type")
        #expect(atom.description == "/Type")
    }

    @Test("Empty atom description")
    func emptyDescription() {
        let atom = ASAtom("")
        #expect(atom.description == "/")
    }

    // MARK: - Codable

    @Test("Encode and decode round-trip")
    func codableRoundTrip() throws {
        let original = ASAtom("MediaBox")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ASAtom.self, from: data)
        #expect(original == decoded)
    }

    @Test("Encode predefined atom")
    func encodePredefined() throws {
        let data = try JSONEncoder().encode(ASAtom.type)
        let decoded = try JSONDecoder().decode(ASAtom.self, from: data)
        #expect(decoded == .type)
    }

    // MARK: - Predefined Atoms Exist

    @Test("Document structure atoms")
    func documentStructureAtoms() {
        #expect(ASAtom.type.stringValue == "Type")
        #expect(ASAtom.subtype.stringValue == "Subtype")
        #expect(ASAtom.pages.stringValue == "Pages")
        #expect(ASAtom.page.stringValue == "Page")
        #expect(ASAtom.catalog.stringValue == "Catalog")
        #expect(ASAtom.count.stringValue == "Count")
        #expect(ASAtom.kids.stringValue == "Kids")
        #expect(ASAtom.parent.stringValue == "Parent")
        #expect(ASAtom.root.stringValue == "Root")
        #expect(ASAtom.info.stringValue == "Info")
        #expect(ASAtom.size.stringValue == "Size")
        #expect(ASAtom.prev.stringValue == "Prev")
    }

    @Test("Content and resource atoms")
    func contentResourceAtoms() {
        #expect(ASAtom.contents.stringValue == "Contents")
        #expect(ASAtom.resources.stringValue == "Resources")
        #expect(ASAtom.mediaBox.stringValue == "MediaBox")
        #expect(ASAtom.cropBox.stringValue == "CropBox")
        #expect(ASAtom.bbox.stringValue == "BBox")
        #expect(ASAtom.matrix.stringValue == "Matrix")
    }

    @Test("Font atoms")
    func fontAtoms() {
        #expect(ASAtom.font.stringValue == "Font")
        #expect(ASAtom.baseFont.stringValue == "BaseFont")
        #expect(ASAtom.encoding.stringValue == "Encoding")
        #expect(ASAtom.toUnicode.stringValue == "ToUnicode")
        #expect(ASAtom.fontDescriptor.stringValue == "FontDescriptor")
        #expect(ASAtom.descendantFonts.stringValue == "DescendantFonts")
    }

    @Test("Filter atoms")
    func filterAtoms() {
        #expect(ASAtom.flateDecode.stringValue == "FlateDecode")
        #expect(ASAtom.lzwDecode.stringValue == "LZWDecode")
        #expect(ASAtom.ascii85Decode.stringValue == "ASCII85Decode")
        #expect(ASAtom.asciiHexDecode.stringValue == "ASCIIHexDecode")
        #expect(ASAtom.runLengthDecode.stringValue == "RunLengthDecode")
    }

    @Test("Color space atoms")
    func colorSpaceAtoms() {
        #expect(ASAtom.deviceGray.stringValue == "DeviceGray")
        #expect(ASAtom.deviceRGB.stringValue == "DeviceRGB")
        #expect(ASAtom.deviceCMYK.stringValue == "DeviceCMYK")
        #expect(ASAtom.iccBased.stringValue == "ICCBased")
        #expect(ASAtom.separation.stringValue == "Separation")
    }

    @Test("Structure tree atoms")
    func structureTreeAtoms() {
        #expect(ASAtom.structTreeRoot.stringValue == "StructTreeRoot")
        #expect(ASAtom.markInfo.stringValue == "MarkInfo")
        #expect(ASAtom.k.stringValue == "K")
        #expect(ASAtom.pg.stringValue == "Pg")
        #expect(ASAtom.lang.stringValue == "Lang")
        #expect(ASAtom.alt.stringValue == "Alt")
        #expect(ASAtom.actualText.stringValue == "ActualText")
        #expect(ASAtom.roleMap.stringValue == "RoleMap")
    }

    // MARK: - RawRepresentable

    @Test("RawRepresentable conformance")
    func rawRepresentable() {
        let atom = ASAtom(rawValue: "Test")
        #expect(atom.rawValue == "Test")
        #expect(atom.stringValue == "Test")
    }

    // MARK: - Sendable

    @Test("ASAtom is Sendable")
    func sendable() async {
        let atom = ASAtom("Type")
        let task = Task { atom }
        let result = await task.value
        #expect(result == atom)
    }

    // MARK: - Case sensitivity

    @Test("Atoms are case-sensitive")
    func caseSensitive() {
        let upper = ASAtom("Type")
        let lower = ASAtom("type")
        #expect(upper != lower)
    }

    // MARK: - Special characters

    @Test("Atom with special characters")
    func specialCharacters() {
        let atom = ASAtom("Adobe#20Illustrator")
        #expect(atom.stringValue == "Adobe#20Illustrator")
    }

    @Test("Atom with Unicode")
    func unicodeAtom() {
        let atom = ASAtom("Test\u{00E9}")
        #expect(atom.stringValue == "Test\u{00E9}")
    }
}
