# Evaluasi pengenalan minuman

Harness ini mengukur kualitas endpoint `recognize-drink` menggunakan foto yang
belum pernah dipakai untuk menyusun prompt atau data katalog. Hasil utamanya
adalah akurasi top-1, top-3, penolakan gambar non-minuman, false-positive rate,
request error rate, serta latency p50 dan p95.

## Menyiapkan dataset lokal

1. Salin `tool/recognition_dataset/manifest.example.json` menjadi
   `tool/recognition_dataset/manifest.json`.
2. Taruh gambar di `tool/recognition_dataset/images/`. Folder gambar dan manifest
   lokal diabaikan Git.
3. Isi minimal 30–50 kasus dari beberapa minuman. Gunakan sudut depan/samping,
   cahaya terang/redup, jarak, dan latar yang berbeda.
4. Sertakan sedikitnya 10 gambar negatif seperti orang, makanan, meja kosong,
   atau benda lain. Untuk kasus negatif, isi `expectedDrinkId` dengan `null`.
5. Gunakan ID persis dari tabel `drinks`. Jangan memakai gambar yang pernah
   diberikan langsung sebagai contoh ke model.

Contoh satu kasus:

```json
{
  "id": "teh-kotak-front-01",
  "image": "images/teh-kotak-front-01.jpg",
  "expectedDrinkId": "teh-melati-kotak"
}
```

## Menjalankan evaluasi

Pastikan `config/env.local.json` berisi URL Supabase, publishable key, dan endpoint
yang sudah dideploy. Lalu jalankan:

```powershell
Copy-Item tool/recognition_dataset/manifest.example.json tool/recognition_dataset/manifest.json
dart run tool/evaluate_recognition.dart
```

Secara default laporan detail dibuat di
`build/recognition-evaluation/report.json`. Gunakan `--help` untuk melihat opsi
path, output, dan timeout. Exit code `2` berarti setidaknya ada request yang
gagal; salah prediksi tetap direkam sebagai hasil evaluasi, bukan error proses.

## Kriteria demo yang disarankan

- request error rate 0%;
- top-3 accuracy minimal 80% pada minuman yang memang tersedia di katalog;
- rejection accuracy minimal 80% untuk gambar non-minuman;
- tidak ada satu kelas yang selalu menjadi jawaban untuk semua foto.

Angka ini adalah target kesiapan demo, bukan klaim akurasi medis atau produksi.
Simpan report setiap kali model, prompt, fungsi, atau katalog berubah agar
perbandingannya dapat ditelusuri.
