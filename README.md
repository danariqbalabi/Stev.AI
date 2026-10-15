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
2. Tombol Scan langsung membuka kamera **Foto Minuman**. Pilihan **Barcode** dan **Label Gizi** tersedia di layar kamera tanpa halaman pemilihan tambahan. Foto minuman masuk identifikasi katalog; barcode mencari produk; label gizi dibaca untuk dikonfirmasi sebelum dicatat.
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
- Katalog demo terpusat berisi 50 minuman (25 kemasan) beserta kategori, jenis, kandungan gula, status validasi, dan fallback gambar.
- State log minuman harian yang menghitung total secara dinamis dan mengganti entri produk yang sama.
- Aturan Swap terpusat untuk level gula minuman non-kemasan dan alternatif produk kemasan yang tersedia.
- Kamera Android/Web dengan preview hasil foto.
- Kamera foto terbuka satu tap dari tombol Scan, dengan pengalih mode Foto, Barcode, dan Label Gizi. Pencarian manual tetap tersedia; kamera lama dilepas sebelum pindah mode.
- OCR label gizi melalui Gemini di Supabase Edge Function, dengan pembacaan gula terpisah dari karbohidrat dan pembedaan per sajian/per 100 ml/per kemasan.
- Form konfirmasi OCR dengan foto, bukti teks label, koreksi angka, bagian kemasan yang diminum, perhitungan lokal, serta persetujuan pengguna sebelum masuk log pribadi. Data tidak terbaca tidak dianggap nol; input label manual tersedia saat kamera/OCR gagal.
- Scanner barcode EAN-8/EAN-13/UPC-A Android/Web, input angka manual, pemeriksaan checksum, serta pencarian Supabase lalu Open Food Facts.
- Konfirmasi barcode menampilkan sumber, gula per porsi, porsi yang dapat diubah, dan total gula sebelum dicatat ke log pribadi. Produk dengan data gula/volume yang tidak lengkap diarahkan ke pencarian atau input manual.
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
- Skrining FINDRISC untuk diri sendiri atau orang tua: delapan jawaban wajib, lima level risiko, skor 0-26, faktor utama, dan perkiraan risiko 10 tahun. Jawaban hanya diproses di memori perangkat dan tidak disimpan.
- Input lingkar pinggang memakai batas berbeda untuk pria dan wanita; kalkulator BMI membulatkan hasil ke satu desimal sebelum menentukan poin.
- Hasil risiko memberi rekomendasi GDP, HbA1c, dan TTGO sesuai level risiko tanpa mengklaim diagnosis.
- Kalkulator BMI lokal dari tinggi dan berat badan untuk membantu menjawab skrining tanpa menyimpan ukuran tubuh.
- Notifikasi Android sungguhan yang dijadwalkan tujuh hari setelah skrining dan dapat dibatalkan dari aplikasi.
- Tab Keluarga lokal untuk melacak status undangan dan pemeriksaan anggota keluarga tanpa menyimpan jawaban, skor, atau BMI.
- Empat poster ajakan untuk mode diri sendiri/Ayah-Ibu dan risiko Sedang/Tinggi, dibagikan bersama pesan otomatis berisi level dan skor melalui share sheet sistem.
- Animasi satu kali dari hasil pencatatan menuju riwayat Dashboard, termasuk meter gula yang ikut berubah dan dukungan reduced motion.
- Evaluation harness untuk mengukur top-1/top-3, penolakan non-minuman, false positive, error request, dan latency recognition.
- Navigasi Android dan web.

Edge Function recognition dan katalog cloud sudah tersedia di source code, tetapi function harus di-deploy dan diberi API key AI sebelum recognition nyata aktif. Tanpa konfigurasi endpoint, hasil recognition tetap memakai adapter demo lokal. Aturan Swap saat ini masih merupakan data demo lokal dari design handoff.

## Data barcode

Hasil barcode disimpan di perangkat maksimal **7 hari / 50 produk** untuk mengurangi request dan membuka produk yang pernah dicari saat offline. Hasil cache ditandai, sumber dan status verifikasi tetap dipertahankan; selalu cocokkan varian, ukuran, dan label kemasan. Cache serta cooldown tidak ikut ekspor/sinkronisasi akun dan ikut terhapus saat reset seluruh data aplikasi.

Request ke Open Food Facts diberi jeda minimal 6 detik pada perangkat. Respons HTTP 429 mengikuti `Retry-After` (angka detik atau HTTP-date), dengan fallback 60 detik. Saat menunggu, pengguna tetap bisa Scan Label Gizi, isi label manual, atau cari minuman manual. Ini pembatasan client best-effort, bukan jaminan kuota per IP: banyak perangkat di Wi-Fi sama tetap dapat terkena limit bersama. Request tetap langsung dari perangkat pengguna, bukan server Vercel.

Pencarian barcode hanya melakukan request baca: pertama ke `drinks.barcode` di Supabase (baris `verified = true`), lalu ke API Open Food Facts jika belum tersedia. Isi kolom barcode dengan EAN/UPC yang benar beserta `serving_ml` dan gula per porsi katalog. Tidak perlu migration atau Edge Function baru untuk fitur ini.

Data Open Food Facts belum diverifikasi Stev.AI. Pengguna perlu mengecek varian dan ukuran pada label sebelum menekan **Konfirmasi & catat**. Gula per 100 ml dikalikan jumlah porsi yang diminum; ukuran kemasan dalam gram tidak dikonversi ke ml. Produk bubuk/sirup dan data tidak lengkap memerlukan input manual. Hasil tidak ditambahkan ke katalog publik.

Sumber eksternal: [Open Food Facts](https://world.openfoodfacts.org), database berlisensi [Open Database License (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/). API eksternal memerlukan internet; pada Web, kamera memerlukan HTTPS atau localhost dan izin browser. Gambar produk mengikuti sumbernya dan memiliki fallback jika gagal dimuat.

Uji pada perangkat fisik: scan produk, ubah porsi, catat, scan lagi, tolak izin kamera lalu ketik barcode, dan coba barcode yang belum tersedia. Browser dapat mengunduh library deteksi barcode saat pertama dibuka. Barcode yang tidak ditemukan juga dapat dilanjutkan ke **Scan Label Gizi**.

## Scan Label Gizi (OCR)

Mode ini memakai kamera/galeri yang sama dengan Foto Minuman. Foto dikirim ke `${SUPABASE_URL}/functions/v1/read-nutrition-label`; API key Gemini tetap berada di Supabase Secrets. Tidak perlu environment variable baru di Vercel: `SUPABASE_URL` dan `SUPABASE_PUBLISHABLE_KEY` yang sudah ada dipakai otomatis.

Deploy backend sebelum merilis UI:

```powershell
npx supabase functions deploy read-nutrition-label
```

Function memakai secret `GEMINI_API_KEY` dan opsional `GEMINI_MODEL`, sama dengan recognition. Backend memeriksa public key ke REST Supabase sebelum memanggil Gemini, membatasi foto JPEG/PNG/WebP hingga 8 MB, serta memakai timeout. Foto dan hasil OCR tidak ditulis ke katalog publik atau Storage oleh function ini.

Gemini hanya mengekstrak teks, angka gula, unit, dasar perhitungan, dan takaran yang benar-benar terlihat. Nilai mg dinormalisasi oleh backend. Confidence di bawah 0,75, label tanpa gula yang jelas, karbohidrat saja, nilai `<1 g`, dan basis per 100 gram ditolak agar pengguna memotret ulang atau mengisi manual. Confidence model tidak menjamin kebenaran; hasil tetap perlu dicocokkan dengan label oleh pengguna.

Perhitungan aplikasi:

- Per sajian: gula × jumlah sajian per kemasan × bagian kemasan yang diminum.
- Per 100 ml: gula × (volume kemasan / 100) × bagian yang diminum.
- Per kemasan: gula × bagian yang diminum; jumlah sajian tidak dikalikan lagi.

Jumlah sajian/volume yang tidak terbaca dibiarkan kosong dan wajib diisi jika dibutuhkan. Nilai `0 g` hanya diterima jika memang terbaca. User bisa mengoreksi dasar perhitungan, angka gula, jumlah sajian, volume, dan memilih seluruh/setengah/seperempat/tiga perempat kemasan. Setiap perubahan membatalkan centang konfirmasi sebelumnya. Catatan tetap berstatus belum diverifikasi; gambar dan teks OCR tidak ikut disimpan di log.

Tes parsing backend dapat dijalankan dengan Node 24:

```powershell
node --test supabase/functions/recognize-drink/recognition.test.ts supabase/functions/read-nutrition-label/nutrition.test.ts
```

Smoke test perangkat: label 9 g dengan 2 sajian menghasilkan 18 g untuk seluruh kemasan, 9 g untuk setengah kemasan; label 6 g/100 ml dan botol 300 ml menghasilkan 18 g. Coba juga label buram, data sajian kosong, izin kamera ditolak, input manual, dan foto ulang setelah kembali dari form.

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
`docs/data/RECOGNITION_EVALUATION.md`. Panduan APK/AAB dan signing tersedia di
`docs/ANDROID_RELEASE.md`.

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

- Pengumpulan dataset foto independen dan evaluasi recognition berkala.
- Rate limiting, abuse protection, dan observability backend production.
- Validasi sumber kandungan gula oleh tim sebelum data demo dipromosikan menjadi data terverifikasi.
- Sinkronisasi per-record dan audit perubahan jika penggunaan lintas perangkat berkembang di luar kebutuhan MVP.
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
- Supabase Auth untuk akun email opsional; aplikasi tetap dapat dipakai sebagai tamu.
- Sinkronisasi snapshot data pengguna yang offline-first dan dilindungi RLS per akun.
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

### Mengaktifkan akun pengguna

Login dan pendaftaran email otomatis aktif saat konfigurasi Supabase di atas valid. Di Supabase Dashboard:

1. Buka **Authentication → Providers → Email** dan pastikan provider Email aktif.
2. Buka **Authentication → URL Configuration**.
3. Isi **Site URL** dengan URL production, misalnya `https://stev-ai.vercel.app`.
4. Tambahkan `http://localhost:*` pada Redirect URLs untuk development lokal.

Pengguna tetap dapat memilih mode tamu. Setelah login, data lokal dapat disinkronkan ke akun dan dipulihkan pada perangkat lain.

Jalankan juga migration `supabase/migrations/202610150002_create_user_data_snapshots.sql` untuk mengaktifkan sinkronisasi. Snapshot mencakup profil, log harian, streak, keluarga, dan riwayat risiko. RLS memastikan setiap akun hanya dapat membaca, menulis, atau menghapus snapshot miliknya sendiri. Perubahan tetap disimpan lokal terlebih dahulu; tombol sinkronisasi tersedia di halaman Profil dan sinkronisasi juga dijalankan setelah login.

## Pemeriksaan kualitas

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
flutter build web --release
```

GitHub Actions menjalankan pemeriksaan yang sama untuk setiap push pada `main`, branch `feat/**`, branch `fix/**`, dan setiap pull request ke `main`. Workflow juga menghasilkan dua artifact yang dapat diunduh dari halaman Actions selama 14 hari:

- Bundle web `build/web` untuk deployment demo.
- APK debug `app-debug.apk` untuk instalasi pada perangkat Android.

Build verifikasi CI tidak memakai `config/env.local.json` atau secret lokal. Karena itu artifact verifikasi menggunakan katalog lokal dan adapter recognition demo.

### Deployment production Vercel

Push ke `main` baru boleh dipublikasikan setelah job format, analyze, test, web build, dan Android build berhasil. Job `Deploy production web` kemudian:

1. Mengambil konfigurasi client production dari Vercel.
2. Menjalankan `flutter build web --release` dengan konfigurasi tersebut.
3. Mengunggah hanya hasil `build/web` ke project `stev-ai`.
4. Memeriksa root app, `main.dart.js`, dan route `/family`.

Tambahkan satu Actions secret bernama `VERCEL_TOKEN` di **GitHub → Settings → Secrets and variables → Actions**. Gunakan token Vercel khusus CI, bukan token login atau secret Supabase. `SUPABASE_URL`, publishable key, dan endpoint recognition disimpan sebagai Config di environment Production Vercel; ketiganya memang dimasukkan ke aplikasi web dan bukan server secret.

Auto-deploy Git Vercel dinonaktifkan melalui `vercel.json` karena Vercel tidak membangun proyek Flutter secara native. Tanpa pengaturan ini, Vercel dapat mempromosikan deployment kosong sebelum GitHub Actions selesai membangun Flutter.

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
