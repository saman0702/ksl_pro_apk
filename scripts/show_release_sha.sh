#!/usr/bin/env bash
# Affiche SHA-1 / SHA-256 de la keystore release (Firebase, Play Console)
set -euo pipefail

ANDROID_DIR="$(cd "$(dirname "$0")/../android" && pwd)"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
ALIAS="upload"

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Keystore absente. Lancez ./scripts/setup_release_keystore.sh"
  exit 1
fi

echo "=== Empreintes release — $KEYSTORE ==="
keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS"

echo ""
echo "Debug keystore (dev local) :"
keytool -list -v -keystore "$HOME/.android/debug.keystore" -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep -E 'SHA1:|SHA256:' || echo "(debug keystore introuvable)"
