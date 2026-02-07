import Testing
@testable import SwiftVerificarParser

@Suite("PDRoleMap Tests")
struct PDRoleMapTests {

    // MARK: - Initialization Tests

    @Test("Initialize from dictionary")
    func testInitializeFromDictionary() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Para"): .name("P")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))
        #expect(roleMap.cosObject.isDictionary)
    }

    @Test("Initialize fails with non-dictionary")
    func testInitializeFailsWithNonDictionary() {
        #expect(throws: PDError.notADictionary) {
            _ = try PDRoleMap(cosObject: .null)
        }
        #expect(throws: PDError.notADictionary) {
            _ = try PDRoleMap(cosObject: .array([]))
        }
    }

    // MARK: - Direct Mapping Tests

    @Test("Get direct mapping")
    func testGetDirectMapping() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Para"): .name("P")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap.directMapping(for: ASAtom("Heading1")) == ASAtom("H1"))
        #expect(roleMap.directMapping(for: ASAtom("Para")) == ASAtom("P"))
    }

    @Test("Direct mapping returns nil for unmapped role")
    func testDirectMappingReturnsNilForUnmappedRole() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap.directMapping(for: ASAtom("Unmapped")) == nil)
    }

    // MARK: - Map to Standard Tests

    @Test("Map custom role to standard type")
    func testMapCustomRoleToStandardType() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Para"): .name("P")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap.mapToStandard(ASAtom("Heading1")) == ASAtom("H1"))
        #expect(roleMap.mapToStandard(ASAtom("Para")) == ASAtom("P"))
    }

    @Test("Map unmapped role returns original")
    func testMapUnmappedRoleReturnsOriginal() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap.mapToStandard(ASAtom("Unmapped")) == ASAtom("Unmapped"))
    }

    @Test("Map through chain of mappings")
    func testMapThroughChainOfMappings() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("CustomHeading"): .name(ASAtom("Heading1")),
            ASAtom("Heading1"): .name("H1")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap.mapToStandard(ASAtom("CustomHeading")) == ASAtom("H1"))
    }

    @Test("Map detects cycles")
    func testMapDetectsCycles() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Role1"): .name(ASAtom("Role2")),
            ASAtom("Role2"): .name(ASAtom("Role1"))
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        // Should return one of the roles in the cycle, not infinite loop
        let result = roleMap.mapToStandard(ASAtom("Role1"))
        #expect(result == ASAtom("Role1") || result == ASAtom("Role2"))
    }

    // MARK: - Has Mapping Tests

    @Test("Has mapping for mapped role")
    func testHasMappingForMappedRole() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap.hasMappingFor(ASAtom("Heading1")))
    }

    @Test("No mapping for unmapped role")
    func testNoMappingForUnmappedRole() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(!roleMap.hasMappingFor(ASAtom("Unmapped")))
    }

    // MARK: - All Custom Roles Tests

    @Test("Get all custom roles")
    func testGetAllCustomRoles() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Heading2"): .name("H2"),
            ASAtom("Para"): .name("P")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        let customRoles = roleMap.allCustomRoles()
        #expect(customRoles.count == 3)
        #expect(customRoles.contains(ASAtom("Heading1")))
        #expect(customRoles.contains(ASAtom("Heading2")))
        #expect(customRoles.contains(ASAtom("Para")))
    }

    @Test("Empty role map returns empty set")
    func testEmptyRoleMapReturnsEmptySet() throws {
        let dict: [ASAtom: COSValue] = [:]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        let customRoles = roleMap.allCustomRoles()
        #expect(customRoles.isEmpty)
    }

    // MARK: - All Mappings Tests

    @Test("Get all mappings")
    func testGetAllMappings() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Para"): .name("P")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        let mappings = roleMap.allMappings()
        #expect(mappings.count == 2)
        #expect(mappings[ASAtom("Heading1")] == ASAtom("H1"))
        #expect(mappings[ASAtom("Para")] == ASAtom("P"))
    }

    @Test("All mappings ignores non-name values")
    func testAllMappingsIgnoresNonNameValues() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("BadEntry"): .integer(42)
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        let mappings = roleMap.allMappings()
        #expect(mappings.count == 1)
        #expect(mappings[ASAtom("Heading1")] == ASAtom("H1"))
        #expect(mappings[ASAtom("BadEntry")] == nil)
    }

    // MARK: - Standard Type Tests

    @Test("Recognize standard structure types")
    func testRecognizeStandardStructureTypes() {
        let standardTypes = [
            "Document", "Part", "Art", "Sect", "Div",
            "P", "H", "H1", "H2", "H3", "H4", "H5", "H6",
            "L", "LI", "Lbl", "LBody",
            "Table", "TR", "TH", "TD", "THead", "TBody", "TFoot",
            "Span", "Quote", "Note", "Reference", "Code", "Link",
            "Figure", "Formula", "Form"
        ]

        for typeName in standardTypes {
            #expect(PDRoleMap.isStandardType(ASAtom(typeName)))
        }
    }

    @Test("Do not recognize custom types as standard")
    func testDoNotRecognizeCustomTypesAsStandard() {
        let customTypes = [
            "CustomHeading", "MyParagraph", "SpecialFigure", "Heading1"
        ]

        for typeName in customTypes {
            #expect(!PDRoleMap.isStandardType(ASAtom(typeName)))
        }
    }

    // MARK: - Complete RoleMap Tests

    @Test("Complete role map")
    func testCompleteRoleMap() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1"),
            ASAtom("Heading2"): .name("H2"),
            ASAtom("Para"): .name("P"),
            ASAtom("CustomHeading"): .name(ASAtom("Heading1")),
            ASAtom("ListItem"): .name("LI")
        ]
        let roleMap = try PDRoleMap(cosObject: .dictionary(dict))

        // Test all custom roles
        let customRoles = roleMap.allCustomRoles()
        #expect(customRoles.count == 5)

        // Test mapping chain
        #expect(roleMap.mapToStandard(ASAtom("CustomHeading")) == ASAtom("H1"))

        // Test direct mappings
        #expect(roleMap.mapToStandard(ASAtom("Heading1")) == ASAtom("H1"))
        #expect(roleMap.mapToStandard(ASAtom("Para")) == ASAtom("P"))

        // Test has mapping
        #expect(roleMap.hasMappingFor(ASAtom("Heading1")))
        #expect(!roleMap.hasMappingFor(ASAtom("NotMapped")))

        // Test all mappings
        let mappings = roleMap.allMappings()
        #expect(mappings.count == 5)
    }

    // MARK: - Hashable Tests

    @Test("PDRoleMap is hashable")
    func testPDRoleMapIsHashable() throws {
        let dict: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1")
        ]
        let roleMap1 = try PDRoleMap(cosObject: .dictionary(dict))
        let roleMap2 = try PDRoleMap(cosObject: .dictionary(dict))

        #expect(roleMap1 == roleMap2)
        #expect(roleMap1.hashValue == roleMap2.hashValue)
    }

    @Test("Different PDRoleMap instances are not equal")
    func testDifferentPDRoleMapInstancesAreNotEqual() throws {
        let dict1: [ASAtom: COSValue] = [
            ASAtom("Heading1"): .name("H1")
        ]
        let dict2: [ASAtom: COSValue] = [
            ASAtom("Heading2"): .name("H2")
        ]

        let roleMap1 = try PDRoleMap(cosObject: .dictionary(dict1))
        let roleMap2 = try PDRoleMap(cosObject: .dictionary(dict2))

        #expect(roleMap1 != roleMap2)
    }
}
