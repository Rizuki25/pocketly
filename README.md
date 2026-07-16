# Pocketly

Pocketly adalah aplikasi Flutter untuk mencatat dan mendampingi target tabungan pribadi. MVP bersifat **local-first**: aplikasi tidak menyimpan, menahan, atau memindahkan uang sungguhan.

Dokumen kebutuhan lengkap berada di [`workflow.md`](workflow.md). Baca `workflow.md` dan README ini sebelum melanjutkan implementasi pada sesi baru.

## Keputusan produk saat ini

- Platform awal: Android dan iOS.
- Mode MVP: lokal tanpa akun/cloud.
- Backup terenkripsi masuk cakupan MVP, tetapi belum diimplementasikan.
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
- Penanganan biometrik gagal, dibatalkan, tidak tersedia, belum terdaftar, dan lockout.
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
- Unit test dan widget test untuk alur utama.

### Belum selesai

- Backup terenkripsi sebenarnya; layar saat ini baru menjelaskan rencana fiturnya.
- Lupa PIN dan pemulihan akses mode lokal.
- Notifikasi, laporan, ekspor, serta sinkronisasi.

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
- Test: 38 test lulus.
- Build Android debug: berhasil.
- Build Android release dengan ProGuard SQLCipher: berhasil.
- APK: `build/app/outputs/flutter-apk/app-debug.apk`.
- APK release: `build/app/outputs/flutter-apk/app-release.apk`.
- Build iOS belum diverifikasi karena lingkungan pengembangan saat ini menggunakan Windows.

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

## Langkah berikutnya yang direkomendasikan

1. QA biometrik dan secure storage pada perangkat Android/iOS nyata.
2. Implementasikan lupa PIN dan pemulihan akses mode lokal.
3. Implementasikan backup lokal terenkripsi.

Untuk melanjutkan menggunakan Codex pada sesi baru, gunakan prompt singkat:

```text
Baca workflow.md dan README.md terlebih dahulu, lalu lanjutkan dari bagian
"Langkah berikutnya yang direkomendasikan" tanpa mengulang fitur yang sudah selesai.
```
