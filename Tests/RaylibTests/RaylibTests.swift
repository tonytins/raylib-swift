// These run without a window or GPU: they check that the C library links and that the
// generated Swift layer matches raylib's own values.

import Raylib
import Testing

@Test func versionMatchesVendoredHeader() {
    #expect(RAYLIB_VERSION_MAJOR >= 6)
}

@Test func colorsMatchRaylibMacros() {
    #expect(Color.rayWhite == Color(r: 245, g: 245, b: 245, a: 255))
    #expect(Color.lightGray == Color(r: 200, g: 200, b: 200, a: 255))
    #expect(Color.blank == Color(r: 0, g: 0, b: 0, a: 0))
    #expect(ColorToInt(.red) == ColorToInt(Color(r: 230, g: 41, b: 55, a: 255)))
}

@Test func enumsImportAsSwiftEnumsWithRaylibValues() {
    #expect(KeyboardKey.space.rawValue == 32)
    #expect(KeyboardKey.a.rawValue == 65)
    #expect(KeyboardKey.kp0.rawValue == 320)
    #expect(MouseButton.left.rawValue == 0)
    #expect(TraceLogLevel.warning.rawValue == 4)
    #expect(PixelFormat.uncompressedR8g8b8a8.rawValue == 7)
}

@Test func flagEnumsImportAsOptionSets() {
    let flags: ConfigFlags = [.vsyncHint, .msaa4xHint]
    #expect(flags.contains(.vsyncHint))
    #expect(!flags.contains(.windowResizable))
    #expect(flags.rawValue == 0x40 | 0x20)
}

@Test func raymathIsCallable() {
    let sum = Vector2Add(Vector2(x: 1, y: 2), Vector2(x: 3, y: 4))
    #expect(sum.x == 4 && sum.y == 6)
    #expect(Clamp(5, 0, 1) == 1)
}

@Test func imagesWorkWithoutAWindow() {
    var image = GenImageColor(4, 2, .blue)
    defer { UnloadImage(image) }
    #expect(image.width == 4 && image.height == 2)
    #expect(GetImageColor(image, 1, 1) == .blue)

    ImageFormat(&image, .uncompressedGrayscale)
    #expect(image.format == Int32(PixelFormat.uncompressedGrayscale.rawValue))
    #expect(GetPixelDataSize(4, 2, .uncompressedGrayscale) == 8)
}

@Test func intOverloadsTakeAndReturnInt() {
    // MeasureText needs the font a window loads, so this uses another int-to-int function.
    let bound: Int = 7
    let value: Int = GetRandomValue(bound, bound)
    #expect(value == 7)

    var image = GenImageColor(4, 2, .green)
    defer { UnloadImage(image) }
    let x: Int = 1
    ImageDrawPixel(&image, x, 1, .red)
    #expect(GetImageColor(image, x, 1) == .red)
}

@Test func intArgumentsClampInsteadOfTrapping() {
    var image = GenImageColor(2, 2, .blue)
    defer { UnloadImage(image) }
    // Int.max doesn't fit an Int32; it clamps, lands off the image, and draws nothing.
    ImageDrawPixel(&image, Int.max, 0, .red)
    #expect(GetImageColor(image, 0, 0) == .blue)
}

@Test func typedOverloadsTakeIntForTheirOtherParameters() {
    let gamepad: Int = 0
    // No gamepad is connected in tests, so this reads as not pressed.
    #expect(!IsGamepadButtonDown(gamepad, .leftFaceUp))
}

@Test func vectorOperatorsMatchRaymath() {
    var a = Vector2(x: 1, y: 2)
    let b = Vector2(x: 3, y: 4)
    #expect(a + b == Vector2(x: 4, y: 6))
    #expect(b - a == Vector2(x: 2, y: 2))
    #expect(a * 2 == Vector2(x: 2, y: 4))
    #expect(2 * a == a * 2)
    #expect(b / 2 == Vector2(x: 1.5, y: 2))
    #expect(-a == Vector2(x: -1, y: -2))
    a += b
    #expect(a == Vector2(x: 4, y: 6))
    #expect(Vector2.zero + .one == .one)
    #expect(Vector3.unitX + .unitY + .unitZ == .one)
}
