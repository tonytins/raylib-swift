/// Swift names for raylib's C names.
public enum Naming {
    /// The Swift case names for an enum's constants, in the same order.
    ///
    /// Drops the words every constant shares (`KEY_` in `KeyboardKey`) and camel-cases the
    /// rest, so `KEY_LEFT_SHIFT` becomes `leftShift` and `FLAG_MSAA_4X_HINT` becomes
    /// `msaa4xHint`. A constant never loses its last word, and a name that would start with
    /// a digit keeps the shared word before it.
    public static func caseNames(for constants: [String]) throws(GeneratorError) -> [String] {
        let words = constants.map { $0.split(separator: "_").map(String.init) }
        guard let first = words.first, let shortest = words.map(\.count).min(), shortest > 0 else {
            return []
        }
        var shared = 0
        while shared < shortest - 1, words.allSatisfy({ $0[shared] == first[shared] }) {
            shared += 1
        }

        var names: [String] = []
        for constant in words {
            var start = shared
            if start > 0, constant[start].first?.isNumber == true {
                start -= 1
            }
            names.append(camelCase(constant[start...]))
        }

        var seen: [String: Int] = [:]
        for (index, name) in names.enumerated() {
            if let earlier = seen[name] {
                throw GeneratorError.duplicateName(name, constants[earlier], constants[index])
            }
            seen[name] = index
        }
        return names
    }

    /// The Swift name for a color macro: `LIGHTGRAY` becomes `lightGray`.
    ///
    /// raylib runs its color words together, so the split comes from the few modifiers it
    /// uses as prefixes. Raylib-cs names the same colors `LightGray`, `RayWhite`, and so on.
    public static func colorName(for macro: String) -> String {
        let lower = macro.lowercased()
        for modifier in ["light", "dark", "sky", "ray"] where lower.hasPrefix(modifier) && lower.count > modifier.count {
            let rest = lower.dropFirst(modifier.count)
            return modifier + rest.prefix(1).uppercased() + String(rest.dropFirst())
        }
        return lower
    }

    private static func camelCase(_ words: ArraySlice<String>) -> String {
        var result = ""
        for (offset, word) in words.enumerated() {
            let lower = word.lowercased()
            result += offset == 0 ? lower : lower.prefix(1).uppercased() + lower.dropFirst()
        }
        return result
    }
}
