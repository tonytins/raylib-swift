#!/usr/bin/env bash
# Prints the newest raylib release tag published at least N days ago (default 14), so an
# update never vendors a release in its first days, while fixes are still landing.
#
# Usage: scripts/pick-raylib-release.sh [min-age-days]
#
# Set GITHUB_TOKEN to avoid the API's anonymous rate limit.
set -euo pipefail

min_age_days="${1:-14}"
if [[ ! "$min_age_days" =~ ^[0-9]+$ ]]; then
    echo "error: min-age-days must be a whole number, not '$min_age_days'" >&2
    exit 1
fi

auth=()
[[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
curl -fsSL "${auth[@]}" "https://api.github.com/repos/raysan5/raylib/releases?per_page=20" |
    python3 -I -c '
import datetime, json, sys
min_age = datetime.timedelta(days=int(sys.argv[1]))
now = datetime.datetime.now(datetime.timezone.utc)
for release in json.load(sys.stdin):
    if release["draft"] or release["prerelease"]:
        continue
    published = datetime.datetime.fromisoformat(release["published_at"].replace("Z", "+00:00"))
    if now - published >= min_age:
        print(release["tag_name"])
        break
else:
    sys.exit("error: no raylib release is old enough")
' "$min_age_days"
