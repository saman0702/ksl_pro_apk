#!/usr/bin/env bash
# Crée la keystore Play Store + android/key.properties (interaction requise).
set -euo pipefail

ANDROID_DIR="$(cd "$(dirname "$0")/../android" && pwd)"
KEYSTORE="$ANDROID_DIR/upload-keystore.jks"
KEY_PROPS="$ANDROID_DIR/key.properties"
ALIAS="upload"

echo "=== Katian Pro — configuration keystore Play Store ==="
echo "Dossier : $ANDROID_DIR"
echo ""

if [[ -f "$KEYSTORE" ]]; then
  echo "La keystore existe déjà : $KEYSTORE"
else
  echo "Création de la keystore (questions interactives)…"
  cd "$ANDROID_DIR"
  keytool -genkey -v \
    -keystore upload-keystore.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$ALIAS"
  echo "OK — Keystore : $KEYSTORE"
fi

if [[ ! -f "$KEY_PROPS" ]]; then
  read -rsp "Mot de passe keystore (storePassword) : " STORE_PW
  echo ""
  read -rsp "Mot de passe clé (keyPassword) : " KEY_PW
  echo ""
  cat > "$KEY_PROPS" <<EOF
storePassword=$STORE_PW
keyPassword=$KEY_PW
keyAlias=$ALIAS
storeFile=upload-keystore.jks
EOF
  chmod 600 "$KEY_PROPS"
  echo "OK — $KEY_PROPS créé."
fi

echo ""
echo "=== Empreintes SHA (Firebase + Play Console) ==="
keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" 2>/dev/null | grep -E 'SHA1:|SHA256:' || true
echo ""
echo "Firebase → créer un projet DÉDIÉ Katian Pro (ex. katian-pro-expedition)"
echo "→ app Android com.katian.katian_pro_compagnietp_app (ne pas utiliser feli-260a9)"
echo "Puis : ./scripts/build_playstore_aab.sh"
