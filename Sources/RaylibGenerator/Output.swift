/// Renders the generated files from a parsed header. Output depends only on the header,
/// so running the generator twice gives the same bytes, and CI can check it with `git diff`.
public enum Output {
    /// Enums raylib uses as bit masks, imported as option sets rather than enums.
    public static let optionSets: Set<String> = ["ConfigFlags", "Gesture"]

    /// The parameters that take an enum value as a plain `int` or `unsigned int`, by
    /// function. Each gets an overload taking the Swift type instead.
    public static let typedParameters: [(function: String, parameter: String, type: String)] = [
        ("IsWindowState", "flag", "ConfigFlags"),
        ("SetWindowState", "flags", "ConfigFlags"),
        ("ClearWindowState", "flags", "ConfigFlags"),
        ("SetConfigFlags", "flags", "ConfigFlags"),
        ("BeginBlendMode", "mode", "BlendMode"),
        ("SetShaderValue", "uniformType", "ShaderUniformDataType"),
        ("SetShaderValueV", "uniformType", "ShaderUniformDataType"),
        ("SetTraceLogLevel", "logLevel", "TraceLogLevel"),
        ("IsKeyPressed", "key", "KeyboardKey"),
        ("IsKeyPressedRepeat", "key", "KeyboardKey"),
        ("IsKeyDown", "key", "KeyboardKey"),
        ("IsKeyReleased", "key", "KeyboardKey"),
        ("IsKeyUp", "key", "KeyboardKey"),
        ("GetKeyName", "key", "KeyboardKey"),
        ("SetExitKey", "key", "KeyboardKey"),
        ("IsGamepadButtonPressed", "button", "GamepadButton"),
        ("IsGamepadButtonDown", "button", "GamepadButton"),
        ("IsGamepadButtonReleased", "button", "GamepadButton"),
        ("IsGamepadButtonUp", "button", "GamepadButton"),
        ("GetGamepadAxisMovement", "axis", "GamepadAxis"),
        ("IsMouseButtonPressed", "button", "MouseButton"),
        ("IsMouseButtonDown", "button", "MouseButton"),
        ("IsMouseButtonReleased", "button", "MouseButton"),
        ("IsMouseButtonUp", "button", "MouseButton"),
        ("SetMouseCursor", "cursor", "MouseCursor"),
        ("SetGesturesEnabled", "flags", "Gesture"),
        ("IsGestureDetected", "gesture", "Gesture"),
        ("UpdateCamera", "mode", "CameraMode"),
        ("LoadImageRaw", "format", "PixelFormat"),
        ("ImageFormat", "newFormat", "PixelFormat"),
        ("LoadTextureCubemap", "layout", "CubemapLayout"),
        ("SetTextureFilter", "filter", "TextureFilter"),
        ("SetTextureWrap", "wrap", "TextureWrap"),
        ("GetPixelColor", "format", "PixelFormat"),
        ("SetPixelColor", "format", "PixelFormat"),
        ("GetPixelDataSize", "format", "PixelFormat"),
    ]

    /// `CRaylib.apinotes`: imports each enum as a Swift enum or option set with camel-case
    /// case names. Enums are open (`NSEnum`), so a value raylib adds later can't trap a switch.
    public static func apiNotes(for header: RaylibHeader) throws(GeneratorError) -> String {
        for name in optionSets.sorted() where !header.enums.contains(where: { $0.name == name }) {
            throw GeneratorError.unknownEnum(name)
        }
        var tags = ""
        var enumerators = ""
        for cEnum in header.enums {
            let kind = optionSets.contains(cEnum.name) ? "NSOptions" : "NSEnum"
            tags += "- Name: \(cEnum.name)\n  EnumKind: \(kind)\n"
            for (constant, name) in zip(cEnum.constants, try Naming.caseNames(for: cEnum.constants)) {
                enumerators += "- Name: \(constant)\n  SwiftName: '\(name)'\n"
            }
        }
        return """
        # \(banner(header))
        ---
        Name: CRaylib
        Tags:
        \(tags)Enumerators:
        \(enumerators)
        """
    }

    /// `Colors.swift`: raylib's color macros, which Swift can't import as written.
    public static func colors(for header: RaylibHeader) -> String {
        var body = ""
        for color in header.colors {
            let c = color.components
            let doc = color.comment.isEmpty ? color.name : color.comment
            body += """
                /// \(doc) (`\(color.name)`).
                public static let \(Naming.colorName(for: color.name)) = Color(r: \(c[0]), g: \(c[1]), b: \(c[2]), a: \(c[3]))

            """
        }
        return """
        // \(banner(header))

        import CRaylib

        extension Color {
        \(body)}

        """
    }

    /// `Overloads.swift`: a Swift-typed overload of each function that takes an `int`.
    ///
    /// Each `int` parameter becomes `Int`, Swift's everyday integer, and an `int` result is
    /// returned as `Int`; the parameters in ``typedParameters`` take their enum or option set
    /// instead. A function whose only `int` is its result gets no overload, since overloads
    /// that differ only by result type make plain `let x = F()` ambiguous. Neither do
    /// variadic functions or ones with a type ``swiftType(for:in:isReturn:)`` can't spell;
    /// the C function is always there as it is.
    public static func overloads(for header: RaylibHeader) throws(GeneratorError) -> String {
        let enumNames = Set(header.enums.map(\.name))
        var byFunction: [String: [String: String]] = [:]
        for entry in typedParameters {
            guard enumNames.contains(entry.type) else { throw GeneratorError.unknownEnum(entry.type) }
            byFunction[entry.function, default: [:]][entry.parameter] = entry.type
        }

        var body = ""
        var found: Set<String> = []
        for function in header.functions {
            if let typed = byFunction[function.name] {
                for parameter in typed.keys.sorted() where !function.parameters.contains(where: { $0.name == parameter }) {
                    throw GeneratorError.unknownParameter(function: function.name, parameter: parameter)
                }
                body += try overload(of: function, typed: typed)
                found.insert(function.name)
            } else if !function.isVariadic, function.parameters.contains(where: { $0.type == "int" }) {
                do {
                    body += try overload(of: function, typed: [:])
                } catch {
                    continue
                }
            }
        }
        for entry in typedParameters where !found.contains(entry.function) {
            throw GeneratorError.unknownParameter(function: entry.function, parameter: entry.parameter)
        }

        return """
        // \(banner(header))

        import CRaylib

        \(body)
        """
    }

    static func overload(of function: CFunction, typed: [String: String]) throws(GeneratorError) -> String {
        var parameters: [String] = []
        var arguments: [String] = []
        for parameter in function.parameters {
            let name = swiftIdentifier(parameter.name)
            if let enumType = typed[parameter.name] {
                parameters.append("_ \(name): \(enumType)")
                let integer = try swiftType(for: parameter.type, in: function.name, isReturn: false)
                arguments.append("\(integer)(truncatingIfNeeded: \(name).rawValue)")
            } else if parameter.type == "int" {
                parameters.append("_ \(name): Int")
                arguments.append("Int32(clamping: \(name))")
            } else {
                parameters.append("_ \(name): \(try swiftType(for: parameter.type, in: function.name, isReturn: false))")
                arguments.append(name)
            }
        }
        let call = "CRaylib.\(function.name)(\(arguments.joined(separator: ", ")))"
        let returnsInt = function.returnType == "int"
        let returnType = returnsInt ? "Int" : try swiftType(for: function.returnType, in: function.name, isReturn: true)
        let arrow = returnType == "Void" ? "" : " -> \(returnType)"
        let comment = function.comment.isEmpty ? function.name : function.comment
        let doc = comment.hasSuffix(".") ? comment : comment + "."
        return """
        /// \(doc)
        ///
        /// Calls `\(function.name)` with `Int` arguments clamped to `Int32` and typed arguments' raw values.
        @inlinable
        public func \(function.name)(\(parameters.joined(separator: ", ")))\(arrow) {
            \(returnsInt ? "Int(\(call))" : call)
        }


        """
    }

    /// The Swift spelling of a C type, as Swift imports it. Pointer parameters are
    /// non-optional; pointer returns are optional, since raylib returns `NULL` on failure.
    static func swiftType(for cType: String, in function: String, isReturn: Bool) throws(GeneratorError) -> String {
        let scalars: [String: String] = [
            "void": "Void", "bool": "Bool", "int": "Int32", "unsigned int": "UInt32",
            "float": "Float", "double": "Double", "char": "CChar", "unsigned char": "UInt8",
        ]
        if let scalar = scalars[cType] { return scalar }

        let isPointer = cType.hasSuffix(" *")
        guard isPointer, !cType.hasSuffix("**") else {
            guard cType.isIdentifier else { throw GeneratorError.unsupportedType(function: function, type: cType) }
            return cType
        }
        var base = String(cType.dropLast(2))
        let isConst = base.hasPrefix("const ")
        if isConst { base = String(base.dropFirst("const ".count)) }

        let pointer: String
        if base == "void" {
            pointer = isConst ? "UnsafeRawPointer" : "UnsafeMutableRawPointer"
        } else if let scalar = scalars[base] ?? (base.isIdentifier ? base : nil) {
            pointer = isConst ? "UnsafePointer<\(scalar)>" : "UnsafeMutablePointer<\(scalar)>"
        } else {
            throw GeneratorError.unsupportedType(function: function, type: cType)
        }
        return isReturn ? pointer + "?" : pointer
    }

    private static func swiftIdentifier(_ name: String) -> String {
        let keywords: Set<String> = ["default", "in", "inout", "func", "var", "let", "repeat", "where", "case", "protocol", "self", "Type"]
        return keywords.contains(name) ? "`\(name)`" : name
    }

    private static func banner(_ header: RaylibHeader) -> String {
        "Generated by raylib-swift-gen from raylib \(header.version)'s raylib.h. Don't edit; run scripts/update-raylib.sh."
    }
}
