import Foundation

/// SwiftVerificarParser - PDF parsing library for SwiftVerificar
///
/// Swift port of veraPDF-parser providing PDF structure parsing,
/// tagged PDF structure tree extraction, and XMP metadata handling.
///
/// - SeeAlso: [veraPDF-parser](https://github.com/veraPDF/veraPDF-parser)
public struct SwiftVerificarParser {

    /// The current version of the library
    public static let version = "0.1.0"

    /// Creates a new instance of SwiftVerificarParser
    public init() {}
}

// MARK: - PDF Document Model

/// Represents a parsed PDF document
public struct PDFDocument: Sendable {
    /// Document metadata
    public let metadata: PDFMetadata?

    /// Structure tree for tagged PDFs
    public let structureTree: PDFStructureTree?

    /// XMP metadata
    public let xmpMetadata: XMPMetadata?
}

/// PDF document metadata from the document info dictionary
public struct PDFMetadata: Sendable {
    public let title: String?
    public let author: String?
    public let subject: String?
    public let keywords: String?
    public let creator: String?
    public let producer: String?
    public let creationDate: Date?
    public let modificationDate: Date?
}

// MARK: - Structure Tree

/// PDF structure tree for tagged PDFs
public struct PDFStructureTree: Sendable {
    /// Root element of the structure tree
    public let root: PDFStructureElement?

    /// Role map for custom structure types
    public let roleMap: [String: String]
}

/// A structure element in the PDF structure tree
public struct PDFStructureElement: Sendable, Identifiable {
    public let id: UUID
    public let type: String
    public let title: String?
    public let altText: String?
    public let language: String?
    public let children: [PDFStructureElement]
}

// MARK: - XMP Metadata

/// XMP (Extensible Metadata Platform) metadata
public struct XMPMetadata: Sendable {
    /// Dublin Core properties
    public let dcTitle: String?
    public let dcCreator: [String]?
    public let dcDescription: String?
    public let dcSubject: [String]?

    /// PDF/A identification
    public let pdfaPart: Int?
    public let pdfaConformance: String?

    /// PDF/UA identification
    public let pdfuaPart: Int?
}
