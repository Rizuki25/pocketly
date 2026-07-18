# Pocketly

Pocketly adalah aplikasi Flutter untuk mencatat dan mendampingi target tabungan pribadi. MVP bersifat **local-first**: aplikasi tidak menyimpan, menahan, atau memindahkan uang sungguhan.

Dokumen kebutuhan lengkap berada di [`workflow.md`](workflow.md), sedangkan
design system, inventaris layar, dan prompt AI UI berada di
[`Design.md`](Design.md). Baca ketiga dokumen tersebut sebelum melanjutkan
implementasi pada sesi baru.

## Keputusan produk saat ini

- Platform awal: Android dan iOS.
- Mode MVP: lokal tanpa akun/cloud.
- Backup lokal terenkripsi termasuk dalam MVP dan sudah tersedia.
- PIN aplikasi: 6 digit.
- Biometrik: opsional, dengan PIN sebagai fallback wajib.
- Auto-lock default yang direncanakan: 1 menit.
- State management belum dipilih karena fitur yang ada masih dikelola secara lokal per layar.
- Palet visual utama:
  - Background: `#FFFFFF`
  - Primary/accent: `#9A6AFF`
  - Teks/ink: `#1E2029`
  - Border/surface lembut: `#E3E3E3`

## Status implementasi

### Sudah selesai

- Splash screen animasi dengan logo Pocketly.
- Onboarding tiga halaman.
- Penjelasan mode lokal dan backup.
- Pembuatan serta konfirmasi PIN 6 digit.
- Validasi PIN lemah.
- Popup PIN berhasil dibuat.
- Hash PIN Argon2id dengan salt acak.
- Penyimpanan credential melalui Keystore/Keychain.
- Lock screen PIN untuk pengguna lama.
- Progressive PIN lockout yang bertahan setelah restart aplikasi.
- Layar penawaran biometrik.
- Autentikasi biometrik native menggunakan `local_auth`.
- Auto-prompt biometrik satu kali pada lock screen.
- Penanganan biometrik gagal, dibatalkan, tidak tersedia, belum terdaftar, dan
  lockout telah tersedia di tingkat kode dan test. QA perangkat Samsung
  menemukan status lockout vendor masih perlu diperbaiki sebelum rilis.
- PIN selalu tersedia sebagai fallback.
- Pengguna yang sudah memiliki PIN dapat mengaktifkan biometrik setelah masuk.
- Auto-lock setelah aplikasi berada di background selama 1 menit.
- Durasi background dihitung saat aplikasi kembali aktif; perubahan jam mundur
  diperlakukan secara aman dengan langsung mengunci aplikasi.
- Snapshot recent apps ditutupi pada Android dan iOS.
- Android memblokir screenshot serta screen recording pada layar PIN, lock
  screen, dan penawaran biometrik menggunakan `FLAG_SECURE`.
- iOS menampilkan privacy shield saat layar sensitif sedang direkam atau
  dicerminkan.
- Dashboard empty state dan struktur navigasi utama lima bagian.
- Database lokal SQLCipher terenkripsi dengan kunci acak 256-bit di
  Keystore/Keychain.
- CRUD target tabungan: buat, lihat, ubah, arsipkan/pulihkan, dan hapus.
- Formulir target dengan validasi nominal, saldo awal, frekuensi, kategori,
  prioritas, dan tenggat.
- Format Rupiah otomatis saat mengetik nominal, misalnya `10000000` menjadi
  `10.000.000`.
- Dialog penyimpanan target dengan progress bar dan animasi centang sukses.
- Detail target dengan progres, informasi tenggat, frekuensi, dan prioritas.
- Kalkulator rencana menabung yang menghitung sisa target, jumlah periode, serta
  rekomendasi setoran harian, mingguan, atau bulanan dengan pembulatan ke atas.
- Setoran dan penarikan dengan pratinjau saldo serta validasi penarikan agar
  tidak melebihi saldo target.
- Riwayat transaksi per target, termasuk ubah, hapus, dan undo penghapusan.
- Penyimpanan transaksi atomik: riwayat dan saldo target berubah dalam satu
  transaksi database sehingga tidak dapat tersimpan separuh.
- Pencegahan transaksi ganda menggunakan ID transaksi unik dan tombol simpan
  yang dinonaktifkan selama operasi berlangsung.
- Pengaturan keamanan untuk mengubah PIN setelah memverifikasi PIN aktif.
- Penonaktifan biometrik dengan autentikasi ulang menggunakan PIN.
- Perubahan PIN atau biometrik mengunci kembali aplikasi; perubahan PIN juga
  menonaktifkan biometrik sampai pengguna mengaktifkannya kembali.
- Pemulihan lupa PIN melalui biometrik yang sudah aktif dan terdaftar, tanpa
  menghapus target maupun transaksi.
- Fallback reset seluruh data lokal dengan peringatan dan konfirmasi ketik
  `HAPUS` ketika pengguna tidak memiliki metode verifikasi yang valid.
- Backup lokal terenkripsi berformat `.pocketly` dengan Argon2id dan
  AES-256-GCM.
- Pembuatan dan pemulihan backup dari menu Profil, termasuk autentikasi ulang,
  validasi file, konfirmasi penggantian data, dan restore atomik.
- Pemulihan lupa PIN melalui file backup dan kata sandi backup, lalu pembuatan
  PIN baru tanpa menyertakan credential lama di dalam file.
- Notifikasi lokal untuk jadwal menabung sesuai frekuensi target dan pengingat
  tiga hari sebelum tenggat.
- Izin notifikasi baru diminta setelah penjelasan manfaat dan tidak menghambat
  aplikasi ketika ditolak.
- Privasi notifikasi tiga tingkat: lengkap, sembunyikan nominal sebagai default,
  atau pesan generik tanpa nama target.
- Waktu pengingat serta quiet hours dapat diatur; jadwal di dalam quiet hours
  ditolak sebelum disimpan.
- Tombol notifikasi uji menampilkan pesan langsung sesuai tingkat privasi tanpa
  menunggu alarm terjadwal.
- Tab Laporan dengan filter 7 hari, bulanan, tahunan, rentang khusus, target,
  serta jenis transaksi.
- Ringkasan total setoran, total penarikan, perubahan bersih, rata-rata setoran,
  progres target, hari setoran paling konsisten, dan perbandingan periode lalu.
- Ekspor seluruh transaksi hasil filter ke CSV setelah autentikasi ulang PIN dan
  peringatan bahwa file tidak terenkripsi.
- CSV memakai UTF-8 BOM, escaping field, dan netralisasi formula spreadsheet;
  file sementara dihapus setelah share sheet selesai.
- Unit test dan widget test untuk alur utama.

### Belum selesai

- Ekspor PDF serta sinkronisasi/cloud opsional.
- Perbaikan klasifikasi temporary/permanent biometric lockout pada dialog vendor
  Samsung, diikuti pengujian ulang perangkat nyata.

Setelah autentikasi berhasil, aplikasi membuka dashboard. Jika belum ada target,
dashboard menampilkan empty state dan shortcut langsung ke formulir target baru.

## Target tabungan

### Prosedur penggunaan

1. Masuk ke Pocketly menggunakan PIN atau biometrik.
2. Dari Beranda, tekan **Buat target pertama**, atau buka menu **Tambah** lalu
   pilih **Target baru**.
3. Isi nama dan nominal target.
4. Isi saldo awal bila sudah memiliki tabungan. Saldo awal tidak boleh melebihi
   nominal target.
5. Pilih frekuensi menabung: harian, mingguan, bulanan, atau fleksibel.
6. Tambahkan kategori, tenggat, dan status prioritas bila diperlukan.
7. Tekan **Simpan target**. Target muncul di menu **Target** dan ringkasannya
   tampil di Beranda setelah animasi penyimpanan berhasil.
8. Gunakan menu tiga titik pada kartu target untuk mengubah, mengarsipkan,
   memulihkan, atau menghapus target.

### Prosedur teknis

1. Saat data target pertama kali dibuka, Pocketly membuat kunci acak 32 byte.
2. Kunci disimpan melalui `flutter_secure_storage`, bukan di database atau log.
3. `sqflite_sqlcipher` membuka `pocketly_encrypted.db` menggunakan kunci tersebut.
4. Aplikasi memeriksa `PRAGMA cipher_version` sebelum memakai database.
5. Jika kunci rusak atau database gagal dibuka, Pocketly menampilkan layar error
   dan tidak membuat database kosong secara otomatis.
6. Skema versi 2 menyimpan target dan transaksi dalam integer satuan rupiah
   untuk menghindari kesalahan floating point.
7. Operasi UI mengakses data melalui `GoalRepository`, sehingga lapisan database
   dapat dimigrasikan tanpa mengubah layar.

## Transaksi tabungan

### Prosedur penggunaan

1. Buka menu **Tambah**, lalu pilih **Setoran** atau **Penarikan**. Transaksi
   juga dapat ditambahkan langsung dari detail target.
2. Pilih target, masukkan nominal, tanggal, sumber dana atau alasan, dan catatan
   opsional.
3. Periksa saldo setelah transaksi sebelum menyimpan.
4. Setoran yang melewati nominal target memerlukan konfirmasi tambahan.
5. Penarikan yang melebihi saldo ditolak tanpa mengubah riwayat maupun saldo.
6. Buka detail target untuk melihat, mengubah, atau menghapus transaksi.
7. Setelah transaksi dihapus, gunakan **Batalkan** pada snackbar untuk
   memulihkannya.

### Jaminan atomik

- SQLCipher menyimpan baris transaksi dan memperbarui saldo target dalam satu
  database transaction.
- Jika salah satu operasi gagal, seluruh perubahan dibatalkan.
- Edit membalik dampak transaksi lama sebelum menerapkan nilai baru.
- Hapus membalik dampak transaksi terhadap saldo; foreign key menghapus riwayat
  ketika target dihapus.
- Nominal disimpan sebagai integer Rupiah, bukan floating point.

Pemilihan saat ini adalah `sqflite_sqlcipher 3.4.0` karena Flutter proyek masih
menyertakan Dart 3.9.2. Jalur Drift dengan SQLite3MultipleCiphers memerlukan versi
SDK yang lebih baru; migrasi dapat dipertimbangkan ketika Flutter SDK dinaikkan.

## Alur aplikasi saat ini

### Pengguna baru

```text
Splash
  -> Onboarding
  -> Penjelasan data lokal dan backup
  -> Buat PIN
  -> Konfirmasi PIN
  -> Popup berhasil
  -> Penawaran biometrik
  -> Dashboard
```

### Pengguna lama

```text
Bootstrap credential
  -> Biometrik otomatis satu kali (jika aktif dan tersedia)
  -> PIN sebagai fallback
  -> Dashboard
```

Jika biometrik dibatalkan, dialog tidak muncul kembali secara otomatis. Pengguna dapat menekan **Gunakan biometrik** atau langsung memasukkan PIN.

## Keamanan PIN

Implementasi utama berada di `lib/core/security/`.

- Algoritma: Argon2id melalui `cryptography`.
- Salt: 16 byte dari generator acak aman.
- Parameter produksi:
  - Memory: 19 MiB (`19 * 1024` blok KiB).
  - Iterations: 2.
  - Parallelism: 1.
  - Hash length: 32 byte.
- Hash dijalankan pada isolate agar UI tidak tersendat.
- Verifikasi hash menggunakan perbandingan constant-time.
- PIN asli tidak disimpan dan tidak dicetak ke log.
- Credential menyimpan versi skema, algoritma, parameter KDF, hash, salt, jumlah kegagalan, waktu lockout, dan waktu perubahan PIN.
- Secure storage Android menggunakan `flutter_secure_storage`; backup aplikasi Android dinonaktifkan agar data terenkripsi tidak dipulihkan tanpa kunci Keystore yang sesuai.
- iOS menggunakan Keychain dengan akses `unlocked_this_device`.

PIN berikut ditolak:

- Digit sama, misalnya `111111`.
- Urutan naik/turun, misalnya `123456` dan `654321`.
- Pola tiga digit berulang, misalnya `123123`.

Progressive lockout:

| Kegagalan berturut-turut | Lockout |
|---:|---:|
| 1-4 | Tidak ada |
| 5 | 30 detik |
| 6 | 1 menit |
| 7 | 5 menit |
| 8+ | 15 menit |

Catatan: perlindungan manipulasi jam perangkat belum sepenuhnya dapat dijamin pada mode lokal tanpa sumber waktu tepercaya. Ini masih menjadi item security hardening.

## Biometrik

- Paket: `local_auth ^3.0.1`.
- Android minimum SDK: 24.
- iOS deployment target: 13.0.
- Android menggunakan `FlutterFragmentActivity` dan izin `USE_BIOMETRIC`.
- iOS memiliki `NSFaceIDUsageDescription`.
- Autentikasi menggunakan `biometricOnly: true`, sehingga fallback PIN perangkat tidak menggantikan PIN aplikasi Pocketly.
- Dialog berasal dari sistem operasi; tidak ada dialog sidik jari buatan aplikasi.
- Adapter native: `lib/core/security/local_auth_biometric_authenticator.dart`.
- Kontrak yang mudah diuji: `lib/core/security/biometric_authenticator.dart`.

Biometrik harus diuji pada perangkat nyata dengan sidik jari/wajah yang sudah terdaftar.

## Pengaturan keamanan

- Menu **Profil** menyediakan tindakan **Ubah PIN**.
- Pengguna wajib memasukkan PIN aktif sebelum membuat PIN baru.
- PIN baru harus memenuhi kebijakan PIN kuat dan dikonfirmasi dua kali.
- Setelah PIN berubah, biometrik dinonaktifkan dan Pocketly dikunci kembali.
- Penonaktifan biometrik memerlukan konfirmasi serta verifikasi PIN.
- Layar ubah PIN dan autentikasi ulang ditandai sebagai layar sensitif sehingga
  perlindungan screenshot mengikuti kebijakan platform.
- Kegagalan PIN pada pengaturan keamanan memakai progressive lockout yang sama
  dengan layar login.

## Lupa PIN dan pemulihan lokal

- Tombol **Lupa PIN?** tersedia pada lock screen.
- Jika biometrik sebelumnya aktif dan masih tersedia, pengguna dapat
  memverifikasi biometrik lalu membuat PIN baru. Data tabungan tetap utuh.
- Setelah PIN dipulihkan, biometrik dinonaktifkan dan aplikasi dikunci kembali;
  pengguna masuk memakai PIN baru dan dapat mengaktifkan biometrik lagi.
- Jika tersedia, pengguna dapat memilih file backup `.pocketly`, memasukkan kata
  sandi backup, lalu membuat PIN baru. Credential PIN lama tidak berasal dari
  backup.
- Pocketly tidak menjanjikan pemulihan tanpa biometrik atau backup yang valid.
- Fallback terakhir adalah reset seluruh data lokal dengan dua tahap
  konfirmasi, termasuk mengetik `HAPUS`.
- Reset lokal menutup database, menghapus file SQLCipher, kunci enkripsi,
  credential PIN, serta preferensi biometrik sebelum kembali ke onboarding.
- Jika salah satu operasi reset gagal, aplikasi tidak membuat database atau
  credential pengganti secara diam-diam dan pengguna dapat mencoba kembali.

## Backup lokal terenkripsi

### Membuat backup

1. Buka **Profil → Backup terenkripsi → Kelola backup**.
2. Verifikasi PIN aktif.
3. Buat kata sandi backup terpisah minimal 10 karakter dan konfirmasikan.
4. Pocketly mengenkripsi seluruh target dan transaksi, lalu membuka share sheet
   sistem untuk menyimpan file `.pocketly` ke lokasi pilihan pengguna.
5. File sementara dibersihkan setelah share sheet selesai.

### Memulihkan backup

1. Dari menu backup, verifikasi PIN aktif lalu pilih file `.pocketly` berukuran
   maksimal 20 MiB.
2. Masukkan kata sandi backup.
3. Tinjau jumlah target dan transaksi, lalu konfirmasi penggantian data lokal.
4. Seluruh target dan transaksi diganti dalam satu transaksi database. File,
   kata sandi, atau data yang tidak valid tidak mengubah data lama.

Format backup versi 1 menggunakan Argon2id untuk derivasi kunci dan AES-256-GCM
untuk kerahasiaan sekaligus autentikasi isi. Salt dan nonce dibuat acak untuk
setiap file. Backup hanya berisi target, transaksi, dan metadata versi; PIN,
hash PIN, preferensi biometrik, serta kunci database tidak pernah disertakan.
Kata sandi backup tidak disimpan oleh Pocketly dan file tidak dapat dipulihkan
jika kata sandinya hilang.

Pemulihan lupa PIN dapat memakai backup tanpa mengetahui PIN aktif. Setelah isi
backup tervalidasi dan dipulihkan, pengguna wajib membuat PIN baru. Ekspor
menggunakan `share_plus 11.1.0`, pemilihan file menggunakan
`file_selector 1.1.0`, dan file sementara menggunakan `path_provider 2.1.5`.

## Notifikasi lokal dan privasi notifikasi

### Mengaktifkan pengingat

1. Buka **Profil → Kelola notifikasi**, atau tekan ikon lonceng di Beranda.
2. Aktifkan **Pengingat tabungan**. Pocketly menjelaskan manfaatnya sebelum
   meminta izin notifikasi dari Android/iOS.
3. Pilih waktu pengingat dan quiet hours. Waktu pengingat tidak boleh berada di
   dalam quiet hours.
4. Pilih tingkat privasi lalu simpan pengaturan.

Target harian dijadwalkan setiap hari, target mingguan dan fleksibel setiap
Senin, serta target bulanan setiap tanggal 1. Target aktif yang memiliki tenggat
juga mendapat satu pengingat tiga hari sebelumnya. Target yang selesai atau
diarsipkan tidak dijadwalkan. Jadwal dibuat ulang setelah target atau transaksi
berubah, dan maksimum 30 target dijadwalkan agar tetap di bawah batas 64
notifikasi tertunda pada iOS.

### Tingkat privasi

- **Sembunyikan nominal** adalah default: nama target boleh tampil, tetapi
  nominal tidak dimasukkan ke pesan.
- **Pesan generik** tidak menyertakan nama target maupun nominal.
- **Lengkap** dapat menampilkan nama target serta rekomendasi nominal setoran.

Semua notifikasi Android memakai visibility `private`. Tampilan akhir pada layar
kunci tetap mengikuti pengaturan sistem perangkat. Pocketly tidak mengirim nama
target atau nominal ke server karena penjadwalan dilakukan sepenuhnya lokal.
Pengaturan disimpan melalui secure storage dan dibersihkan saat seluruh data
lokal direset.

Implementasi memakai `flutter_local_notifications 20.1.0`, `flutter_timezone
5.1.0`, dan `timezone 0.10.1`, yaitu versi yang kompatibel dengan Dart 3.9.2.
Alarm Android memakai mode inexact sehingga tidak memerlukan izin exact alarm.
Android dijadwalkan ulang setelah reboot dan aplikasi memakai zona waktu IANA
perangkat agar perubahan zona waktu/DST ditangani dengan benar saat jadwal
dibuat ulang.

## Laporan dan ekspor CSV

Tab **Laporan** menghitung ringkasan langsung dari riwayat transaksi lokal.
Filter yang tersedia:

- 7 hari terakhir, bulan berjalan, tahun berjalan, atau rentang tanggal khusus.
- Semua target atau satu target.
- Semua transaksi, setoran saja, atau penarikan saja.

Laporan menampilkan total setoran, total penarikan, perubahan bersih, rata-rata
setoran, progres target saat ini, hari dengan jumlah setoran terbanyak, dan
perbandingan perubahan bersih terhadap rentang sebelumnya yang sama panjang.
Insight hanya menyatakan hasil hitungan tersebut dan tidak memberi penilaian
subjektif mengenai kesehatan keuangan pengguna.

Tombol **CSV** mengekspor seluruh transaksi yang cocok dengan filter, meskipun
layar hanya menampilkan 20 transaksi pertama agar tetap ringkas. Kolom CSV
mencakup tanggal, target, jenis, nominal integer Rupiah, sumber/alasan, dan
catatan. Sebelum ekspor, Pocketly:

1. Menjelaskan bahwa CSV merupakan plaintext dan dapat dibaca aplikasi lain.
2. Meminta autentikasi ulang menggunakan PIN aktif.
3. Membuat file sementara dan membuka share sheet sistem.
4. Menghapus file sementara setelah share sheet selesai.

CSV diberi UTF-8 BOM agar teks Indonesia terbaca baik di aplikasi spreadsheet,
semua field di-escape, dan nilai yang diawali `=`, `+`, `-`, atau `@`
dinetralkan untuk mencegah formula injection. Ekspor PDF belum diimplementasikan;
backup `.pocketly` tetap menjadi pilihan untuk pemindahan data yang terenkripsi.

## Privasi layar

- Android selalu mengaktifkan `FLAG_SECURE` ketika aplikasi masuk background
  agar recent apps tidak menyimpan snapshot data. Saat aplikasi aktif, flag
  tetap menyala hanya pada layar sensitif.
- iOS memasang privacy shield saat aplikasi tidak aktif sehingga app switcher
  hanya menampilkan layar Pocketly yang netral. Privacy shield juga ditampilkan
  ketika screen recording atau mirroring terdeteksi pada layar sensitif.
- iOS tidak menyediakan API resmi untuk mencegah satu screenshot statis sebelum
  gambar diambil. Pocketly tidak menggunakan trik `UITextField` tidak resmi yang
  berisiko merusak rendering dan aksesibilitas Flutter.

## Struktur penting

```text
lib/
  app/
    pocketly_app.dart
    theme/
  core/
    security/
      biometric_authenticator.dart
      biometric_preference_repository.dart
      local_auth_biometric_authenticator.dart
      pin_auth_repository.dart
      pin_credential.dart
      pin_hasher.dart
      secure_key_value_store.dart
  features/
    backup/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      presentation/
    reports/
      data/
      domain/
      presentation/
    onboarding/
    security/
    splash/
  main.dart

assets/
  branding/
    pocketly_logo.png
    pocketly_logo_splash.png

test/
  pin_auth_repository_test.dart
  pin_policy_test.dart
  widget_test.dart
```

## Menjalankan proyek

Prasyarat:

- Flutter dengan Dart `^3.9.2`.
- Android API 24 atau lebih baru.
- Untuk biometrik, gunakan perangkat fisik atau emulator yang telah dikonfigurasi biometriknya.

```powershell
flutter pub get
flutter run
```

Untuk menjalankan verifikasi:

```powershell
dart analyze lib test
flutter test
flutter build apk --debug
```

Status verifikasi terakhir:

- Analyzer: tidak ada masalah.
- Test: 62 test lulus.
- Build Android debug: berhasil.
- Build Android release dengan ProGuard SQLCipher: berhasil.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- APK release: `build/app/outputs/flutter-apk/app-release.apk`.
- Build iOS belum diverifikasi karena lingkungan pengembangan saat ini menggunakan Windows.

## Hasil QA biometrik dan secure storage Android nyata

QA dilakukan pada 17 Juli 2026 menggunakan Samsung SM-A155F dengan Android 16
(API 36). Build debug dipasang sebagai update agar persistensi credential dan
database dapat diperiksa sebelum dan sesudah pengujian.

### Lulus

- Aktivasi biometrik dan dialog native Android.
- Login menggunakan fingerprint terdaftar.
- Biometrik tidak dikenali tanpa menyebabkan crash.
- Pembatalan dialog tidak memicu prompt otomatis berulang.
- PIN tetap dapat digunakan setelah biometrik gagal, dibatalkan, temporary
  lockout, maupun permanent lockout.
- Auto-prompt biometrik tetap bekerja setelah cold restart aplikasi.
- Credential, material secure key, target, transaksi, dan database tetap
  tersedia setelah reboot perangkat.
- Android berhasil mengaktifkan temporary lockout 30 detik dan permanent
  lockout setelah terlalu banyak percobaan fingerprint yang salah.
- Permanent lockout dapat dipulihkan menggunakan credential lock screen
  perangkat, kemudian Pocketly tetap dapat dibuka dengan PIN atau fingerprint.
- Perubahan enrollment fingerprint tidak menghapus credential maupun data
  Pocketly. Fingerprint utama tetap dapat membuka aplikasi setelah fingerprint
  sementara dihapus.
- `FLAG_SECURE` menutup isi lock screen Pocketly pada hasil screenshot.
- Tidak ditemukan nilai PIN enam digit dalam bentuk plaintext pada XML secure
  storage.
- Header database tidak sama dengan header SQLite plaintext dan checksum
  credential, secure key, serta database tetap konsisten selama restart,
  reboot, lockout, dan perubahan enrollment.
- Tidak ditemukan crash, `PlatformException`, `SQLiteException`, atau
  `SecurityException` selama rangkaian QA.

### Temuan yang harus diperbaiki

- Pada Samsung SM-A155F, setelah temporary maupun permanent lockout lalu dialog
  vendor ditutup, Pocketly menerima/menampilkan status sebagai pembatalan:
  **“Autentikasi dibatalkan. Gunakan PIN atau coba lagi.”**
- Tombol **Gunakan biometrik** masih aktif setelah lockout. Perilaku yang
  diharapkan adalah pesan **“Biometrik sedang terkunci. Gunakan PIN.”** dan
  tombol biometrik dinonaktifkan untuk sesi tersebut.
- Fingerprint sementara yang baru ditambahkan sempat tidak dikenali. Log Android
  mencatat penolakan pada lapisan sensor, bukan penolakan identitas oleh
  Pocketly. Fingerprint utama tetap berhasil. Skenario enrollment baru perlu
  diulang setelah perbaikan lockout untuk memastikan hasil konsisten.

### Cakupan yang masih perlu diuji

- Perangkat Android tanpa biometrik yang tersisa/terdaftar.
- Pengujian ulang temporary dan permanent lockout setelah perbaikan.
- Seluruh matriks biometrik dan secure storage pada perangkat iOS nyata.

## Catatan build Windows lintas drive

Proyek berada di drive `D:`, sementara Pub cache berada di drive `C:`. Kotlin incremental compiler gagal membuat path relatif untuk source plugin `local_auth_android` dan menghasilkan error seperti:

```text
this and base files have different roots
```

Perbaikan permanen sudah ditambahkan ke `android/gradle.properties`:

```properties
kotlin.incremental=false
```

Konsekuensinya hanya kompilasi Kotlin sedikit lebih lambat. Runtime aplikasi tidak terpengaruh.

Jika cache lama kembali bermasalah, jalankan:

```powershell
flutter clean
flutter pub get --offline
flutter build apk --debug
```

Gunakan `--offline` hanya jika seluruh package sudah tersedia di cache lokal.

## Checklist pengujian biometrik nyata

1. Daftarkan sidik jari atau wajah di pengaturan perangkat.
2. Jalankan aplikasi dan buat PIN kuat.
3. Pada layar penawaran, tekan **Aktifkan biometrik**.
4. Verifikasi bahwa dialog native muncul.
5. Tutup lalu buka ulang aplikasi.
6. Pastikan biometrik dipicu hanya satu kali secara otomatis.
7. Batalkan dialog dan pastikan aplikasi tetap berada di lock screen.
8. Masuk menggunakan PIN setelah biometrik dibatalkan atau gagal.
9. Uji biometrik yang tidak cocok dan tombol coba lagi.
10. Uji perangkat tanpa biometrik terdaftar.
11. Uji temporary/permanent biometric lockout bila perangkat memungkinkan.

## Checklist pengujian notifikasi nyata

1. Aktifkan pengingat dan pastikan dialog izin sistem baru muncul setelah layar
   penjelasan.
2. Tolak izin dan pastikan Pocketly tetap dapat dipakai tanpa pengingat.
3. Aktifkan izin dari pengaturan sistem lalu simpan kembali pengaturan.
4. Uji ketiga tingkat privasi pada layar kunci perangkat.
5. Pastikan waktu di dalam quiet hours ditolak.
6. Uji target harian, mingguan, bulanan, fleksibel, dan pengingat tenggat.
7. Restart perangkat dan pastikan notifikasi masih terjadwal.
8. Ubah zona waktu perangkat lalu buka Pocketly untuk membuat ulang jadwal.

## Langkah berikutnya yang direkomendasikan

1. Perbaiki klasifikasi temporary/permanent biometric lockout pada perangkat
   Samsung, nonaktifkan retry biometrik selama lockout, lalu ulangi QA terkait.
2. Selesaikan QA kondisi tanpa biometrik terdaftar pada Android dan jalankan
   matriks biometrik/secure storage pada perangkat iOS nyata.
3. Tindak lanjuti keterbatasan pemulihan alarm otomatis setelah reboot pada
   Samsung; QA notifikasi lainnya sudah selesai dan dicatat di
   `docs/qa-notifications-android.md`.
4. QA share sheet untuk backup dan CSV pada Android/iOS nyata.
5. Tambahkan pengujian migrasi database serta audit keamanan pra-rilis.
6. Putuskan apakah sinkronisasi/cloud masuk fase berikutnya atau aplikasi tetap
   sepenuhnya lokal.

Untuk melanjutkan menggunakan Codex pada sesi baru, gunakan prompt singkat:

```text
Baca workflow.md dan README.md terlebih dahulu, lalu lanjutkan dari bagian
"Langkah berikutnya yang direkomendasikan" tanpa mengulang fitur yang sudah selesai.
```
