# SwiftVerificar-parser Porting TODO

## Source Repository

**Source:** [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
**Branch:** `integration`
**License:** GPLv3+ / MPLv2+ (dual-licensed)

---

## Overview

This document provides a comprehensive porting plan for converting veraPDF-parser (~200 Java classes) to Swift. The parser provides two abstraction layers:

1. **COS Layer** - Low-level PDF object model (Carousel Object System)
2. **PD Layer** - High-level, typed PDF document model

### Swift Advantages to Leverage

- **Value types** (structs) for immutable PDF objects
- **Enums with associated values** for type-safe object representation
- **Protocols with default implementations** instead of abstract classes
- **Result types** for error handling instead of exceptions
- **Async/await** for I/O operations
- **Copy-on-write** for efficient immutable collections
- **Property wrappers** for lazy loading
- **PDFKit/CoreGraphics** integration where possible

---

## Phase 1: Foundation Types (COS Layer Core)

### 1.1 COS Object Type System

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `COSObjType` (enum) | `COSObjectType` (enum) | Direct port |
| `COSBase` (abstract) | `COSObject` (protocol) | Protocol with associated type |
| `COSDirect` (abstract) | Part of `COSValue` enum | Use enum with associated values |
| `COSIndirect` | `COSReference` (struct) | Simple value type |
| `COSObject` (wrapper) | `COSValue` (enum) | **Consolidate** - enum cases for each type |

**Swift Idiom Consolidation:**
```swift
// Consolidate COSBase hierarchy into a single enum
enum COSValue: Sendable, Equatable {
    case null
    case boolean(Bool)
    case integer(Int64)
    case real(Double)
    case string(COSString)
    case name(ASAtom)
    case array([COSValue])
    case dictionary([ASAtom: COSValue])
    case stream(COSStream)
    case reference(COSReference)
}
```

**Classes to Consolidate:**
- `COSNull`, `COSBoolean`, `COSInteger`, `COSReal`, `COSString`, `COSName`, `COSArray`, `COSDictionary` → Single `COSValue` enum
- Eliminates need for visitor pattern in most cases

### 1.2 Core Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `COSKey` | `COSObjectKey` (struct) | `Hashable`, `Comparable` |
| `COSString` | `COSString` (struct) | Store raw bytes + encoding info |
| `ASAtom` | `ASAtom` (struct) | Interned name table using `StaticString` or string interning |
| `COSStream` | `COSStream` (struct/class) | Consider class for large data |
| `COSHeader` | `PDFHeader` (struct) | Version info |
| `COSTrailer` | `PDFTrailer` (struct) | Root, info, encrypt refs |

### 1.3 ASAtom Implementation

```swift
// High-performance name interning
struct ASAtom: Hashable, Sendable, ExpressibleByStringLiteral {
    private let index: UInt32  // Index into interned table

    // Predefined atoms (compile-time constants)
    static let type: ASAtom = "Type"
    static let subtype: ASAtom = "Subtype"
    static let bbox: ASAtom = "BBox"
    // ... hundreds more predefined names
}
```

### 1.4 Character Tables

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `CharTable` | `PDFCharacterSet` (enum/struct) | Use `CharacterSet` where possible |

---

## Phase 2: Stream and Filter System

### 2.1 Input/Output Streams

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `ASInputStream` (abstract) | `PDFInputStream` (protocol) | Async stream protocol |
| `ASOutputStream` (abstract) | `PDFOutputStream` (protocol) | Async write protocol |
| `ASMemoryInStream` | `DataInputStream` (struct) | Wrap `Data` |
| `ASConcatenatedInputStream` | `ConcatenatedInputStream` | Use `AsyncSequence` |
| `SeekableInputStream` | `SeekableStream` (protocol) | Add seeking capability |

**Swift Improvement:**
```swift
protocol PDFInputStream: AsyncSequence where Element == UInt8 {
    var position: Int64 { get }
    func read(_ buffer: inout [UInt8], maxLength: Int) async throws -> Int
}

protocol SeekablePDFInputStream: PDFInputStream {
    func seek(to position: Int64) async throws
}
```

### 2.2 Filter System

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `IASFilterFactory` (interface) | `PDFFilterFactory` (protocol) | Factory protocol |
| `ASFilterFactory` | `DefaultFilterFactory` | Default impl |
| `COSFilterRegistry` | `FilterRegistry` (actor) | Thread-safe registry |
| `COSFilterFlateDecode` | `FlateDecodeFilter` | Use `Compression` framework |
| `COSFilterLZWDecode` | `LZWDecodeFilter` | Manual implementation |
| `COSFilterASCII85Decode` | `ASCII85Filter` | Pure Swift |
| `COSFilterASCIIHexDecode` | `ASCIIHexFilter` | Pure Swift |
| `COSFilterAESDecryptionDefault` | `AESDecryptFilter` | Use `CryptoKit` |
| `COSFilterRC4DecryptionDefault` | `RC4DecryptFilter` | Use `CryptoKit` or manual |
| `COSPredictorDecode` | `PredictorFilter` | PNG/TIFF predictors |
| `RunLengthDecode` | `RunLengthFilter` | Pure Swift |

**Performance Note:** Use `Compression` framework for Flate where possible (hardware acceleration).

---

## Phase 3: Parser Infrastructure

### 3.1 Tokenizer

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `Token` | `PDFToken` (enum) | Enum with associated values |
| `Token.Type` (enum) | Part of `PDFToken` | Consolidate |
| `Token.Keyword` (enum) | `PDFKeyword` (enum) | Separate enum |

**Swift Consolidation:**
```swift
enum PDFToken: Equatable {
    case keyword(PDFKeyword)
    case integer(Int64)
    case real(Double)
    case string(Data)
    case hexString(Data)
    case name(ASAtom)
    case arrayStart, arrayEnd
    case dictionaryStart, dictionaryEnd
    case comment(String)
    case endOfFile
}

enum PDFKeyword: String, CaseIterable {
    case `true`, `false`, null
    case obj, endobj, stream, endstream
    case xref, trailer, startxref
    case R  // indirect reference
}
```

### 3.2 Parser Hierarchy

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `BaseParser` (abstract) | `PDFTokenizer` (struct) | Tokenization only |
| `COSParser` (abstract) | `COSParser` (protocol) | Object parsing |
| `PDFParser` | `PDFDocumentParser` (struct) | Full document parser |
| `PDFStreamParser` | `ContentStreamParser` (struct) | Content stream ops |
| `XRefReader` | `XRefParser` (struct) | XRef parsing |
| `XrefStreamParser` | Part of `XRefParser` | Consolidate |

**Swift Improvement - Streaming Parser:**
```swift
struct PDFDocumentParser {
    func parse(from stream: SeekablePDFInputStream) async throws -> ParsedPDFDocument
}

// Use AsyncSequence for content streams
struct ContentStreamParser: AsyncSequence {
    typealias Element = PDFOperation
    // Yields operations lazily
}
```

### 3.3 Cross-Reference Table

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `COSXRefTable` | `XRefTable` (struct) | Main xref structure |
| `COSXRefSection` | Part of `XRefTable` | Consolidate |
| `COSXRefEntry` | `XRefEntry` (enum) | Free/InUse/Compressed |
| `COSXRefInfo` | Part of `XRefTable` | Consolidate |
| `COSXRefRange` | `Range<Int>` | Use stdlib |

---

## Phase 4: PD Layer - Document Model

### 4.1 Core Document Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDObject` | `PDObject` (protocol) | Base protocol |
| `PDDocument` | `PDFDocument` (class) | Main document, consider actor |
| `PDCatalog` | `PDFCatalog` (struct) | Document catalog |
| `PDPage` | `PDFPage` (struct) | Single page |
| `PDPageTree` | `PDFPageTree` (struct) | Lazy page access |
| `PDResources` | `PDFResources` (struct) | Resource dictionary |
| `PDContentStream` | `PDFContentStream` (struct) | Content stream wrapper |

**Swift Improvement - Lazy Loading:**
```swift
@propertyWrapper
struct LazyLoaded<T> {
    private var value: T?
    private let loader: () throws -> T

    var wrappedValue: T {
        mutating get throws {
            if let value { return value }
            let loaded = try loader()
            value = loaded
            return loaded
        }
    }
}

struct PDFPage {
    @LazyLoaded var contents: PDFContentStream
    @LazyLoaded var resources: PDFResources
}
```

### 4.2 Metadata and Structure

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDMetadata` | `XMPMetadata` (struct) | Use `XMLParser` |
| `PDStructTreeRoot` | `StructureTreeRoot` (struct) | Tagged PDF root |
| `PDStructTreeNode` (abstract) | `StructureNode` (protocol) | Node protocol |
| `PDStructElem` | `StructureElement` (struct) | Structure element |
| `PDStructureNameSpace` | `StructureNamespace` (struct) | PDF 2.0 namespaces |
| `StructureType` | `StructureType` (struct) | Type + namespace |
| `PDNameTreeNode` | `NameTree<T>` (struct) | Generic name tree |
| `PDNumberTreeNode` | `NumberTree<T>` (struct) | Generic number tree |

---

## Phase 5: Font System

### 5.1 Font Base Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `FontProgram` (interface) | `FontProgram` (protocol) | Core font protocol |
| `PDFont` (abstract) | `PDFFont` (protocol) | PD font protocol |
| `PDSimpleFont` (abstract) | `SimpleFont` (protocol) | Simple font protocol |
| `PDFontDescriptor` | `FontDescriptor` (struct) | Descriptor |
| `Encoding` | `FontEncoding` (struct) | Font encoding |

### 5.2 Font Types

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDType1Font` | `Type1Font` (struct) | Type 1 font |
| `PDTrueTypeFont` | `TrueTypeFont` (struct) | TrueType font |
| `PDType3Font` | `Type3Font` (struct) | Type 3 font |
| `PDType0Font` | `Type0Font` (struct) | Composite font |
| `PDCIDFont` | `CIDFont` (struct) | CID font |

### 5.3 Font Programs

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `Type1FontProgram` | `Type1Program` (struct) | Type 1 program |
| `TrueTypeFontProgram` | `TrueTypeProgram` (struct) | Consider `CTFont` integration |
| `CFFFontProgram` | `CFFProgram` (struct) | CFF program |
| `CFFType1FontProgram` | Part of `CFFProgram` | Consolidate |
| `CFFCIDFontProgram` | Part of `CFFProgram` | Consolidate |
| `OpenTypeFontProgram` | `OpenTypeProgram` (struct) | OpenType |

**CoreText Integration:**
```swift
// Use CoreText for glyph/width information where possible
protocol FontProgram {
    var ctFont: CTFont? { get }  // Optional CoreText backing
    func width(for glyphID: UInt16) -> Double
    func glyphName(for glyphID: UInt16) -> String?
}
```

### 5.4 CMap System

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `CMap` | `CMap` (struct) | Character mapping |
| `PDCMap` | `PDFCMap` (struct) | PD wrapper |
| `CMapFile` | Part of `CMap` | Consolidate |
| `CMapParser` | `CMapParser` (struct) | Parser |
| `CodeSpace` | `CodeSpaceRange` (struct) | Code space |
| `CIDInterval` | `CIDMapping` (enum) | Mapping types |
| `ToUnicodeInterval` | `UnicodeMapping` (struct) | Unicode mapping |
| `IdentityCMap` | Static on `CMap` | Identity CMap |

### 5.5 Font Parsing

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `TrueTypeFontParser` | `TrueTypeParser` (struct) | TrueType parser |
| `TrueTypeTable` | `TrueTypeTable` (protocol) | Table protocol |
| `TrueTypeCmapTable` | `CmapTable` (struct) | cmap table |
| `TrueTypeHeadTable` | `HeadTable` (struct) | head table |
| `TrueTypeHheaTable` | `HheaTable` (struct) | hhea table |
| `TrueTypeHmtxTable` | `HmtxTable` (struct) | hmtx table |
| `AFMParser` | `AFMParser` (struct) | AFM parser |
| `StandardFontMetrics` | `StandardMetrics` (struct) | Standard 14 metrics |

---

## Phase 6: Color Spaces

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDColorSpace` (abstract) | `PDFColorSpace` (protocol) | Color space protocol |
| `PDDeviceGray` | `DeviceGrayColorSpace` | Use `CGColorSpace` |
| `PDDeviceRGB` | `DeviceRGBColorSpace` | Use `CGColorSpace` |
| `PDDeviceCMYK` | `DeviceCMYKColorSpace` | Use `CGColorSpace` |
| `PDCalGray` | `CalGrayColorSpace` | Calibrated gray |
| `PDCalRGB` | `CalRGBColorSpace` | Calibrated RGB |
| `PDLab` | `LabColorSpace` | CIE Lab |
| `PDICCBased` | `ICCBasedColorSpace` | ICC profile based |
| `PDIndexed` | `IndexedColorSpace` | Indexed |
| `PDSeparation` | `SeparationColorSpace` | Separation |
| `PDDeviceN` | `DeviceNColorSpace` | DeviceN |

**CoreGraphics Integration:**
```swift
protocol PDFColorSpace {
    var cgColorSpace: CGColorSpace? { get }
    var numberOfComponents: Int { get }
    func toRGB(_ components: [Double]) -> (r: Double, g: Double, b: Double)
}
```

---

## Phase 7: XObjects and Patterns

### 7.1 XObjects

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDXObject` (abstract) | `PDFXObject` (protocol) | XObject protocol |
| `PDXImage` | `ImageXObject` (struct) | Image XObject |
| `PDXForm` | `FormXObject` (struct) | Form XObject |
| `PDXPostScript` | `PostScriptXObject` (struct) | PS XObject |
| `PDInlineImage` | `InlineImage` (struct) | Inline image |

### 7.2 Patterns

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDPattern` | `PDFPattern` (protocol) | Pattern protocol |
| `PDTilingPattern` | `TilingPattern` (struct) | Tiling |
| `PDShadingPattern` | `ShadingPattern` (struct) | Shading pattern |
| `PDShading` | `Shading` (struct) | Shading definition |

---

## Phase 8: Graphics State and Operations

### 8.1 Graphics State

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDExtGState` | `ExtendedGraphicsState` (struct) | ExtGState |
| `PDGroup` | `TransparencyGroup` (struct) | Transparency group |
| `PDHalftone` | `Halftone` (struct) | Halftone |

### 8.2 Operators

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `Operator` | `PDFOperator` (enum) | Content stream operators |
| `InlineImageOperator` | Part of `PDFOperator` | Inline image case |
| `Operators` (constants) | Part of `PDFOperator` | Static properties |

**Swift Consolidation:**
```swift
enum PDFOperator: Equatable {
    // Graphics state
    case saveState           // q
    case restoreState        // Q
    case setMatrix(CGAffineTransform)  // cm
    case setLineWidth(Double)  // w
    case setLineCap(Int)     // J
    case setLineJoin(Int)    // j
    // ... many more

    // Text
    case beginText           // BT
    case endText             // ET
    case setFont(ASAtom, Double)  // Tf
    case showText(Data)      // Tj
    // ... many more

    // Path
    case moveTo(Double, Double)  // m
    case lineTo(Double, Double)  // l
    case curveTo(...)        // c, v, y
    case closePath           // h
    case stroke              // S
    case fill                // f
    // ... many more
}
```

---

## Phase 9: Annotations and Actions

### 9.1 Annotations

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDAnnotation` | `PDFAnnotation` (struct) | Base annotation |
| `PDWidgetAnnotation` | `WidgetAnnotation` (struct) | Form widget |
| `PDAppearanceStream` | `AppearanceStream` (struct) | Appearance |
| `PDAppearanceEntry` | `AppearanceEntry` (struct) | AP entry |

### 9.2 Actions

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDAction` | `PDFAction` (enum) | Action types |
| `PDAbstractAdditionalActions` | `AdditionalActions` (struct) | Additional actions |
| `PDMediaClip` | `MediaClip` (struct) | Media clip |

---

## Phase 10: Encryption and Security

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `PDEncryption` | `EncryptionDict` (struct) | Encryption dictionary |
| `PDCryptFilter` | `CryptFilter` (struct) | Crypt filter |
| `StandardSecurityHandler` | `StandardSecurity` (struct) | Use `CryptoKit` |
| `AccessPermissions` | `AccessPermissions` (OptionSet) | Use OptionSet |
| `EncryptionToolsRevision4` | Part of `StandardSecurity` | Consolidate |
| `EncryptionToolsRevision5_6` | Part of `StandardSecurity` | Consolidate |
| `RC4Encryption` | Use `CryptoKit` | Remove custom impl |

---

## Phase 11: External Objects

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `ICCProfile` | `ICCProfile` (struct) | Use `CGColorSpace` |
| `JPEG2000` | `JPEG2000Image` (struct) | Use `ImageIO` |

---

## Phase 12: Utilities

| Java Class | Swift Equivalent | Notes |
|------------|-----------------|-------|
| `StaticResources` | `ParserContext` (class/actor) | Thread-local → Actor |
| `TypeConverter` | Extensions on types | Swift extensions |
| `PDFDocEncoding` | `PDFEncoding` (enum) | Encoding utilities |
| `PageLabels` | `PageLabelParser` (struct) | Page labels |
| `TaggedPDFConstants` | `TaggedPDFConstants` (enum) | Structure type constants |
| `TaggedPDFHelper` | `TaggedPDFHelper` (enum) | Static methods |
| `TaggedPDFRoleMapHelper` | `RoleMapResolver` (struct) | Role mapping |
| `FontProgramIDGenerator` | `FontIDGenerator` (struct) | ID generation |

---

## Testing Strategy

### Unit Tests

1. **Tokenizer Tests**
   - Test all token types
   - Test edge cases (malformed tokens, Unicode)
   - Test comment handling

2. **COS Object Tests**
   - Test each object type creation/access
   - Test dictionary operations
   - Test array operations
   - Test stream decoding with all filters

3. **Parser Tests**
   - Test header parsing (various PDF versions)
   - Test xref parsing (table and stream formats)
   - Test trailer parsing
   - Test incremental updates

4. **Font Tests**
   - Test Type 1 parsing
   - Test TrueType parsing
   - Test CFF parsing
   - Test CMap parsing
   - Test encoding handling

5. **Color Space Tests**
   - Test each color space type
   - Test color conversion to RGB

### Integration Tests

1. **Document Loading**
   - Load reference PDFs from veraPDF test corpus
   - Verify page count, metadata extraction
   - Test structure tree extraction

2. **Content Stream Parsing**
   - Parse and validate operator sequences
   - Test text extraction accuracy

3. **Encryption Tests**
   - Test password-protected documents (R2-R6)
   - Test permissions handling

### Performance Tests

1. **Large Document Tests**
   - Memory usage during parsing
   - Parsing speed benchmarks

2. **Lazy Loading Tests**
   - Verify objects loaded on-demand
   - Test seeking efficiency

---

## Phased Implementation

### Phase 1: MVP (Critical for PDF/UA validation)
1. COS object model (`COSValue` enum)
2. Basic tokenizer and parser
3. XRef table parsing
4. Document structure (catalog, pages)
5. Structure tree parsing (critical for PDF/UA)
6. XMP metadata extraction

### Phase 2: Complete Parsing
1. All stream filters
2. Font system (basic)
3. Color spaces
4. Content stream parsing

### Phase 3: Full Font Support
1. Complete font parsing (Type1, TrueType, CFF)
2. CMap support
3. ToUnicode mapping
4. Glyph width extraction

### Phase 4: Advanced Features
1. Encryption support
2. Digital signatures
3. Form fields
4. Annotations

---

## Performance Optimizations

1. **String Interning for ASAtom**
   - Use compile-time constants for common names
   - Single global intern table

2. **Lazy Object Loading**
   - Parse object only when accessed
   - Use `@LazyLoaded` property wrapper

3. **Memory-Mapped I/O**
   - Use `DispatchData` or `mmap` for large files
   - Efficient seeking without loading entire file

4. **Copy-on-Write Collections**
   - Use Swift's COW semantics for arrays/dictionaries
   - Avoid unnecessary copying

5. **Compression Framework**
   - Use Apple's `Compression` for Flate (hardware acceleration)

6. **CoreText Integration**
   - Use `CTFont` for glyph metrics where possible
   - Avoid re-parsing font data CoreText already handles

7. **Parallel Parsing**
   - Parse independent objects concurrently
   - Use `TaskGroup` for multi-page processing

---

## Class Count Summary

| Category | Java Classes | Swift Types | Reduction |
|----------|-------------|-------------|-----------|
| COS Objects | 15 | 3 (enum + structs) | 80% |
| Parsers | 12 | 6 | 50% |
| Filters | 12 | 10 | 17% |
| Fonts | 40 | 25 | 38% |
| Color Spaces | 12 | 12 | 0% |
| Structure | 10 | 8 | 20% |
| Utilities | 15 | 10 | 33% |
| **Total** | ~200 | ~100 | **50%** |

The consolidation primarily comes from:
- Using enums with associated values instead of class hierarchies
- Consolidating abstract classes into protocols
- Using Swift stdlib types (Range, OptionSet, etc.)
- Removing visitor pattern (pattern matching instead)
