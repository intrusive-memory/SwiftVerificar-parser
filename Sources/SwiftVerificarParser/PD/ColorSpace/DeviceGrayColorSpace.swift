import Foundation
import CoreGraphics

/// DeviceGray color space.
///
/// This corresponds to the Java `PDDeviceGray` class from veraPDF-parser.
/// DeviceGray is a single-component color space representing grayscale values.
///
/// ## PDF Specification
/// Specified as the name `/DeviceGray` in PDF documents.
/// - Components: 1 (gray value from 0.0 to 1.0)
/// - 0.0 = black, 1.0 = white
///
/// ## Usage
/// ```swift
/// let gray = DeviceGrayColorSpace(cosObject: .name(.deviceGray))
/// let rgb = try gray.toRGB([0.5])  // → (0.5, 0.5, 0.5)
/// ```
public struct DeviceGrayColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a DeviceGray color space.
    ///
    /// - Parameter cosObject: The COS value (should be `.name(.deviceGray)`).
    public init(cosObject: COSValue) {
        self.cosObject = cosObject
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .deviceGray
    }

    public var numberOfComponents: Int {
        1
    }

    public var cgColorSpace: CGColorSpace? {
        CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 1 else {
            throw PDError.invalidColorComponents(expected: 1, got: components.count)
        }

        let gray = components[0].clamped(to: 0.0...1.0)
        return (gray, gray, gray)
    }
}

// MARK: - Helper

fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
