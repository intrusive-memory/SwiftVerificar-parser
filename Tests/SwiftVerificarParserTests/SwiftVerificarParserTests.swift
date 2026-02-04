import Testing
@testable import SwiftVerificarParser

@Suite("SwiftVerificarParser Tests")
struct SwiftVerificarParserTests {

    @Test("Library version is set correctly")
    func versionIsSet() {
        #expect(SwiftVerificarParser.version == "0.1.0")
    }

    @Test("Parser can be instantiated")
    func canInstantiate() {
        let parser = SwiftVerificarParser()
        #expect(parser != nil)
    }
}
