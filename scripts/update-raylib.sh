#!/usr/bin/env bash
# Vendors a raylib release into Sources/CRaylib/raylib and regenerates the Swift layer.
#
# Usage: scripts/update-raylib.sh [tag]
#
# With no tag, uses the latest GitHub release of raysan5/raylib. Set GITHUB_TOKEN to
# avoid the API's anonymous rate limit. Prints the vendored version on success.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
vendor="$root/Sources/CRaylib/raylib"

tag="${1:-}"
if [[ -z "$tag" ]]; then
    auth=()
    [[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
    tag="$(curl -fsSL "${auth[@]}" https://api.github.com/repos/raysan5/raylib/releases/latest |
        python3 -I -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])')"
fi
if [[ ! "$tag" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    echo "error: unexpected raylib tag '$tag'" >&2
    exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -fsSL "https://github.com/raysan5/raylib/archive/refs/tags/$tag.tar.gz" -o "$work/raylib.tar.gz"
mkdir "$work/x"
tar -xzf "$work/raylib.tar.gz" -C "$work/x"
src="$work/x/raylib-$tag/src"
if [[ ! -f "$src/raylib.h" || ! -f "$src/rglfw.c" ]]; then
    echo "error: raylib $tag has no src/raylib.h or src/rglfw.c; the layout changed" >&2
    exit 1
fi

# Keep only what a desktop build compiles or includes: the module sources and headers,
# external/ (GLFW, miniaudio, stb, ...), and platforms/ (rcore.c includes the backend).
staged="$work/staged"
mkdir "$staged"
cp "$src"/*.c "$src"/*.h "$staged/"
cp -R "$src/external" "$src/platforms" "$staged/"
cp "$work/x/raylib-$tag/LICENSE" "$staged/LICENSE"

# Swap in the new copy only once it is complete.
rm -rf "$vendor"
mv "$staged" "$vendor"
printf '%s\n' "$tag" > "$root/RAYLIB_VERSION"

swift run --package-path "$root" raylib-swift-gen "$root"
echo "$tag"
