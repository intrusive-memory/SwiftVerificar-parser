import Testing
@testable import SwiftVerificarParser

@Suite("PDObject Protocol Tests")
struct PDObjectTests {

    // MARK: - Helper Type

    struct TestPDObject: PDObject {
        let cosObject: COSValue

        init(cosObject: COSValue) throws {
            guard cosObject.isDictionary else {
                throw PDError.notADictionary
            }
            self.cosObject = cosObject
        }
    }

    // MARK: - Initialization Tests

    @Test("PDObject requires dictionary")
    func requiresDictionary() throws {
        #expect(throws: PDError.notADictionary) {
            try TestPDObject(cosObject: .null)
        }

        #expect(throws: PDError.notADictionary) {
            try TestPDObject(cosObject: .integer(42))
        }

        // Should succeed with a dictionary
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)
        #expect(obj.cosObject.isDictionary)
    }

    // MARK: - Entry Access Tests

    @Test("requireEntry throws for missing entries")
    func requireEntryThrows() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        #expect(throws: PDError.missingRequiredEntry(key: "Missing")) {
            try obj.requireEntry("Missing")
        }
    }

    @Test("requireEntry returns value for present entries")
    func requireEntryReturns() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        let value = try obj.requireEntry(.type)
        #expect(value.nameValue == .page)
    }

    @Test("optionalEntry returns nil for missing entries")
    func optionalEntryNil() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        let value = obj.optionalEntry("Missing")
        #expect(value == nil)
    }

    @Test("optionalEntry returns value for present entries")
    func optionalEntryReturns() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        let value = obj.optionalEntry(.type)
        #expect(value?.nameValue == .page)
    }

    // MARK: - Name Access Tests

    @Test("requireName throws for missing entries")
    func requireNameMissing() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        #expect(throws: PDError.missingRequiredEntry(key: "Missing")) {
            try obj.requireName("Missing")
        }
    }

    @Test("requireName throws for incorrect type")
    func requireNameWrongType() throws {
        let dict: COSValue = [.type: .integer(42)]
        let obj = try TestPDObject(cosObject: dict)

        #expect(throws: (any Error).self) {
            try obj.requireName(.type)
        }
    }

    @Test("requireName returns name for valid entries")
    func requireNameValid() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        let name = try obj.requireName(.type)
        #expect(name == .page)
    }

    @Test("optionalName returns nil for missing entries")
    func optionalNameMissing() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        let name = obj.optionalName("Missing")
        #expect(name == nil)
    }

    @Test("optionalName returns nil for incorrect type")
    func optionalNameWrongType() throws {
        let dict: COSValue = [.type: .integer(42)]
        let obj = try TestPDObject(cosObject: dict)

        let name = obj.optionalName(.type)
        #expect(name == nil)
    }

    @Test("optionalName returns name for valid entries")
    func optionalNameValid() throws {
        let dict: COSValue = [.type: .name(.page)]
        let obj = try TestPDObject(cosObject: dict)

        let name = obj.optionalName(.type)
        #expect(name == .page)
    }

    // MARK: - Integer Access Tests

    @Test("requireInteger works correctly")
    func requireInteger() throws {
        let dict: COSValue = [.count: .integer(10)]
        let obj = try TestPDObject(cosObject: dict)

        let value = try obj.requireInteger(.count)
        #expect(value == 10)

        #expect(throws: (any Error).self) {
            try obj.requireInteger("Missing")
        }
    }

    @Test("optionalInteger works correctly")
    func optionalInteger() throws {
        let dict: COSValue = [.count: .integer(10)]
        let obj = try TestPDObject(cosObject: dict)

        let value = obj.optionalInteger(.count)
        #expect(value == 10)

        let missing = obj.optionalInteger("Missing")
        #expect(missing == nil)
    }

    // MARK: - Array Access Tests

    @Test("requireArray works correctly")
    func requireArray() throws {
        let dict: COSValue = [.kids: .array([.integer(1), .integer(2)])]
        let obj = try TestPDObject(cosObject: dict)

        let value = try obj.requireArray(.kids)
        #expect(value.count == 2)

        #expect(throws: (any Error).self) {
            try obj.requireArray("Missing")
        }
    }

    @Test("optionalArray works correctly")
    func optionalArray() throws {
        let dict: COSValue = [.kids: .array([.integer(1), .integer(2)])]
        let obj = try TestPDObject(cosObject: dict)

        let value = obj.optionalArray(.kids)
        #expect(value?.count == 2)

        let missing = obj.optionalArray("Missing")
        #expect(missing == nil)
    }

    // MARK: - Dictionary Access Tests

    @Test("requireDictionary works correctly")
    func requireDictionary() throws {
        let innerDict: COSValue = [.type: .name(.page)]
        let dict: COSValue = [.resources: innerDict]
        let obj = try TestPDObject(cosObject: dict)

        let value = try obj.requireDictionary(.resources)
        #expect(value.count == 1)

        #expect(throws: (any Error).self) {
            try obj.requireDictionary("Missing")
        }
    }

    @Test("optionalDictionary works correctly")
    func optionalDictionary() throws {
        let innerDict: COSValue = [.type: .name(.page)]
        let dict: COSValue = [.resources: innerDict]
        let obj = try TestPDObject(cosObject: dict)

        let value = obj.optionalDictionary(.resources)
        #expect(value?.count == 1)

        let missing = obj.optionalDictionary("Missing")
        #expect(missing == nil)
    }

    // MARK: - PDError Tests

    @Test("PDError descriptions are correct")
    func errorDescriptions() {
        let error1 = PDError.missingRequiredEntry(key: "Test")
        #expect(error1.description.contains("Missing required entry: Test"))

        let error2 = PDError.incorrectType(key: "Type", expected: "name", actual: "integer")
        #expect(error2.description.contains("Incorrect type"))

        let error3 = PDError.notADictionary
        #expect(error3.description.contains("not a dictionary"))

        let error4 = PDError.notAnArray
        #expect(error4.description.contains("not an array"))

        let error5 = PDError.pageIndexOutOfBounds(index: 5, count: 3)
        #expect(error5.description.contains("out of bounds"))

        let error6 = PDError.invalidPageTree(reason: "test")
        #expect(error6.description.contains("Invalid page tree"))

        let error7 = PDError.invalidDocument(reason: "test")
        #expect(error7.description.contains("Invalid document"))
    }
}
