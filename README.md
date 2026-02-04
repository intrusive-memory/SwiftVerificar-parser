# SwiftVerificar-parser

Swift port of [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser).

## Overview

SwiftVerificar-parser provides PDF parsing capabilities for the SwiftVerificar ecosystem, including:

- PDF document structure parsing
- Tagged PDF structure tree extraction
- XMP metadata handling
- PDF object model

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftVerificar-parser.git", from: "0.1.0")
]
```

## Usage

```swift
import SwiftVerificarParser

let parser = SwiftVerificarParser()
// PDF parsing functionality coming soon
```

## Source Reference

- **Original**: [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
- **Language**: Java → Swift
- **License**: GPLv3+ / MPLv2+

## Development

See the parent [SwiftVerificar/AGENTS.md](../AGENTS.md) for development guidelines.

### Building

```bash
xcodebuild build -scheme SwiftVerificarParser -destination 'platform=macOS'
```

### Testing

```bash
xcodebuild test -scheme SwiftVerificarParser -destination 'platform=macOS'
```
