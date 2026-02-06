import Foundation
import CoreGraphics

/// Lab (CIE L*a*b*) color space.
///
/// This corresponds to the Java `PDLab` class from veraPDF-parser.
/// Lab is a device-independent color space based on human color perception.
///
/// ## PDF Specification
/// Specified as an array: `[/Lab dictionary]`
///
/// Dictionary keys:
/// - `/WhitePoint` (required): [Xw Yw Zw] - CIE XYZ white point
/// - `/BlackPoint` (optional): [Xb Yb Zb] - CIE XYZ black point (default: [0 0 0])
/// - `/Range` (optional): [amin amax bmin bmax] - valid ranges for a* and b* (default: [-100 100 -100 100])
///
/// ## Color Components
/// - L*: Lightness (0 to 100)
/// - a*: Green-red axis (range specified by /Range)
/// - b*: Blue-yellow axis (range specified by /Range)
///
/// ## Usage
/// ```swift
/// let lab = try LabColorSpace(cosObject: arrayValue)
/// let rgb = try lab.toRGB([50, 0, 0])  // neutral gray at 50% lightness
/// ```
public struct LabColorSpace: PDFColorSpace, Sendable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The white point as CIE XYZ tristimulus values.
    public let whitePoint: (x: Double, y: Double, z: Double)

    /// The black point as CIE XYZ tristimulus values.
    public let blackPoint: (x: Double, y: Double, z: Double)

    /// The valid range for a* and b* components.
    public let range: (aMin: Double, aMax: Double, bMin: Double, bMax: Double)

    // MARK: - Initialization

    /// Creates a Lab color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/Lab dict]`.
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

        // Parse Range (optional, default [-100 100 -100 100])
        if let rangeValue = dict[.range],
           case .array(let rangeArray) = rangeValue,
           rangeArray.count == 4,
           case .real(let amin) = rangeArray[0].asNumber,
           case .real(let amax) = rangeArray[1].asNumber,
           case .real(let bmin) = rangeArray[2].asNumber,
           case .real(let bmax) = rangeArray[3].asNumber {
            self.range = (amin, amax, bmin, bmax)
        } else {
            self.range = (-100, 100, -100, 100)
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .lab
    }

    public var numberOfComponents: Int {
        3
    }

    public var cgColorSpace: CGColorSpace? {
        // Create Lab color space
        var whitePointArray: [CGFloat] = [whitePoint.x, whitePoint.y, whitePoint.z]
        var blackPointArray: [CGFloat] = [blackPoint.x, blackPoint.y, blackPoint.z]
        var rangeArray: [CGFloat] = [range.aMin, range.aMax, range.bMin, range.bMax]

        return CGColorSpace(
            labWhitePoint: &whitePointArray,
            blackPoint: &blackPointArray,
            range: &rangeArray
        )
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 3 else {
            throw PDError.invalidColorComponents(expected: 3, got: components.count)
        }

        let lStar = components[0].clamped(to: 0.0...100.0)
        let aStar = components[1].clamped(to: range.aMin...range.aMax)
        let bStar = components[2].clamped(to: range.bMin...range.bMax)

        // Convert Lab to XYZ
        let fy = (lStar + 16.0) / 116.0
        let fx = aStar / 500.0 + fy
        let fz = fy - bStar / 200.0

        let xr = Self.labInverse(fx)
        let yr = Self.labInverse(fy)
        let zr = Self.labInverse(fz)

        let x = xr * whitePoint.x
        let y = yr * whitePoint.y
        let z = zr * whitePoint.z

        // Convert XYZ to RGB (using sRGB conversion)
        let rgb = Self.xyzToRGB(x: x, y: y, z: z)

        return (rgb.r.clamped(to: 0.0...1.0), rgb.g.clamped(to: 0.0...1.0), rgb.b.clamped(to: 0.0...1.0))
    }

    // MARK: - Helpers

    private static func labInverse(_ t: Double) -> Double {
        let delta = 6.0 / 29.0
        if t > delta {
            return t * t * t
        } else {
            return 3.0 * delta * delta * (t - 4.0 / 29.0)
        }
    }

    private static func xyzToRGB(x: Double, y: Double, z: Double) -> (r: Double, g: Double, b: Double) {
        // sRGB transformation matrix (D65 white point)
        let r = 3.2406 * x - 1.5372 * y - 0.4986 * z
        let g = -0.9689 * x + 1.8758 * y + 0.0415 * z
        let b = 0.0557 * x - 0.2040 * y + 1.0570 * z

        // Apply gamma correction
        let rGamma = Self.sRGBGamma(r)
        let gGamma = Self.sRGBGamma(g)
        let bGamma = Self.sRGBGamma(b)

        return (rGamma, gGamma, bGamma)
    }

    private static func sRGBGamma(_ value: Double) -> Double {
        if value <= 0.0031308 {
            return 12.92 * value
        } else {
            return 1.055 * pow(value, 1.0 / 2.4) - 0.055
        }
    }
}

// MARK: - Hashable

extension LabColorSpace: Hashable {
    public static func == (lhs: LabColorSpace, rhs: LabColorSpace) -> Bool {
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
