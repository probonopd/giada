#!/usr/bin/env bash

set -euo pipefail

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    echo "Usage: make-appimage.sh [build-id] [x86_64|aarch64]"
    exit 1
fi

BUILD_ID="$1"
ARCH="$2"
APPDIR="temp/AppDir"
APPIMAGE_TOOL="temp/appimagetool.AppImage"
OUTPUT="dist/giada-${BUILD_ID}-${ARCH}-linux.AppImage"
MIN_SIZE=$((5 * 1024 * 1024))

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
    echo "Unsupported arch: $ARCH"
    exit 1
fi

if [[ ! "$BUILD_ID" =~ ^[[:alnum:]._-]+$ ]]; then
    echo "Unsupported build id format: $BUILD_ID"
    exit 1
fi

rm -rf dist temp
mkdir -p dist "$APPDIR"

mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/metainfo"
mkdir -p "$APPDIR/usr/share/icons/hicolor/scalable/apps"

cp build/giada "$APPDIR/usr/bin/giada"
cp extras/com.giadamusic.Giada.desktop "$APPDIR/usr/share/applications/"
cp extras/com.giadamusic.Giada.metainfo.xml "$APPDIR/usr/share/metainfo/"
cp extras/giada-logo.svg "$APPDIR/usr/share/icons/hicolor/scalable/apps/com.giadamusic.Giada.svg"

cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/giada" "$@"
EOF
chmod +x "$APPDIR/AppRun"

cp extras/com.giadamusic.Giada.desktop "$APPDIR/"
cp extras/giada-logo.png "$APPDIR/.DirIcon"

RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/AppImage/appimagetool/releases/tags/continuous)"
EXPECTED_DIGEST="$(python3 -c 'import json,sys
arch=sys.argv[1]
asset_name=f"appimagetool-{arch}.AppImage"
release=json.load(sys.stdin)
for asset in release.get("assets", []):
    if asset.get("name") == asset_name:
        digest = asset.get("digest", "")
        if digest.startswith("sha256:"):
            print(digest.split(":", 1)[1])
            raise SystemExit(0)
print("")
' "$ARCH" <<< "$RELEASE_JSON")"

if [ -z "$EXPECTED_DIGEST" ]; then
    echo "Unable to determine appimagetool digest for $ARCH"
    exit 1
fi

curl -fsSL -o "$APPIMAGE_TOOL" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
DOWNLOADED_DIGEST="$(sha256sum "$APPIMAGE_TOOL" | awk '{print $1}')"
if [ "$DOWNLOADED_DIGEST" != "$EXPECTED_DIGEST" ]; then
    echo "appimagetool digest mismatch for $ARCH"
    echo "expected: $EXPECTED_DIGEST"
    echo "actual:   $DOWNLOADED_DIGEST"
    exit 1
fi

chmod +x "$APPIMAGE_TOOL"

ARCH="$ARCH" APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGE_TOOL" --no-appstream "$APPDIR" "$OUTPUT"

APPIMAGE_SIZE=$(stat -c%s "$OUTPUT")
if [ "$APPIMAGE_SIZE" -lt "$MIN_SIZE" ]; then
    echo "AppImage too small: ${APPIMAGE_SIZE} bytes (< ${MIN_SIZE})"
    exit 1
fi

echo "Created $OUTPUT (${APPIMAGE_SIZE} bytes)"
