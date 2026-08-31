#!/usr/bin/env bash
# Bundles every community catalog into per-language packs plus one combined
# archive, for attaching to a GitHub release. Each pack is what Sparkle's
# Import Language Pack accepts.

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

(cd "$ROOT_DIR" && zip -q -r -X "$OUTPUT_DIR/Sparkle-translations.zip" translations -x '*/.*')
echo "Wrote $(ls -1 "$OUTPUT_DIR" | wc -l | tr -d ' ') archives to $OUTPUT_DIR"
