/// The parts of `raylib.h` the generator reads.
///
/// raylib keeps its header to strict conventions, which its own `rlparser` relies on: one
/// `RLAPI` declaration per line, `typedef enum {` blocks closed by `} Name;`, and colors as
/// `#define NAME CLITERAL(Color){ r, g, b, a }`. The parser reads those shapes and nothing
/// else, and anything it can't read in them is an error rather than a skipped line, so a
/// raylib release that changes its conventions stops an update instead of shipping a gap.
public struct RaylibHeader: Equatable, Sendable {
    /// The value of `RAYLIB_VERSION`, such as `6.0`.
    public var version: String
    /// The anonymous `typedef enum` blocks, in header order.
    public var enums: [CEnum]
    /// The `Color` constants, in header order.
    public var colors: [ColorDefine]
    /// The `RLAPI` functions, in header order.
    public var functions: [CFunction]

    /// Parses the text of `raylib.h`.
    public init(parsing text: String) throws(GeneratorError) {
        var version: String?
        var enums: [CEnum] = []
        var colors: [ColorDefine] = []
        var functions: [CFunction] = []
        var openEnum: [String]?

        for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineNumber = index + 1
            let line = rawLine.trimmingSpaces()

            if var constants = openEnum {
                let code = line.removingLineComment()
                if code.isEmpty { continue }
                if code.hasPrefix("}") {
                    guard let name = code.dropFirst().trimmingSpaces().strippingSuffix(";"),
                          name.isIdentifier else {
                        throw GeneratorError.malformed(line: lineNumber, String(line))
                    }
                    enums.append(CEnum(name: name, constants: constants))
                    openEnum = nil
                    continue
                }
                let name = code.prefix { $0 != "=" && $0 != "," }.trimmingSpaces()
                guard name.isIdentifier else {
                    throw GeneratorError.malformed(line: lineNumber, String(line))
                }
                constants.append(String(name))
                openEnum = constants
                continue
            }

            if line == "typedef enum {" {
                openEnum = []
            } else if line.hasPrefix("#define RAYLIB_VERSION ") {
                version = try parseVersion(line, lineNumber: lineNumber)
            } else if line.hasPrefix("#define "), line.range(of: "CLITERAL(Color)") != nil {
                colors.append(try parseColor(line, lineNumber: lineNumber))
            } else if line.hasPrefix("RLAPI ") {
                functions.append(try parseFunction(line, lineNumber: lineNumber))
            }
        }

        guard openEnum == nil else { throw GeneratorError.unterminatedEnum }
        guard let version else { throw GeneratorError.missingVersion }
        self.version = version
        self.enums = enums
        self.colors = colors
        self.functions = functions
    }
}

/// An anonymous `typedef enum { ... } Name;` block.
public struct CEnum: Equatable, Sendable {
    /// The typedef name, such as `KeyboardKey`.
    public var name: String
    /// The enumerator names, such as `KEY_SPACE`, in declaration order.
    public var constants: [String]
}

/// A `#define NAME CLITERAL(Color){ r, g, b, a } // comment` line.
public struct ColorDefine: Equatable, Sendable {
    /// The macro name, such as `LIGHTGRAY`.
    public var name: String
    /// The red, green, blue, and alpha components.
    public var components: [UInt8]
    /// The trailing comment, such as `Light Gray`.
    public var comment: String
}

/// An `RLAPI` function declaration.
public struct CFunction: Equatable, Sendable {
    /// The function name.
    public var name: String
    /// The C return type, normalized (such as `const char *`).
    public var returnType: String
    /// The parameters, in order. Empty for `(void)`.
    public var parameters: [CParameter]
    /// Whether the parameter list ends in `...`.
    public var isVariadic: Bool
    /// The trailing comment.
    public var comment: String
}

/// One parameter of a ``CFunction``.
public struct CParameter: Equatable, Sendable {
    /// The C type, normalized (such as `Camera *`).
    public var type: String
    /// The parameter name.
    public var name: String
}

private func parseVersion(_ line: Substring, lineNumber: Int) throws(GeneratorError) -> String {
    let parts = line.split(separator: "\"")
    guard parts.count >= 2 else { throw GeneratorError.malformed(line: lineNumber, String(line)) }
    return String(parts[1])
}

private func parseColor(_ line: Substring, lineNumber: Int) throws(GeneratorError) -> ColorDefine {
    let fields = line.dropFirst("#define ".count)
    let name = fields.prefix { !$0.isWhitespace }
    guard name.isIdentifier,
          let open = line.firstIndex(of: "{"),
          let close = line[open...].firstIndex(of: "}") else {
        throw GeneratorError.malformed(line: lineNumber, String(line))
    }
    var components: [UInt8] = []
    for field in line[line.index(after: open)..<close].split(separator: ",") {
        guard let value = UInt8(field.trimmingSpaces()) else {
            throw GeneratorError.malformed(line: lineNumber, String(line))
        }
        components.append(value)
    }
    guard components.count == 4 else { throw GeneratorError.malformed(line: lineNumber, String(line)) }
    return ColorDefine(name: String(name), components: components, comment: line.lineComment())
}

private func parseFunction(_ line: Substring, lineNumber: Int) throws(GeneratorError) -> CFunction {
    let code = line.removingLineComment().dropFirst("RLAPI ".count)
    guard let open = code.firstIndex(of: "("),
          let close = code.lastIndex(of: ")"),
          open < close,
          code[code.index(after: close)...].trimmingSpaces() == ";" else {
        throw GeneratorError.malformed(line: lineNumber, String(line))
    }
    guard let head = splitDeclaration(code[..<open]) else {
        throw GeneratorError.malformed(line: lineNumber, String(line))
    }

    var parameters: [CParameter] = []
    var isVariadic = false
    let list = code[code.index(after: open)..<close].trimmingSpaces()
    if list != "void" && !list.isEmpty {
        for field in list.split(separator: ",") {
            let field = field.trimmingSpaces()
            if field == "..." {
                isVariadic = true
                continue
            }
            guard !isVariadic, let parameter = splitDeclaration(field) else {
                throw GeneratorError.malformed(line: lineNumber, String(line))
            }
            parameters.append(CParameter(type: parameter.type, name: parameter.name))
        }
    }
    return CFunction(
        name: head.name,
        returnType: head.type,
        parameters: parameters,
        isVariadic: isVariadic,
        comment: line.lineComment()
    )
}

/// Splits `const char *name` into the type `const char *` and the name `name`.
private func splitDeclaration(_ text: Substring) -> (type: String, name: String)? {
    let text = text.trimmingSpaces()
    let name = text.reversed().prefix { $0.isLetter || $0.isNumber || $0 == "_" }.reversed()
    let nameText = String(name)
    guard nameText.isIdentifier else { return nil }
    let typeText = text.dropLast(nameText.count).trimmingSpaces()
    guard !typeText.isEmpty else { return nil }
    return (normalizeType(typeText), nameText)
}

/// Normalizes spacing so pointer types read `T *` and `T **`.
private func normalizeType(_ type: Substring) -> String {
    let stars = type.filter { $0 == "*" }.count
    let base = type.filter { $0 != "*" }.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    return stars == 0 ? base : base + " " + String(repeating: "*", count: stars)
}

extension StringProtocol where SubSequence == Substring {
    func trimmingSpaces() -> Substring {
        let start = firstIndex { !$0.isWhitespace } ?? endIndex
        let end = lastIndex { !$0.isWhitespace }.map(index(after:)) ?? start
        return self[start..<end]
    }

    func strippingSuffix(_ suffix: String) -> String? {
        guard hasSuffix(suffix) else { return nil }
        return String(dropLast(suffix.count)).trimmingSpaces().description
    }

    func removingLineComment() -> Substring {
        guard let range = range(of: "//") else { return trimmingSpaces() }
        return self[..<range.lowerBound].trimmingSpaces()
    }

    func lineComment() -> String {
        guard let range = range(of: "//") else { return "" }
        return String(self[range.upperBound...].trimmingSpaces())
    }

    var isIdentifier: Bool {
        guard let first, first.isLetter || first == "_" else { return false }
        return allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
    }
}
