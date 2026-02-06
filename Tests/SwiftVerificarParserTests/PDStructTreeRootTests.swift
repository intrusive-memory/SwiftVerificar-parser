import Testing
@testable import SwiftVerificarParser

@Suite("PDStructTreeRoot Tests")
struct PDStructTreeRootTests {

    // MARK: - Initialization Tests

    @Test("Initialize from dictionary")
    func testInitializeFromDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot),
            .k: .dictionary([.s: .name("Document")])
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.cosObject.isDictionary)
    }

    @Test("Initialize fails with non-dictionary")
    func testInitializeFailsWithNonDictionary() {
        #expect(throws: PDError.notADictionary) {
            _ = try PDStructTreeRoot(cosObject: .null)
        }
        #expect(throws: PDError.notADictionary) {
            _ = try PDStructTreeRoot(cosObject: .integer(42))
        }
        #expect(throws: PDError.notADictionary) {
            _ = try PDStructTreeRoot(cosObject: .array([]))
        }
    }

    // MARK: - Type Entry Tests

    @Test("Get type entry")
    func testGetTypeEntry() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot)
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.type == .structTreeRoot)
    }

    @Test("Type entry is optional")
    func testTypeEntryIsOptional() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.type == nil)
    }

    // MARK: - K (Children) Tests

    @Test("Get single child")
    func testGetSingleChild() throws {
        let childDict: COSValue = .dictionary([.s: .name("Document")])
        let dict: [ASAtom: COSValue] = [
            .k: childDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let children = try root.children()
        #expect(children.count == 1)
        #expect(children[0] == childDict)
    }

    @Test("Get multiple children as array")
    func testGetMultipleChildren() throws {
        let child1: COSValue = .dictionary([.s: .name("Document")])
        let child2: COSValue = .dictionary([.s: .name("Part")])
        let dict: [ASAtom: COSValue] = [
            .k: .array([child1, child2])
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let children = try root.children()
        #expect(children.count == 2)
        #expect(children[0] == child1)
        #expect(children[1] == child2)
    }

    @Test("No children returns empty array")
    func testNoChildrenReturnsEmptyArray() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let children = try root.children()
        #expect(children.isEmpty)
    }

    @Test("K entry is accessible")
    func testKEntryIsAccessible() throws {
        let childDict: COSValue = .dictionary([.s: .name("Document")])
        let dict: [ASAtom: COSValue] = [
            .k: childDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.k == childDict)
    }

    // MARK: - RoleMap Tests

    @Test("Get role map entry")
    func testGetRoleMapEntry() throws {
        let roleMapDict: COSValue = .dictionary([
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Para"): .name("P")
        ])
        let dict: [ASAtom: COSValue] = [
            .roleMap: roleMapDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.roleMap == roleMapDict)
    }

    @Test("RoleMap entry is optional")
    func testRoleMapEntryIsOptional() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.roleMap == nil)
    }

    @Test("Get role map as object")
    func testGetRoleMapAsObject() throws {
        let roleMapDict: COSValue = .dictionary([
            ASAtom("Heading1"): .name("H1")
        ])
        let dict: [ASAtom: COSValue] = [
            .roleMap: roleMapDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let roleMap = try root.roleMapObject()
        #expect(roleMap != nil)
        #expect(roleMap?.cosObject == roleMapDict)
    }

    @Test("Role map object is nil when not present")
    func testRoleMapObjectIsNilWhenNotPresent() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let roleMap = try root.roleMapObject()
        #expect(roleMap == nil)
    }

    // MARK: - ClassMap Tests

    @Test("Get class map entry")
    func testGetClassMapEntry() throws {
        let classMapDict: COSValue = .dictionary([
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ])
        let dict: [ASAtom: COSValue] = [
            .classMap: classMapDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.classMap == classMapDict)
    }

    @Test("ClassMap entry is optional")
    func testClassMapEntryIsOptional() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.classMap == nil)
    }

    @Test("Get class map as object")
    func testGetClassMapAsObject() throws {
        let classMapDict: COSValue = .dictionary([
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ])
        let dict: [ASAtom: COSValue] = [
            .classMap: classMapDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let classMap = try root.classMapObject()
        #expect(classMap != nil)
        #expect(classMap?.cosObject == classMapDict)
    }

    @Test("Class map object is nil when not present")
    func testClassMapObjectIsNilWhenNotPresent() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let classMap = try root.classMapObject()
        #expect(classMap == nil)
    }

    // MARK: - ParentTree Tests

    @Test("Get parent tree entry")
    func testGetParentTreeEntry() throws {
        let parentTreeDict: COSValue = .dictionary([
            ASAtom("Nums"): .array([.integer(0), .dictionary([:])])
        ])
        let dict: [ASAtom: COSValue] = [
            ASAtom("ParentTree"): parentTreeDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.parentTree == parentTreeDict)
    }

    @Test("ParentTree entry is optional")
    func testParentTreeEntryIsOptional() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.parentTree == nil)
    }

    @Test("Get parent tree next key")
    func testGetParentTreeNextKey() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("ParentTreeNextKey"): .integer(42)
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.parentTreeNextKey == 42)
    }

    @Test("ParentTreeNextKey is optional")
    func testParentTreeNextKeyIsOptional() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.parentTreeNextKey == nil)
    }

    // MARK: - IDTree Tests

    @Test("Get ID tree entry")
    func testGetIDTreeEntry() throws {
        let idTreeDict: COSValue = .dictionary([
            ASAtom("Names"): .array([.string(COSString("elem1")), .dictionary([:])])
        ])
        let dict: [ASAtom: COSValue] = [
            ASAtom("IDTree"): idTreeDict
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.idTree == idTreeDict)
    }

    @Test("IDTree entry is optional")
    func testIDTreeEntryIsOptional() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.idTree == nil)
    }

    // MARK: - Validation Tests

    @Test("Validate with correct type")
    func testValidateWithCorrectType() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot)
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.validate())
    }

    @Test("Validate with incorrect type")
    func testValidateWithIncorrectType() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name("WrongType")
        ]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(!root.validate())
    }

    @Test("Validate without type entry")
    func testValidateWithoutTypeEntry() throws {
        let dict: [ASAtom: COSValue] = [:]
        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))
        #expect(root.validate())
    }

    // MARK: - Complex Structure Tests

    @Test("Complete structure tree root")
    func testCompleteStructureTreeRoot() throws {
        let roleMapDict: COSValue = .dictionary([
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Para"): .name("P")
        ])
        let classMapDict: COSValue = .dictionary([
            ASAtom("Header"): .dictionary([ASAtom("O"): .name("Layout")])
        ])
        let child1: COSValue = .dictionary([.s: .name("Document")])
        let child2: COSValue = .dictionary([.s: .name("Part")])

        let dict: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot),
            .k: .array([child1, child2]),
            .roleMap: roleMapDict,
            .classMap: classMapDict,
            ASAtom("ParentTreeNextKey"): .integer(10)
        ]

        let root = try PDStructTreeRoot(cosObject: .dictionary(dict))

        #expect(root.type == .structTreeRoot)
        #expect(root.validate())

        let children = try root.children()
        #expect(children.count == 2)

        #expect(root.roleMap == roleMapDict)
        #expect(root.classMap == classMapDict)
        #expect(root.parentTreeNextKey == 10)

        let roleMap = try root.roleMapObject()
        #expect(roleMap != nil)

        let classMap = try root.classMapObject()
        #expect(classMap != nil)
    }

    // MARK: - Hashable and Sendable Tests

    @Test("PDStructTreeRoot is hashable")
    func testPDStructTreeRootIsHashable() throws {
        let dict: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot)
        ]
        let root1 = try PDStructTreeRoot(cosObject: .dictionary(dict))
        let root2 = try PDStructTreeRoot(cosObject: .dictionary(dict))

        #expect(root1 == root2)
        #expect(root1.hashValue == root2.hashValue)
    }

    @Test("Different PDStructTreeRoot instances are not equal")
    func testDifferentPDStructTreeRootInstancesAreNotEqual() throws {
        let dict1: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot)
        ]
        let dict2: [ASAtom: COSValue] = [
            .type: .name(.structTreeRoot),
            .k: .dictionary([.s: .name("Document")])
        ]

        let root1 = try PDStructTreeRoot(cosObject: .dictionary(dict1))
        let root2 = try PDStructTreeRoot(cosObject: .dictionary(dict2))

        #expect(root1 != root2)
    }
}
