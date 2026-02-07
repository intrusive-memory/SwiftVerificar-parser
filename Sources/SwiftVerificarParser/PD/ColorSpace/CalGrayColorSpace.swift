import Foundation
import CoreGraphics

/// CalGray (Calibrated Gray) color space.
///
/// This corresponds to the Java `PDCalGray` class from veraPDF-parser.
/// CalGray is a single-component CIE-based color space with calibration parameters.
///
/// ## PDF Specification
/// Specified as an array: `[/CalGray dictionary]`
///
/// Dictionary keys:
/// - `/WhitePoint` (required): [Xw Yw Zw] - CIE XYZ white point
/// - `/BlackPoint` (optional): [Xb Yb Zb] - CIE XYZ black point (default: [0 0 0])
/// - `/Gamma` (optional): Gamma value (default: 1.0)
///
/// ## Usage
/// ```swift
/// let calGray = try CalGrayColorSpace(cosObject: arrayValue)
/// let whitePoint = calGray.whitePoint
/// let gamma = calGray.gamma
/// ```
public struct CalGrayColorSpace: PDFColorSpace, Sendable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The white point as CIE XYZ tristimulus values.
    public let whitePoint: (x: Double, y: Double, z: Double)

    /// The black point as CIE XYZ tristimulus values.
    public let blackPoint: (x: Double, y: Double, z: Double)

    /// The gamma correction value.
    public let gamma: Double

    // MARK: - Initialization

    /// Creates a CalGray color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/CalGray dict]`.
    /// - Throws: `PDError` if the array format is invalid.
    public init(cosObject: COSValue) throws {
        self.cosObject = cosObject

        guard case .array(let array) = cosObject, array.count == 2 else {
            throw PDError.invalidColorSpace
        }

        guard case .dictionary(let dict) = array[1] else {
            throw PDError.invalidColorSpace
        }

        // Parse WhitePoint (required)
        guard let wpValue = dict[.whitePoint],
              case .array(let wpArray) = wpValue,
              wpArray.count == 3,
              case .real(let xw) = wpArray[0].asNumber,
              case .real(let yw) = wpArray[1].asNumber,
              case .real(let zw) = wpArray[2].asNumber else {
            throw PDError.missingRequiredEntry(key: "WhitePoint")
        }
        self.whitePoint = (xw, yw, zw)

        // Parse BlackPoint (optional, default [0 0 0])
        if let bpValue = dict[.blackPoint],
           case .array(let bpArray) = bpValue,
           bpArray.count == 3,
           case .real(let xb) = bpArray[0].asNumber,
           case .real(let yb) = bpArray[1].asNumber,
           case .real(let zb) = bpArray[2].asNumber {
            self.blackPoint = (xb, yb, zb)
        } else {
            self.blackPoint = (0, 0, 0)
        }

        // Parse Gamma (optional, default 1.0)
        if let gammaValue = dict[.gamma],
           case .real(let g) = gammaValue.asNumber {
            self.gamma = g
        } else {
            self.gamma = 1.0
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .calGray
    }

    public var numberOfComponents: Int {
        1
    }

    public var cgColorSpace: CGColorSpace? {
        // Create calibrated gray color space using white point and gamma
        var whitePointArray: [CGFloat] = [whitePoint.x, whitePoint.y, whitePoint.z]
        var blackPointArray: [CGFloat] = [blackPoint.x, blackPoint.y, blackPoint.z]

        return CGColorSpace(
            calibratedGrayWhitePoint: &whitePointArray,
            blackPoint: &blackPointArray,
            gamma: CGFloat(gamma)
        )
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 1 else {
            throw PDError.invalidColorComponents(expected: 1, got: components.count)
        }

        // Apply gamma correction
        let a = components[0].clamped(to: 0.0...1.0)
        let gray = pow(a, gamma)

        return (gray, gray, gray)
    }
}

// MARK: - Hashable

extension CalGrayColorSpace: Hashable {
    public static func == (lhs: CalGrayColorSpace, rhs: CalGrayColorSpace) -> Bool {
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
