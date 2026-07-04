# room_reservation_mobile_app

Aplikasi mobile reservasi ruangan berbasis Flutter.

## Konfigurasi Environment

Konfigurasi aplikasi (termasuk endpoint API yang dipakai saat login) dibaca
dari environment lewat `--dart-define` / `--dart-define-from-file`, bukan
di-hardcode. Definisi nilai ada di
[`lib/app/core/config/app_environment.dart`](lib/app/core/config/app_environment.dart).

| Variabel              | Default            | Keterangan                                        |
| --------------------- | ------------------ | ------------------------------------------------- |
| `APP_ENV`             | `development`      | Nama environment (`development`/`production`)     |
| `API_PROTOCOL`        | `http`             | Protokol API (`http`/`https`)                     |
| `API_BASE_URL`        | `192.168.0.34:8000`| Host (dan port) API, tanpa protokol               |
| `API_PREFIX`          | `api`              | Prefix path API                                   |
| `API_VERSION`         | `v1`               | Versi API                                         |
| `API_TIMEOUT_SECONDS` | `30`               | Timeout request API (detik)                       |
| `USE_API`             | `true`             | `true` = login via REST API, `false` = Firestore  |

### Menjalankan aplikasi

```sh
# Development (memakai env/development.json)
flutter run --dart-define-from-file=env/development.json

# Production (salin env/production.example.json ke env/production.json lalu isi)
flutter run --dart-define-from-file=env/production.json

# Atau override satuan
flutter run --dart-define=API_BASE_URL=api.example.com --dart-define=API_PROTOCOL=https
```

File `env/production.json`, `env/staging.json`, dan `env/local.json`
di-gitignore — jangan commit kredensial/endpoint production.

### File Firebase

`lib/firebase_options.dart` dan `android/app/google-services.json` di-gitignore.
Untuk pengembangan lokal, generate lewat `flutterfire configure`.

## Testing

```sh
flutter test --dart-define-from-file=env/development.json
```

## CI/CD

Workflow GitHub Actions ada di
[`.github/workflows/ci.yml`](.github/workflows/ci.yml) dan berjalan pada setiap
push ke `master` serta setiap pull request:

1. **Analyze & Test** — cek format (`dart format`), `flutter analyze`, dan
   `flutter test --coverage` (laporan coverage diunggah sebagai artifact).
2. **Build Android APK** — build APK release setelah test hijau; APK diunggah
   sebagai artifact.

Karena file Firebase di-gitignore, CI memakai stub dari `tool/ci/` agar project
bisa di-compile. Untuk memakai konfigurasi asli, set GitHub Actions secrets
berikut (opsional):

| Secret                 | Isi                                              |
| ---------------------- | ------------------------------------------------ |
| `FIREBASE_OPTIONS_DART`| Isi lengkap file `lib/firebase_options.dart`     |
| `GOOGLE_SERVICES_JSON` | Isi lengkap file `android/app/google-services.json` |
| `ENV_PRODUCTION_JSON`  | Isi environment production (format seperti `env/production.example.json`) |
