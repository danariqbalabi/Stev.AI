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

- Mode **Diri sendiri** dan **Ayah/Ibu** dapat membuka halaman berbagi poster
  ketika skor FINDRISC minimal 12.
- Poster dipilih dari empat aset berdasarkan subjek dan band risiko Sedang atau
  Tinggi/Sangat tinggi.
- Share sheet membagikan poster beserta pesan otomatis yang menyertakan level
  dan skor. Pesan tetap dapat diedit sebelum dibagikan.
- Risiko Rendah dan Sedikit meningkat tidak menampilkan CTA poster.

## Skoring FINDRISC

- Seluruh delapan pertanyaan wajib dijawab; opsi **"Tidak tahu"** dihapus agar
  jawaban kosong tidak menurunkan skor secara diam-diam.
- Gunakan lima level skor: Rendah (0-6), Sedikit meningkat (7-11), Sedang
  (12-14), Tinggi (15-20), dan Sangat tinggi (21-26).
- Halaman hasil menampilkan skor, level, dan perkiraan risiko 10 tahun, dengan
  disclaimer bahwa hasil merupakan skrining dan bukan diagnosis.

## BMI dan lingkar pinggang

- Pertanyaan BMI menyediakan kalkulator dari tinggi badan dalam sentimeter dan
  berat badan dalam kilogram.
- Perhitungan dilakukan lokal dengan rumus
  `BMI = berat_kg / (tinggi_meter * tinggi_meter)`.
- BMI dibulatkan menjadi satu desimal sebelum dipetakan ke kategori:
  `<25`, `25-30`, atau `>30`.
- Tinggi, berat, BMI, jawaban, dan skor hanya berada di memori selama alur Cek
  Risiko dan tidak disimpan atau dikirim ke server.
- Lingkar pinggang diisi dalam sentimeter dan membutuhkan pilihan Pria/Wanita
  karena batas FINDRISC berbeda. Nilai batas masuk rentang tengah.

## Rekomendasi tes

- Judul hasil menggunakan **"Hasil cek risiko"**, bukan diagnosis.
- Risiko Rendah belum memerlukan tes khusus; Sedikit meningkat mendapat opsi
  tes terutama bila ada riwayat keluarga.
- Risiko Sedang ke atas menampilkan GDP, HbA1c, dan TTGO beserta fungsi,
  persiapan, serta catatan singkat.
- Lokasi yang disebutkan adalah Puskesmas, klinik, atau laboratorium. Aplikasi
  tidak menampilkan interpretasi angka hasil laboratorium pada tahap ini.

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

## Referensi kesehatan

- [Form FINDRISC Finnish Diabetes Association](https://carpha.org/Portals/0/FINDRISC.pdf)
  untuk delapan pertanyaan, bobot, serta lima level risiko.
- [The Diabetes Risk Score, Diabetes Care (2003)](https://diabetesjournals.org/care/article-pdf/26/3/725/665299/dc0303000725.pdf)
  sebagai publikasi pengembangan skor.
- [Juknis Integrasi Pelayanan Kesehatan Primer Kemenkes](https://jdih.kemkes.go.id/common/dokumen/KMK%20No.%20HK.01.07-MENKES-2015-2023%20ttg%20Juknis%20Integrasi%20Pelayanan%20Kesehatan%20Primer-signed.pdf)
  sebagai rujukan pemeriksaan gula darah pada layanan primer Indonesia.

