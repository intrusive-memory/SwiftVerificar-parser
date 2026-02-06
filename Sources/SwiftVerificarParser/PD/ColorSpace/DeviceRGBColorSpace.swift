import Foundation
import CoreGraphics

/// DeviceRGB color space.
///
/// This corresponds to the Java `PDDeviceRGB` class from veraPDF-parser.
/// DeviceRGB is a three-component color space representing RGB colors.
///
/// ## PDF Specification
/// Specified as the name `/DeviceRGB` in PDF documents.
/// - Components: 3 (red, green, blue, each from 0.0 to 1.0)
/// - (0, 0, 0) = black, (1, 1, 1) = white
///
/// ## Usage
/// ```swift
/// let rgb = DeviceRGBColorSpace(cosObject: .name(.deviceRGB))
/// let converted = try rgb.toRGB([1.0, 0.0, 0.0])  // → (1.0, 0.0, 0.0) red
/// ```
public struct DeviceRGBColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a DeviceRGB color space.
    ///
    /// - Parameter cosObject: The COS value (should be `.name(.deviceRGB)`).
    public init(cosObject: COSValue) {
        self.cosObject = cosObject
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .deviceRGB
    }

    public var numberOfComponents: Int {
        3
    }

    public var cgColorSpace: CGColorSpace? {
        CGColorSpace(name: CGColorSpace.sRGB)
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 3 else {
            throw PDError.invalidColorComponents(expected: 3, got: components.count)
        }

        let r = components[0].clamped(to: 0.0...1.0)
        let g = components[1].clamped(to: 0.0...1.0)
        let b = components[2].clamped(to: 0.0...1.0)

        return (r, g, b)
    }
}

// MARK: - Helper

fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
