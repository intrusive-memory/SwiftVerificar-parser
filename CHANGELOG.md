# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-07

### Added
- Initial release of SwiftVerificarParser
- COS layer: COSValue enum, ASAtom, COSString, COSReference, COSObjectKey, COSStream
- Stream processing: PDFInputStream/OutputStream protocols, DataInputStream, ConcatenatedInputStream
- Filter system: Flate, LZW, ASCII85, ASCIIHex, RunLength, AES/RC4 decrypt, Predictor filters
- Parser layer: PDFTokenizer, ObjectParser, PDFDocumentParser, XRefParser, ContentStreamParser
- PD layer: PDFDocument, PDFCatalog, PDFPageTree, PDFPage, PDFResources, PDFContentStream
- Font system: PDFFont protocol, Type1Font, TrueTypeFont, Type0Font, CIDFont, FontDescriptor
- Color spaces: DeviceGray/RGB/CMYK, ICCBased, CalGray/CalRGB, Lab, Indexed, Separation, DeviceN, Pattern
- Structure tree: PDStructTreeRoot, PDStructElement, PDMarkedContent, PDRoleMap, PDClassMap
- Text extraction: PDFTextStripper, TextPosition, TextLine, TextBlock
- XObject support: ImageXObject, FormXObject, PostScriptXObject, InlineImage
- Pattern support: TilingPattern, ShadingPattern, Shading
- XMP metadata extraction
- 2700+ tests with 90%+ coverage

[0.1.0]: https://github.com/intrusive-memory/SwiftVerificar-parser/releases/tag/v0.1.0
