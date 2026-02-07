import Testing
@testable import SwiftVerificarParser

@Suite("PDStructElement Tests")
struct PDStructElementTests {

    // MARK: - Initialization Tests

    @Test("Initialize from dictionary")
    func testInitializeFromDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .parent: .reference(COSReference(objectNumber: 1, generation: 0))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.cosObject.isDictionary)
    }

    @Test("Initialize fails with non-dictionary")
    func testInitializeFailsWithNonDictionary() {
        #expect(throws: PDError.notADictionary) {
            _ = try PDStructElement(cosObject: .null)
        }
        #expect(throws: PDError.notADictionary) {
            _ = try PDStructElement(cosObject: .integer(42))
        }
    }

    // MARK: - Structure Type Tests

    @Test("Get structure type")
    func testGetStructureType() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        let structType = try elem.structureType()
        #expect(structType == ASAtom("P"))
    }

    @Test("Structure type is required")
    func testStructureTypeIsRequired() throws {
        let dict: [ASAtom: COSValue] = [:]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(throws: PDError.missingRequiredEntry(key: "S")) {
            _ = try elem.structureType()
        }
    }

    @Test("Various structure types")
    func testVariousStructureTypes() throws {
        let types = ["Document", "Part", "H1", "H2", "P", "Figure", "Table", "TR", "TD"]

        for typeName in types {
            let dict: [ASAtom: COSValue] = [
                .s: .name(ASAtom(typeName))
            ]
            let elem = try PDStructElement(cosObject: .dictionary(dict))
            let structType = try elem.structureType()
            #expect(structType == ASAtom(typeName))
        }
    }

    // MARK: - Parent Tests

    @Test("Get parent reference")
    func testGetParentReference() throws {
        let parentRef = COSReference(objectNumber: 10, generation: 0)
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .parent: .reference(parentRef)
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        let parent = try elem.parent()
        #expect(parent == .reference(parentRef))
    }

    @Test("Parent is required")
    func testParentIsRequired() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(throws: PDError.missingRequiredEntry(key: "Parent")) {
            _ = try elem.parent()
        }
    }

    // MARK: - K (Children) Tests

    @Test("Get single child MCID")
    func testGetSingleChildMCID() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .k: .integer(5)
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        let children = try elem.children()
        #expect(children.count == 1)
        #expect(children[0].integerValue == 5)
    }

    @Test("Get single child structure element")
    func testGetSingleChildStructureElement() throws {
        let childDict: COSValue = .dictionary([.s: .name("Span")])
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .k: childDict
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        let children = try elem.children()
        #expect(children.count == 1)
        #expect(children[0] == childDict)
    }

    @Test("Get multiple children")
    func testGetMultipleChildren() throws {
        let child1: COSValue = .integer(0)
        let child2: COSValue = .integer(1)
        let child3: COSValue = .dictionary([.s: .name("Span")])
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .k: .array([child1, child2, child3])
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        let children = try elem.children()
        #expect(children.count == 3)
        #expect(children[0] == child1)
        #expect(children[1] == child2)
        #expect(children[2] == child3)
    }

    @Test("No children returns empty array")
    func testNoChildrenReturnsEmptyArray() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        let children = try elem.children()
        #expect(children.isEmpty)
    }

    // MARK: - Page Tests

    @Test("Get page reference")
    func testGetPageReference() throws {
        let pageRef = COSReference(objectNumber: 20, generation: 0)
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .pg: .reference(pageRef)
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.page == .reference(pageRef))
    }

    @Test("Page is optional")
    func testPageIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.page == nil)
    }

    // MARK: - Attributes Tests

    @Test("Get attributes dictionary")
    func testGetAttributesDictionary() throws {
        let attrsDict: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            .bbox: .array([.integer(0), .integer(0), .integer(100), .integer(100)])
        ])
        let dict: [ASAtom: COSValue] = [
            .s: .name("Figure"),
            ASAtom("A"): attrsDict
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.attributes == attrsDict)
    }

    @Test("Attributes is optional")
    func testAttributesIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.attributes == nil)
    }

    // MARK: - Attribute Classes Tests

    @Test("Get single attribute class")
    func testGetSingleAttributeClass() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            ASAtom("C"): .name(ASAtom("NormalPara"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.attributeClasses?.nameValue == ASAtom("NormalPara"))
    }

    @Test("Get multiple attribute classes")
    func testGetMultipleAttributeClasses() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            ASAtom("C"): .array([.name(ASAtom("Class1")), .name(ASAtom("Class2"))])
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.attributeClasses?.arrayValue?.count == 2)
    }

    @Test("Attribute classes is optional")
    func testAttributeClassesIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.attributeClasses == nil)
    }

    // MARK: - Revision Tests

    @Test("Get revision number")
    func testGetRevisionNumber() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            ASAtom("R"): .integer(2)
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.revision == 2)
    }

    @Test("Revision is optional")
    func testRevisionIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.revision == nil)
    }

    // MARK: - Title Tests

    @Test("Get title")
    func testGetTitle() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("Figure"),
            ASAtom("T"): .string(COSString("Figure 1: Sample Image"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.title == "Figure 1: Sample Image")
    }

    @Test("Title is optional")
    func testTitleIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.title == nil)
    }

    // MARK: - Language Tests

    @Test("Get language")
    func testGetLanguage() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .lang: .string(COSString("en-US"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.language == "en-US")
    }

    @Test("Language is optional")
    func testLanguageIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.language == nil)
    }

    // MARK: - Alternate Description Tests

    @Test("Get alternate description")
    func testGetAlternateDescription() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("Figure"),
            .alt: .string(COSString("A photo of a sunset"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.alternateDescription == "A photo of a sunset")
    }

    @Test("Alternate description is optional")
    func testAlternateDescriptionIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.alternateDescription == nil)
    }

    // MARK: - Actual Text Tests

    @Test("Get actual text")
    func testGetActualText() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("Span"),
            .actualText: .string(COSString("Logo"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.actualText == "Logo")
    }

    @Test("Actual text is optional")
    func testActualTextIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.actualText == nil)
    }

    // MARK: - Expanded Form Tests

    @Test("Get expanded form")
    func testGetExpandedForm() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("Span"),
            .e: .string(COSString("World Wide Web"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.expandedForm == "World Wide Web")
    }

    @Test("Expanded form is optional")
    func testExpandedFormIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.expandedForm == nil)
    }

    // MARK: - ID Tests

    @Test("Get element ID")
    func testGetElementID() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .id: .string(COSString("para-1"))
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.id == "para-1")
    }

    @Test("ID is optional")
    func testIDIsOptional() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.id == nil)
    }

    // MARK: - Marked Content Detection Tests

    @Test("Has marked content with MCID")
    func testHasMarkedContentWithMCID() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .k: .integer(5)
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(try elem.hasMarkedContent())
    }

    @Test("Has marked content with MCR dictionary")
    func testHasMarkedContentWithMCRDictionary() throws {
        let mcrDict: COSValue = .dictionary([
            .type: .name(ASAtom("MCR")),
            ASAtom("MCID"): .integer(3)
        ])
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .k: .array([mcrDict])
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(try elem.hasMarkedContent())
    }

    @Test("No marked content with structure element children")
    func testNoMarkedContentWithStructureElementChildren() throws {
        let childDict: COSValue = .dictionary([.s: .name("Span")])
        let dict: [ASAtom: COSValue] = [
            .s: .name("P"),
            .k: .array([childDict])
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(try !elem.hasMarkedContent())
    }

    @Test("No marked content with no children")
    func testNoMarkedContentWithNoChildren() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(try !elem.hasMarkedContent())
    }

    // MARK: - Validation Tests

    @Test("Validate with structure type")
    func testValidateWithStructureType() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(elem.validate())
    }

    @Test("Validate fails without structure type")
    func testValidateFailsWithoutStructureType() throws {
        let dict: [ASAtom: COSValue] = [:]
        let elem = try PDStructElement(cosObject: .dictionary(dict))
        #expect(!elem.validate())
    }

    // MARK: - Complex Structure Tests

    @Test("Complete structure element")
    func testCompleteStructureElement() throws {
        let attrsDict: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            .bbox: .array([.integer(0), .integer(0), .integer(200), .integer(100)])
        ])

        let dict: [ASAtom: COSValue] = [
            .s: .name("Figure"),
            .parent: .reference(COSReference(objectNumber: 1, generation: 0)),
            .k: .integer(10),
            .pg: .reference(COSReference(objectNumber: 5, generation: 0)),
            ASAtom("A"): attrsDict,
            ASAtom("C"): .name(ASAtom("ImageClass")),
            ASAtom("T"): .string(COSString("Figure 1")),
            .lang: .string(COSString("en-US")),
            .alt: .string(COSString("A sample figure")),
            .id: .string(COSString("fig-1"))
        ]

        let elem = try PDStructElement(cosObject: .dictionary(dict))

        #expect(try elem.structureType() == ASAtom("Figure"))
        #expect(elem.validate())

        let children = try elem.children()
        #expect(children.count == 1)
        #expect(children[0].integerValue == 10)

        #expect(elem.attributes == attrsDict)
        #expect(elem.title == "Figure 1")
        #expect(elem.language == "en-US")
        #expect(elem.alternateDescription == "A sample figure")
        #expect(elem.id == "fig-1")
        #expect(try elem.hasMarkedContent())
    }

    // MARK: - Hashable Tests

    @Test("PDStructElement is hashable")
    func testPDStructElementIsHashable() throws {
        let dict: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let elem1 = try PDStructElement(cosObject: .dictionary(dict))
        let elem2 = try PDStructElement(cosObject: .dictionary(dict))

        #expect(elem1 == elem2)
        #expect(elem1.hashValue == elem2.hashValue)
    }

    @Test("Different PDStructElement instances are not equal")
    func testDifferentPDStructElementInstancesAreNotEqual() throws {
        let dict1: [ASAtom: COSValue] = [
            .s: .name("P")
        ]
        let dict2: [ASAtom: COSValue] = [
            .s: .name("H1")
        ]

        let elem1 = try PDStructElement(cosObject: .dictionary(dict1))
        let elem2 = try PDStructElement(cosObject: .dictionary(dict2))

        #expect(elem1 != elem2)
    }
}
