/// A reason the generator stopped. Each one means raylib's header changed in a way the
/// generator's tables or parser need updating for.
public enum GeneratorError: Error, Equatable, CustomStringConvertible {
    /// A line had a recognized shape but couldn't be read.
    case malformed(line: Int, String)
    /// A `typedef enum {` block had no closing `} Name;`.
    case unterminatedEnum
    /// The header has no `RAYLIB_VERSION`.
    case missingVersion
    /// Two constants of one enum would get the same Swift name.
    case duplicateName(String, String, String)
    /// A table names an enum that the header doesn't declare.
    case unknownEnum(String)
    /// The typed-overload table names a function or parameter the header doesn't declare.
    case unknownParameter(function: String, parameter: String)
    /// A C type the generator has no Swift spelling for.
    case unsupportedType(function: String, type: String)
    /// A file couldn't be read or written.
    case io(path: String, reason: String)

    public var description: String {
        switch self {
        case .malformed(let line, let text):
            "raylib.h:\(line): couldn't read: \(text)"
        case .unterminatedEnum:
            "raylib.h: a typedef enum block never closes"
        case .missingVersion:
            "raylib.h: no RAYLIB_VERSION define"
        case .duplicateName(let name, let first, let second):
            "\(first) and \(second) would both be named '\(name)'"
        case .unknownEnum(let name):
            "raylib.h no longer declares enum \(name); update the generator's tables"
        case .unknownParameter(let function, let parameter):
            "raylib.h has no parameter '\(parameter)' on \(function); update Overloads.table"
        case .unsupportedType(let function, let type):
            "\(function): no Swift spelling for C type '\(type)'"
        case .io(let path, let reason):
            "\(path): \(reason)"
        }
    }
}
