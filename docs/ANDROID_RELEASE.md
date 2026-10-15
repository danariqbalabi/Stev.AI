# Android release

Stev.AI tidak memakai debug key untuk build release. Tanpa
`android/key.properties`, Gradle hanya menghasilkan artifact release unsigned;
ini cukup untuk verifikasi build, tetapi tidak dapat didistribusikan sebagai
release resmi.

## Verifikasi sebelum demo

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config/env.local.json
flutter build apk --debug --dart-define-from-file=config/env.local.json
```

Uji APK pada perangkat fisik, khususnya kamera, pemilih gambar, notifikasi tujuh
hari, share sheet, widget home screen, dan pembukaan Scan dari widget/notifikasi.
Flutter Web tidak menyediakan home-screen widget Android.

## Membuat upload key

Jalankan sekali dan simpan keystore serta password di password manager tim:

```powershell
keytool -genkeypair -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android/key.properties.example android/key.properties
```

Isi password pada `android/key.properties`. Kedua file tersebut diabaikan Git.
Jangan mengunggahnya ke repository, chat, atau artifact CI. Kehilangan upload key
dapat menghambat pembaruan aplikasi.

## Build release bertanda tangan

```powershell
flutter build apk --release --dart-define-from-file=config/env.local.json
flutter build appbundle --release --dart-define-from-file=config/env.local.json
```

Output APK berada di `build/app/outputs/flutter-apk/`; AAB berada di
`build/app/outputs/bundle/release/`. Sebelum membagikan build, pastikan
`config/env.local.json` hanya berisi Supabase publishable key. Secret Gemini dan
Supabase service-role key harus tetap berada di backend.

## Checklist kandidat release

- Naikkan `version` dan build number pada `pubspec.yaml` untuk setiap kandidat.
- Terapkan seluruh migration Supabase sesuai urutan nama file.
- Deploy ulang Edge Function dan jalankan evaluation recognition.
- Pastikan data gula yang ditampilkan publik sudah memiliki status validasi dan
  sumber yang benar; data demo harus tetap diberi label demo.
- Jalankan smoke test pada Android 13+ untuk permission notifikasi.
- Simpan report recognition dan catat commit Git yang dipakai membangun APK.
