import Foundation
@testable import RaylibGenerator
import Testing

/// A header in raylib's conventions, small enough to read at a glance.
private let sampleHeader = """
#define RAYLIB_VERSION  "9.9"
#define LIGHTGRAY  CLITERAL(Color){ 200, 200, 200, 255 }   // Light Gray
#define BLANK      CLITERAL(Color){ 0, 0, 0, 0 }           // Blank (Transparent)
    typedef enum bool { false = 0, true = !false } bool;
// System/Window config flags
typedef enum {
    FLAG_VSYNC_HINT         = 0x00000040,   // Set to try enabling V-Sync on GPU
    FLAG_MSAA_4X_HINT       = 0x00000020,   // Set to try enabling MSAA 4X
} ConfigFlags;
typedef enum {
    KEY_NULL            = 0,        // Key: NULL, used for no key pressed

    KEY_LEFT_SHIFT      = 340,      // Key: Shift left
    KEY_KP_0            = 320,      // Key: Keypad 0
} KeyboardKey;
typedef enum {
    GESTURE_NONE        = 0,        // No gesture
    GESTURE_TAP         = 1,        // Tap gesture
} Gesture;
RLAPI void SetConfigFlags(unsigned int flags);                  // Setup init configuration flags (view FLAGS)
RLAPI bool IsKeyDown(int key);                                // Check if a key is being pressed
RLAPI const char *GetKeyName(int key);                        // Get name of a QWERTY key
RLAPI void TraceLog(int logLevel, const char *text, ...);       // Show trace log messages
RLAPI void InitWindow(int width, int height, const char *title);  // Initialize window
"""

@Test func parsesEachShapeTheGeneratorReads() throws {
    let header = try RaylibHeader(parsing: sampleHeader)
    #expect(header.version == "9.9")
    #expect(header.colors == [
        ColorDefine(name: "LIGHTGRAY", components: [200, 200, 200, 255], comment: "Light Gray"),
        ColorDefine(name: "BLANK", components: [0, 0, 0, 0], comment: "Blank (Transparent)"),
    ])
    #expect(header.enums.map(\.name) == ["ConfigFlags", "KeyboardKey", "Gesture"])
    #expect(header.enums[1].constants == ["KEY_NULL", "KEY_LEFT_SHIFT", "KEY_KP_0"])

    let getKeyName = try #require(header.functions.first { $0.name == "GetKeyName" })
    #expect(getKeyName.returnType == "const char *")
    #expect(getKeyName.parameters == [CParameter(type: "int", name: "key")])

    let traceLog = try #require(header.functions.first { $0.name == "TraceLog" })
    #expect(traceLog.isVariadic)
    #expect(traceLog.parameters.map(\.type) == ["int", "const char *"])
}

@Test(arguments: [
    (["KEY_NULL", "KEY_LEFT_SHIFT", "KEY_KP_0"], ["null", "leftShift", "kp0"]),
    (["FLAG_VSYNC_HINT", "FLAG_MSAA_4X_HINT"], ["vsyncHint", "msaa4xHint"]),
    (["MOUSE_BUTTON_LEFT", "MOUSE_BUTTON_RIGHT"], ["left", "right"]),
    // A lone constant keeps its last word.
    (["NPATCH_NINE_PATCH"], ["patch"]),
    // A name that would start with a digit keeps the shared word before it.
    (["CUBE_1X6", "CUBE_6X1"], ["cube1x6", "cube6x1"]),
])
func caseNamesDropTheSharedPrefix(constants: [String], expected: [String]) throws {
    #expect(try Naming.caseNames(for: constants) == expected)
}

@Test func caseNamesRejectCollisions() {
    #expect(throws: GeneratorError.duplicateName("leftShift", "KEY_LEFT_SHIFT", "KEY_LEFT__SHIFT")) {
        try Naming.caseNames(for: ["KEY_A", "KEY_LEFT_SHIFT", "KEY_LEFT__SHIFT"])
    }
}

@Test(arguments: [
    ("LIGHTGRAY", "lightGray"), ("DARKBLUE", "darkBlue"), ("SKYBLUE", "skyBlue"),
    ("RAYWHITE", "rayWhite"), ("RED", "red"), ("BLANK", "blank"),
])
func colorNamesSplitRaylibModifiers(macro: String, expected: String) {
    #expect(Naming.colorName(for: macro) == expected)
}

@Test(arguments: [
    ("int", false, "Int32"), ("unsigned int", false, "UInt32"), ("Camera *", false, "UnsafeMutablePointer<Camera>"),
    ("const void *", false, "UnsafeRawPointer"), ("const char *", true, "UnsafePointer<CChar>?"),
    ("Texture2D", false, "Texture2D"),
])
func cTypesMapToSwift(cType: String, isReturn: Bool, expected: String) throws {
    #expect(try Output.swiftType(for: cType, in: "F", isReturn: isReturn) == expected)
}

@Test func unsupportedTypesAreReported() {
    #expect(throws: GeneratorError.unsupportedType(function: "F", type: "char **")) {
        try Output.swiftType(for: "char **", in: "F", isReturn: false)
    }
}

@Test func apiNotesMarkFlagEnumsAsOptionSets() throws {
    let notes = try Output.apiNotes(for: try RaylibHeader(parsing: sampleHeader))
    #expect(notes.contains("- Name: ConfigFlags\n  EnumKind: NSOptions\n"))
    #expect(notes.contains("- Name: KeyboardKey\n  EnumKind: NSEnum\n"))
    // Quoted, or YAML would read `null` as no value.
    #expect(notes.contains("- Name: KEY_NULL\n  SwiftName: 'null'\n"))
}

@Test func colorsRenderAsStaticConstants() throws {
    let colors = Output.colors(for: try RaylibHeader(parsing: sampleHeader))
    #expect(colors.contains("public static let lightGray = Color(r: 200, g: 200, b: 200, a: 255)"))
}

@Test func overloadsNeedEveryTableEntryInTheHeader() throws {
    // The sample lacks most of the table's functions, as a raylib release that renamed
    // them would; the generator must stop, not write a partial file.
    let header = try RaylibHeader(parsing: sampleHeader)
    #expect(throws: GeneratorError.self) { try Output.overloads(for: header) }
}

@Test(arguments: [
    "typedef enum {\n    KEY_A = 65,\n",                          // never closed
    "#define RAYLIB_VERSION \"1\"\nRLAPI void Broken(int key)\n",   // no semicolon
    "#define RAYLIB_VERSION \"1\"\n#define BAD CLITERAL(Color){ 1, 2, 3 }\n",
    "RLAPI void InitWindow(void);\n",                              // no version
])
func malformedHeadersThrow(text: String) {
    #expect(throws: GeneratorError.self) { try RaylibHeader(parsing: text) }
}

/// The vendored raylib.h renders to exactly the checked-in files, so nobody edited them
/// by hand and the generator is deterministic.
@Test func checkedInFilesMatchTheVendoredHeader() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let header = try String(contentsOf: root.appendingPathComponent(Generator.Path.header), encoding: .utf8)
    for (path, contents) in try Generator.render(headerText: header) {
        let onDisk = try String(contentsOf: root.appendingPathComponent(path), encoding: .utf8)
        #expect(onDisk == contents, "\(path) is out of date; run swift run raylib-swift-gen")
    }
}

@Test func intParametersGetIntOverloads() throws {
    let header = try RaylibHeader(parsing: """
    #define RAYLIB_VERSION "9.9"
    RLAPI void InitWindow(int width, int height, const char *title);  // Initialize window
    RLAPI int MeasureText(const char *text, int fontSize);           // Measure string width
    RLAPI int GetScreenWidth(void);                                   // Get current screen width
    RLAPI void TraceLog(int logLevel, const char *text, ...);         // Show trace log messages
    RLAPI void LoadThing(char **names, int count);                    // A type the generator can't spell
    """)
    let functions = header.functions.filter { $0.name != "TraceLog" }
    var output = ""
    for function in functions {
        guard function.parameters.contains(where: { $0.type == "int" }) else { continue }
        if let rendered = try? Output.overload(of: function, typed: [:]) { output += rendered }
    }
    #expect(output.contains("public func InitWindow(_ width: Int, _ height: Int, _ title: UnsafePointer<CChar>) {"))
    #expect(output.contains("CRaylib.InitWindow(Int32(clamping: width), Int32(clamping: height), title)"))
    #expect(output.contains("public func MeasureText(_ text: UnsafePointer<CChar>, _ fontSize: Int) -> Int {"))
    #expect(output.contains("Int(CRaylib.MeasureText(text, Int32(clamping: fontSize)))"))
    #expect(!output.contains("GetScreenWidth"))
    #expect(!output.contains("LoadThing"))
}
