// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "raylib-swift",
    products: [
        .library(name: "Raylib", targets: ["Raylib"]),
    ],
    targets: [
        // raylib itself, vendored unmodified in raylib/ by scripts/update-raylib.sh.
        .target(
            name: "CRaylib",
            exclude: [
                // Included by the module sources, not compiled on their own.
                "raylib/external",
                "raylib/platforms",
                // Compiled through glfw.c (Linux, Windows) and glfw.m (macOS).
                "raylib/rglfw.c",
                "raylib/LICENSE",
            ],
            cSettings: [
                .headerSearchPath("raylib/external/glfw/include"),
                .define("PLATFORM_DESKTOP_GLFW"),
                .define("GRAPHICS_API_OPENGL_33"),
                // Empty, as GLFW's posix_poll.c defines it, so the two definitions agree.
                .define("_GNU_SOURCE", to: "", .when(platforms: [.linux])),
                .define("_GLFW_X11", .when(platforms: [.linux])),
            ],
            linkerSettings: [
                .linkedLibrary("m", .when(platforms: [.linux])),
                .linkedLibrary("pthread", .when(platforms: [.linux])),
                .linkedLibrary("dl", .when(platforms: [.linux])),
                .linkedLibrary("rt", .when(platforms: [.linux])),
                .linkedLibrary("X11", .when(platforms: [.linux])),
                .linkedFramework("OpenGL", .when(platforms: [.macOS])),
                .linkedFramework("Cocoa", .when(platforms: [.macOS])),
                .linkedFramework("IOKit", .when(platforms: [.macOS])),
                .linkedFramework("CoreAudio", .when(platforms: [.macOS])),
                .linkedFramework("CoreVideo", .when(platforms: [.macOS])),
                .linkedLibrary("opengl32", .when(platforms: [.windows])),
                .linkedLibrary("gdi32", .when(platforms: [.windows])),
                .linkedLibrary("winmm", .when(platforms: [.windows])),
                .linkedLibrary("shell32", .when(platforms: [.windows])),
            ]
        ),
        // The Swift layer: re-exports CRaylib and adds generated conveniences.
        .target(name: "Raylib", dependencies: ["CRaylib"]),

        // Reads raylib.h and writes the generated files. Not a product.
        .target(name: "RaylibGenerator"),
        .executableTarget(name: "raylib-swift-gen", dependencies: ["RaylibGenerator"]),

        .executableTarget(name: "basic-window", dependencies: ["Raylib"], path: "Examples/BasicWindow"),

        .testTarget(name: "RaylibTests", dependencies: ["Raylib"]),
        .testTarget(name: "RaylibGeneratorTests", dependencies: ["RaylibGenerator"]),
    ],
    cLanguageStandard: .c99
)
