import Testing
@testable import SwiftVerificarParser

@Suite("PDClassMap Tests")
struct PDClassMapTests {

    // MARK: - Initialization Tests

    @Test("Initialize from dictionary")
    func testInitializeFromDictionary() throws {
        let attrDict: COSValue = .dictionary([ASAtom("O"): .name("Layout")])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): attrDict
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))
        #expect(classMap.cosObject.isDictionary)
    }

    @Test("Initialize fails with non-dictionary")
    func testInitializeFailsWithNonDictionary() {
        #expect(throws: PDError.notADictionary) {
            _ = try PDClassMap(cosObject: .null)
        }
        #expect(throws: PDError.notADictionary) {
            _ = try PDClassMap(cosObject: .array([]))
        }
    }

    // MARK: - Attributes for Class Tests

    @Test("Get attributes for class")
    func testGetAttributesForClass() throws {
        let attrDict: COSValue = .dictionary([ASAtom("O"): .name("Layout")])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): attrDict
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let attrs = classMap.attributesForClass(ASAtom("Header"))
        #expect(attrs == attrDict)
    }

    @Test("Attributes for class returns nil when not found")
    func testAttributesForClassReturnsNilWhenNotFound() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let attrs = classMap.attributesForClass(ASAtom("NotFound"))
        #expect(attrs == nil)
    }

    // MARK: - Attribute Object for Class Tests

    @Test("Get attribute object for class")
    func testGetAttributeObjectForClass() throws {
        let attrDict: COSValue = .dictionary([ASAtom("O"): .name("Layout")])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): attrDict
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let attrObj = try classMap.attributeObjectForClass(ASAtom("Header"))
        #expect(attrObj != nil)
        #expect(attrObj?.cosObject == attrDict)
    }

    @Test("Attribute object for class returns nil when not found")
    func testAttributeObjectForClassReturnsNilWhenNotFound() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let attrObj = try classMap.attributeObjectForClass(ASAtom("NotFound"))
        #expect(attrObj == nil)
    }

    // MARK: - Has Class Tests

    @Test("Has class returns true for defined class")
    func testHasClassReturnsTrueForDefinedClass() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        #expect(classMap.hasClass(ASAtom("Header")))
    }

    @Test("Has class returns false for undefined class")
    func testHasClassReturnsFalseForUndefinedClass() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        #expect(!classMap.hasClass(ASAtom("NotDefined")))
    }

    // MARK: - All Class Names Tests

    @Test("Get all class names")
    func testGetAllClassNames() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")]),
            ASAtom("Footer"): .dictionary([ASAtom("O"): .name("Layout")]),
            ASAtom("Emphasis"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let classNames = classMap.allClassNames()
        #expect(classNames.count == 3)
        #expect(classNames.contains(ASAtom("Header")))
        #expect(classNames.contains(ASAtom("Footer")))
        #expect(classNames.contains(ASAtom("Emphasis")))
    }

    @Test("Empty class map returns empty set")
    func testEmptyClassMapReturnsEmptySet() throws {
        let dict: [ASAtom: COSValue] = [:]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let classNames = classMap.allClassNames()
        #expect(classNames.isEmpty)
    }

    // MARK: - All Mappings Tests

    @Test("Get all mappings")
    func testGetAllMappings() throws {
        let attrDict1: COSValue = .dictionary([ASAtom("O"): .name("Layout")])
        let attrDict2: COSValue = .dictionary([ASAtom("O"): .name("Table")])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): attrDict1,
            ASAtom("TableHeader"): attrDict2
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let mappings = classMap.allMappings()
        #expect(mappings.count == 2)
        #expect(mappings[ASAtom("Header")] == attrDict1)
        #expect(mappings[ASAtom("TableHeader")] == attrDict2)
    }

    // MARK: - Resolve Attributes Tests

    @Test("Resolve attributes for single class")
    func testResolveAttributesForSingleClass() throws {
        let attrDict: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            .bbox: .array([.integer(0), .integer(0), .integer(100), .integer(50)])
        ])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): attrDict
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let resolved = try classMap.resolveAttributes(forClasses: [ASAtom("Header")])
        #expect(resolved != nil)
        #expect(try resolved?.owner() == ASAtom("Layout"))
    }

    @Test("Resolve attributes for multiple classes")
    func testResolveAttributesForMultipleClasses() throws {
        let attrDict1: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            ASAtom("Attr1"): .integer(10)
        ])
        let attrDict2: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            ASAtom("Attr2"): .integer(20)
        ])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Class1"): attrDict1,
            ASAtom("Class2"): attrDict2
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let resolved = try classMap.resolveAttributes(forClasses: [ASAtom("Class1"), ASAtom("Class2")])
        #expect(resolved != nil)

        // Both attributes should be present
        #expect(resolved?.integerAttribute(ASAtom("Attr1")) == 10)
        #expect(resolved?.integerAttribute(ASAtom("Attr2")) == 20)
    }

    @Test("Resolve attributes with override")
    func testResolveAttributesWithOverride() throws {
        let attrDict1: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            ASAtom("Color"): .name("Red")
        ])
        let attrDict2: COSValue = .dictionary([
            ASAtom("O"): .name("Layout"),
            ASAtom("Color"): .name("Blue")
        ])
        let dict: [ASAtom: COSValue] = [
            ASAtom("Class1"): attrDict1,
            ASAtom("Class2"): attrDict2
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let resolved = try classMap.resolveAttributes(forClasses: [ASAtom("Class1"), ASAtom("Class2")])
        #expect(resolved != nil)

        // Class2 should override Class1
        #expect(resolved?.nameAttribute(ASAtom("Color")) == ASAtom("Blue"))
    }

    @Test("Resolve attributes returns nil for undefined classes")
    func testResolveAttributesReturnsNilForUndefinedClasses() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap = try PDClassMap(cosObject: .dictionary(dict))

        let resolved = try classMap.resolveAttributes(forClasses: [ASAtom("NotDefined")])
        #expect(resolved == nil)
    }

    // MARK: - Hashable Tests

    @Test("PDClassMap is hashable")
    func testPDClassMapIsHashable() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ]
        let classMap1 = try PDClassMap(cosObject: .dictionary(dict))
        let classMap2 = try PDClassMap(cosObject: .dictionary(dict))

        #expect(classMap1 == classMap2)
        #expect(classMap1.hashValue == classMap2.hashValue)
    }
}

@Suite("PDAttributeObject Tests")
struct PDAttributeObjectTests {

    // MARK: - Initialization Tests

    @Test("Initialize from dictionary")
    func testInitializeFromDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.cosObject.isDictionary)
    }

    @Test("Initialize fails with non-dictionary")
    func testInitializeFailsWithNonDictionary() {
        #expect(throws: PDError.notADictionary) {
            _ = try PDAttributeObject(cosObject: .null)
        }
    }

    // MARK: - Owner Tests

    @Test("Get owner")
    func testGetOwner() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        let owner = try attrObj.owner()
        #expect(owner == ASAtom("Layout"))
    }

    @Test("Owner is required")
    func testOwnerIsRequired() throws {
        let dict: [ASAtom: COSValue] = [:]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(throws: PDError.missingRequiredEntry(key: "O")) {
            _ = try attrObj.owner()
        }
    }

    @Test("Various owner types")
    func testVariousOwnerTypes() throws {
        let owners = ["Layout", "List", "Table", "PrintField"]

        for ownerName in owners {
            let dict: [ASAtom: COSValue] = [
                ASAtom("O"): .name(ASAtom(ownerName))
            ]
            let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
            #expect(try attrObj.owner() == ASAtom(ownerName))
        }
    }

    // MARK: - Generic Attribute Tests

    @Test("Get string attribute")
    func testGetStringAttribute() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("Title"): .string(COSString("Header"))
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.stringAttribute(ASAtom("Title")) == "Header")
    }

    @Test("Get integer attribute")
    func testGetIntegerAttribute() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("RowSpan"): .integer(2)
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.integerAttribute(ASAtom("RowSpan")) == 2)
    }

    @Test("Get numeric attribute")
    func testGetNumericAttribute() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("Width"): .real(100.5)
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.numericAttribute(ASAtom("Width")) == 100.5)
    }

    @Test("Get name attribute")
    func testGetNameAttribute() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("Placement"): .name("Block")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.nameAttribute(ASAtom("Placement")) == ASAtom("Block"))
    }

    @Test("Get array attribute")
    func testGetArrayAttribute() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            .bbox: .array([.integer(0), .integer(0), .integer(100), .integer(100)])
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        let bbox = attrObj.arrayAttribute(.bbox)
        #expect(bbox?.count == 4)
    }

    @Test("Get boolean attribute")
    func testGetBooleanAttribute() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("Bold"): .boolean(true)
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.booleanAttribute(ASAtom("Bold")) == true)
    }

    // MARK: - Layout Attributes Tests

    @Test("Get bounding box")
    func testGetBoundingBox() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            .bbox: .array([.integer(10), .integer(20), .integer(110), .integer(120)])
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        let bbox = attrObj.boundingBox
        #expect(bbox?.count == 4)
        #expect(bbox?[0].integerValue == 10)
        #expect(bbox?[3].integerValue == 120)
    }

    @Test("Get placement")
    func testGetPlacement() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("Placement"): .name("Block")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.placement == ASAtom("Block"))
    }

    @Test("Get writing mode")
    func testGetWritingMode() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("WritingMode"): .name("LrTb")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.writingMode == ASAtom("LrTb"))
    }

    @Test("Get background color")
    func testGetBackgroundColor() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("BackgroundColor"): .array([.real(1.0), .real(0.0), .real(0.0)])
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        let bgColor = attrObj.backgroundColor
        #expect(bgColor?.count == 3)
    }

    @Test("Get text alignment")
    func testGetTextAlignment() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            ASAtom("TextAlign"): .name("Center")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.textAlign == ASAtom("Center"))
    }

    // MARK: - Table Attributes Tests

    @Test("Get row span")
    func testGetRowSpan() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("RowSpan"): .integer(3)
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.rowSpan == 3)
    }

    @Test("Get column span")
    func testGetColumnSpan() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("ColSpan"): .integer(2)
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.colSpan == 2)
    }

    @Test("Get headers")
    func testGetHeaders() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("Headers"): .array([.string(COSString("hdr1")), .string(COSString("hdr2"))])
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        let headers = attrObj.headers
        #expect(headers?.count == 2)
    }

    @Test("Get scope")
    func testGetScope() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("Scope"): .name("Column")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.scope == ASAtom("Column"))
    }

    @Test("Get summary")
    func testGetSummary() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("Summary"): .string(COSString("A table of results"))
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.summary == "A table of results")
    }

    // MARK: - List Attributes Tests

    @Test("Get list numbering")
    func testGetListNumbering() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("List"),
            ASAtom("ListNumbering"): .name("Decimal")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.listNumbering == ASAtom("Decimal"))
    }

    // MARK: - Validation Tests

    @Test("Validate with owner")
    func testValidateWithOwner() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout")
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(attrObj.validate())
    }

    @Test("Validate fails without owner")
    func testValidateFailsWithoutOwner() throws {
        let dict: [ASAtom: COSValue] = [:]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))
        #expect(!attrObj.validate())
    }

    // MARK: - Complete Attribute Object Tests

    @Test("Complete layout attribute object")
    func testCompleteLayoutAttributeObject() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout"),
            .bbox: .array([.integer(0), .integer(0), .integer(200), .integer(100)]),
            ASAtom("Placement"): .name("Block"),
            ASAtom("WritingMode"): .name("LrTb"),
            ASAtom("TextAlign"): .name("Justify"),
            ASAtom("BackgroundColor"): .array([.real(0.9), .real(0.9), .real(0.9)])
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))

        #expect(try attrObj.owner() == ASAtom("Layout"))
        #expect(attrObj.validate())
        #expect(attrObj.boundingBox?.count == 4)
        #expect(attrObj.placement == ASAtom("Block"))
        #expect(attrObj.writingMode == ASAtom("LrTb"))
        #expect(attrObj.textAlign == ASAtom("Justify"))
        #expect(attrObj.backgroundColor?.count == 3)
    }

    @Test("Complete table attribute object")
    func testCompleteTableAttributeObject() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Table"),
            ASAtom("RowSpan"): .integer(2),
            ASAtom("ColSpan"): .integer(3),
            ASAtom("Scope"): .name("Row"),
            ASAtom("Headers"): .array([.string(COSString("hdr1"))])
        ]
        let attrObj = try PDAttributeObject(cosObject: .dictionary(dict))

        #expect(try attrObj.owner() == ASAtom("Table"))
        #expect(attrObj.validate())
        #expect(attrObj.rowSpan == 2)
        #expect(attrObj.colSpan == 3)
        #expect(attrObj.scope == ASAtom("Row"))
        #expect(attrObj.headers?.count == 1)
    }

    // MARK: - Hashable Tests

    @Test("PDAttributeObject is hashable")
    func testPDAttributeObjectIsHashable() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("O"): .name("Layout")
        ]
        let attrObj1 = try PDAttributeObject(cosObject: .dictionary(dict))
        let attrObj2 = try PDAttributeObject(cosObject: .dictionary(dict))

        #expect(attrObj1 == attrObj2)
        #expect(attrObj1.hashValue == attrObj2.hashValue)
    }
}
