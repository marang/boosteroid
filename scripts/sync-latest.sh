#!/bin/sh
set -eu

MANIFEST="io.github.marang.boosteroid.yml"
BUILD_DIR="build-dir"
APP_ID="io.github.marang.boosteroid"
URL="https://boosteroid.com/linux/installer/boosteroid-install-x64.deb"
UA="Mozilla/5.0"
SKIP_REINSTALL=0
CHECK_ONLY=0
MANIFEST_SET=""
BUILD_DIR_SET=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --manifest)
      [ "$#" -ge 2 ] || { echo "Missing value for --manifest" >&2; exit 1; }
      MANIFEST="$2"
      shift 2
      ;;
    --build-dir)
      [ "$#" -ge 2 ] || { echo "Missing value for --build-dir" >&2; exit 1; }
      BUILD_DIR="$2"
      shift 2
      ;;
    --skip-reinstall|--no-reinstall)
      SKIP_REINSTALL=1
      shift
      ;;
    --check)
      CHECK_ONLY=1
      shift
      ;;
    -h|--help)
      cat <<EOF
Usage: sync-latest.sh [options]

Options:
  --manifest FILE      Manifest to update (default: io.github.marang.boosteroid.yml)
  --build-dir PATH     flatpak-builder build dir (default: build-dir)
  --skip-reinstall     Update manifest only, do not reinstall/rebuild locally
  --check              Check upstream Deb and update manifest if needed
  --help               Show this help
EOF
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [ -z "$MANIFEST_SET" ]; then
        MANIFEST="$1"
        MANIFEST_SET=1
      elif [ -z "$BUILD_DIR_SET" ]; then
        BUILD_DIR="$1"
        BUILD_DIR_SET=1
      else
        echo "Too many positional arguments: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

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

CHANGED=0
if [ "${OLD_SIZE:-}" != "$NEW_SIZE" ] || [ "${OLD_SHA256:-}" != "$NEW_SHA256" ]; then
  CHANGED=1
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

if [ "$CHECK_ONLY" -eq 1 ] && [ "$CHANGED" -eq 0 ]; then
  exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ] || [ "$SKIP_REINSTALL" -eq 1 ]; then
  exit 0
fi

if [ "$CHANGED" -eq 0 ]; then
  exit 0
fi

echo "Uninstalling existing user installation (if present): $APP_ID"
flatpak uninstall --user -y "$APP_ID" || true

echo "Reinstalling with a clean build dir."
flatpak-builder --user --install --force-clean "$BUILD_DIR" "$MANIFEST"
