import Foundation

/// Reads the vendored `raylib.h` and writes the generated files into a package checkout.
public enum Generator {
    /// The files the generator writes, relative to the package root.
    public enum Path {
        /// The vendored header the generator reads.
        public static let header = "Sources/CRaylib/raylib/raylib.h"
        /// The API notes beside CRaylib's module map.
        public static let apiNotes = "Sources/CRaylib/include/CRaylib.apinotes"
        /// The color constants.
        public static let colors = "Sources/Raylib/Generated/Colors.swift"
        /// The typed overloads.
        public static let typedOverloads = "Sources/Raylib/Generated/TypedOverloads.swift"
    }

    /// Renders every generated file from the header text, by path. Nothing is written.
    public static func render(headerText: String) throws(GeneratorError) -> [(path: String, contents: String)] {
        let header = try RaylibHeader(parsing: headerText)
        return [
            (Path.apiNotes, try Output.apiNotes(for: header)),
            (Path.colors, Output.colors(for: header)),
            (Path.typedOverloads, try Output.typedOverloads(for: header)),
        ]
    }

    /// Regenerates the files under `root`, returning the paths whose contents changed.
    ///
    /// Everything is rendered before anything is written, so a header the generator can't
    /// read leaves the checkout as it was.
    public static func run(root: URL) throws(GeneratorError) -> [String] {
        let headerURL = root.appending(path: Path.header)
        let headerText: String
        do {
            headerText = try String(contentsOf: headerURL, encoding: .utf8)
        } catch {
            throw GeneratorError.io(path: headerURL.path, reason: error.localizedDescription)
        }

        var changed: [String] = []
        for (path, contents) in try render(headerText: headerText) {
            let url = root.appending(path: path)
            if (try? String(contentsOf: url, encoding: .utf8)) == contents { continue }
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try contents.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                throw GeneratorError.io(path: url.path, reason: error.localizedDescription)
            }
            changed.append(path)
        }
        return changed
    }
}
