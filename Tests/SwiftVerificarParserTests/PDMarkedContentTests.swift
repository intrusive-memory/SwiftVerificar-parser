import Testing
@testable import SwiftVerificarParser

@Suite("PDMarkedContent Tests")
struct PDMarkedContentTests {

    // MARK: - Initialization Tests

    @Test("Initialize with tag only")
    func testInitializeWithTagOnly() {
        let mc = PDMarkedContent(tag: ASAtom("Artifact"))
        #expect(mc.tag == ASAtom("Artifact"))
        #expect(mc.properties == nil)
        #expect(!mc.hasProperties)
    }

    @Test("Initialize with tag and properties")
    func testInitializeWithTagAndProperties() {
        let props: COSValue = .dictionary([ASAtom("MCID"): .integer(5)])
        let mc = PDMarkedContent(tag: ASAtom("Span"), properties: props)
        #expect(mc.tag == ASAtom("Span"))
        #expect(mc.properties == props)
        #expect(mc.hasProperties)
    }

    @Test("Initialize with tag and MCID")
    func testInitializeWithTagAndMCID() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 42)
        #expect(mc.tag == ASAtom("P"))
        #expect(mc.mcid == 42)
        #expect(mc.hasProperties)
        #expect(mc.isStructureReference)
    }

    // MARK: - MCID Tests

    @Test("Get MCID from properties")
    func testGetMCIDFromProperties() {
        let props: COSValue = .dictionary([ASAtom("MCID"): .integer(10)])
        let mc = PDMarkedContent(tag: ASAtom("Span"), properties: props)
        #expect(mc.mcid == 10)
    }

    @Test("MCID is nil when not present")
    func testMCIDIsNilWhenNotPresent() {
        let mc = PDMarkedContent(tag: ASAtom("Artifact"))
        #expect(mc.mcid == nil)
    }

    @Test("MCID is nil with non-dictionary properties")
    func testMCIDIsNilWithNonDictionaryProperties() {
        let props: COSValue = .array([.integer(5)])
        let mc = PDMarkedContent(tag: ASAtom("Span"), properties: props)
        #expect(mc.mcid == nil)
    }

    // MARK: - Language Tests

    @Test("Get language from properties")
    func testGetLanguageFromProperties() {
        let props: COSValue = .dictionary([.lang: .string(COSString("fr-FR"))])
        let mc = PDMarkedContent(tag: ASAtom("Span"), properties: props)
        #expect(mc.language == "fr-FR")
    }

    @Test("Language is nil when not present")
    func testLanguageIsNilWhenNotPresent() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        #expect(mc.language == nil)
    }

    // MARK: - Actual Text Tests

    @Test("Get actual text from properties")
    func testGetActualTextFromProperties() {
        let props: COSValue = .dictionary([.actualText: .string(COSString("Logo"))])
        let mc = PDMarkedContent(tag: ASAtom("Figure"), properties: props)
        #expect(mc.actualText == "Logo")
    }

    @Test("Actual text is nil when not present")
    func testActualTextIsNilWhenNotPresent() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        #expect(mc.actualText == nil)
    }

    // MARK: - Alternate Description Tests

    @Test("Get alternate description from properties")
    func testGetAlternateDescriptionFromProperties() {
        let props: COSValue = .dictionary([.alt: .string(COSString("Company logo"))])
        let mc = PDMarkedContent(tag: ASAtom("Figure"), properties: props)
        #expect(mc.alternateDescription == "Company logo")
    }

    @Test("Alternate description is nil when not present")
    func testAlternateDescriptionIsNilWhenNotPresent() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        #expect(mc.alternateDescription == nil)
    }

    // MARK: - Expanded Form Tests

    @Test("Get expanded form from properties")
    func testGetExpandedFormFromProperties() {
        let props: COSValue = .dictionary([.e: .string(COSString("United States"))])
        let mc = PDMarkedContent(tag: ASAtom("Span"), properties: props)
        #expect(mc.expandedForm == "United States")
    }

    @Test("Expanded form is nil when not present")
    func testExpandedFormIsNilWhenNotPresent() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        #expect(mc.expandedForm == nil)
    }

    // MARK: - Artifact Detection Tests

    @Test("Detect artifact")
    func testDetectArtifact() {
        let mc = PDMarkedContent(tag: ASAtom("Artifact"))
        #expect(mc.isArtifact)
    }

    @Test("Non-artifact content")
    func testNonArtifactContent() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        #expect(!mc.isArtifact)
    }

    // MARK: - Structure Reference Detection Tests

    @Test("Detect structure reference with MCID")
    func testDetectStructureReferenceWithMCID() {
        let mc = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        #expect(mc.isStructureReference)
    }

    @Test("Not a structure reference without MCID")
    func testNotAStructureReferenceWithoutMCID() {
        let mc = PDMarkedContent(tag: ASAtom("Artifact"))
        #expect(!mc.isStructureReference)
    }

    // MARK: - Complete Properties Tests

    @Test("Marked content with all properties")
    func testMarkedContentWithAllProperties() {
        let props: COSValue = .dictionary([
            ASAtom("MCID"): .integer(7),
            .lang: .string(COSString("en-GB")),
            .actualText: .string(COSString("Actual")),
            .alt: .string(COSString("Alternative")),
            .e: .string(COSString("Expanded"))
        ])
        let mc = PDMarkedContent(tag: ASAtom("Span"), properties: props)

        #expect(mc.tag == ASAtom("Span"))
        #expect(mc.mcid == 7)
        #expect(mc.language == "en-GB")
        #expect(mc.actualText == "Actual")
        #expect(mc.alternateDescription == "Alternative")
        #expect(mc.expandedForm == "Expanded")
        #expect(mc.hasProperties)
        #expect(mc.isStructureReference)
        #expect(!mc.isArtifact)
    }

    // MARK: - Hashable Tests

    @Test("PDMarkedContent is hashable")
    func testPDMarkedContentIsHashable() {
        let mc1 = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        let mc2 = PDMarkedContent(tag: ASAtom("P"), mcid: 5)

        #expect(mc1 == mc2)
        #expect(mc1.hashValue == mc2.hashValue)
    }

    @Test("Different PDMarkedContent instances are not equal")
    func testDifferentPDMarkedContentInstancesAreNotEqual() {
        let mc1 = PDMarkedContent(tag: ASAtom("P"), mcid: 5)
        let mc2 = PDMarkedContent(tag: ASAtom("P"), mcid: 6)

        #expect(mc1 != mc2)
    }
}

@Suite("PDMarkedContentReference Tests")
struct PDMarkedContentReferenceTests {

    // MARK: - Initialization Tests

    @Test("Initialize from dictionary")
    func testInitializeFromDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("MCR")),
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.cosObject.isDictionary)
    }

    @Test("Initialize fails with non-dictionary")
    func testInitializeFailsWithNonDictionary() {
        #expect(throws: PDError.notADictionary) {
            _ = try PDMarkedContentReference(cosObject: .null)
        }
        #expect(throws: PDError.notADictionary) {
            _ = try PDMarkedContentReference(cosObject: .integer(42))
        }
    }

    // MARK: - Type Entry Tests

    @Test("Get type entry")
    func testGetTypeEntry() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("MCR")),
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.type == ASAtom("MCR"))
    }

    @Test("Type entry is optional")
    func testTypeEntryIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.type == nil)
    }

    // MARK: - Page Tests

    @Test("Get page reference")
    func testGetPageReference() throws {
        let pageRef = COSReference(objectNumber: 10, generation: 0)
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5),
            .pg: .reference(pageRef)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.page == .reference(pageRef))
    }

    @Test("Page is optional")
    func testPageIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.page == nil)
    }

    // MARK: - MCID Tests

    @Test("Get MCID")
    func testGetMCID() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(42)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        let mcid = try mcr.mcid()
        #expect(mcid == 42)
    }

    @Test("MCID is required")
    func testMCIDIsRequired() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("MCR"))
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(throws: PDError.missingRequiredEntry(key: "MCID")) {
            _ = try mcr.mcid()
        }
    }

    @Test("Various MCID values")
    func testVariousMCIDValues() throws {
        let mcidValues: [Int64] = [0, 1, 10, 100, 999, 12345]

        for mcidValue in mcidValues {
            let dict: [ASAtom: COSValue] = [
                ASAtom("MCID"): .integer(mcidValue)
            ]
            let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
            #expect(try mcr.mcid() == mcidValue)
        }
    }

    // MARK: - Stream Tests

    @Test("Get stream reference")
    func testGetStreamReference() throws {
        let streamRef = COSReference(objectNumber: 15, generation: 0)
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5),
            ASAtom("Stm"): .reference(streamRef)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.stream == .reference(streamRef))
    }

    @Test("Stream is optional")
    func testStreamIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.stream == nil)
    }

    // MARK: - Stream Owner Tests

    @Test("Get stream owner reference")
    func testGetStreamOwnerReference() throws {
        let ownerRef = COSReference(objectNumber: 20, generation: 0)
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5),
            ASAtom("StmOwn"): .reference(ownerRef)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.streamOwner == .reference(ownerRef))
    }

    @Test("Stream owner is optional")
    func testStreamOwnerIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.streamOwner == nil)
    }

    // MARK: - Validation Tests

    @Test("Validate with MCID")
    func testValidateWithMCID() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(mcr.validate())
    }

    @Test("Validate fails without MCID")
    func testValidateFailsWithoutMCID() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("MCR"))
        ]
        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))
        #expect(!mcr.validate())
    }

    // MARK: - Complete MCR Tests

    @Test("Complete marked content reference")
    func testCompleteMarkedContentReference() throws {
        let pageRef = COSReference(objectNumber: 10, generation: 0)
        let streamRef = COSReference(objectNumber: 15, generation: 0)

        let dict: [ASAtom: COSValue] = [
            .type: .name(ASAtom("MCR")),
            .pg: .reference(pageRef),
            ASAtom("MCID"): .integer(7),
            ASAtom("Stm"): .reference(streamRef)
        ]

        let mcr = try PDMarkedContentReference(cosObject: .dictionary(dict))

        #expect(mcr.type == ASAtom("MCR"))
        #expect(try mcr.mcid() == 7)
        #expect(mcr.page == .reference(pageRef))
        #expect(mcr.stream == .reference(streamRef))
        #expect(mcr.validate())
    }

    // MARK: - Hashable Tests

    @Test("PDMarkedContentReference is hashable")
    func testPDMarkedContentReferenceIsHashable() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let mcr1 = try PDMarkedContentReference(cosObject: .dictionary(dict))
        let mcr2 = try PDMarkedContentReference(cosObject: .dictionary(dict))

        #expect(mcr1 == mcr2)
        #expect(mcr1.hashValue == mcr2.hashValue)
    }

    @Test("Different PDMarkedContentReference instances are not equal")
    func testDifferentPDMarkedContentReferenceInstancesAreNotEqual() throws {
        let dict1: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(5)
        ]
        let dict2: [ASAtom: COSValue] = [
            ASAtom("MCID"): .integer(6)
        ]

        let mcr1 = try PDMarkedContentReference(cosObject: .dictionary(dict1))
        let mcr2 = try PDMarkedContentReference(cosObject: .dictionary(dict2))

        #expect(mcr1 != mcr2)
    }
}
