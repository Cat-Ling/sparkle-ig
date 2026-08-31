#!/usr/bin/env bash
# Bundles every community catalog into one pack per language, for attaching to a
# GitHub release. Each pack holds a single <code>.lproj, which is what Sparkle's
# Import Language Pack accepts.
#
# There is deliberately no combined archive: the importer installs the first
# .lproj it finds, so an archive holding every catalog would silently install
# one language.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT_DIR/packages/translations}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for catalog in "$ROOT_DIR"/translations/*.lproj; do
    [ -d "$catalog" ] || continue
    code="$(basename "$catalog" .lproj)"
    staging="$(mktemp -d "${TMPDIR:-/tmp}/sparkle-lang.XXXXXX")"
    cp -R "$catalog" "$staging/"
    (cd "$staging" && zip -q -r -X "$OUTPUT_DIR/Sparkle-$code.zip" "$code.lproj")
    rm -rf "$staging"
    echo "Packaged $code"
done

echo "Wrote $(ls -1 "$OUTPUT_DIR" | wc -l | tr -d ' ') language packs to $OUTPUT_DIR"
