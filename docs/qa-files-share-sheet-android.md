# QA file dan share sheet Android nyata

Tanggal pengujian: 18 Juli 2026  
Perangkat: Samsung Galaxy A15 (SM-A155F)  
Android: 16 / API 36

## Hasil

| Skenario | Status | Bukti ringkas |
|---|---|---|
| Membuat backup `.pocketly` | Lulus | PIN dan kata sandi backup tervalidasi, lalu share sheet sistem terbuka. |
| Menyimpan/membagikan backup | Lulus | Pocketly menampilkan konfirmasi backup siap disimpan. |
| Membatalkan share backup | Lulus | Pocketly menampilkan ekspor dibatalkan dan cache dibersihkan. |
| Kata sandi backup salah | Lulus | File ditolak sebelum dialog penggantian data. |
| Kata sandi backup benar | Lulus | Ringkasan jumlah target/transaksi tampil sebelum restore. |
| Membatalkan konfirmasi restore | Lulus | Data tidak diganti dan pesan berhasil tidak ditampilkan. |
| Restore backup | Lulus | Restore selesai, target dan transaksi tetap dapat dibuka. |
| File backup rusak | Lulus | File ditolak tanpa mengubah data lokal. |
| File backup 21 MiB | Lulus | Ditolak dengan pesan ukuran file tidak valid sebelum kata sandi diminta. |
| Ekspor CSV | Lulus | Peringatan plaintext, autentikasi ulang, dan share sheet bekerja. |
| Membatalkan share CSV | Lulus | Pocketly menampilkan ekspor CSV dibatalkan. |
| Pembersihan file sementara | Lulus | Cache `share_plus` dan salinan file-picker UUID kosong setelah cleanup/startup. |

## Temuan dan perbaikan

1. `share_plus` menyimpan salinan attachment di `cache/share_plus` hingga share
   berikutnya. Pocketly kini menghapus hanya salinan file terkait setelah jeda
   30 detik dan membersihkan sisa cache share saat startup.
2. `file_selector` pada Android menyalin file terpilih ke direktori cache UUID.
   Pocketly kini membersihkan salinan lama sebelum picker dibuka dan menghapus
   salinan baru setelah bytes selesai dibaca, tanpa menghapus sumber di
   Download atau cloud.
3. Error file di atas 20 MiB kini ditampilkan secara spesifik sebagai
   **Ukuran file backup tidak valid.**
4. Dua file QA rusak/terlalu besar yang dibuat di Download sudah dihapus setelah
   pengujian.

## Verifikasi otomatis setelah perubahan

- `dart analyze lib test`: lulus tanpa masalah.
- `flutter test`: 67 test lulus.
- Build APK debug: berhasil dan dipasang sebagai update tanpa menghapus data.

