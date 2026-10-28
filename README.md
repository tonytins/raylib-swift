# raylib-swift

[raylib](https://www.raylib.com) for Swift, kept current by automation.

raylib is vendored as source and built by SwiftPM, so there's nothing to install
besides the system headers below. The whole C API comes through unchanged, along with
raymath and rlgl. On top of it, a generated Swift layer adds what Swift can't import
from raylib's header on its own:

| raylib (C) | Swift |
| --- | --- |
| `KEY_SPACE`, `MOUSE_BUTTON_LEFT` | `KeyboardKey.space`, `MouseButton.left` |
| `FLAG_VSYNC_HINT \| FLAG_MSAA_4X_HINT` | `[.vsyncHint, .msaa4xHint]` (an `OptionSet`) |
| `RAYWHITE`, `LIGHTGRAY` (compound-literal macros) | `Color.rayWhite`, `Color.lightGray` |
| `IsKeyDown(KEY_SPACE)` (takes an `int`) | `IsKeyDown(.space)` |
| `DrawText(text, x, y, 20, color)` (C `int`, imported as `Int32`) | the same call with `Int` values; `MeasureText` returns `Int` |
| `Vector2Add(a, Vector2Scale(b, 2))` | `a + b * 2`, plus `Vector2.zero` and `.one`, and the same for `Vector3` |

Function names stay raylib's, so raylib's examples and cheatsheet read the same in Swift.

`Int` arguments are clamped to `Int32`'s range rather than trapping. A function whose only
`int` is its result, such as `GetScreenWidth()`, still returns `Int32`: an overload that
differed only in its result type would make `let width = GetScreenWidth()` ambiguous. Wrap
it as `Int(GetScreenWidth())` where you need an `Int`.

```swift
import Raylib

SetConfigFlags([.vsyncHint, .windowResizable])
InitWindow(800, 450, "raylib-swift - basic window")
SetTargetFPS(60)

while !WindowShouldClose() {
    BeginDrawing()
    ClearBackground(.rayWhite)
    DrawText("Congrats! You created your first window!", 190, 200, 20, .lightGray)
    EndDrawing()
}

CloseWindow()
```

The vendored raylib version is in [`RAYLIB_VERSION`](RAYLIB_VERSION).

## Using it

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/tonytins/raylib-swift", branch: "main"),
],
targets: [
    .executableTarget(name: "MyGame", dependencies: [
        .product(name: "Raylib", package: "raylib-swift"),
    ]),
]
```

Run the example with `swift run basic-window`.

### Requirements

Swift 6.0 or later, and on Linux the X11 and GL development headers. raylib loads
OpenGL and audio at run time, so nothing else needs to be installed.

| System | Install |
| --- | --- |
| Debian, Ubuntu | `sudo apt install libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libxext-dev libgl1-mesa-dev` |
| Fedora | `sudo dnf install libX11-devel libXrandr-devel libXinerama-devel libXcursor-devel libXi-devel libXext-devel mesa-libGL-devel` |
| Fedora Atomic (Bazzite, Bluefin, Aurora) | Build in a Distrobox with the Fedora or Ubuntu packages above, or use Homebrew's (below) |
| macOS | Nothing; the frameworks ship with the OS |

With Homebrew on Linux (`brew install libx11 libxrandr libxinerama libxcursor libxi mesa xorgproto`),
point the compiler at its headers. `xorgproto` isn't linked into Homebrew's prefix, so it
needs its own entry:

```sh
export CPATH="$(brew --prefix)/include:$(brew --prefix xorgproto)/include"
export LIBRARY_PATH="$(brew --prefix)/lib"
```

The built program loads the system's `libX11.so.6` at run time, not Homebrew's.

## How it's kept current

Nothing in `Sources/Raylib/Generated/` or `Sources/CRaylib/include/CRaylib.apinotes` is
written by hand. `raylib-swift-gen` reads the vendored `raylib.h` and writes them:

- **`CRaylib.apinotes`** tells Swift's importer to bring each raylib enum in as a Swift
  enum (or, for `ConfigFlags` and `Gesture`, an option set) and gives every case a
  camel-case name: `KEY_LEFT_SHIFT` becomes `leftShift`. Enums are imported open, so a
  value raylib adds later can't trap a `switch`.
- **`Colors.swift`** holds raylib's color macros as `Color` constants.
- **`Overloads.swift`** has an overload of each function that takes an `int`, taking
  `Int` instead, or the Swift enum or option set for the parameters in the generator's
  table (`Output.typedParameters`). An `int` result comes back as `Int`.

The generator reads `raylib.h` directly instead of raylib's `raylib_api.json`, which
isn't valid JSON in raylib 6.0. When the header changes in a way it doesn't expect (a
function in its table is renamed, say), it stops with an error and writes nothing.

To update by hand:

```sh
scripts/update-raylib.sh 6.2      # or no argument for the latest release
swift build && swift test
```

### Automation

- **CI** (`.github/workflows/ci.yml`) builds and tests on Linux and macOS for every push
  and pull request. One test checks that the generated files match the vendored header.
- **Update** (`.github/workflows/update.yml`) runs once a quarter, on January, April, July, and October 1. It picks the newest raylib
  release that's at least 14 days old, vendors it, regenerates, builds, and tests, and
  opens a pull request only if all of that passes.

For the update workflow to work, enable **Settings → Actions → General → Allow GitHub
Actions to create and approve pull requests**. GitHub doesn't run CI on pull requests
opened with the default token, so to get the macOS check on update PRs, add a
fine-grained personal access token (contents and pull requests: read and write) as the
`RAYLIB_UPDATE_TOKEN` secret.

## Known limitations

- **Linux uses X11.** It runs on Wayland desktops through XWayland. GLFW's native Wayland
  backend needs generated protocol headers and isn't enabled.
- **Windows is untested.** `Package.swift` links the libraries raylib's Makefile uses on
  Windows, but no build has run there and CI doesn't cover it.
- **Stale enums after an update.** Clang's module cache doesn't track `.apinotes` files.
  If the Swift enums look wrong after regenerating, run `swift package clean`.
- One warning from raylib's bundled `stb_vorbis.c` shows when building this package
  itself. It's upstream code, and SwiftPM hides it when this package is a remote dependency.

## License

zlib, the same as raylib. See [LICENSE](LICENSE). raylib's own license is in
[`Sources/CRaylib/raylib/LICENSE`](Sources/CRaylib/raylib/LICENSE).
