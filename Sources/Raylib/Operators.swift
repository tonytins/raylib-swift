import CRaylib

// Arithmetic on raylib's vectors, as raymath does it, so `a + b * 2` reads as it would in
// Raylib-cs (whose vectors are System.Numerics') or in C++.

extension Vector2: @retroactive Equatable {
    /// The zero vector.
    public static let zero = Vector2(x: 0, y: 0)
    /// A vector of ones.
    public static let one = Vector2(x: 1, y: 1)
    /// The unit vector along x.
    public static let unitX = Vector2(x: 1, y: 0)
    /// The unit vector along y.
    public static let unitY = Vector2(x: 0, y: 1)

    /// Whether both components match exactly.
    public static func == (lhs: Vector2, rhs: Vector2) -> Bool { lhs.x == rhs.x && lhs.y == rhs.y }

    /// The component-wise sum.
    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 { Vector2Add(lhs, rhs) }
    /// The component-wise difference.
    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 { Vector2Subtract(lhs, rhs) }
    /// The component-wise product.
    public static func * (lhs: Vector2, rhs: Vector2) -> Vector2 { Vector2Multiply(lhs, rhs) }
    /// The component-wise quotient.
    public static func / (lhs: Vector2, rhs: Vector2) -> Vector2 { Vector2Divide(lhs, rhs) }
    /// The vector scaled.
    public static func * (lhs: Vector2, rhs: Float) -> Vector2 { Vector2Scale(lhs, rhs) }
    /// The vector scaled.
    public static func * (lhs: Float, rhs: Vector2) -> Vector2 { Vector2Scale(rhs, lhs) }
    /// The vector divided by a scalar.
    public static func / (lhs: Vector2, rhs: Float) -> Vector2 { Vector2(x: lhs.x / rhs, y: lhs.y / rhs) }
    /// The vector reversed.
    public static prefix func - (vector: Vector2) -> Vector2 { Vector2Negate(vector) }

    /// Adds in place.
    public static func += (lhs: inout Vector2, rhs: Vector2) { lhs = lhs + rhs }
    /// Subtracts in place.
    public static func -= (lhs: inout Vector2, rhs: Vector2) { lhs = lhs - rhs }
    /// Scales in place.
    public static func *= (lhs: inout Vector2, rhs: Float) { lhs = lhs * rhs }
    /// Divides in place.
    public static func /= (lhs: inout Vector2, rhs: Float) { lhs = lhs / rhs }
}

extension Vector3: @retroactive Equatable {
    /// The zero vector.
    public static let zero = Vector3(x: 0, y: 0, z: 0)
    /// A vector of ones.
    public static let one = Vector3(x: 1, y: 1, z: 1)
    /// The unit vector along x.
    public static let unitX = Vector3(x: 1, y: 0, z: 0)
    /// The unit vector along y.
    public static let unitY = Vector3(x: 0, y: 1, z: 0)
    /// The unit vector along z.
    public static let unitZ = Vector3(x: 0, y: 0, z: 1)

    /// Whether every component matches exactly.
    public static func == (lhs: Vector3, rhs: Vector3) -> Bool { lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z }

    /// The component-wise sum.
    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 { Vector3Add(lhs, rhs) }
    /// The component-wise difference.
    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 { Vector3Subtract(lhs, rhs) }
    /// The component-wise product.
    public static func * (lhs: Vector3, rhs: Vector3) -> Vector3 { Vector3Multiply(lhs, rhs) }
    /// The component-wise quotient.
    public static func / (lhs: Vector3, rhs: Vector3) -> Vector3 { Vector3Divide(lhs, rhs) }
    /// The vector scaled.
    public static func * (lhs: Vector3, rhs: Float) -> Vector3 { Vector3Scale(lhs, rhs) }
    /// The vector scaled.
    public static func * (lhs: Float, rhs: Vector3) -> Vector3 { Vector3Scale(rhs, lhs) }
    /// The vector divided by a scalar.
    public static func / (lhs: Vector3, rhs: Float) -> Vector3 { Vector3(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs) }
    /// The vector reversed.
    public static prefix func - (vector: Vector3) -> Vector3 { Vector3Negate(vector) }

    /// Adds in place.
    public static func += (lhs: inout Vector3, rhs: Vector3) { lhs = lhs + rhs }
    /// Subtracts in place.
    public static func -= (lhs: inout Vector3, rhs: Vector3) { lhs = lhs - rhs }
    /// Scales in place.
    public static func *= (lhs: inout Vector3, rhs: Float) { lhs = lhs * rhs }
    /// Divides in place.
    public static func /= (lhs: inout Vector3, rhs: Float) { lhs = lhs / rhs }
}

extension Rectangle: @retroactive Equatable {
    /// Whether every field matches exactly.
    public static func == (lhs: Rectangle, rhs: Rectangle) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.width == rhs.width && lhs.height == rhs.height
    }
}
