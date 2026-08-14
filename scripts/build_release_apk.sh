#!/usr/bin/env bash
# Build APK release Katian Pro (tests internes / sideload)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Nom de l'APK : ex. katian_pro_app-release.apk (override via APP_SLUG)
APP_SLUG="${APP_SLUG:-katian_pro_app}"
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
RELEASE_APK_NAME="${APP_SLUG}-release.apk"
VERSIONED_APK_NAME="${APP_SLUG}-${VERSION}.apk"

API_BASE_URL="${API_BASE_URL:-https://testapi.katianlogistique.com}"

echo "==> Build APK Katian Pro"
echo "    APP_SLUG=$APP_SLUG"
echo "    APK sortie=$RELEASE_APK_NAME"
echo "    API_BASE_URL=$API_BASE_URL"
echo "    version=$VERSION"

flutter pub get

flutter build apk --release \
  --dart-define=USE_LOCAL_DEV=false \
  "--dart-define=API_BASE_URL=$API_BASE_URL"

FLUTTER_APK_DIR="$ROOT/build/app/outputs/flutter-apk"
# Toujours préférer le vrai artefact Flutter (app-release.apk), puis les noms custom
SRC=""
for candidate in \
  "$FLUTTER_APK_DIR/app-release.apk" \
  "$FLUTTER_APK_DIR/$RELEASE_APK_NAME" \
  "$FLUTTER_APK_DIR/katian_pro_compagnietp_app-release.apk"; do
  if [[ -f "$candidate" ]]; then
    SRC="$candidate"
    break
  fi
done

if [[ -z "$SRC" ]]; then
  echo "ERREUR: APK non trouvé dans $FLUTTER_APK_DIR"
  ls -la "$FLUTTER_APK_DIR" 2>/dev/null || true
  exit 1
fi

mkdir -p "$ROOT/dist"

DEST_NAMED="$FLUTTER_APK_DIR/$RELEASE_APK_NAME"
if [[ "$(realpath -m "$SRC")" != "$(realpath -m "$DEST_NAMED")" ]]; then
  cp -f "$SRC" "$DEST_NAMED"
fi

cp -f "$SRC" "$ROOT/dist/$RELEASE_APK_NAME"
cp -f "$SRC" "$ROOT/dist/$VERSIONED_APK_NAME"

ls -lh "$ROOT/dist/$RELEASE_APK_NAME" "$ROOT/dist/$VERSIONED_APK_NAME"
echo ""
echo "OK — APK Katian Pro prêt :"
echo "  source : $SRC"
echo "  $ROOT/dist/$RELEASE_APK_NAME"
echo "  $ROOT/dist/$VERSIONED_APK_NAME"
