# SwiftVerificar-parser — Agent Instructions

Swift port of [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser).

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for ecosystem overview, implementation roadmap, and general guidelines.

## Purpose

PDF parsing library providing:

- PDF document structure parsing
- Tagged PDF structure tree extraction (critical for PDF/UA validation)
- XMP metadata extraction
- PDF object model

## Source Reference

- **Original**: [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Key Types to Implement

```swift
// Document Model
struct PDFDocument
struct PDFObject
struct PDFStream
struct PDFDictionary
struct PDFArray
struct PDFCrossReferenceTable

// Structure Tree (critical for UA)
struct PDFStructureTree
struct PDFStructureElement
struct PDFTaggedContent
struct PDFRoleMap

// Metadata
struct XMPMetadata
struct PDFMetadata
```

## Implementation Strategy

1. **Use PDFKit where possible** — Apple's PDFKit handles basic PDF parsing
2. **Custom structure tree parsing** — PDFKit doesn't expose tagged PDF structures well
3. **Core Graphics for low-level access** — `CGPDFDocument` for object-level access
4. **XMP parsing** — Use XMLParser for XMP metadata extraction
