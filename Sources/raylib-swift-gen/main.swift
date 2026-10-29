// Usage: raylib-swift-gen [package-root]
//
// Regenerates CRaylib.apinotes and Sources/Raylib/Generated from the vendored raylib.h.

import Foundation
import RaylibGenerator

let arguments = CommandLine.arguments.dropFirst()
guard arguments.count <= 1 else {
    FileHandle.standardError.write(Data("usage: raylib-swift-gen [package-root]\n".utf8))
    exit(2)
}
let root = URL(fileURLWithPath: arguments.first ?? FileManager.default.currentDirectoryPath, isDirectory: true)

do {
    let changed = try Generator.run(root: root)
    print(changed.isEmpty ? "Generated files are up to date." : changed.map { "Wrote \($0)" }.joined(separator: "\n"))
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(1)
}
