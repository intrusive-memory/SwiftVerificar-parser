# SwiftVerificarParser -- Agent Instructions

## Module

`SwiftVerificarParser` (import name: `import SwiftVerificarParser`)

## What This Library Does

SwiftVerificarParser is a native Swift PDF parsing library for the SwiftVerificar ecosystem. It provides:

- **PDF document structure parsing** -- header, cross-reference tables, trailer, indirect object retrieval
- **Tagged PDF structure tree extraction** -- critical for PDF/UA (Universal Accessibility) validation
- **XMP metadata handling** -- Dublin Core, PDF/A identification, PDF/UA identification
- **Complete COS (Carousel Object System) object model** -- the foundational PDF value types
- **Content stream parsing** -- PDF operators and operands for page rendering instructions
- **Font system** -- Type1, TrueType, Type0, CID font parsing with font descriptors and encodings
- **Color space support** -- Device, CIE-based, ICC, Indexed, Separation, DeviceN, Pattern
- **Stream filters** -- Flate, LZW, ASCII85, ASCIIHex, RunLength, AES/RC4 decrypt, Predictor
- **Text extraction** -- PDFTextStripper with TextPosition, TextLine, TextBlock
- **XObject support** -- Image, Form, PostScript XObjects, inline images, tiling/shading patterns

No external dependencies (Foundation only). 86+ public types. 2700+ tests. Swift 6.0 strict concurrency -- all public types are Sendable.

## Architecture Layers

The library is organized in four layers, from low-level to high-level:

```
COS (Carousel Object System)
  COSValue, ASAtom, COSString, COSReference, COSObjectKey, COSStream, PDFHeader, PDFTrailer

Stream / Filter
  PDFInputStream, PDFOutputStream, DataInputStream, SeekableStream, ConcatenatedInputStream
  FlateDecodeFilter, LZWDecodeFilter, ASCII85Filter, ASCIIHexFilter, RunLengthFilter,
  AESDecryptFilter, RC4DecryptFilter, PredictorFilter, FilterRegistry

Parser
  PDFTokenizer, PDFToken, ObjectParser, PDFDocumentParser, XRefParser, XRefTable,
  ContentStreamParser, PDFOperator, GraphicsState, TextState

PD (Page Description) -- high-level document model
  PDFDocument (class), PDFCatalog, PDFPageTree, PDFPage, PDFResources, PDFContentStream
  PDStructTreeRoot, PDStructElement, PDMarkedContent, PDRoleMap, PDClassMap, PDAttributeObject
  PDFFont, Type1Font, TrueTypeFont, Type0Font, CIDFont, FontDescriptor, FontEncoding
  DeviceGrayColorSpace, DeviceRGBColorSpace, DeviceCMYKColorSpace, ICCBasedColorSpace,
    CalGrayColorSpace, CalRGBColorSpace, LabColorSpace, IndexedColorSpace,
    SeparationColorSpace, DeviceNColorSpace, PatternColorSpace
  ImageXObject, FormXObject, PostScriptXObject, InlineImage
  TilingPattern, ShadingPattern, Shading
  PDFTextStripper, TextPosition, TextLine, TextBlock
```

## Key Public Types

### Entry Points

- **`PDFDocumentParser`** -- Top-level parser. Creates a parsed document from a `SeekableStream`. Provides access to the PDF header, cross-reference table, trailer, and indirect object retrieval with caching.
  ```swift
  let stream = try DataInputStream(data: pdfData)
  let parser = try await PDFDocumentParser(stream: stream)
  let catalog = try await parser.getObject(key: catalogKey)
  ```

- **`PDFDocument`** (class, in `PD/PDFDocument.swift`) -- Complete parsed PDF document with pages, catalog, trailer, and xref table. The document-level model after full parsing.

- **`PDFDocument`** (struct, in `SwiftVerificarParser.swift`) -- High-level facade with `metadata: PDFMetadata?`, `structureTree: PDFStructureTree?`, and `xmpMetadata: XMPMetadata?`.

### COS Layer

- **`COSValue`** -- Foundational enum representing any PDF object value. Cases: `.null`, `.boolean(Bool)`, `.integer(Int64)`, `.real(Double)`, `.string(COSString)`, `.name(ASAtom)`, `.array([COSValue])`, `.dictionary([ASAtom: COSValue])`, `.reference(COSReference)`. Supports subscript access, literal conformances, Codable, Hashable.

- **`ASAtom`** -- Interned PDF name objects (e.g., `/Type`, `/Page`). Predefined constants for common PDF names.

- **`COSString`** -- PDF string objects (literal or hex-encoded). Handles encoding/decoding.

- **`COSReference`** -- Indirect object references (object number + generation number).

- **`COSObjectKey`** -- Key for identifying indirect objects (object number + generation).

- **`COSStream`** -- PDF stream objects (dictionary + byte stream data).

### Structure Tree (Tagged PDF / PDF/UA)

- **`PDStructTreeRoot`** -- Root of the structure tree. Access role maps, class maps, parent tree, children.
- **`PDStructElement`** -- Individual structure element with type, title, alt text, language, children.
- **`PDMarkedContent`** -- Marked content sequences within content streams.
- **`PDRoleMap`** -- Maps custom structure roles to standard types.
- **`PDClassMap`** -- Maps class names to attribute dictionaries.

### Content Stream Parsing

- **`ContentStreamParser`** -- Parses PDF content streams into operator sequences.
- **`PDFOperator`** -- Represents a PDF operator with its operands.

### Font System

- **`PDFFont`** -- Protocol for all PDF font types.
- **`Type1Font`**, **`TrueTypeFont`**, **`Type0Font`**, **`CIDFont`** -- Font type implementations.
- **`FontDescriptor`** -- Font metrics and flags.

### Color Spaces

- **`PDFColorSpace`** -- Protocol for color spaces.
- Device: `DeviceGrayColorSpace`, `DeviceRGBColorSpace`, `DeviceCMYKColorSpace`
- CIE-based: `CalGrayColorSpace`, `CalRGBColorSpace`, `LabColorSpace`
- ICC: `ICCBasedColorSpace`
- Special: `IndexedColorSpace`, `SeparationColorSpace`, `DeviceNColorSpace`, `PatternColorSpace`

### XMP Metadata

- **`XMPMetadata`** -- XMP metadata with Dublin Core properties (`dcTitle`, `dcCreator`, `dcDescription`, `dcSubject`), PDF/A identification (`pdfaPart`, `pdfaConformance`), and PDF/UA identification (`pdfuaPart`).

### Filter System

- `FlateDecodeFilter`, `LZWDecodeFilter`, `ASCII85Filter`, `ASCIIHexFilter`, `RunLengthFilter`
- `AESDecryptFilter`, `RC4DecryptFilter`, `PredictorFilter`
- `PDFFilterFactory`, `FilterRegistry`, `DefaultFilterFactory`

## Build Commands

**CRITICAL: NEVER use `swift build` or `swift test`. Always use `xcodebuild`.**

```bash
# Build (must cd to package directory first)
cd /Users/stovak/Projects/SwiftVerificar/SwiftVerificar-parser
xcodebuild build -scheme SwiftVerificarParser -destination 'platform=macOS'

# Test
cd /Users/stovak/Projects/SwiftVerificar/SwiftVerificar-parser
xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'
```

## Testing Framework

This library uses the **Swift Testing** framework (not XCTest):

```swift
import Testing

@Suite("COSValue Tests")
struct COSValueTests {
    @Test("Integer creation and extraction")
    func integerValue() {
        let value: COSValue = .integer(42)
        #expect(value.integerValue == 42)
        #expect(value.isInteger)
    }
}
```

Key patterns:
- `import Testing` (not `import XCTest`)
- `@Suite` for test groupings
- `@Test` for individual test functions
- `#expect(...)` for assertions (not `XCTAssertEqual`)
- No class inheritance required

## Concurrency Model

Swift 6.0 strict concurrency is enforced. All public types conform to `Sendable`:
- Value types (structs, enums) are inherently Sendable
- `PDFDocumentParser` uses `@unchecked Sendable` with internal isolation guarantees
- Async/await is used for I/O operations (stream reading, object parsing)

## Dependencies

None. Foundation only. No third-party packages.

## Package Configuration

- Swift tools version: 6.0
- Platforms: macOS 14.0+, iOS 17.0+
- Library product: `SwiftVerificarParser`
- Test target: `SwiftVerificarParserTests`

## Stats

- 86+ public types
- 2700+ tests
- 14 implementation sprints
- 90%+ test coverage target per sprint
