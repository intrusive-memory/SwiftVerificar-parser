import Foundation

/// Represents the page tree structure of a PDF document.
///
/// The page tree is a balanced tree structure that organizes all pages in the document.
/// It consists of page tree nodes (intermediate nodes with `/Type` = `/Pages`) and
/// page objects (leaf nodes with `/Type` = `/Page`).
///
/// This type corresponds to the Java `PDPageTree` class from veraPDF-parser.
///
/// ## PDF Specification
/// - Page tree nodes have a `/Kids` array containing references to child nodes or pages
/// - Page tree nodes have a `/Count` entry specifying the total number of leaf pages
/// - The root of the page tree is referenced by the `/Pages` entry in the catalog
///
/// ## Usage
/// ```swift
/// let pageTree = try PDFPageTree(cosObject: pagesDict)
/// let pageCount = try pageTree.count()
/// let firstPage = try pageTree.page(at: 0)
/// ```
public struct PDFPageTree: PDObject, Sendable, Hashable {

    // MARK: - Properties

    /// The underlying COS dictionary for this page tree node.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a page tree node from a COS dictionary.
    ///
    /// - Parameter cosObject: The COS object (must be a dictionary with `/Type` = `/Pages`).
    /// - Throws: `PDError.notADictionary` if the object is not a dictionary.
    public init(cosObject: COSValue) throws {
        guard cosObject.isDictionary else {
            throw PDError.notADictionary
        }
        self.cosObject = cosObject
    }

    // MARK: - Page Tree Attributes

    /// The total number of pages in this subtree (required).
    ///
    /// Returns the `/Count` entry which specifies the number of leaf page objects
    /// that are descendants of this node.
    ///
    /// - Returns: The page count.
    /// - Throws: `PDError.missingRequiredEntry` if the `/Count` entry is missing.
    public func count() throws -> Int {
        let countValue = try requireInteger(.count)
        return Int(countValue)
    }

    /// The array of child nodes (required).
    ///
    /// Returns the `/Kids` entry which is an array of references to page tree nodes
    /// or page objects.
    ///
    /// - Returns: The kids array.
    /// - Throws: `PDError.missingRequiredEntry` if the `/Kids` entry is missing.
    public func kids() throws -> [COSValue] {
        try requireArray(.kids)
    }

    /// The parent page tree node (optional, except for the root).
    ///
    /// Returns the `/Parent` entry which references the parent node.
    /// The root of the page tree does not have a parent.
    ///
    /// - Returns: The COSValue for the parent node, or `nil` if this is the root.
    public var parent: COSValue? {
        optionalEntry(.parent)
    }

    // MARK: - Page Access

    /// Retrieves a page at the specified index.
    ///
    /// This method traverses the page tree to find the page at the given zero-based index.
    /// The traversal is depth-first and uses the `/Count` entries to efficiently skip
    /// over entire subtrees.
    ///
    /// - Parameter index: The zero-based page index.
    /// - Returns: The page object at the specified index.
    /// - Throws: `PDError.pageIndexOutOfBounds` if the index is out of range,
    ///   or `PDError.invalidPageTree` if the tree structure is malformed.
    public func page(at index: Int) throws -> PDFPage {
        let totalCount = try count()
        guard index >= 0 && index < totalCount else {
            throw PDError.pageIndexOutOfBounds(index: index, count: totalCount)
        }

        return try findPage(at: index, currentOffset: 0).page
    }

    /// Recursively finds a page in the tree.
    ///
    /// - Parameters:
    ///   - targetIndex: The target page index (absolute, zero-based).
    ///   - currentOffset: The current page offset at this level of the tree.
    /// - Returns: A tuple containing the found page and the offset after this subtree.
    /// - Throws: `PDError.invalidPageTree` if the tree structure is invalid.
    private func findPage(at targetIndex: Int, currentOffset: Int) throws -> (page: PDFPage, nextOffset: Int) {
        let children = try kids()
        var offset = currentOffset

        for child in children {
            // Determine if this child is a page or a page tree node
            if let type = child.typeEntry {
                if type == .page {
                    // This is a leaf page
                    if offset == targetIndex {
                        return (try PDFPage(cosObject: child), offset + 1)
                    }
                    offset += 1
                } else if type == .pages {
                    // This is an intermediate page tree node
                    let childTree = try PDFPageTree(cosObject: child)
                    let childCount = try childTree.count()

                    // Check if the target is in this subtree
                    if targetIndex < offset + childCount {
                        return try childTree.findPage(at: targetIndex, currentOffset: offset)
                    }
                    offset += childCount
                } else {
                    throw PDError.invalidPageTree(reason: "Invalid child type: \(type)")
                }
            } else {
                // No /Type entry, assume it's a page for lenient parsing
                if offset == targetIndex {
                    return (try PDFPage(cosObject: child), offset + 1)
                }
                offset += 1
            }
        }

        throw PDError.invalidPageTree(reason: "Page index \(targetIndex) not found in tree")
    }

    /// Returns all pages in this subtree as an array.
    ///
    /// This method traverses the entire page tree and collects all page objects.
    /// Use with caution on large documents as it loads all pages into memory.
    ///
    /// - Returns: An array of all page objects in this subtree.
    /// - Throws: `PDError.invalidPageTree` if the tree structure is malformed.
    public func allPages() throws -> [PDFPage] {
        let totalCount = try count()
        var pages: [PDFPage] = []
        pages.reserveCapacity(totalCount)

        for i in 0..<totalCount {
            pages.append(try page(at: i))
        }

        return pages
    }

    // MARK: - Inherited Attributes

    /// The resources dictionary inherited by pages in this subtree (optional).
    ///
    /// Returns the `/Resources` entry which can be inherited by descendant pages
    /// that don't specify their own resources.
    ///
    /// - Returns: The COSValue for the resources dictionary, or `nil` if not present.
    public var resources: COSValue? {
        optionalEntry(.resources)
    }

    /// The media box inherited by pages in this subtree (optional).
    ///
    /// Returns the `/MediaBox` entry which can be inherited by descendant pages
    /// that don't specify their own media box.
    ///
    /// - Returns: The media box array, or `nil` if not present.
    public var mediaBox: [COSValue]? {
        optionalArray(.mediaBox)
    }

    /// The crop box inherited by pages in this subtree (optional).
    ///
    /// Returns the `/CropBox` entry which can be inherited by descendant pages.
    ///
    /// - Returns: The crop box array, or `nil` if not present.
    public var cropBox: [COSValue]? {
        optionalArray(.cropBox)
    }

    /// The rotation angle inherited by pages in this subtree (optional).
    ///
    /// Returns the `/Rotate` entry which can be inherited by descendant pages.
    ///
    /// - Returns: The rotation angle in degrees, or `nil` if not present.
    public var rotate: Int64? {
        optionalInteger("Rotate")
    }
}
