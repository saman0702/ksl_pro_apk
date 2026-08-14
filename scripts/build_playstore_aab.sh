#!/usr/bin/env bash
# Build Android App Bundle (.aab) pour Google Play Store — Katian Pro
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

API_BASE_URL="${API_BASE_URL:-https://testapi.katianlogistique.com}"

KEY_PROPS="$ROOT/android/key.properties"
if [[ ! -f "$KEY_PROPS" ]]; then
  echo "ERREUR: android/key.properties manquant."
  echo "Lancez : ./scripts/setup_release_keystore.sh"
  exit 1
fi

if [[ ! -f "$ROOT/android/app/google-services.json" ]]; then
  echo "AVERTISSEMENT: android/app/google-services.json absent (FCM push)."
  echo "Créez un projet Firebase DÉDIÉ Katian Pro (pas feli-260a9)"
  echo "→ app com.katian.katian_pro_compagnietp_app"
fi

echo "==> Build AAB Katian Pro"
echo "    API_BASE_URL=$API_BASE_URL"
echo "    version=$(grep '^version:' pubspec.yaml | awk '{print $2}')"

flutter clean
flutter pub get

flutter build appbundle --release \
  --dart-define=USE_LOCAL_DEV=false \
  --dart-define=API_BASE_URL="$API_BASE_URL"

OUT="$ROOT/build/app/outputs/bundle/release/app-release.aab"
if [[ -f "$OUT" ]]; then
  mkdir -p "$ROOT/dist"
  cp "$OUT" "$ROOT/dist/katian-pro-playstore-$(grep '^version:' pubspec.yaml | awk '{print $2}').aab"
  ls -lh "$ROOT/dist/"*.aab 2>/dev/null || ls -lh "$OUT"
  echo ""
  echo "OK — Uploadez le .aab dans Google Play Console."
else
  echo "ERREUR: AAB non généré."
  exit 1
fi
