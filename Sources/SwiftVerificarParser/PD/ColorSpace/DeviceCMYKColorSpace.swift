import Foundation
import CoreGraphics

/// DeviceCMYK color space.
///
/// This corresponds to the Java `PDDeviceCMYK` class from veraPDF-parser.
/// DeviceCMYK is a four-component subtractive color space used for printing.
///
/// ## PDF Specification
/// Specified as the name `/DeviceCMYK` in PDF documents.
/// - Components: 4 (cyan, magenta, yellow, black, each from 0.0 to 1.0)
/// - (0, 0, 0, 0) = white, (0, 0, 0, 1) = black
/// - This is a subtractive color model (ink on paper)
///
/// ## Usage
/// ```swift
/// let cmyk = DeviceCMYKColorSpace(cosObject: .name(.deviceCMYK))
/// let rgb = try cmyk.toRGB([0.0, 1.0, 1.0, 0.0])  // → red
/// ```
public struct DeviceCMYKColorSpace: PDFColorSpace, Sendable, Hashable {

    // MARK: - Properties

    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a DeviceCMYK color space.
    ///
    /// - Parameter cosObject: The COS value (should be `.name(.deviceCMYK)`).
    public init(cosObject: COSValue) {
        self.cosObject = cosObject
    }

    // MARK: - PDFColorSpace

    public var name: ASAtom {
        .deviceCMYK
    }

    public var numberOfComponents: Int {
        4
    }

    public var cgColorSpace: CGColorSpace? {
        CGColorSpace(name: CGColorSpace.genericCMYK)
    }

    public func toRGB(_ components: [Double]) throws -> (r: Double, g: Double, b: Double) {
        guard components.count == 4 else {
            throw PDError.invalidColorComponents(expected: 4, got: components.count)
        }

        let c = components[0].clamped(to: 0.0...1.0)
        let m = components[1].clamped(to: 0.0...1.0)
        let y = components[2].clamped(to: 0.0...1.0)
        let k = components[3].clamped(to: 0.0...1.0)

        // Standard CMYK to RGB conversion
        // RGB = (1 - C) * (1 - K), (1 - M) * (1 - K), (1 - Y) * (1 - K)
        let r = (1.0 - c) * (1.0 - k)
        let g = (1.0 - m) * (1.0 - k)
        let b = (1.0 - y) * (1.0 - k)

        return (r, g, b)
    }
}

// MARK: - Helper

fileprivate extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
