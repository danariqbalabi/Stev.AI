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
- Dashboard.
- Kamera Android/Web dengan preview hasil foto.
- Fallback pemilihan gambar dari galeri/file.
- State izin ditolak, kamera tidak tersedia, dan coba lagi.
- Konfirmasi minuman.
- Hasil kandungan gula.
- Swap bottom sheet.
- Navigasi Android dan web.

AI, database, penyimpanan riwayat, widget Android, dan penerapan desain final ke seluruh screen belum diimplementasikan. Seluruh tebakan, angka, dan minuman setelah foto diambil masih merupakan data demo.

## Design system

Implementasi UI baru harus mengambil warna, tipografi, spacing, radius, shadow, ukuran, motion, dan aturan gula dari `lib/core/theme/stev_tokens.dart`. Theme aplikasi berada di `lib/core/theme/stev_theme.dart`, sedangkan komponen bersama dapat diimpor dari `lib/shared/widgets/stev_design_system.dart`.

Dokumen handoff dari desain tersedia di `docs/design/`:

- `DESIGN.md`: spesifikasi visual dan komponen.
- `MOTION.md`: timing, curve, dan perilaku reduced motion.
- `SCREENS.md`: anatomi setiap screen.
- `DATA.md`: data demo dan aturan produk.

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

- Home-screen widget Android.
- Pencarian minuman manual.
- Grafik konsumsi mingguan.
- Tambah minuman custom.
- Onboarding dan personalisasi.
- Animasi penghematan gula dan confetti kontekstual.
- Dukungan kategori makanan.

## Teknologi

- Flutter dan Dart.
- Material 3.
- Design tokens terpusat, font Onest, dan `flutter_svg` untuk aset vektor.
- `go_router` untuk navigasi.
- `camera` untuk viewfinder dan pengambilan foto di Android/Web.
- `image_picker` sebagai fallback galeri/file.
- Android dan Flutter Web dari satu codebase.
- Supabase untuk backend dan database pada tahap berikutnya.
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

## Pemeriksaan kualitas

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

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
