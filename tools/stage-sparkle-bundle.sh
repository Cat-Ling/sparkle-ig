#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DESTINATION="${1:?usage: stage-sparkle-bundle.sh <destination> [--localizations-only|--augment-ffmpeg]}"
MODE="${2:-}"

if [ "$(basename "$DESTINATION")" != "Sparkle.bundle" ]; then
    echo "Refusing to replace a destination not named Sparkle.bundle: $DESTINATION" >&2
    exit 1
fi

normalize_bundle_permissions() {
    # Contributed catalogs can arrive with owner-only permissions. Jailbreak
    # packages install resources as root:wheel, while Instagram reads them as
    # mobile, so every bundled resource must remain world-readable. Preserve
    # executable bits on framework binaries while removing unintended writes.
    find "$DESTINATION" -type d -exec chmod 755 {} +
    find "$DESTINATION" -type f -exec chmod a+r,u+w,go-w {} +
}

case "$MODE" in
    ""|--localizations-only)
        rm -rf "$DESTINATION"
        mkdir -p "$DESTINATION"
        cp "$ROOT_DIR/resources/Sparkle.bundle/Info.plist" "$DESTINATION/Info.plist"
        for localization in "$ROOT_DIR"/resources/Sparkle.bundle/*.lproj; do
            cp -R "$localization" "$DESTINATION/"
        done
        ;;
    --augment-ffmpeg)
        if [ ! -f "$DESTINATION/Info.plist" ]; then
            echo "Sparkle.bundle was not staged before FFmpeg augmentation: $DESTINATION" >&2
            exit 1
        fi
        ;;
    *)
        echo "Unknown mode: $MODE" >&2
        echo "Usage: stage-sparkle-bundle.sh <destination> [--localizations-only|--augment-ffmpeg]" >&2
        exit 1
        ;;
esac

if [ "$MODE" = "--localizations-only" ]; then
    normalize_bundle_permissions
    exit 0
fi

rm -rf "$DESTINATION/FFmpegKit" "$DESTINATION/FFmpegKit.bundle"
find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d \( -name 'ffmpegkit.framework' -o -name 'libav*.framework' -o -name 'libsw*.framework' \) -exec rm -rf {} +

libraries=(libavutil libswresample libswscale libavcodec libavformat libavfilter libavdevice)
for library in "${libraries[@]}" ffmpegkit; do
    source_framework="$ROOT_DIR/modules/ffmpegkit/${library}.framework"
    source_binary="$source_framework/$library"
    if [ ! -f "$source_binary" ]; then
        echo "Missing FFmpeg binary: $source_binary" >&2
        echo "Run ./fetch-ffmpegkit.sh first." >&2
        exit 1
    fi

    destination_framework="$DESTINATION/${library}.framework"
    cp -R "$source_framework" "$destination_framework"
    rm -rf "$destination_framework/Headers" "$destination_framework/Modules"
done

targets=()
for library in "${libraries[@]}" ffmpegkit; do
    binary="$DESTINATION/${library}.framework/$library"
    install_name_tool -id "@loader_path/../${library}.framework/$library" "$binary"
    targets+=("$binary")
done

for binary in "${targets[@]}"; do
    for dependency in "${libraries[@]}"; do
        install_name_tool -change "@rpath/${dependency}.framework/${dependency}" "@loader_path/../${dependency}.framework/${dependency}" "$binary" 2>/dev/null || true
    done
done

# Theos may normalize framework metadata after after-stage, so jailbreak
# packages need code-only signatures which do not seal their Info.plists.
# Standalone IPA staging has no later metadata pass and can seal each complete
# framework; the user's sideload signer will replace those signatures anyway.
if [ "$MODE" = "--augment-ffmpeg" ]; then
    signing_directory="$(mktemp -d "${TMPDIR:-/tmp}/sparkle-ffmpeg-signing.XXXXXX")"
    trap 'rm -rf "$signing_directory"' EXIT
    for binary in "${targets[@]}"; do
        signing_binary="$signing_directory/$(basename "$binary")"
        cp "$binary" "$signing_binary"
        codesign --force --sign - --timestamp=none --identifier "com.sparkle.ffmpeg.$(basename "$binary")" "$signing_binary"
        cp "$signing_binary" "$binary"
        codesign --verify --strict --all-architectures --ignore-resources "$binary"
    done
else
    for binary in "${targets[@]}"; do
        codesign --force --sign - --timestamp=none "$binary"
        codesign --verify --strict --all-architectures "$binary"
    done
fi

framework_count="$(find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d -name '*.framework' | wc -l | tr -d ' ')"
if [ "$framework_count" != 8 ]; then
    echo "Sparkle.bundle must contain exactly eight FFmpeg frameworks; found $framework_count" >&2
    exit 1
fi

normalize_bundle_permissions
