import Foundation
import CoreGraphics

/// CalRGB (Calibrated RGB) color space.
///
/// This corresponds to the Java `PDCalRGB` class from veraPDF-parser.
/// CalRGB is a three-component CIE-based color space with calibration parameters.
///
/// ## PDF Specification
/// Specified as an array: `[/CalRGB dictionary]`
///
/// Dictionary keys:
/// - `/WhitePoint` (required): [Xw Yw Zw] - CIE XYZ white point
/// - `/BlackPoint` (optional): [Xb Yb Zb] - CIE XYZ black point (default: [0 0 0])
/// - `/Gamma` (optional): [GR GG GB] - gamma values for each component (default: [1 1 1])
/// - `/Matrix` (optional): 3x3 transformation matrix (default: identity)
///
/// ## Usage
/// ```swift
/// let calRGB = try CalRGBColorSpace(cosObject: arrayValue)
/// let whitePoint = calRGB.whitePoint
/// let gamma = calRGB.gamma
/// ```
public struct CalRGBColorSpace: PDFColorSpace, Sendable {

    // MARK: - Properties

    public let cosObject: COSValue

    /// The white point as CIE XYZ tristimulus values.
    public let whitePoint: (x: Double, y: Double, z: Double)

    /// The black point as CIE XYZ tristimulus values.
    public let blackPoint: (x: Double, y: Double, z: Double)

    /// The gamma correction values for R, G, B.
    public let gamma: (r: Double, g: Double, b: Double)

    /// The 3x3 transformation matrix (row-major order).
    public let matrix: [Double]

    // MARK: - Initialization

    /// Creates a CalRGB color space from a COS array.
    ///
    /// - Parameter cosObject: Array of the form `[/CalRGB dict]`.
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

        // Parse Gamma (optional, default [1 1 1])
        if let gammaValue = dict[.gamma],
           case .array(let gammaArray) = gammaValue,
           gammaArray.count == 3,
           case .real(let gr) = gammaArray[0].asNumber,
           case .real(let gg) = gammaArray[1].asNumber,
           case .real(let gb) = gammaArray[2].asNumber {
            self.gamma = (gr, gg, gb)
        } else {
            self.gamma = (1.0, 1.0, 1.0)
        }

        // Parse Matrix (optional, default identity)
        if let matrixValue = dict[.matrix],
           case .array(let matrixArray) = matrixValue,
           matrixArray.count == 9 {
            var parsedMatrix: [Double] = []
            for element in matrixArray {
                if case .real(let value) = element.asNumber {
                    parsedMatrix.append(value)
                } else {
                    throw PDError.invalidColorSpace
                }
            }
            self.matrix = parsedMatrix
        } else {
            // Identity matrix
            self.matrix = [1, 0, 0, 0, 1, 0, 0, 0, 1]
        }
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .calRGB
    }

    public var numberOfComponents: Int {
        3
    }

    public var cgColorSpace: CGColorSpace? {
        // Create calibrated RGB color space
        var whitePointArray: [CGFloat] = [whitePoint.x, whitePoint.y, whitePoint.z]
        var blackPointArray: [CGFloat] = [blackPoint.x, blackPoint.y, blackPoint.z]
        var gammaArray: [CGFloat] = [gamma.r, gamma.g, gamma.b]
        var matrixCopy: [CGFloat] = matrix.map { CGFloat($0) }

        return CGColorSpace(
            calibratedRGBWhitePoint: &whitePointArray,
            blackPoint: &blackPointArray,
            gamma: &gammaArray,
            matrix: &matrixCopy
        )
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 3 else {
            throw PDError.invalidColorComponents(expected: 3, got: components.count)
        }

        // Apply gamma correction
        let a = components[0].clamped(to: 0.0...1.0)
        let b = components[1].clamped(to: 0.0...1.0)
        let c = components[2].clamped(to: 0.0...1.0)

        let r = pow(a, gamma.r)
        let g = pow(b, gamma.g)
        let b_out = pow(c, gamma.b)

        // Apply matrix transformation
        let x = matrix[0] * r + matrix[1] * g + matrix[2] * b_out
        let y = matrix[3] * r + matrix[4] * g + matrix[5] * b_out
        let z = matrix[6] * r + matrix[7] * g + matrix[8] * b_out

        // For simplicity, we'll just return the gamma-corrected RGB
        // Full XYZ to RGB conversion would require color adaptation
        return (x.clamped(to: 0.0...1.0), y.clamped(to: 0.0...1.0), z.clamped(to: 0.0...1.0))
    }
}

// MARK: - Hashable

extension CalRGBColorSpace: Hashable {
    public static func == (lhs: CalRGBColorSpace, rhs: CalRGBColorSpace) -> Bool {
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
