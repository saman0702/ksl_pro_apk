# Déploiement Play Store — Katian Pro (compagnie TP)

API de production/test : **https://testapi.katianlogistique.com/**

## 1. Firebase — projet **séparé** de Feli

Katian Pro et Feli utilisent **deux projets Firebase distincts**. Ne mélangez pas les fichiers ni les comptes de service.

| | Feli | Katian Pro |
|---|------|------------|
| Package Android | `com.katian.feli_app` | `com.katian.katian_pro_compagnietp_app` |
| Projet Firebase | `feli-260a9` | **À créer** (ex. `katian-pro-expedition`) |
| JSON Admin SDK serveur | `FCM_SERVICE_ACCOUNT_PATH` | `FCM_KATIAN_PRO_SERVICE_ACCOUNT_PATH` |
| Canal push Android | `feli_notifications` | `katian_pro_notifications` |

### Créer le projet Katian Pro

1. [Firebase Console](https://console.firebase.google.com/) → **Créer un projet** (ex. `katian-pro-expedition`)
2. Ajouter une app **Android** :
   - Package : `com.katian.katian_pro_compagnietp_app`
3. Télécharger **`google-services.json`** → `android/app/google-services.json`
4. **Paramètres → Comptes de service** → Générer une clé privée JSON
   - Stocker sur le serveur (ex. `secrets/katian-pro-firebase-adminsdk.json`)
   - **Ne pas** réutiliser le JSON du projet Feli
5. Empreintes SHA-1 / SHA-256 :
   ```bash
   ./scripts/show_release_sha.sh
   ```
6. Configurer Flutter :
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=katian-pro-expedition
   ```
   Ou mettre à jour manuellement `lib/firebase_options.dart`.

## 2. Backend

Endpoints Katian Pro (`/api/katian-pro/v1/`) :

- `GET /notifications/`
- `GET /notifications/unread-count/`
- `POST /notifications/{id}/read/`
- `POST /notifications/read-all/`
- `POST /notifications/register-device/`
- `POST /notifications/unregister-device/`

Migration (tokens séparés par `app_source`) :

```bash
python manage.py migrate mobileAPI
```

Variables serveur **distinctes** :

```env
# Feli uniquement
FCM_SERVICE_ACCOUNT_PATH=/chemin/vers/feli-firebase-adminsdk.json

# Katian Pro uniquement
FCM_KATIAN_PRO_SERVICE_ACCOUNT_PATH=/chemin/vers/katian-pro-firebase-adminsdk.json
```

Les tokens FCM sont stockés avec `app_source=feli` ou `app_source=katian_pro` — jamais mélangés.

## 3. Signature release (keystore)

Keystore **dédiée** Katian Pro (ne pas réutiliser celle de Feli) :

```bash
chmod +x scripts/*.sh
./scripts/setup_release_keystore.sh
./scripts/show_release_sha.sh
```

Fichiers générés (non versionnés) :

- `android/upload-keystore.jks`
- `android/key.properties`

## 4. Build APK (tests)

```bash
./scripts/build_release_apk.sh
# Sortie : dist/katian-pro-1.0.0+1.apk
```

## 5. Build AAB (Play Store)

```bash
./scripts/build_playstore_aab.sh
# Sortie : dist/katian-pro-playstore-1.0.0+1.aab
```

## 6. Google Play Console

1. Créer l’application **Katian Expédition Transporteur** (listing séparé de Feli)
2. Package : `com.katian.katian_pro_compagnietp_app`
3. Uploader le `.aab` en test interne

## 7. Notifications

- Cloche avec badge (non lues)
- Bottom sheet in-app
- Push FCM via le **projet Firebase Katian Pro** uniquement

## 8. Développement local

```bash
flutter run --dart-define=USE_LOCAL_DEV=true --dart-define=API_BASE_URL=http://192.168.x.x:3002
```

Par défaut : **testapi.katianlogistique.com**.
