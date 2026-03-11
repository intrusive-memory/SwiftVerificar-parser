import Foundation
import CoreGraphics

/// ICCBased color space.
///
/// This corresponds to the Java `PDICCBased` class from veraPDF-parser.
/// ICCBased color spaces use ICC (International Color Consortium) profiles
/// for device-independent color specification.
///
/// ## PDF Specification
/// Specified as an array: `[/ICCBased stream]`
///
/// The stream contains the ICC profile data, and its dictionary may contain:
/// - `/N` (required): Number of color components (1, 3, or 4)
/// - `/Alternate` (optional): Alternate color space if ICC profile cannot be used
/// - `/Range` (optional): Valid ranges for each component
/// - `/Metadata` (optional): Metadata stream
///
/// ## Usage
/// ```swift
/// let iccBased = try ICCBasedColorSpace(cosObject: arrayValue)
/// let numComponents = iccBased.numberOfComponents
/// let alternate = iccBased.alternateColorSpace
/// ```
public struct ICCBasedColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The number of color components (1, 3, or 4).
    private let numberOfComponentsValue: Int

    /// The alternate color space to use if the ICC profile cannot be processed.
    public let alternateColorSpace: (any PDFColorSpace)?

    /// Valid ranges for each color component.
    public let range: [ClosedRange<Double>]?

    // MARK: - Initialization

    /// Creates an ICCBased color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/ICCBased streamOrRef]`.
    /// - Throws: `PDError` if the array format is invalid.
    ///
    /// The second array element may be:
    /// - A dictionary (inline stream dictionary with /N, /Alternate, /Range entries)
    /// - An indirect reference to a stream object — when a reference is provided,
    ///   the stream cannot be resolved without a document context, so the color space
    ///   is created with a default of 3 components (sRGB-like) and no alternate space.
    ///   Callers with document access should resolve the reference first and pass the
    ///   resolved stream dictionary instead.
    public init(cosObject: COSValue) throws {
        self.cosObject = cosObject

        guard case .array(let array) = cosObject, array.count == 2 else {
            throw PDError.invalidColorSpace
        }

        // The second element may be a stream dictionary or an indirect reference.
        switch array[1] {
        case .dictionary(let streamDict):
            // Inline stream dictionary: parse /N, /Alternate, /Range
            guard let nValue = streamDict[.n],
                  let n = nValue.asInteger,
                  [1, 3, 4].contains(n) else {
                throw PDError.missingRequiredEntry(key: "N")
            }
            self.numberOfComponentsValue = n

            if let altValue = streamDict[.alternate] {
                self.alternateColorSpace = try? PDFColorSpaceFactory.create(from: altValue)
            } else {
                self.alternateColorSpace = nil
            }

            if let rangeValue = streamDict[.range],
               case .array(let rangeArray) = rangeValue,
               rangeArray.count == n * 2 {
                var parsedRanges: [ClosedRange<Double>] = []
                for i in 0..<n {
                    if case .real(let min) = rangeArray[i * 2].asNumber,
                       case .real(let max) = rangeArray[i * 2 + 1].asNumber {
                        parsedRanges.append(min...max)
                    }
                }
                self.range = parsedRanges.count == n ? parsedRanges : nil
            } else {
                self.range = nil
            }

        case .reference:
            // Indirect reference to a stream object. Without a document context we
            // cannot resolve the reference here. Use a safe default (3 components,
            // no alternate, no range) so that objects can be created and the
            // reference recorded for deferred resolution by the document layer.
            self.numberOfComponentsValue = 3
            self.alternateColorSpace = nil
            self.range = nil

        default:
            throw PDError.invalidColorSpace
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .iccBased
    }

    public var numberOfComponents: Int {
        numberOfComponentsValue
    }

    public var cgColorSpace: CGColorSpace? {
        // Try to create CGColorSpace from ICC profile data
        // In a real implementation, we would decode the stream here
        // For now, fall back to alternate color space
        return alternateColorSpace?.cgColorSpace
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == numberOfComponentsValue else {
            throw PDError.invalidColorComponents(expected: numberOfComponentsValue, got: components.count)
        }

        // If we have an alternate color space, use it for conversion
        if let alternate = alternateColorSpace {
            return try alternate.toRGB(components)
        }

        // Fallback: assume components are already in RGB-like space
        switch numberOfComponentsValue {
        case 1:
            let gray = components[0].clamped(to: 0.0...1.0)
            return (gray, gray, gray)
        case 3:
            return (
                components[0].clamped(to: 0.0...1.0),
                components[1].clamped(to: 0.0...1.0),
                components[2].clamped(to: 0.0...1.0)
            )
        case 4:
            // Assume CMYK
            let c = components[0].clamped(to: 0.0...1.0)
            let m = components[1].clamped(to: 0.0...1.0)
            let y = components[2].clamped(to: 0.0...1.0)
            let k = components[3].clamped(to: 0.0...1.0)
            let r = (1.0 - c) * (1.0 - k)
            let g = (1.0 - m) * (1.0 - k)
            let b = (1.0 - y) * (1.0 - k)
            return (r, g, b)
        default:
            throw PDError.invalidColorSpace
        }
    }

    // MARK: - Hashable

    public static func == (lhs: ICCBasedColorSpace, rhs: ICCBasedColorSpace) -> Bool {
        lhs.cosObject == rhs.cosObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cosObject)
    }
}

// MARK: - Helper

fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
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

    var asNumber: COSValue {
        switch self {
        case .integer(let i):
            return .real(Double(i))
        case .real:
            return self
        default:
            return .real(0)
        }
    }
}
