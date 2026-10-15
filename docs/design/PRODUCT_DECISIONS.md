# Stev.AI product decisions

Dokumen ini mencatat keputusan produk yang sudah disetujui setelah handoff
terakhir. Untuk topik yang tercantum di sini, keputusan ini menggantikan
pertanyaan terbuka atau perilaku berbeda pada proposal, prototype, dan dokumen
handoff sebelumnya.

Terakhir diperbarui: 15 Oktober 2026.

## Pengingat pemeriksaan

- Switch **"Ingatkan aku dalam 7 hari"** harus menjadwalkan notifikasi lokal
  yang benar-benar muncul di notification bar perangkat.
- Menonaktifkan switch membatalkan pengingat yang belum dikirim.
- Implementasi Android harus meminta izin notifikasi ketika diperlukan.
- Reminder tidak mengirim jawaban, skor, atau data kesehatan ke server.

## Alur berdasarkan subjek Cek Risiko

- Mode **Orang tua** dapat membuka halaman **Ajak & Rujukan** dan membagikan
  pesan ajakan yang dapat diedit.
- Mode **Diri sendiri** tidak menampilkan CTA atau halaman Ajak & Rujukan.
  Pengguna tetap dapat melihat tindakan yang disarankan, membuka daftar
  Puskesmas contoh, lalu menyelesaikan alur.

## Jawaban "Tidak tahu"

- Setiap jawaban **"Tidak tahu"** bernilai 0 poin.
- Jika sedikitnya satu jawaban adalah "Tidak tahu", Hasil Risiko menampilkan
  label **"Estimasi minimal"**.
- Tidak ada hasil khusus "Belum cukup data" ketika empat atau lebih jawaban
  tidak diketahui.
- Disclaimer bahwa hasil merupakan skrining dan bukan diagnosis tetap wajib
  ditampilkan.

## BMI dan lingkar pinggang

- Pertanyaan BMI menyediakan kalkulator dari tinggi badan dalam sentimeter dan
  berat badan dalam kilogram.
- Perhitungan dilakukan lokal dengan rumus
  `BMI = berat_kg / (tinggi_meter * tinggi_meter)`.
- Hasil otomatis dipetakan ke kategori skor yang sudah digunakan aplikasi:
  `<25`, `25-30`, atau `>30`.
- Tinggi, berat, BMI, jawaban, dan skor hanya berada di memori selama alur Cek
  Risiko dan tidak disimpan atau dikirim ke server.
- Kategori lingkar pinggang tetap dipilih manual. Kalkulator lingkar pinggang
  tidak ditambahkan pada tahap ini.

## Data Puskesmas

- Daftar Puskesmas tetap menggunakan data contoh dari prototype.
- UI harus mempertahankan keterangan **"Contoh lokasi untuk prototipe"** agar
  data dummy tidak disalahartikan sebagai hasil lokasi nyata.
- Integrasi GPS, Maps, atau direktori fasilitas kesehatan nyata belum termasuk
  ruang lingkup MVP.

## Tab Keluarga

- Tambahkan tab **Keluarga** untuk membantu pengguna melacak pendampingan
  anggota keluarga.
- MVP disimpan lokal pada perangkat dan dapat memuat nama panggilan, hubungan,
  waktu pembaruan, serta status:
  - Belum dicek
  - Sudah cek risiko
  - Sudah diajak
  - Sudah periksa
- Tab Keluarga tidak menyimpan jawaban Cek Risiko, skor, BMI, atau informasi
  kesehatan lain.
- Sinkronisasi antarperangkat, akun bersama, dan undangan anggota keluarga
  belum termasuk ruang lingkup MVP karena membutuhkan keputusan autentikasi,
  persetujuan, dan privasi tambahan.

## Urutan implementasi

1. Selaraskan copy dan perilaku aplikasi dengan handoff final.
2. Pisahkan alur hasil Cek Risiko diri sendiri dan orang tua.
3. Tambahkan kalkulator BMI lokal.
4. Implementasikan notifikasi pengingat tujuh hari.
5. Tambahkan Tab Keluarga dengan penyimpanan lokal.

