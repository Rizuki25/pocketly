# QA notifikasi Android nyata

Tanggal pengujian: 18 Juli 2026  
Perangkat: Samsung Galaxy A15 (SM-A155F)  
Android: 16 / API 36  
Zona waktu utama: Asia/Jakarta

## Hasil

| Skenario | Status | Bukti ringkas |
|---|---|---|
| Izin notifikasi diterima | Lulus | `POST_NOTIFICATIONS` berstatus granted dan notifikasi tampil. |
| Izin notifikasi ditolak | Lulus | Status izin berhasil diubah ke denied; aplikasi tetap dapat dibuka. Alur penolakan UI juga tercakup widget test. |
| Pengingat harian | Lulus | Notifikasi tampil dan alarm berikutnya terjadwal untuk hari berikutnya pada jam lokal yang sama. |
| Pengingat bulanan | Lulus | Alarm tanggal 1 terdaftar di AlarmManager. |
| Pengingat mingguan | Lulus | Alarm terdaftar untuk Senin berikutnya pada jam lokal yang dipilih. |
| Pengingat fleksibel | Lulus | Alarm terdaftar untuk Senin berikutnya pada jam lokal yang dipilih. |
| Quiet hours | Lulus | UI perangkat menolak waktu pengingat di dalam quiet hours; rentang siang dan lintas tengah malam juga tercakup test otomatis. |
| Pengingat tenggat | Lulus | Alarm tenggat masa depan terdaftar bersama pengingat rutin. |
| Privasi: sembunyikan nominal | Lulus | Notification record tidak mengandung nominal Rupiah dan memakai visibility `PRIVATE`. |
| Privasi: pesan generik | Lulus | Notifikasi tampil dan notification record tidak mengandung nominal; pengguna mengonfirmasi pesan generik. |
| Privasi: lengkap | Lulus | Notifikasi uji menampilkan nama target dan rekomendasi nominal; visibility tetap `PRIVATE`. |
| Perubahan zona waktu | Lulus | Asia/Jakarta -> Asia/Singapore -> Asia/Jakarta mempertahankan pukul lokal pengingat setelah aplikasi resume. |
| Reboot | Gagal terbatas OEM | Alarm tidak dipulihkan receiver setelah reboot Galaxy A15, tetapi keenam alarm pulih setelah Pocketly dibuka. |

## Temuan dan perbaikan

1. Penjadwalan ulang kini membatalkan seluruh pending notification sebelum
   membuat alarm baru agar alarm lama tidak menumpuk.
2. Bootstrap tanpa credential membatalkan notifikasi lama untuk mencegah
   informasi target lama muncul setelah reset atau pemulihan parsial.
3. Zona waktu dibaca ulang sebelum reschedule dan jadwal disinkronkan ketika
   aplikasi kembali aktif.
4. Manifest memiliki `RECEIVE_BOOT_COMPLETED` dan receiver resmi
   `flutter_local_notifications`. Pada perangkat uji, pembatasan background
   Samsung tetap mencegah pemulihan sebelum aplikasi pertama kali dibuka.
5. Layar pengaturan menyediakan tombol **Kirim notifikasi uji** agar ketiga
   tingkat privasi dapat diperiksa tanpa menunggu alarm inexact.

## Verifikasi otomatis setelah perubahan

- `dart analyze lib test`: lulus tanpa masalah.
- `flutter test`: 62 test lulus.
- Widget test baru memastikan bootstrap tanpa credential membatalkan
  notifikasi lama.
