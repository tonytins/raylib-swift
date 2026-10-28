// Raylib: raylib for Swift.
//
// The whole C API comes through CRaylib unchanged, with raymath and rlgl. The Swift layer
// adds what Swift can't import from the header on its own:
//
// - Enums as Swift enums and option sets with camel-case cases (`KeyboardKey.space`,
//   `ConfigFlags.msaa4xHint`), from the generated CRaylib.apinotes.
// - The color macros as `Color` constants (`Color.rayWhite`), in Generated/Colors.swift.
// - Overloads that take `Int` where raylib takes a C `int`, and those types where the `int`
//   holds an enum value (`IsKeyDown(.space)`), in Generated/Overloads.swift.

@_exported import CRaylib
