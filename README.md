# SwiftVerificar-parser

Native Swift PDF parsing library for the SwiftVerificar ecosystem. Provides document structure parsing, tagged PDF structure tree extraction (critical for PDF/UA accessibility validation), XMP metadata handling, and a complete PDF object model. Part of the SwiftVerificar suite of libraries for PDF/A and PDF/UA validation.

## Overview

SwiftVerificarParser is a Swift port of [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser), providing:

- PDF document structure parsing (header, cross-reference tables, trailer, indirect objects)
- Tagged PDF structure tree extraction (PDStructTreeRoot, PDStructElement, role maps, class maps)
- XMP metadata handling (Dublin Core, PDF/A identification, PDF/UA identification)
- Complete COS (Carousel Object System) object model
- Content stream parsing (PDF operators and operands)
- Font system (Type1, TrueType, Type0, CID fonts)
- Color space support (Device, CIE-based, ICC, Indexed, Separation, DeviceN, Pattern)
- Text extraction (PDFTextStripper with positional text data)
- Stream filters (Flate, LZW, ASCII85, ASCIIHex, RunLength, AES/RC4 decrypt, Predictor)

**Stats**: 86+ public types, 2700+ tests, 14 implementation sprints, 90%+ coverage target.

## Requirements

- Swift 6.0+
- macOS 14.0+
- iOS 17.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftVerificar-parser.git", from: "0.2.0")
]
```

Then add `SwiftVerificarParser` as a dependency of your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftVerificarParser"]
)
```

## Usage

```swift
import SwiftVerificarParser

// Parse a PDF document
let stream = try DataInputStream(data: pdfData)
let parser = try await PDFDocumentParser(stream: stream)

// Access document metadata
print("PDF version: \(parser.header.version)")

// Retrieve objects by key
if let catalog = try await parser.getObject(key: catalogKey) {
    print("Catalog: \(catalog)")
}

// Work with COS values
let value: COSValue = .dictionary([.type: .name(.page)])
if let type = value.typeEntry {
    print("Type: \(type)")
}
```

## Source Reference

- **Original**: [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
- **Language**: Java -> Swift
- **License**: GPLv3+ / MPLv2+

## Porting Process

This library was ported from its Java source using a structured, AI-assisted methodology. The original veraPDF Java codebase was analyzed to extract type hierarchies, public APIs, and behavioral contracts. An execution plan decomposed the port into sequential sprints, each targeting a cohesive set of types with explicit entry/exit criteria (build must pass, all tests must pass, 90%+ coverage). AI coding agents (Claude) executed each sprint autonomously -- translating Java patterns to idiomatic Swift (enums for sealed hierarchies, structs for value types, actors for thread-safe singletons, async/await for concurrency), writing Swift Testing framework tests, and verifying builds with xcodebuild. A supervisor process coordinated sprint sequencing, tracked cross-package dependencies, and performed reconciliation passes to ensure type agreement across the five-package ecosystem. The result is a clean-room Swift implementation that preserves the original's validation semantics while embracing Swift 6 strict concurrency, value semantics, and protocol-oriented design.

## Development

### Building

```bash
xcodebuild build -scheme SwiftVerificarParser -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'
```

**IMPORTANT**: Never use `swift build` or `swift test`. Always use `xcodebuild`.
