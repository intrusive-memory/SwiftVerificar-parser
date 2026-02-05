import Testing
@testable import SwiftVerificarParser

@Suite("PDFResources Tests")
struct PDFResourcesTests {

    // MARK: - Initialization Tests

    @Test("PDFResources requires dictionary")
    func requiresDictionary() throws {
        #expect(throws: PDError.notADictionary) {
            try PDFResources(cosObject: .null)
        }

        #expect(throws: PDError.notADictionary) {
            try PDFResources(cosObject: .array([]))
        }
    }

    @Test("PDFResources accepts valid dictionary")
    func acceptsValidDictionary() throws {
        let resourcesDict: COSValue = [
            .font: [ASAtom("F1"): .reference(COSReference(objectNumber: 10))]
        ]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.cosObject.isDictionary)
    }

    @Test("PDFResources accepts empty dictionary")
    func acceptsEmptyDictionary() throws {
        let resourcesDict: COSValue = .dictionary([:])
        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.cosObject.isDictionary)
    }

    // MARK: - Resource Dictionary Tests

    @Test("fonts returns font dictionary")
    func fonts() throws {
        let fontDict: COSValue = [
            ASAtom("F1"): .reference(COSReference(objectNumber: 10)),
            ASAtom("F2"): .reference(COSReference(objectNumber: 11))
        ]
        let resourcesDict: COSValue = [.font: fontDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.fonts != nil)
        #expect(resources.fonts?.isDictionary == true)
    }

    @Test("fonts returns nil when missing")
    func fontsMissing() throws {
        let resourcesDict: COSValue = .dictionary([:])
        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.fonts == nil)
    }

    @Test("xObjects returns XObject dictionary")
    func xObjects() throws {
        let xObjectDict: COSValue = [
            ASAtom("Im1"): .reference(COSReference(objectNumber: 20)),
            ASAtom("Fm1"): .reference(COSReference(objectNumber: 21))
        ]
        let resourcesDict: COSValue = [.xObject: xObjectDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.xObjects != nil)
        #expect(resources.xObjects?.isDictionary == true)
    }

    @Test("colorSpaces returns color space dictionary")
    func colorSpaces() throws {
        let csDict: COSValue = [
            ASAtom("CS1"): .reference(COSReference(objectNumber: 30))
        ]
        let resourcesDict: COSValue = [.colorSpace: csDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.colorSpaces != nil)
    }

    @Test("patterns returns pattern dictionary")
    func patterns() throws {
        let patternDict: COSValue = [
            ASAtom("P1"): .reference(COSReference(objectNumber: 40))
        ]
        let resourcesDict: COSValue = [.pattern: patternDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.patterns != nil)
    }

    @Test("shadings returns shading dictionary")
    func shadings() throws {
        let shadingDict: COSValue = [
            ASAtom("Sh1"): .reference(COSReference(objectNumber: 50))
        ]
        let resourcesDict: COSValue = ["Shading": shadingDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.shadings != nil)
    }

    @Test("extGStates returns ExtGState dictionary")
    func extGStates() throws {
        let extGStateDict: COSValue = [
            ASAtom("GS1"): .reference(COSReference(objectNumber: 60))
        ]
        let resourcesDict: COSValue = [.extGState: extGStateDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.extGStates != nil)
    }

    @Test("properties returns properties dictionary")
    func properties() throws {
        let propertiesDict: COSValue = [
            ASAtom("MC1"): .reference(COSReference(objectNumber: 70))
        ]
        let resourcesDict: COSValue = [.properties: propertiesDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.properties != nil)
    }

    @Test("procSet returns procedure set array")
    func procSet() throws {
        let procSetArray: COSValue = .array([
            .name("PDF"),
            .name("Text"),
            .name("ImageC")
        ])
        let resourcesDict: COSValue = ["ProcSet": procSetArray]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.procSet != nil)
        #expect(resources.procSet?.count == 3)
    }

    // MARK: - Resource Lookup Tests

    @Test("font named returns font")
    func fontNamed() throws {
        let fontRef: COSValue = .reference(COSReference(objectNumber: 10))
        let fontDict: COSValue = [ASAtom("F1"): fontRef]
        let resourcesDict: COSValue = [.font: fontDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let font = resources.font(named: ASAtom("F1"))
        #expect(font != nil)
        #expect(font?.referenceValue?.objectNumber == 10)
    }

    @Test("font named returns nil for missing font")
    func fontNamedMissing() throws {
        let fontDict: COSValue = [ASAtom("F1"): .reference(COSReference(objectNumber: 10))]
        let resourcesDict: COSValue = [.font: fontDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let font = resources.font(named: ASAtom("F2"))
        #expect(font == nil)
    }

    @Test("xObject named returns XObject")
    func xObjectNamed() throws {
        let xObjectRef: COSValue = .reference(COSReference(objectNumber: 20))
        let xObjectDict: COSValue = [ASAtom("Im1"): xObjectRef]
        let resourcesDict: COSValue = [.xObject: xObjectDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let xObject = resources.xObject(named: ASAtom("Im1"))
        #expect(xObject != nil)
        #expect(xObject?.referenceValue?.objectNumber == 20)
    }

    @Test("colorSpace named returns color space")
    func colorSpaceNamed() throws {
        let csRef: COSValue = .reference(COSReference(objectNumber: 30))
        let csDict: COSValue = [ASAtom("CS1"): csRef]
        let resourcesDict: COSValue = [.colorSpace: csDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let cs = resources.colorSpace(named: ASAtom("CS1"))
        #expect(cs != nil)
        #expect(cs?.referenceValue?.objectNumber == 30)
    }

    @Test("pattern named returns pattern")
    func patternNamed() throws {
        let patternRef: COSValue = .reference(COSReference(objectNumber: 40))
        let patternDict: COSValue = [ASAtom("P1"): patternRef]
        let resourcesDict: COSValue = [.pattern: patternDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let pattern = resources.pattern(named: ASAtom("P1"))
        #expect(pattern != nil)
        #expect(pattern?.referenceValue?.objectNumber == 40)
    }

    @Test("shading named returns shading")
    func shadingNamed() throws {
        let shadingRef: COSValue = .reference(COSReference(objectNumber: 50))
        let shadingDict: COSValue = [ASAtom("Sh1"): shadingRef]
        let resourcesDict: COSValue = ["Shading": shadingDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let shading = resources.shading(named: ASAtom("Sh1"))
        #expect(shading != nil)
        #expect(shading?.referenceValue?.objectNumber == 50)
    }

    @Test("extGState named returns graphics state")
    func extGStateNamed() throws {
        let gsRef: COSValue = .reference(COSReference(objectNumber: 60))
        let gsDict: COSValue = [ASAtom("GS1"): gsRef]
        let resourcesDict: COSValue = [.extGState: gsDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let gs = resources.extGState(named: ASAtom("GS1"))
        #expect(gs != nil)
        #expect(gs?.referenceValue?.objectNumber == 60)
    }

    @Test("property named returns property")
    func propertyNamed() throws {
        let propRef: COSValue = .reference(COSReference(objectNumber: 70))
        let propDict: COSValue = [ASAtom("MC1"): propRef]
        let resourcesDict: COSValue = [.properties: propDict]

        let resources = try PDFResources(cosObject: resourcesDict)
        let prop = resources.property(named: ASAtom("MC1"))
        #expect(prop != nil)
        #expect(prop?.referenceValue?.objectNumber == 70)
    }

    // MARK: - Comprehensive Resources Test

    @Test("all resource types can coexist")
    func allResourceTypes() throws {
        let resourcesDict: COSValue = [
            .font: [ASAtom("F1"): .reference(COSReference(objectNumber: 10))],
            .xObject: [ASAtom("Im1"): .reference(COSReference(objectNumber: 20))],
            .colorSpace: [ASAtom("CS1"): .reference(COSReference(objectNumber: 30))],
            .pattern: [ASAtom("P1"): .reference(COSReference(objectNumber: 40))],
            "Shading": [ASAtom("Sh1"): .reference(COSReference(objectNumber: 50))],
            .extGState: [ASAtom("GS1"): .reference(COSReference(objectNumber: 60))],
            .properties: [ASAtom("MC1"): .reference(COSReference(objectNumber: 70))]
        ]

        let resources = try PDFResources(cosObject: resourcesDict)
        #expect(resources.fonts != nil)
        #expect(resources.xObjects != nil)
        #expect(resources.colorSpaces != nil)
        #expect(resources.patterns != nil)
        #expect(resources.shadings != nil)
        #expect(resources.extGStates != nil)
        #expect(resources.properties != nil)
    }

    // MARK: - Hashable Tests

    @Test("PDFResources is hashable")
    func hashable() throws {
        let resourcesDict: COSValue = [
            .font: [ASAtom("F1"): .reference(COSReference(objectNumber: 10))]
        ]
        let resources1 = try PDFResources(cosObject: resourcesDict)
        let resources2 = try PDFResources(cosObject: resourcesDict)

        #expect(resources1 == resources2)
        #expect(resources1.hashValue == resources2.hashValue)
    }
}
