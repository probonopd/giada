#!/usr/bin/env bash

set -euo pipefail

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    echo "Usage: make-appimage.sh [release-version] [x86_64|aarch64]"
    exit 1
fi

RELEASE_VERSION="${1//\//-}"
ARCH="$2"
APPDIR="temp/AppDir"
APPIMAGE_TOOL="temp/appimagetool.AppImage"
OUTPUT="dist/giada-${RELEASE_VERSION}-${ARCH}-linux.AppImage"
MIN_SIZE=$((5 * 1024 * 1024))

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
    echo "Unsupported arch: $ARCH"
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

curl -sSL -o "$APPIMAGE_TOOL" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
chmod +x "$APPIMAGE_TOOL"

ARCH="$ARCH" APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGE_TOOL" --no-appstream "$APPDIR" "$OUTPUT"

APPIMAGE_SIZE=$(stat -c%s "$OUTPUT")
if [ "$APPIMAGE_SIZE" -lt "$MIN_SIZE" ]; then
    echo "AppImage too small: ${APPIMAGE_SIZE} bytes (< ${MIN_SIZE})"
    exit 1
fi

echo "Created $OUTPUT (${APPIMAGE_SIZE} bytes)"
