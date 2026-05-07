#!/usr/bin/env bash

set -euo pipefail

if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
    echo "Usage: make-appimage.sh [build-id] [x86_64|aarch64]"
    exit 1
fi

BUILD_ID="$1"
ARCH="$2"
APPDIR="temp/AppDir"
LINUXDEPLOY_TOOL="temp/linuxdeploy.AppImage"
OUTPUT="dist/giada-${BUILD_ID}-${ARCH}-linux.AppImage"
MIN_SIZE=$((5 * 1024 * 1024))
GITHUB_API_URL="https://api.github.com/repos/linuxdeploy/linuxdeploy/releases/tags/continuous"

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

AUTH_HEADER=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

RELEASE_JSON="$(curl -fSL "${AUTH_HEADER[@]}" "$GITHUB_API_URL")" || {
    echo "Failed to fetch linuxdeploy release metadata"
    exit 1
}
EXPECTED_DIGEST="$(python3 -c 'import json,sys
arch=sys.argv[1]
asset_name=f"linuxdeploy-{arch}.AppImage"
release=json.load(sys.stdin)
for asset in release.get("assets", []):
    if asset.get("name") == asset_name:
        digest = asset.get("digest", "")
        if digest.startswith("sha256:"):
            print(digest.split(":", 1)[1])
            raise SystemExit(0)
        print(f"Malformed digest for {asset_name}: {digest!r}", file=sys.stderr)
        raise SystemExit(1)
print(f"Asset not found: {asset_name}", file=sys.stderr)
raise SystemExit(1)
' "$ARCH" <<< "$RELEASE_JSON")" || {
    echo "Unable to determine linuxdeploy digest for $ARCH"
    exit 1
}

curl -fSL -o "$LINUXDEPLOY_TOOL" "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage" || {
    echo "Failed to download linuxdeploy for $ARCH"
    exit 1
}
DOWNLOADED_DIGEST="$(sha256sum "$LINUXDEPLOY_TOOL" | awk '{print $1}')" || {
    echo "Failed to calculate digest for downloaded linuxdeploy"
    exit 1
}
if [ "$DOWNLOADED_DIGEST" != "$EXPECTED_DIGEST" ]; then
    echo "linuxdeploy digest mismatch for $ARCH"
    echo "expected: $EXPECTED_DIGEST"
    echo "actual:   $DOWNLOADED_DIGEST"
    exit 1
fi

chmod +x "$LINUXDEPLOY_TOOL"

ARCH="$ARCH" APPIMAGE_EXTRACT_AND_RUN=1 "$LINUXDEPLOY_TOOL" \
    --appdir "$APPDIR" \
    --desktop-file extras/com.giadamusic.Giada.desktop \
    --icon-file extras/giada-logo.svg \
    --executable "$APPDIR/usr/bin/giada" \
    --output appimage

GENERATED_APPIMAGE="$(find . -maxdepth 1 -type f -name '*.AppImage' | head -n 1)"
if [ -z "$GENERATED_APPIMAGE" ]; then
    echo "linuxdeploy did not produce an AppImage"
    exit 1
fi

mv "$GENERATED_APPIMAGE" "$OUTPUT"

APPIMAGE_SIZE=$(stat -c%s "$OUTPUT") || {
    echo "Failed to read AppImage size: $OUTPUT"
    exit 1
}
if [ "$APPIMAGE_SIZE" -lt "$MIN_SIZE" ]; then
    echo "AppImage too small: ${APPIMAGE_SIZE} bytes (< ${MIN_SIZE})"
    exit 1
fi

echo "Created $OUTPUT (${APPIMAGE_SIZE} bytes)"
