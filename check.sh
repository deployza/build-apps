#!/bin/bash
# The repo's own check, run as dz-project.yaml's commands.build: offline, and it writes
# nothing. build-maven.sh parses, and so does maven-settings.xml.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

failed=0
fail() { echo "check: $*" >&2; failed=1; }
# Tracked files and new ones not yet added, but not what .gitignore keeps out.
files() { git ls-files --cached --others --exclude-standard; }

# Every shell script parses: *.sh, and anything with a bash or sh shebang (an installed
# command has no .sh, so a glob alone would miss it).
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in
    *.sh) ;;
    *) head -n1 "$f" | grep -qE '^#!.*[/ ](ba)?sh\b' || continue ;;
  esac
  bash -n "$f" || fail "bash -n failed: $f"
done < <(files)

# A Python that runs: python3, else python (on Windows, python3 may be a store stub).
PY=""
for p in python3 python; do
  if command -v "$p" >/dev/null && "$p" -c 1 2>/dev/null; then PY="$p"; break; fi
done
[ -n "$PY" ] || { echo "check: no Python found" >&2; exit 1; }

# Every XML file parses (no entity or DTD is fetched).
files | grep -E '\.xml$' | "$PY" -I -c '
import sys
import xml.etree.ElementTree as ET
bad = 0
for name in sys.stdin.read().split("\n"):
    if not name:
        continue
    try:
        ET.parse(name)
    except (OSError, ET.ParseError) as e:
        print(f"check: {name}: {e}", file=sys.stderr)
        bad = 1
sys.exit(bad)
' || failed=1

exit "$failed"
