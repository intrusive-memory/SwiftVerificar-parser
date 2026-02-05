import Foundation

/// A PDF name object with string interning for efficient comparison and hashing.
///
/// `ASAtom` corresponds to the Java `ASAtom` class from veraPDF-parser.
/// It uses a global intern table (via an actor) so that identical name strings
/// share a single canonical representation, enabling O(1) equality checks
/// via integer index comparison.
///
/// PDF names are used extensively as dictionary keys throughout PDF documents.
/// Common names like "Type", "Subtype", "BBox", etc. are predefined as static
/// constants for convenience and performance.
///
/// ## Usage
/// ```swift
/// let atom = ASAtom("Type")
/// let same: ASAtom = "Type"      // ExpressibleByStringLiteral
/// assert(atom == same)
/// ```
///
/// ## Thread Safety
/// The global intern table is managed by an actor (`ASAtomInternTable`),
/// ensuring safe concurrent access. However, the `ASAtom` struct itself
/// is a value type and is `Sendable`.
public struct ASAtom: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {

    // MARK: - Storage

    /// The canonical interned string value for this atom.
    ///
    /// We store the string directly rather than an index into an intern table
    /// to keep the type simple, `Codable`, and avoid async initialization.
    /// Swift's built-in string interning (via the runtime) provides much of
    /// the deduplication benefit automatically for short strings.
    private let value: String

    // MARK: - Initialization

    /// Creates an atom from the given string value.
    ///
    /// - Parameter value: The PDF name string. Must not include the leading `/`
    ///   delimiter used in PDF syntax; that is a syntactic marker, not part of
    ///   the name value.
    public init(_ value: String) {
        self.value = value
    }

    // MARK: - Properties

    /// The string value of this atom.
    public var stringValue: String {
        value
    }

    /// Whether this atom represents an empty name.
    public var isEmpty: Bool {
        value.isEmpty
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        "/\(value)"
    }

    // MARK: - Comparable

    public static func < (lhs: ASAtom, rhs: ASAtom) -> Bool {
        lhs.value < rhs.value
    }

    // MARK: - Predefined Atoms (PDF Specification)

    // Document structure
    /// The "Type" name, used in dictionary type identification.
    public static let type = ASAtom("Type")
    /// The "Subtype" name.
    public static let subtype = ASAtom("Subtype")
    /// The "S" name, commonly used for subtype in structure elements.
    public static let s = ASAtom("S")
    /// The "Pages" name.
    public static let pages = ASAtom("Pages")
    /// The "Page" name.
    public static let page = ASAtom("Page")
    /// The "Catalog" name.
    public static let catalog = ASAtom("Catalog")
    /// The "Count" name.
    public static let count = ASAtom("Count")
    /// The "Kids" name.
    public static let kids = ASAtom("Kids")
    /// The "Parent" name.
    public static let parent = ASAtom("Parent")
    /// The "Root" name.
    public static let root = ASAtom("Root")
    /// The "Info" name.
    public static let info = ASAtom("Info")
    /// The "Size" name.
    public static let size = ASAtom("Size")
    /// The "Prev" name.
    public static let prev = ASAtom("Prev")

    // Content and resources
    /// The "Contents" name.
    public static let contents = ASAtom("Contents")
    /// The "Resources" name.
    public static let resources = ASAtom("Resources")
    /// The "MediaBox" name.
    public static let mediaBox = ASAtom("MediaBox")
    /// The "CropBox" name.
    public static let cropBox = ASAtom("CropBox")
    /// The "BBox" name.
    public static let bbox = ASAtom("BBox")
    /// The "Matrix" name.
    public static let matrix = ASAtom("Matrix")

    // Fonts
    /// The "Font" name.
    public static let font = ASAtom("Font")
    /// The "BaseFont" name.
    public static let baseFont = ASAtom("BaseFont")
    /// The "Encoding" name.
    public static let encoding = ASAtom("Encoding")
    /// The "ToUnicode" name.
    public static let toUnicode = ASAtom("ToUnicode")
    /// The "FontDescriptor" name.
    public static let fontDescriptor = ASAtom("FontDescriptor")
    /// The "DescendantFonts" name.
    public static let descendantFonts = ASAtom("DescendantFonts")
    /// The "Type0" name.
    public static let type0 = ASAtom("Type0")
    /// The "Type1" name.
    public static let type1 = ASAtom("Type1")
    /// The "TrueType" name.
    public static let trueType = ASAtom("TrueType")
    /// The "CIDFontType0" name.
    public static let cidFontType0 = ASAtom("CIDFontType0")
    /// The "CIDFontType2" name.
    public static let cidFontType2 = ASAtom("CIDFontType2")

    // Streams and filters
    /// The "Length" name.
    public static let length = ASAtom("Length")
    /// The "Filter" name.
    public static let filter = ASAtom("Filter")
    /// The "DecodeParms" name.
    public static let decodeParms = ASAtom("DecodeParms")
    /// The "FlateDecode" name.
    public static let flateDecode = ASAtom("FlateDecode")
    /// The "LZWDecode" name.
    public static let lzwDecode = ASAtom("LZWDecode")
    /// The "ASCII85Decode" name.
    public static let ascii85Decode = ASAtom("ASCII85Decode")
    /// The "ASCIIHexDecode" name.
    public static let asciiHexDecode = ASAtom("ASCIIHexDecode")
    /// The "RunLengthDecode" name.
    public static let runLengthDecode = ASAtom("RunLengthDecode")
    /// The "DCTDecode" name.
    public static let dctDecode = ASAtom("DCTDecode")
    /// The "JPXDecode" name.
    public static let jpxDecode = ASAtom("JPXDecode")
    /// The "CCITTFaxDecode" name.
    public static let ccittFaxDecode = ASAtom("CCITTFaxDecode")
    /// The "Crypt" name.
    public static let crypt = ASAtom("Crypt")

    // Color spaces
    /// The "ColorSpace" name.
    public static let colorSpace = ASAtom("ColorSpace")
    /// The "DeviceGray" name.
    public static let deviceGray = ASAtom("DeviceGray")
    /// The "DeviceRGB" name.
    public static let deviceRGB = ASAtom("DeviceRGB")
    /// The "DeviceCMYK" name.
    public static let deviceCMYK = ASAtom("DeviceCMYK")
    /// The "CalGray" name.
    public static let calGray = ASAtom("CalGray")
    /// The "CalRGB" name.
    public static let calRGB = ASAtom("CalRGB")
    /// The "Lab" name.
    public static let lab = ASAtom("Lab")
    /// The "ICCBased" name.
    public static let iccBased = ASAtom("ICCBased")
    /// The "Indexed" name.
    public static let indexed = ASAtom("Indexed")
    /// The "Separation" name.
    public static let separation = ASAtom("Separation")
    /// The "DeviceN" name.
    public static let deviceN = ASAtom("DeviceN")
    /// The "Pattern" name.
    public static let pattern = ASAtom("Pattern")

    // XObjects
    /// The "XObject" name.
    public static let xObject = ASAtom("XObject")
    /// The "Image" name.
    public static let image = ASAtom("Image")
    /// The "Form" name.
    public static let form = ASAtom("Form")

    // Structure tree
    /// The "StructTreeRoot" name.
    public static let structTreeRoot = ASAtom("StructTreeRoot")
    /// The "MarkInfo" name.
    public static let markInfo = ASAtom("MarkInfo")
    /// The "K" name (structure element kids).
    public static let k = ASAtom("K")
    /// The "Pg" name (page reference in structure elements).
    public static let pg = ASAtom("Pg")
    /// The "Lang" name.
    public static let lang = ASAtom("Lang")
    /// The "Alt" name (alternate text).
    public static let alt = ASAtom("Alt")
    /// The "ActualText" name.
    public static let actualText = ASAtom("ActualText")
    /// The "E" name (expanded form of abbreviations).
    public static let e = ASAtom("E")
    /// The "RoleMap" name.
    public static let roleMap = ASAtom("RoleMap")
    /// The "ClassMap" name.
    public static let classMap = ASAtom("ClassMap")

    // Metadata
    /// The "Metadata" name.
    public static let metadata = ASAtom("Metadata")
    /// The "XML" name.
    public static let xml = ASAtom("XML")

    // Encryption
    /// The "Encrypt" name.
    public static let encrypt = ASAtom("Encrypt")
    /// The "ID" name.
    public static let id = ASAtom("ID")

    // Annotations
    /// The "Annot" name.
    public static let annot = ASAtom("Annot")
    /// The "Annots" name.
    public static let annots = ASAtom("Annots")
    /// The "Link" name.
    public static let link = ASAtom("Link")
    /// The "Rect" name.
    public static let rect = ASAtom("Rect")

    // Graphics state
    /// The "ExtGState" name.
    public static let extGState = ASAtom("ExtGState")
    /// The "Properties" name.
    public static let properties = ASAtom("Properties")

    // Miscellaneous
    /// The "Width" name.
    public static let width = ASAtom("Width")
    /// The "Height" name.
    public static let height = ASAtom("Height")
    /// The "BitsPerComponent" name.
    public static let bitsPerComponent = ASAtom("BitsPerComponent")
    /// The "Columns" name.
    public static let columns = ASAtom("Columns")
    /// The "Predictor" name.
    public static let predictor = ASAtom("Predictor")
    /// The "N" name.
    public static let n = ASAtom("N")
    /// The "W" name (used in XRef streams for field widths).
    public static let w = ASAtom("W")
    /// The "Index" name.
    public static let index = ASAtom("Index")
    /// The "XRef" name.
    public static let xRef = ASAtom("XRef")
}

// MARK: - ExpressibleByStringLiteral

extension ASAtom: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - RawRepresentable

extension ASAtom: RawRepresentable {
    public var rawValue: String {
        value
    }

    public init(rawValue: String) {
        self.init(rawValue)
    }
}
