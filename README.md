# Stev.AI

Stev.AI adalah aplikasi mobile-first yang membantu pengguna mengetahui kandungan gula minuman sebelum membelinya, memahami dampaknya terhadap batas konsumsi harian, dan menemukan alternatif yang lebih rendah gula.

Project ini dikembangkan sebagai prototype kategori **Healthcare** untuk Hackathon JOINTS UGM 2026. Aplikasi dibangun dengan Flutter dan ditargetkan untuk Android serta web agar dapat didemokan melalui APK maupun tautan browser.

## Latar belakang

Minuman manis seperti es teh, kopi susu, boba, dan minuman kemasan telah menjadi bagian dari konsumsi sehari-hari anak muda. Masalahnya, kandungan gula di dalam minuman sering kali tidak terlihat atau sulit diperkirakan, terutama pada minuman non-kemasan.

Berdasarkan brainstorming dan riset awal tim:

- 47,5% penduduk Indonesia mengonsumsi minuman manis lebih dari sekali sehari.
- Satu minuman kemasan dapat mengandung sekitar 20-35 gram gula.
- Referensi konsumsi gula yang digunakan dalam konsep awal adalah 50 gram per hari.
- Gen Z mulai peduli pada kesehatan, tetapi membutuhkan informasi praktis tepat sebelum mengambil keputusan membeli.

Referensi awal tim:

- [Data SKI 2023 - MetroTV](https://www.metrotvnews.com/read/kM6C4rRo-menkes-ingatkan-pola-makan-buruk-tingkatkan-risiko-stroke-hingga-jantung)
- [Peringatan konsumsi minuman manis - DetikHealth](https://health.detik.com/berita-detikhealth/d-8323427/menkes-wanti-wanti-jenis-minuman-yang-picu-kerusakan-ginjal)
- Permenkes No. 30 Tahun 2013 sebagai salah satu rujukan batas konsumsi gula dalam konsep produk.

> Angka kesehatan, estimasi kandungan gula, dan sumber data masih harus divalidasi sebelum aplikasi digunakan di luar kebutuhan prototype. Stev.AI bukan alat diagnosis atau pengganti saran tenaga kesehatan.

## Pertanyaan produk

> Bagaimana Gen Z bisa tetap menikmati minuman favorit dalam kehidupan sehari-hari tanpa diam-diam mengonsumsi gula secara berlebihan?

## Solusi

Stev.AI memungkinkan pengguna memotret minuman atau menu, memilih hasil identifikasi yang paling sesuai, lalu melihat:

- Estimasi kandungan gula dalam gram.
- Visualisasi gula dalam bentuk sendok teh.
- Sisa referensi konsumsi gula hari itu.
- Alternatif minuman, ukuran, atau level gula yang lebih rendah melalui fitur **Swap Drink**.
- Riwayat minuman yang dipilih pada hari tersebut.

Untuk minuman kemasan, angka gula direncanakan berasal dari informasi label atau database produk. Untuk minuman non-kemasan, hasil harus selalu diberi label **estimasi**.

## Alur demo utama

1. Pengguna membuka Dashboard dan menekan **Scan minuman**.
2. Kamera dibuka untuk mengambil foto minuman atau menu.
3. Aplikasi memberikan tiga kandidat minuman.
4. Pengguna memilih kandidat dan level gula jika minuman tidak memiliki label kemasan.
5. Aplikasi menampilkan estimasi gula, visual sendok, dan sisa referensi harian.
6. Pengguna dapat membuka **Swap Drink** untuk melihat alternatif yang lebih rendah gula.
7. Pilihan pengguna dicatat dan Dashboard diperbarui.

## Status implementasi

Saat ini repository berisi alur MVP awal yang dapat diklik:

- Design system Stev.AI dengan token terpusat, font Onest, dan aset SVG.
- Komponen dasar reusable: logo, maskot, icon, button, glass card, aura, spoon meter, dan level gula.
- Onboarding first-launch, profil singkat, dan penyimpanan preferensi lokal.
- Dashboard final dengan week strip, meter sendok gula, riwayat minuman, dan tab bar.
- Katalog terpusat berisi 10 minuman dari design handoff beserta foto, kategori, jenis, dan kandungan gulanya.
- State log minuman harian yang menghitung total secara dinamis dan mengganti entri produk yang sama.
- Aturan Swap terpusat untuk level gula minuman non-kemasan dan alternatif produk kemasan yang tersedia.
- Kamera Android/Web dengan preview hasil foto.
- Fallback pemilihan gambar dari galeri/file.
- State izin ditolak, kamera tidak tersedia, dan coba lagi.
- Konfirmasi minuman sesuai design handoff dengan foto hasil scan, tiga kandidat katalog, dan penanda kandidat paling cocok.
- Hasil kandungan gula sesuai design handoff dengan level picker, visual sendok, status batas harian, dan pencatatan ke Dashboard.
- Reward overlay Swap dengan odometer gram, penghematan, confetti kontekstual, dan pencatatan hasil pilihan.
- Pencarian manual dengan filter kategori dan katalog 10 minuman yang terhubung ke Result.
- Dashboard mingguan dari log lokal dengan ringkasan penghematan Swap, grafik konsumsi tujuh hari, dan penanda batas 50 gram.
- Form minuman custom dengan input sendok gula, pump sirup, preview estimasi, dan pencatatan ke Dashboard.
- Persistensi log minuman lokal per tanggal, termasuk level gula, minuman custom, dan penghematan Swap.
- Home-screen widget Android yang menampilkan sisa gula hari ini dan membuka Scan dalam satu tap.
- Alur pengenalan foto dengan state loading, error/retry, tiga kandidat dinamis, dan fallback pencarian manual.
- Client recognition API yang dapat dikonfigurasi saat build, lengkap dengan timeout, validasi response, deduplikasi kandidat, dan fallback otomatis ke adapter demo lokal.
- Confidence hasil recognition diteruskan ke UI; kandidat di bawah 55% ditolak dan pengguna diarahkan untuk memotret ulang atau mencari manual.
- Fondasi Supabase untuk katalog remote, schema/RLS, seed 10 minuman, gambar remote, dan fallback offline ke katalog lokal.
- Personalisasi Dashboard dari nama dan waktu beli minuman yang disimpan saat onboarding.
- Skrining risiko diabetes untuk diri sendiri atau orang tua: delapan pertanyaan, kategori risiko, faktor utama, estimasi minimal untuk jawaban yang tidak diketahui, dan arahan pemeriksaan. Jawaban hanya diproses di memori perangkat dan tidak disimpan.
- Ajak & Rujukan dengan pesan yang dapat diedit, share sheet sistem, informasi Cek Kesehatan Gratis, dan tanpa memasukkan skor atau jawaban kesehatan ke pesan.
- Navigasi Android dan web.

Edge Function recognition dan katalog cloud sudah tersedia di source code, tetapi function harus di-deploy dan diberi API key AI sebelum recognition nyata aktif. Tanpa konfigurasi endpoint, hasil recognition tetap memakai adapter demo lokal. Aturan Swap saat ini masih merupakan data demo lokal dari design handoff.

## Design system

Implementasi UI baru harus mengambil warna, tipografi, spacing, radius, shadow, ukuran, motion, dan aturan gula dari `lib/core/theme/stev_tokens.dart`. Theme aplikasi berada di `lib/core/theme/stev_theme.dart`, sedangkan komponen bersama dapat diimpor dari `lib/shared/widgets/stev_design_system.dart`.

Dokumen handoff dari desain tersedia di `docs/design/`:

- `PRODUCT_DECISIONS.md`: keputusan produk terbaru yang menggantikan pertanyaan terbuka pada handoff lama.
- `DESIGN.md`: spesifikasi visual dan komponen.
- `MOTION.md`: timing, curve, dan perilaku reduced motion.
- `SCREENS.md`: anatomi setiap screen.
- `DATA.md`: data demo dan aturan produk.

Alur validasi sumber gula tersedia di `docs/data/DRINK_VERIFICATION.md`. Cara
mengukur akurasi dan latency recognition tersedia di
`docs/data/RECOGNITION_EVALUATION.md`.

Font Onest disimpan lokal agar konsisten pada Android dan web. Lisensi SIL Open Font License tersedia di `assets/fonts/OFL.txt`.

## Ruang lingkup MVP

### Must have

- Dashboard dan meter referensi konsumsi gula.
- Kamera atau pemilih gambar.
- Tiga kandidat hasil identifikasi minuman.
- Konfirmasi jenis minuman dan level gula.
- Hasil kandungan gula dengan status estimasi atau sesuai label.
- Swap ke alternatif yang lebih rendah gula.
- Pencatatan pilihan dan pembaruan Dashboard.
- Android APK dan versi web untuk demo.

### Roadmap

- Penyesuaian alur Cek Risiko untuk diri sendiri dan orang tua.
- Kalkulator BMI lokal dari tinggi dan berat badan.
- Notifikasi lokal pengingat pemeriksaan tujuh hari setelah skrining.
- Tab Keluarga lokal untuk melacak progres pendampingan tanpa menyimpan data kesehatan.
- Dataset recognition, evaluasi akurasi, dan rate limiting production.
- Animasi penghematan gula dan confetti kontekstual.
- Dukungan kategori makanan.

## Teknologi

- Flutter dan Dart.
- Material 3.
- Design tokens terpusat, font Onest, dan `flutter_svg` untuk aset vektor.
- `go_router` untuk navigasi.
- `camera` untuk viewfinder dan pengambilan foto di Android/Web.
- `image_picker` sebagai fallback galeri/file.
- `shared_preferences` untuk status onboarding, profil, dan log minuman harian lokal.
- Android dan Flutter Web dari satu codebase.
- Supabase/PostgreSQL untuk katalog remote, dengan Row Level Security dan fallback data lokal.
- Backend/Edge Function untuk menjaga API key layanan AI agar tidak tersimpan di client.
- Git dan GitHub dengan branch per fitur.

## Struktur project

```text
lib/
├── app/                 # Root aplikasi dan router
├── core/                # Theme dan konfigurasi lintas fitur
├── features/            # Kode yang dikelompokkan per fitur
│   ├── dashboard/
│   ├── scan/
│   ├── confirmation/
│   ├── result/
│   └── swap/
├── shared/              # Widget/model yang digunakan bersama
└── main.dart
```

## Menjalankan project

Pastikan Flutter telah terpasang dan `flutter doctor` tidak menunjukkan masalah untuk target Android atau Chrome.

```bash
flutter pub get
flutter run -d chrome
```

Browser akan meminta izin kamera saat halaman Scan dibuka. Kamera web hanya dapat digunakan melalui `localhost` saat development atau koneksi HTTPS saat deployment.

Untuk menjalankan pada Android, sambungkan perangkat dengan USB debugging atau jalankan emulator, kemudian:

```bash
flutter devices
flutter run -d <device-id>
```

### Menghubungkan recognition API

Secara default, Scan memakai adapter demo lokal. Untuk memakai backend recognition, jalankan aplikasi dengan endpoint milik tim:

```bash
flutter run -d chrome --dart-define=STEV_RECOGNITION_ENDPOINT=https://api.example.com/recognize
```

Client mengirim request `POST` JSON berikut:

```json
{
  "imageBase64": "...",
  "mimeType": "image/jpeg",
  "catalogIds": ["es-teh-manis", "boba-milk-tea"]
}
```

Backend harus mengembalikan maksimal tiga kandidat terurut. ID yang tidak ada di katalog akan diabaikan:

```json
{
  "candidates": [
    {"id": "es-teh-manis", "confidence": 0.94},
    {"id": "boba-milk-tea", "confidence": 0.81}
  ]
}
```

Token gateway demo opsional dapat diberikan lewat `--dart-define=STEV_RECOGNITION_TOKEN=...`. Jangan menaruh API key provider AI atau secret production di aplikasi Flutter; simpan secret tersebut di backend.

### Deploy recognition backend

Backend recognition berada di `supabase/functions/recognize-drink`. Function memvalidasi request dan publishable key, membaca hanya katalog terverifikasi, mengirim gambar ke Gemini Developer API dengan structured output, lalu menyaring ulang kandidat terhadap ID database. Backend Stev.AI tidak menyimpan foto.

Login dan hubungkan Supabase CLI:

```bash
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
```

Simpan API key AI sebagai secret server dan deploy function:

```bash
npx supabase secrets set GEMINI_API_KEY=YOUR_GEMINI_API_KEY
npx supabase secrets set GEMINI_MODEL=gemini-3.5-flash-lite
npx supabase functions deploy recognize-drink
```

Ambil API key dari [Google AI Studio](https://aistudio.google.com/app/apikey). Jangan memasukkan `GEMINI_API_KEY` ke `config/env.local.json`, Flutter, atau Git. Untuk development lokal, salin `supabase/functions/.env.example` menjadi `supabase/functions/.env`; file tersebut diabaikan Git.

Gemini menyediakan free tier dengan kuota terbatas. Pada free tier, konten yang dikirim dapat digunakan Google untuk meningkatkan produknya. Karena itu, arahkan kamera hanya ke minuman dan jangan kirim foto yang memuat wajah atau data sensitif.

Setelah function berhasil di-deploy, isi konfigurasi Flutter:

```json
{
  "STEV_RECOGNITION_ENDPOINT": "https://YOUR_PROJECT_REF.supabase.co/functions/v1/recognize-drink",
  "STEV_RECOGNITION_TOKEN": ""
}
```

Client otomatis mengirim `SUPABASE_PUBLISHABLE_KEY` melalui header `apikey` untuk endpoint Supabase. `STEV_RECOGNITION_TOKEN` hanya diperlukan jika kelak memakai backend non-Supabase yang membutuhkan Bearer token.

### Mengaktifkan Supabase

Tanpa konfigurasi, aplikasi tetap memakai katalog lokal. Untuk memakai katalog Supabase:

1. Buat project Supabase.
2. Jalankan migration `supabase/migrations/202610140001_create_drink_catalog.sql` melalui SQL Editor atau Supabase CLI.
3. Salin `config/env.example.json` menjadi `config/env.local.json`.
4. Isi Project URL dan publishable key dari panel **Connect**. File lokal ini diabaikan Git.
5. Jalankan:

```bash
flutter run -d chrome --dart-define-from-file=config/env.local.json
```

Migration mengaktifkan RLS. Client hanya dapat membaca minuman terverifikasi beserta opsi gula dan aliasnya. Operasi tulis tidak dibuka untuk client; penambahan atau verifikasi data harus dilakukan melalui dashboard atau backend yang aman. Jangan pernah memasukkan service-role key ke Flutter.

## Pemeriksaan kualitas

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

GitHub Actions menjalankan pemeriksaan yang sama untuk setiap push pada `main`, branch `feat/**`, branch `fix/**`, dan setiap pull request ke `main`. Workflow juga menghasilkan dua artifact yang dapat diunduh dari halaman Actions selama 14 hari:

- Bundle web `build/web` untuk deployment demo.
- APK debug `app-debug.apk` untuk instalasi pada perangkat Android.

Konfigurasi CI tidak memakai `config/env.local.json` atau secret lokal. Karena itu build CI menggunakan katalog lokal dan adapter recognition demo; konfigurasi Supabase/Gemini tetap diberikan hanya saat deployment yang dipercaya.

## Workflow Git

Setiap fitur dikembangkan pada branch terpisah, misalnya:

```bash
git switch -c feat/dashboard
git add .
git commit -m "feat: build dashboard sugar tracker"
```

Commit hanya dilakukan setelah format, analisis, dan test berhasil.

## Penggunaan AI

Tim menggunakan coding assistant seperti Codex untuk membantu perencanaan, implementasi, review, dan pengujian. Seluruh perubahan tetap ditinjau dan diuji oleh tim. Penggunaan AI dalam proses pengembangan akan dinyatakan secara transparan sesuai ketentuan kompetisi.

Pada produk akhir, AI direncanakan hanya membantu menghasilkan kandidat identitas minuman. Kandungan gula akan dicocokkan dengan data terstruktur dan tetap menampilkan sumber atau label estimasi yang sesuai.

## Lisensi

Status lisensi project belum ditentukan. Jangan menggunakan ulang source code, desain, atau aset project ini tanpa izin tim.
