#!/usr/bin/env bash

# Set these environment variables to match your device and bundle IDs
# export PYMOBILEDEVICE3_UDID=00000000-0000000000000000
# export LIVECONTAINER_APPID=com.kdt.livecontainer.randomizedaltstoreid
# export DEVLAUNCHER_APPID=com.socuul.scinsta-devlauncher[.randomizedaltstoreid]

set -e

echo 'Note: This script is meant to be used while developing the tweak.'
echo '      LiveContainer / base IPAs: ./build.sh ipa --ffmpeg  (optional: --flex, --patch)'
echo '      Build libFLEX only: ./build.sh ipa --buildonly --flex'
echo

if [ "$1" == "true" ];
then
    ./build.sh ipa --dev --release

else
    # Built tweak and deploy to live container
    make clean
    make DEV=1 SIDELOAD=1

    # Change framework locations to @rpath
    install_name_tool -change "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" \
                              "@rpath/CydiaSubstrate.framework/CydiaSubstrate" \
                              ".theos/obj/debug/Sparkle.dylib" 2>/dev/null || true

    # Kill running process
    pymobiledevice3 developer dvt pkill "LiveContainer" --tunnel $PYMOBILEDEVICE3_UDID

    # Copy the tweak and a lightweight sibling resource bundle. The base IPA may
    # keep the full FFmpeg bundle; translation edits only push the small catalogs.
    pymobiledevice3 apps push $LIVECONTAINER_APPID .theos/obj/debug/Sparkle.dylib Documents/Tweaks/Sparkle
    DEV_RESOURCE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sparkle-dev-resources.XXXXXX")"
    ./tools/stage-sparkle-bundle.sh "$DEV_RESOURCE_DIR/Sparkle.bundle" --localizations-only
    pymobiledevice3 apps push $LIVECONTAINER_APPID "$DEV_RESOURCE_DIR/Sparkle.bundle" Documents/Tweaks/Sparkle
    rm -rf "$DEV_RESOURCE_DIR"

    # Launch Sparkle on iPhone
    sleep 1
    pymobiledevice3 developer dvt launch --kill-existing --tunnel $PYMOBILEDEVICE3_UDID $DEVLAUNCHER_APPID
fi
