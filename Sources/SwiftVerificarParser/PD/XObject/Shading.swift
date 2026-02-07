import Foundation
import CoreGraphics

/// Represents a PDF Shading dictionary.
///
/// Shadings define smooth color gradients that can be used directly
/// via the `sh` operator or indirectly via shading patterns.
///
/// This type corresponds to the Java `PDShading` class from veraPDF-parser.
///
/// ## Shading Types
/// 1. **Function-based**: Color defined by a mathematical function
/// 2. **Axial**: Linear gradient between two points
/// 3. **Radial**: Gradient between two circles
/// 4. **Free-form Gouraud**: Triangular mesh with vertex colors
/// 5. **Lattice-form Gouraud**: Regular mesh with vertex colors
/// 6. **Coons patch**: Cubic Bezier curves with color interpolation
/// 7. **Tensor-product patch**: Higher-order Bezier surfaces
///
/// ## Required Entries
/// - `/ShadingType` - Integer from 1 to 7
/// - `/ColorSpace` - Color space for the gradient
///
/// ## Usage
/// ```swift
/// let shading = try Shading(cosObject: shadingDict)
/// print("Type: \(shading.shadingType)")
/// print("Color space: \(shading.colorSpaceName)")
/// ```
public struct Shading: PDObject, Sendable, Hashable {

    // MARK: - Shading Type

    /// The type of shading.
    public enum ShadingType: Int, Sendable, Hashable, CaseIterable, CustomStringConvertible {
        /// Function-based shading.
        case functionBased = 1

        /// Axial (linear) shading.
        case axial = 2

        /// Radial (circular) shading.
        case radial = 3

        /// Free-form Gouraud-shaded triangle mesh.
        case freeFormGouraud = 4

        /// Lattice-form Gouraud-shaded triangle mesh.
        case latticeFormGouraud = 5

        /// Coons patch mesh.
        case coonsPatch = 6

        /// Tensor-product patch mesh.
        case tensorProductPatch = 7

        public var description: String {
            switch self {
            case .functionBased:
                return "Function-based"
            case .axial:
                return "Axial"
            case .radial:
                return "Radial"
            case .freeFormGouraud:
                return "Free-form Gouraud"
            case .latticeFormGouraud:
                return "Lattice-form Gouraud"
            case .coonsPatch:
                return "Coons patch"
            case .tensorProductPatch:
                return "Tensor-product patch"
            }
        }

        /// Whether this shading type requires a stream.
        public var requiresStream: Bool {
            switch self {
            case .functionBased, .axial, .radial:
                return false
            case .freeFormGouraud, .latticeFormGouraud, .coonsPatch, .tensorProductPatch:
                return true
            }
        }
    }

    // MARK: - Properties

    /// The underlying COS dictionary or stream for this shading.
    public let cosObject: COSValue

    // MARK: - Initialization

    /// Creates a Shading from a COS dictionary or stream.
    ///
    /// - Parameter cosObject: The COS object.
    /// - Throws: `XObjectError` if required entries are missing or invalid.
    public init(cosObject: COSValue) throws {
        // Validate shading type
        guard let typeValue = cosObject["ShadingType"]?.integerValue else {
            throw XObjectError.invalidShadingType(nil)
        }

        guard ShadingType(rawValue: Int(typeValue)) != nil else {
            throw XObjectError.invalidShadingType(Int(typeValue))
        }

        // ColorSpace is required
        guard cosObject[.colorSpace] != nil else {
            throw XObjectError.invalidColorSpace("missing ColorSpace in Shading")
        }

        self.cosObject = cosObject
    }

    // MARK: - Shading Properties

    /// The shading type as an enum.
    public var type: ShadingType {
        ShadingType(rawValue: shadingType)!
    }

    /// The shading type as an integer (1-7).
    public var shadingType: Int {
        Int(cosObject["ShadingType"]!.integerValue!)
    }

    /// The color space for the gradient colors.
    public var colorSpace: COSValue {
        cosObject[.colorSpace]!
    }

    /// The color space name if it's a simple color space.
    public var colorSpaceName: ASAtom? {
        if let name = colorSpace.nameValue {
            return name
        }
        if let array = colorSpace.arrayValue, !array.isEmpty {
            return array[0].nameValue
        }
        return nil
    }

    /// The background color for areas outside the shading domain.
    ///
    /// If present, areas not covered by the shading are filled with this color.
    public var background: [Double]? {
        cosObject["Background"]?.arrayValue?.compactMap { $0.numericValue }
    }

    /// The bounding box for the shading.
    ///
    /// If present, the shading is clipped to this rectangle.
    public var bBox: FormXObject.Rectangle? {
        FormXObject.Rectangle(from: cosObject[.bbox])
    }

    /// Whether anti-aliasing should be applied.
    public var antiAlias: Bool {
        cosObject["AntiAlias"]?.boolValue ?? false
    }

    // MARK: - Function-Based Shading (Type 1)

    /// The domain for the shading function (type 1 only).
    ///
    /// Defaults to [0 1 0 1] if not specified.
    public var domain: [Double]? {
        guard shadingType == 1 else { return nil }
        if let array = cosObject["Domain"]?.arrayValue {
            return array.compactMap { $0.numericValue }
        }
        return [0, 1, 0, 1] // Default
    }

    /// The transformation matrix for function-based shading (type 1).
    public var shadingMatrix: FormXObject.Matrix? {
        guard shadingType == 1 else { return nil }
        return FormXObject.Matrix(from: cosObject[.matrix])
    }

    /// The function that computes color values (type 1).
    public var function: COSValue? {
        cosObject["Function"]
    }

    // MARK: - Axial Shading (Type 2)

    /// The coordinates for axial shading (type 2): [x0 y0 x1 y1].
    public var axialCoords: (start: CGPoint, end: CGPoint)? {
        guard shadingType == 2 else { return nil }
        guard let array = cosObject["Coords"]?.arrayValue, array.count >= 4 else {
            return nil
        }
        guard let x0 = array[0].numericValue,
              let y0 = array[1].numericValue,
              let x1 = array[2].numericValue,
              let y1 = array[3].numericValue else {
            return nil
        }
        return (CGPoint(x: x0, y: y0), CGPoint(x: x1, y: y1))
    }

    // MARK: - Radial Shading (Type 3)

    /// The coordinates for radial shading (type 3): [x0 y0 r0 x1 y1 r1].
    public var radialCoords: (startCenter: CGPoint, startRadius: Double, endCenter: CGPoint, endRadius: Double)? {
        guard shadingType == 3 else { return nil }
        guard let array = cosObject["Coords"]?.arrayValue, array.count >= 6 else {
            return nil
        }
        guard let x0 = array[0].numericValue,
              let y0 = array[1].numericValue,
              let r0 = array[2].numericValue,
              let x1 = array[3].numericValue,
              let y1 = array[4].numericValue,
              let r1 = array[5].numericValue else {
            return nil
        }
        return (CGPoint(x: x0, y: y0), r0, CGPoint(x: x1, y: y1), r1)
    }

    // MARK: - Common Properties for Types 2 and 3

    /// The parameter domain [t0 t1] for axial/radial shading.
    ///
    /// Defaults to [0 1] if not specified.
    public var parameterDomain: (t0: Double, t1: Double)? {
        guard shadingType == 2 || shadingType == 3 else { return nil }
        if let array = cosObject["Domain"]?.arrayValue, array.count >= 2 {
            if let t0 = array[0].numericValue, let t1 = array[1].numericValue {
                return (t0, t1)
            }
        }
        return (0, 1) // Default
    }

    /// The extend flags for axial/radial shading.
    ///
    /// Specifies whether to extend the gradient beyond the endpoints.
    public var extend: (extendStart: Bool, extendEnd: Bool)? {
        guard shadingType == 2 || shadingType == 3 else { return nil }
        if let array = cosObject["Extend"]?.arrayValue, array.count >= 2 {
            let start = array[0].boolValue ?? false
            let end = array[1].boolValue ?? false
            return (start, end)
        }
        return (false, false) // Default
    }

    // MARK: - Mesh Shading Properties (Types 4-7)

    /// The bits per coordinate value for mesh shadings (types 4-7).
    public var bitsPerCoordinate: Int? {
        guard shadingType >= 4 else { return nil }
        return cosObject["BitsPerCoordinate"]?.integerValue.map { Int($0) }
    }

    /// The bits per color component for mesh shadings (types 4-7).
    public var bitsPerComponent: Int? {
        guard shadingType >= 4 else { return nil }
        return cosObject[.bitsPerComponent]?.integerValue.map { Int($0) }
    }

    /// The bits per flag value for free-form and Coons/tensor patch shadings.
    public var bitsPerFlag: Int? {
        guard shadingType == 4 || shadingType == 6 || shadingType == 7 else {
            return nil
        }
        return cosObject["BitsPerFlag"]?.integerValue.map { Int($0) }
    }

    /// The decode array for mesh coordinates and colors.
    public var decode: [Double]? {
        guard shadingType >= 4 else { return nil }
        return cosObject["Decode"]?.arrayValue?.compactMap { $0.numericValue }
    }

    /// The vertices per row for lattice-form Gouraud shading (type 5).
    public var verticesPerRow: Int? {
        guard shadingType == 5 else { return nil }
        return cosObject["VerticesPerRow"]?.integerValue.map { Int($0) }
    }

    // MARK: - Validation

    /// Whether the shading has all required properties for its type.
    public var isValid: Bool {
        switch type {
        case .functionBased:
            return function != nil

        case .axial:
            return axialCoords != nil && function != nil

        case .radial:
            return radialCoords != nil && function != nil

        case .freeFormGouraud:
            return bitsPerCoordinate != nil && bitsPerComponent != nil &&
                   bitsPerFlag != nil && decode != nil

        case .latticeFormGouraud:
            return bitsPerCoordinate != nil && bitsPerComponent != nil &&
                   verticesPerRow != nil && decode != nil

        case .coonsPatch, .tensorProductPatch:
            return bitsPerCoordinate != nil && bitsPerComponent != nil &&
                   bitsPerFlag != nil && decode != nil
        }
    }
}

// MARK: - CustomStringConvertible

extension Shading: CustomStringConvertible {
    public var description: String {
        var parts = ["Shading(type:\(type)"]

        if let name = colorSpaceName {
            parts.append("cs:\(name.stringValue)")
        }

        if let bbox = bBox {
            parts.append("bbox:\(bbox)")
        }

        if antiAlias {
            parts.append("antiAlias")
        }

        return parts.joined(separator: ", ") + ")"
    }
}
