#!/bin/sh
set -eu

MANIFEST="${1:-org.boosteroid.Boosteroid.yml}"
BUILD_DIR="${2:-build-dir}"
APP_ID="io.github.unofficial.boosteroid"
URL="https://boosteroid.com/linux/installer/boosteroid-install-x64.deb"
UA="Mozilla/5.0"

if [ ! -f "$MANIFEST" ]; then
  echo "Manifest not found: $MANIFEST" >&2
  exit 1
fi

TMP_DEB=$(mktemp /tmp/boosteroid-extra-data.XXXXXX.deb)
TMP_YML=$(mktemp /tmp/boosteroid-manifest.XXXXXX.yml)
trap 'rm -f "$TMP_DEB" "$TMP_YML"' EXIT INT TERM HUP

echo "Downloading: $URL"
curl -fL -A "$UA" -o "$TMP_DEB" "$URL"

NEW_SIZE=$(stat -c '%s' "$TMP_DEB")
NEW_SHA256=$(sha256sum "$TMP_DEB" | awk '{print $1}')

OLD_SIZE=$(awk '/filename: boosteroid-install-x64\.deb/{f=1} f && /size:/{print $2; exit}' "$MANIFEST")
OLD_SHA256=$(awk '/filename: boosteroid-install-x64\.deb/{f=1} f && /sha256:/{print $2; exit}' "$MANIFEST")

echo "Current size:   ${OLD_SIZE:-unknown}"
echo "Current sha256: ${OLD_SHA256:-unknown}"
echo "Latest size:    $NEW_SIZE"
echo "Latest sha256:  $NEW_SHA256"

if [ "${OLD_SIZE:-}" != "$NEW_SIZE" ] || [ "${OLD_SHA256:-}" != "$NEW_SHA256" ]; then
  awk -v new_size="$NEW_SIZE" -v new_sha="$NEW_SHA256" '
    {
      if ($0 ~ /filename: boosteroid-install-x64\.deb/) {
        in_block=1
        print
        next
      }
      if (in_block && $0 ~ /^[[:space:]]*size:/) {
        sub(/[0-9]+$/, new_size)
        print
        next
      }
      if (in_block && $0 ~ /^[[:space:]]*sha256:/) {
        sub(/[0-9a-f]+$/, new_sha)
        print
        in_block=0
        next
      }
      print
    }
  ' "$MANIFEST" > "$TMP_YML"
  mv "$TMP_YML" "$MANIFEST"
  echo "Manifest updated."
else
  echo "Manifest already up to date."
fi

echo "Uninstalling existing user installation (if present): $APP_ID"
flatpak uninstall --user -y "$APP_ID" || true

echo "Reinstalling with a clean build dir."
flatpak-builder --user --install --force-clean "$BUILD_DIR" "$MANIFEST"
