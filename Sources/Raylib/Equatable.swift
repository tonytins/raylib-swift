import CRaylib

// raylib compares colors field by field (ColorIsEqual); Equatable lets Swift do the same.
extension Color: @retroactive Equatable {
    /// Whether every component matches.
    public static func == (lhs: Color, rhs: Color) -> Bool {
        lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
    }
}
