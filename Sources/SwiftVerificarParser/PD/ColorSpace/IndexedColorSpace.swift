import Foundation
import CoreGraphics

/// Indexed color space.
///
/// This corresponds to the Java `PDIndexed` class from veraPDF-parser.
/// Indexed color spaces use a color lookup table to map single-byte indices
/// to colors in a base color space.
///
/// ## PDF Specification
/// Specified as an array: `[/Indexed base hival lookup]`
///
/// - `base`: The base color space (can be any device or CIE-based space)
/// - `hival`: Maximum valid index (0 to 255)
/// - `lookup`: Color lookup table (string or stream)
///
/// ## Usage
/// ```swift
/// let indexed = try IndexedColorSpace(cosObject: arrayValue)
/// let baseSpace = indexed.baseColorSpace
/// let maxIndex = indexed.highValue
/// ```
public struct IndexedColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The base color space.
    public let baseColorSpace: any PDFColorSpace

    /// The maximum valid color index (0 to 255).
    public let highValue: Int

    /// The color lookup table data.
    public let lookupTable: Data

    // MARK: - Initialization

    /// Creates an Indexed color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/Indexed base hival lookup]`.
    /// - Throws: `PDError` if the array format is invalid.
    public init(cosObject: COSValue) throws {
        self.cosObject = cosObject

        guard case .array(let array) = cosObject, array.count == 4 else {
            throw PDError.invalidColorSpace
        }

        // Parse base color space
        self.baseColorSpace = try PDFColorSpaceFactory.create(from: array[1])

        // Parse hival (maximum index)
        guard let hival = array[2].asInteger, hival >= 0, hival <= 255 else {
            throw PDError.invalidColorSpace
        }
        self.highValue = hival

        // Parse lookup table (can be string or dictionary representing stream)
        switch array[3] {
        case .string(let cosString):
            self.lookupTable = cosString.data
        case .dictionary:
            // In a real implementation, we would decode the stream
            // For now, use empty data as placeholder
            self.lookupTable = Data()
        default:
            throw PDError.invalidColorSpace
        }

        // Validate lookup table size
        let expectedSize = (hival + 1) * baseColorSpace.numberOfComponents
        guard lookupTable.count >= expectedSize else {
            throw PDError.invalidColorSpace
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .indexed
    }

    public var numberOfComponents: Int {
        1  // Single index value
    }

    public var cgColorSpace: CGColorSpace? {
        // CGColorSpace can represent indexed color spaces
        guard let baseCG = baseColorSpace.cgColorSpace else {
            return nil
        }

        // Only create indexed color space if we have lookup table data
        guard !lookupTable.isEmpty else {
            return baseCG
        }

        // Convert lookup table to format expected by CGColorSpace
        let lastIndex = highValue
        return lookupTable.withUnsafeBytes { buffer -> CGColorSpace? in
            guard let baseAddress = buffer.baseAddress else { return nil }
            return CGColorSpace(
                indexedBaseSpace: baseCG,
                last: lastIndex,
                colorTable: baseAddress.assumingMemoryBound(to: UInt8.self)
            )
        }
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 1 else {
            throw PDError.invalidColorComponents(expected: 1, got: components.count)
        }

        // Clamp index to valid range
        let index = Int(components[0]).clamped(to: 0...highValue)

        // Extract color components from lookup table
        let baseComponents = baseColorSpace.numberOfComponents
        let offset = index * baseComponents

        guard offset + baseComponents <= lookupTable.count else {
            throw PDError.invalidColorSpace
        }

        // Convert byte values (0-255) to normalized values (0.0-1.0)
        var colorComponents: [Double] = []
        for i in 0..<baseComponents {
            let byteValue = lookupTable[offset + i]
            colorComponents.append(Double(byteValue) / 255.0)
        }

        // Use base color space to convert to RGB
        return try baseColorSpace.toRGB(colorComponents)
    }

    // MARK: - Hashable

    public static func == (lhs: IndexedColorSpace, rhs: IndexedColorSpace) -> Bool {
        lhs.cosObject == rhs.cosObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cosObject)
    }
}

// MARK: - Helper

fileprivate extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - COSValue Extension

fileprivate extension COSValue {
    var asInteger: Int? {
        switch self {
        case .integer(let i):
            return Int(i)
        case .real(let d):
            return Int(d)
        default:
            return nil
        }
    }
}
