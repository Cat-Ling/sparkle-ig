#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${1:?usage: stage-sparkle-bundle.sh <destination> [--localizations-only]}"
MODE="${2:-}"

if [ "$(basename "$DESTINATION")" != "Sparkle.bundle" ]; then
    echo "Refusing to replace a destination not named Sparkle.bundle: $DESTINATION" >&2
    exit 1
fi

rm -rf "$DESTINATION"
mkdir -p "$DESTINATION"
cp "$ROOT_DIR/Sparkle.bundle/Info.plist" "$DESTINATION/Info.plist"
for localization in "$ROOT_DIR"/Sparkle.bundle/*.lproj; do
    cp -R "$localization" "$DESTINATION/"
done

if [ "$MODE" = "--localizations-only" ]; then
    exit 0
fi

FFMPEG_DESTINATION="$DESTINATION/FFmpegKit"
mkdir -p "$FFMPEG_DESTINATION"

libraries=(libavutil libswresample libswscale libavcodec libavformat libavfilter libavdevice ffmpegkit)
for library in "${libraries[@]}"; do
    source_binary="$ROOT_DIR/modules/ffmpegkit/${library}.framework/${library}"
    if [ ! -f "$source_binary" ]; then
        echo "Missing FFmpeg binary: $source_binary" >&2
        echo "Run ./fetch-ffmpegkit.sh first." >&2
        exit 1
    fi
    cp "$source_binary" "$FFMPEG_DESTINATION/$library"
done

for library in "${libraries[@]}"; do
    binary="$FFMPEG_DESTINATION/$library"
    install_name_tool -id "@loader_path/$library" "$binary"
    for dependency in "${libraries[@]}"; do
        install_name_tool -change "@rpath/${dependency}.framework/${dependency}" "@loader_path/${dependency}" "$binary" 2>/dev/null || true
        install_name_tool -change "@loader_path/../${dependency}.framework/${dependency}" "@loader_path/${dependency}" "$binary" 2>/dev/null || true
    done
    ldid -S "$binary"
done

if find "$DESTINATION" -type d -name '*.framework' -print -quit | grep -q .; then
    echo "Sparkle.bundle must not contain framework directories" >&2
    exit 1
fi
