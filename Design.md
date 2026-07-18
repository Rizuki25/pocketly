# Pocketly UI Design Specification

Dokumen ini adalah sumber acuan desain UI/UX Pocketly untuk desainer manusia
dan AI pembuat UI. Gunakan dokumen ini bersama `README.md` dan `workflow.md`.
Dokumen ini menjelaskan tampilan, isi, perilaku, state, dan batasan produk yang
sudah ada. AI boleh meningkatkan kualitas visual, tetapi tidak boleh menghapus
fungsi, validasi, privasi, atau alur keamanan yang disebutkan di sini.

## 1. Ringkasan produk

Pocketly adalah aplikasi pencatat dan pendamping target tabungan pribadi untuk
Android dan iOS. Pocketly bukan bank, dompet digital, atau aplikasi investasi.
Aplikasi tidak menyimpan dan tidak memindahkan uang sungguhan; pengguna hanya
mencatat uang yang tetap berada di rekening, e-wallet, tunai, atau tempat lain
milik pengguna.

Karakter produk:

- Local-first dan dapat digunakan tanpa internet.
- Privat, aman, tenang, dan tidak menghakimi.
- Membantu pengguna membangun kebiasaan melalui langkah kecil.
- Menggunakan bahasa Indonesia yang ramah dan langsung.
- Menampilkan data finansial secara jelas tanpa terasa seperti aplikasi bank
  korporat yang kaku.

Target kesan visual:

- Modern, premium, friendly, clean, dan ringan.
- Optimistis tanpa terlihat kekanak-kanakan.
- Banyak ruang putih, hierarki kuat, dan interaksi mudah dijangkau satu tangan.
- Bentuk lembut dan rounded dipadukan dengan tipografi display yang berkarakter.
- Ungu menjadi identitas utama, bukan memenuhi semua permukaan.

## 2. Prinsip desain

1. **Satu fokus utama per layar.** CTA utama harus langsung terlihat.
2. **Mendukung, bukan menghakimi.** Gunakan kata “belum”, “coba lagi”, atau
   “sesuaikan rencana”; hindari bahasa yang menyalahkan pengguna.
3. **Privasi terlihat sebagai manfaat.** Jelaskan bahwa data lokal dan backup
   terenkripsi melindungi pengguna, bukan sebagai peringatan teknis yang menakutkan.
4. **Progress terasa memotivasi.** Tampilkan kemajuan dengan bar, ring, angka,
   milestone, dan pesan singkat yang positif.
5. **Keamanan tidak boleh membingungkan.** PIN selalu menjadi fallback biometrik.
6. **Nominal mudah dipindai.** Gunakan tabular figures dan format Rupiah Indonesia.
7. **Aksi destruktif tidak dominan.** Hapus/reset memakai dialog konfirmasi dan
   warna bahaya hanya saat diperlukan.
8. **Semua state didesain.** Loading, empty, error, disabled, success, offline,
   archived, completed, dan locked tidak boleh menjadi tampilan seadanya.

## 3. Identitas visual

### 3.1 Logo dan aset

- Logo utama: `assets/branding/pocketly_logo.png`.
- Logo splash: `assets/branding/pocketly_logo_splash.png`.
- Wordmark selalu ditulis lowercase: **pocketly**.
- Tagline splash: **grow at your own pace**.
- Jangan menggambar ulang logo dengan ikon generik.
- Berikan clear space minimal setara setengah tinggi logo.

### 3.2 Palet warna inti

| Token | Nilai | Penggunaan |
|---|---:|---|
| `primary` | `#9A6AFF` | CTA, progress, icon aktif, highlight |
| `primary-dark` | `#7D4FE3` | pressed state, gradient, kontras |
| `primary-light` | `#F3EDFF` | surface lembut, icon container |
| `background` | `#FFFFFF` | background utama dan card |
| `background-soft` | `#F8F7FC` | form, detail, sheet section |
| `ink` | `#1E2029` | judul dan teks utama |
| `text-secondary` | `#71809B` | deskripsi, metadata |
| `muted` | `#E3E3E3` | border dan divider |
| `success` | `#257A4B` | setoran dan status berhasil |
| `danger` | `#E84C62` | penarikan, error, aksi destruktif |
| `warning` | `#E49A35` | tenggat dekat dan perhatian |

Aturan warna:

- Gunakan ungu paling kuat untuk CTA, progress, prioritas, dan selected state.
- Card biasa tetap putih agar card prioritas benar-benar menonjol.
- Warna hijau dan merah tidak boleh menjadi satu-satunya pembeda; sertakan ikon,
  label, atau tanda plus/minus.
- Teks utama harus memiliki kontras tinggi di atas background.
- Jangan menampilkan seluruh layar dengan gradient ungu kecuali momen singkat
  seperti hero card atau success celebration.

### 3.3 Tipografi

Sistem saat ini memakai sans-serif sistem. Halaman Target memakai serif display
untuk judul dan nama target agar terasa editorial dan premium.

Rekomendasi pasangan font untuk desain AI:

- Sans-serif UI: **Inter**, **Plus Jakarta Sans**, atau **Manrope**.
- Serif display: **DM Serif Display**, **Lora**, atau **Playfair Display**.
- Jika font eksternal tidak tersedia, gunakan system sans dan system serif.

Skala tipografi:

| Style | Ukuran | Weight | Penggunaan |
|---|---:|---:|---|
| Display | 36–40 | 800/900 | Judul halaman seperti Target |
| H1 | 30–34 | 800 | Judul utama layar |
| H2 | 22–25 | 800 | Hero card dan judul target |
| H3 | 18–20 | 700/800 | Judul section/card |
| Body large | 16 | 400/500 | Deskripsi utama |
| Body | 14 | 400/600 | Isi form dan card |
| Caption | 11–12 | 600/700 | Metadata dan kategori |
| Eyebrow | 10–12 | 800/900 | Label uppercase, letter spacing |

Aturan angka:

- Gunakan tabular figures untuk nominal, tanggal, persentase, dan PIN indicator.
- Format Rupiah: `Rp3.500.000` atau `Rp 3.500.000`, konsisten per komponen.
- Jangan memakai angka desimal untuk nominal Rupiah.

### 3.4 Spacing, shape, dan elevation

- Grid dasar: 4 px.
- Padding layar utama: 20–24 px.
- Jarak antarseksi: 18–30 px.
- Padding card: 16–24 px.
- Radius field: 16–18 px.
- Radius card biasa: 20–24 px.
- Radius hero/priority card: 26–30 px.
- Radius bottom sheet atas: 32–36 px.
- Tinggi CTA utama: 56–62 px.
- Touch target minimum: 44 × 44 px.
- Shadow lembut, blur 12–24 px, opacity rendah; hindari bayangan hitam pekat.
- Border memakai `muted` atau ungu dengan opacity rendah.

### 3.5 Ikonografi

- Gunakan Material Rounded atau set ikon rounded yang konsisten.
- Ikon utama ditempatkan di dalam container 40–54 px dengan background lavender.
- Pemetaan target yang disarankan:
  - Elektronik/laptop: laptop.
  - Dana darurat/finansial: piggy bank atau savings.
  - Liburan: flight.
  - Rumah: home.
  - Kendaraan: car.
  - Pendidikan/sertifikasi: school atau book.
  - Default: flag.
- Arah transaksi:
  - Setoran: panah masuk/down-left dan tanda `+`.
  - Penarikan: panah keluar/up-right dan tanda `−`.

### 3.6 Motion

- Durasi transisi komponen: 180–350 ms.
- Gunakan fade, scale, atau slide pendek dengan easing lembut.
- Success penyimpanan target memakai progress lalu animated check.
- Selected bottom navigation bergerak sedikit ke atas dan menampilkan dot.
- Jangan memakai animasi terus-menerus di layar finansial utama.
- Hormati reduce motion; informasi tidak boleh bergantung pada animasi.

## 4. Struktur navigasi

Navigasi utama memiliki lima bagian:

1. **Beranda** — ikon home.
2. **Target** — ikon flag.
3. **Tambah** — tombol lingkaran menonjol dengan ikon savings/piggy bank.
4. **Laporan** — ikon bar chart.
5. **Profil** — ikon person.

Bottom navigation:

- Berbentuk floating rounded bar dengan notch di tengah.
- Background putih, shadow lembut, margin horizontal 16 px.
- Item aktif berwarna ungu dan memiliki indicator dot.
- Item tidak aktif abu kebiruan.
- Tombol tengah berdiameter sekitar 58 px dan berada di atas notch.
- Safe-area bawah harus dihormati.

Layar form, detail, backup, notifikasi, dan keamanan dibuka sebagai route baru
dengan app bar dan tombol kembali. Ringkasan target dibuka sebagai modal bottom
sheet di atas daftar Target.

## 5. Komponen global

### 5.1 Header halaman

- Optional eyebrow **POCKETLY** berwarna ungu.
- Judul besar rata kiri.
- Optional action di kanan: tambah, refresh, edit, atau notifikasi.
- Subjudul maksimal dua baris dan memakai warna secondary.

### 5.2 Tombol

- **Primary filled:** ungu, label tebal, radius 18–20 px.
- **Secondary outlined:** background putih, border muted/ungu lembut.
- **Tonal:** lavender, untuk aksi pendukung seperti ekspor.
- **Text button:** batal, nanti, atau aksi tersier.
- **Danger:** hanya untuk konfirmasi hapus/reset.
- Loading button menampilkan spinner kecil dan menonaktifkan ketukan ulang.

### 5.3 Form field

- Filled background `background-soft` atau putih.
- Border 1 px, radius 18 px, focus border ungu 1.5–2 px.
- Prefix icon ungu.
- Label tetap terbaca setelah field terisi.
- Error merah dengan pesan tindakan berikutnya.
- Nominal memiliki prefix `Rp` dan formatter ribuan otomatis.

### 5.4 Surface card

- Background putih, border tipis, radius 20–24 px.
- Judul section disertai ikon dalam container lavender.
- Gunakan shadow sangat ringan hanya untuk memisahkan dari background.

### 5.5 Feedback

- Snackbar untuk hasil singkat dan undo.
- Inline error untuk validasi field dan kegagalan simpan.
- Dialog untuk konfirmasi sensitif/destruktif.
- Success modal untuk pencapaian penting.
- Loading state harus mempertahankan struktur layar agar tidak terasa melompat.

### 5.6 Empty state

- Ikon/ilustrasi dalam container lavender.
- Judul singkat, deskripsi suportif, satu CTA utama.
- Jangan hanya menampilkan tulisan “data kosong”.

## 6. Inventaris layar dan spesifikasi UI

### 6.1 Splash

Tujuan: memperkenalkan identitas dan menunggu bootstrap keamanan.

Isi:

- Logo splash Pocketly di tengah.
- Wordmark **pocketly**.
- Tagline **grow at your own pace**.
- Background bersih dan animasi masuk yang lembut.

Larangan: jangan pernah menampilkan nama target atau nominal sebelum autentikasi.

### 6.2 Onboarding — tiga halaman

Layout umum:

- Header logo dan wordmark; tombol **Lewati** di kanan.
- Artwork besar dalam surface lavender.
- Eyebrow uppercase ungu.
- Judul besar dua baris.
- Deskripsi pendukung.
- Indicator tiga halaman dan counter `1/3`.
- CTA bawah **Lanjut**; halaman terakhir **Mulai sekarang**.

Konten:

1. **TUJUANMU** — “Rencana kecil, hasil yang berarti.”
2. **PROGRESMU** — “Setiap langkah layak dirayakan.”
3. **PRIVASIMU** — “Tetap privat. Tetap milikmu.”

### 6.3 Penjelasan data lokal

Tujuan: memastikan pengguna memahami mode lokal dan pemulihan.

Isi:

- App bar/header **Data & pemulihan**.
- Hero: **Data tetap dekat denganmu.**
- Penjelasan bahwa target dan transaksi tersimpan di perangkat.
- Benefit card **Tersimpan di perangkat**.
- Benefit card **Backup terenkripsi**.
- Warning lembut bahwa kehilangan PIN dan backup dapat membuat data tidak bisa
  dipulihkan.
- CTA **Saya mengerti, lanjutkan**.

### 6.4 Pembuatan PIN

Alur dua langkah:

1. **Buat PIN 6 digit**.
2. **Ulangi PIN-mu**.

Isi:

- Progress label `LANGKAH 1 DARI 2` atau `LANGKAH 2 DARI 2`.
- Logo/brand kecil.
- Enam indicator digit yang tidak memperlihatkan angka.
- Keypad angka besar dengan tombol hapus.
- Pesan PIN lemah/mismatch/error secara inline.
- CTA **Lanjut** atau **Konfirmasi PIN**.
- Saat proses hash/simpan: loading yang jelas dan input terkunci.

Success:

- Check/lock illustration.
- **PIN berhasil dibuat!**
- Penjelasan data lokal sudah terlindungi.
- CTA **Lanjutkan**.
- Hint: **Berikutnya: aktifkan biometrik**.

### 6.5 Penawaran biometrik

Isi:

- Tombol **Nanti saja**.
- Hero fingerprint/face dalam lingkaran lavender.
- Judul **Masuk lebih cepat** bila tersedia; **PIN tetap siap** bila tidak.
- Penjelasan bahwa sidik jari/wajah diproses oleh sistem perangkat.
- CTA **Aktifkan biometrik**.
- Secondary action **Tetap gunakan PIN**.
- State: checking, available, no hardware, not enrolled, unavailable, failed,
  cancelled, temporary/permanent lockout.

Dialog biometrik harus selalu dialog native Android/iOS, bukan dialog visual
buatan aplikasi.

### 6.6 Lock screen Pocketly

Isi:

- Logo dan wordmark.
- Judul **Selamat datang kembali**.
- Instruksi **Masukkan PIN untuk membuka Pocketly.**
- Tombol **Gunakan biometrik** jika tersedia.
- Aksi **Lupa PIN?**.
- Enam indicator PIN dan keypad.
- CTA **Buka Pocketly**.
- Countdown progressive PIN lockout bila terlalu banyak PIN salah.

State biometrik:

- Tidak dikenali: tawarkan coba lagi atau PIN.
- Dibatalkan: tetap di lock screen; jangan auto-loop.
- Lockout: tampilkan **Biometrik sedang terkunci. Gunakan PIN.** dan nonaktifkan
  retry biometrik untuk sesi tersebut.
- Tidak terdaftar/tidak tersedia: sembunyikan/nonaktifkan retry dan arahkan ke PIN.

Privacy:

- Screenshot dan screen recording diblokir pada Android.
- App switcher tidak boleh menampilkan PIN atau data finansial.

### 6.7 Beranda

Header:

- Logo dan wordmark Pocketly.
- Ikon notifikasi di kanan.
- Judul **Selamat datang**.
- Copy: **Satu target kecil bisa menjadi awal yang berarti.**

State kosong:

- Illustration/icon savings.
- **Belum ada target tabungan**.
- Penjelasan singkat.
- CTA **Buat target pertama**.

State aktif:

- Hero summary lavender dengan **Total tabungan**.
- Nominal total besar.
- Badge **Target Prioritas**.
- Nama satu target prioritas.
- Progress bar.
- Secondary CTA **Target baru**.

Info card:

- Ikon lock.
- **Data tetap di perangkatmu**.
- Penjelasan penyimpanan lokal.

### 6.8 Halaman Target

Referensi visual:

- `references/card-target.png`.
- `references/card-target-biasa.png`.
- `references/sheet_dialog_target.png`.

Header:

- Eyebrow **POCKETLY**.
- Judul serif besar **Target**.
- Tombol tambah ungu di kanan.
- Segmented control **Aktif (n)** dan **Arsip (n)**.
- Pull-to-refresh.

#### Card target prioritas

- Hanya untuk target aktif dengan `priority > 0`.
- Card besar dengan gradient ungu dan radius sekitar 27 px.
- Decorative translucent circle di kanan atas.
- Icon target kiri atas.
- Badge **PRIORITAS** kanan atas.
- Nama target serif putih.
- Kategori dan frekuensi.
- Saldo sekarang dan nominal target.
- Progress bar putih.
- Ringkasan tenggat/tercapai dan persentase selesai.

#### Card target biasa

- Card putih kompak dengan border dan shadow sangat lembut.
- Icon dalam kotak lavender di kiri.
- Nama target serif gelap.
- Kategori dan frekuensi.
- Progress bar ungu tipis.
- Saldo sekarang `/` nominal target.
- Ikon more di kanan; card dapat diketuk.
- Target arsip memakai varian ini dengan warna lebih redup dan label Arsip.

#### Empty state

- Aktif kosong: **Belum ada target** + CTA **Buat target**.
- Arsip kosong: **Arsip masih kosong** tanpa CTA dominan.

### 6.9 Bottom sheet ringkasan target

Muncul setelah card target diketuk.

Isi:

- Background overlay gelap transparan.
- Sheet putih dengan radius atas sekitar 34 px dan drag handle.
- Header: icon, nama, kategori, menu kelola, dan tombol close.
- Menu: **Lihat detail**, **Ubah**, **Arsipkan/Pulihkan**, **Hapus**.
- Progress radial dengan persentase.
- Saldo terkumpul dan nominal yang masih diperlukan.
- Dua info box: **FREKUENSI** dan **TENGGAT**.
- Info box penuh: **SISTEM MENABUNG**.
- Card **CATATAN** dengan copy motivasi.
- Section **SIMULASI MENABUNG LANGSUNG**.
- Nominal rekomendasi dan CTA **Simulasi Tabung (x2)**.

Simulasi hanya preview; tidak boleh mengubah saldo atau membuat transaksi asli.

### 6.10 Form target baru/ubah target

Isi:

- App bar: **Target baru** atau **Ubah target**.
- Hero gradient: **Wujudkan rencanamu**.
- Section **Tentang target**:
  - Nama target, wajib, maksimal 60 karakter.
  - Kategori opsional.
- Section **Rencana tabungan**:
  - Nominal target.
  - Saldo awal.
  - Frekuensi: harian, mingguan, bulanan, fleksibel.
  - Tenggat opsional dengan date picker dan clear action.
  - Switch **Target prioritas**.
- Inline error.
- CTA **Simpan target** atau **Simpan perubahan**.

Validasi:

- Nama tidak boleh kosong.
- Nominal target harus lebih dari nol.
- Saldo awal tidak boleh melebihi target.
- Tenggat tidak boleh berada di masa lalu.

Dialog simpan:

- Loading progress dengan icon savings.
- Success animated check dan **Target berhasil disimpan!**.
- Failed state dan CTA kembali ke formulir.

### 6.11 Detail target

Isi:

- App bar **Detail target** + edit icon.
- Hero progress card gradient: kategori, nama, saldo/target, progress, persentase.
- CTA sejajar: **Setoran** dan **Tarik**.
- Tarik disabled jika saldo nol; kedua CTA disembunyikan untuk target arsip.
- Card **Rencana menabung** dengan rekomendasi berdasarkan kondisi.
- Card **Riwayat transaksi**.
- Card **Informasi target**: frekuensi, tenggat, prioritas.

State rencana:

- Target selesai.
- Tenggat lewat.
- Tanpa tenggat.
- Frekuensi fleksibel.
- Rekomendasi nominal per periode.

Riwayat transaksi:

- Loading, error + **Coba lagi**, atau empty.
- Tile berisi icon, jenis, tanggal, sumber/alasan, catatan, dan nominal plus/minus.
- Menu **Ubah** dan **Hapus**.
- Hapus memakai dialog; snackbar memiliki undo **Batalkan**.

### 6.12 Halaman Tambah

- Judul **Tambah**.
- Copy **Pilih hal yang ingin kamu catat.**
- Tiga action card vertikal:
  - **Target baru** — flag.
  - **Setoran** — panah masuk.
  - **Penarikan** — panah keluar.
- Masing-masing memiliki icon container, deskripsi, dan chevron.

### 6.13 Form transaksi

Mode: tambah/ubah setoran dan tambah/ubah penarikan.

Isi:

- App bar dinamis.
- Hero icon dan penjelasan sesuai jenis transaksi.
- Dropdown target.
- Input nominal Rupiah.
- Pemilih tanggal.
- Sumber dana opsional untuk setoran atau alasan opsional untuk penarikan.
- Catatan opsional, maksimal 200 karakter.
- Preview **Saldo setelah transaksi**.
- Inline error.
- CTA **Simpan transaksi** dengan loading state.

Validasi:

- Target harus dipilih.
- Nominal lebih dari nol.
- Penarikan tidak boleh melebihi saldo.
- Setoran melewati target memerlukan dialog konfirmasi.

### 6.14 Laporan

Header:

- Judul **Laporan**.
- Refresh icon.
- Penjelasan bahwa ringkasan dihitung dari riwayat lokal.

Filter card:

- Periode: 7 hari, bulan ini, tahun ini, atau rentang khusus.
- Target: semua atau satu target.
- Jenis: semua, setoran, atau penarikan.
- Tampilkan tanggal awal–akhir aktif.

Ringkasan:

- Grid 2 kolom:
  - Total setoran.
  - Total penarikan.
  - Perubahan bersih.
  - Rata-rata setoran.
- Card **Insight terukur**:
  - Progres target.
  - Hari setoran paling konsisten.
  - Perbandingan periode sebelumnya.
- Header transaksi + CTA tonal **CSV**.
- Daftar maksimal 20 transaksi di layar.
- Empty state bila filter tidak menghasilkan data.

Ekspor CSV:

- Peringatan bahwa CSV tidak terenkripsi.
- Autentikasi ulang PIN.
- Loading, berhasil, dibatalkan, dan error.

### 6.15 Profil

- Judul **Profil**.
- Info card status biometrik aktif/nonaktif.
- **Ubah PIN**.
- **Aktifkan biometrik** atau **Nonaktifkan biometrik**.
- Info card **Notifikasi privat** + **Kelola notifikasi**.
- Info card **Backup terenkripsi** + **Kelola backup**.
- Info card **Mode lokal**.

Kelompokkan menu berdasarkan Keamanan, Pengingat, dan Data agar mudah dipindai.

### 6.16 Pengaturan notifikasi

- App bar **Notifikasi**.
- Hero **Pengingat yang menjaga privasi**.
- Switch **Pengingat tabungan**.
- Dialog edukasi sebelum meminta izin sistem.
- Section **Privasi layar kunci**:
  - Lengkap termasuk nominal.
  - Sembunyikan nominal, default.
  - Pesan generik.
- Section **Jadwal**:
  - Waktu pengingat.
  - Quiet hours mulai.
  - Quiet hours selesai.
- Inline message dan CTA **Simpan pengaturan**.

State:

- Permission allowed/denied.
- Disabled settings.
- Waktu pengingat berada di dalam quiet hours.
- Saving/success/error.

### 6.17 Backup terenkripsi

- App bar **Backup terenkripsi**.
- Hero **Backup dilindungi kata sandi terpisah**.
- Warning bahwa kata sandi tidak dapat dipulihkan Pocketly.
- Card **Buat backup baru** + CTA **Buat dan simpan backup**.
- Card **Pulihkan dari file** + CTA **Pilih file backup**.
- Inline result message.

Alur backup:

- Autentikasi ulang PIN.
- Dialog buat/masukkan kata sandi backup.
- Minimal 10 karakter; konfirmasi saat membuat.
- Share sheet atau file picker sistem.
- Restore preview jumlah target dan transaksi.
- Dialog **Ganti data lokal?** sebelum restore atomik.

### 6.18 Ubah PIN dan autentikasi ulang

Ubah PIN memiliki tiga tahap:

1. Masukkan PIN saat ini.
2. Buat PIN baru.
3. Ulangi PIN baru.

Setelah sukses:

- Dialog **PIN berhasil diubah**.
- Informasi bahwa aplikasi akan dikunci.
- CTA **Kunci Pocketly**.

Autentikasi ulang untuk tindakan sensitif:

- App bar **Verifikasi keamanan**.
- Alasan tindakan ditampilkan.
- PIN indicator dan keypad.
- Error/lockout.
- CTA **Verifikasi PIN**.

### 6.19 Lupa PIN dan pemulihan

- App bar **Lupa PIN**.
- Hero **Pulihkan akses lokal**.
- Penjelasan bahwa tidak ada akun/server untuk mengirim ulang PIN.
- Tiga metode dalam card terpisah:
  - Pulihkan dengan biometrik.
  - Pulihkan file backup `.pocketly`.
  - Reset seluruh data lokal.

Reset lokal harus memakai dua tahap:

1. Dialog risiko kehilangan target, transaksi, PIN, dan pengaturan.
2. Pengguna mengetik `HAPUS`, lalu CTA **Hapus permanen**.

Warna danger hanya digunakan pada jalur reset, bukan mendominasi layar awal.

### 6.20 Buat PIN baru setelah pemulihan

- App bar **Buat PIN baru**.
- Dua tahap: atur PIN baru dan ulangi.
- Pesan bahwa data tabungan tetap tersimpan jika pemulihan berhasil.
- Error inline dan CTA dinamis.

### 6.21 Layar kegagalan penyimpanan aman/database

Sediakan layar khusus, bukan blank screen:

- Icon security/storage error.
- Judul jelas bahwa data tidak dapat dibuka dengan aman.
- Penjelasan bahwa aplikasi tidak membuat database kosong otomatis.
- Tindakan aman seperti coba lagi, pulihkan backup, atau kembali.
- Jangan menampilkan stack trace atau material kunci.

## 7. State matrix wajib

Setiap desain AI harus menyertakan state yang relevan berikut:

| Area | State wajib |
|---|---|
| Global | loading, error, offline, success, disabled |
| Target | empty, active, completed, archived, overdue, priority |
| Transaksi | deposit, withdrawal, over-target, insufficient balance |
| PIN | empty, partially filled, verifying, incorrect, timed lockout |
| Biometrik | checking, success, failed, cancelled, unavailable, not enrolled, temporary/permanent lockout |
| Notifikasi | permission unknown, allowed, denied, disabled, quiet-hours conflict |
| Backup | idle, authenticating, encrypting, sharing, cancelled, restoring, invalid file, success |
| Laporan | loading, empty filter, populated, exporting, export warning/error |

## 8. Privasi dan keamanan UI

- Jangan tampilkan data finansial sebelum autentikasi.
- PIN tidak pernah ditampilkan, disalin, disimpan, atau dikirim.
- Gunakan native biometric prompt.
- PIN selalu tersedia sebagai fallback.
- Tindakan sensitif meminta autentikasi ulang.
- CSV diberi peringatan karena plaintext.
- Backup dibedakan jelas sebagai file terenkripsi.
- Screenshot lock/PIN/security screen diblokir pada Android.
- Notification preview default menyembunyikan nominal.
- Error pengguna tidak boleh memuat kode teknis sensitif atau stack trace.

## 9. Aksesibilitas

- Semua icon-only button memiliki semantic label/tooltip.
- Touch target minimal 44 × 44 px.
- Urutan screen reader mengikuti hierarki visual.
- Keypad PIN memiliki label angka dan tombol hapus.
- Progress bar/ring memiliki label persentase tekstual.
- Informasi setoran/penarikan memakai ikon, tanda, dan label selain warna.
- Layout harus tetap terbaca pada text scaling besar.
- Bottom sheet dapat di-scroll pada layar kecil.
- Gunakan SafeArea dan hindari CTA tertutup keyboard/bottom navigation.
- Kontras teks minimum mengikuti WCAG AA.

## 10. Aturan responsif

- Prioritaskan mobile portrait 360–430 px.
- Gunakan max-width agar konten tidak terlalu melebar pada tablet.
- Grid laporan 2 kolom dapat berubah menjadi 1 kolom pada layar sempit atau
  text scaling besar.
- Tombol sejajar dapat menjadi vertikal jika label tidak muat.
- Nominal panjang memakai FittedBox atau overflow yang tetap dapat dipahami.
- Bottom sheet maksimum sekitar 88% tinggi layar dan isinya scrollable.

## 11. Yang boleh dan tidak boleh diubah AI

AI boleh:

- Meningkatkan komposisi, spacing, tipografi, ilustrasi, dan visual hierarchy.
- Membuat variasi light/dark selama light theme tetap tersedia.
- Menambahkan microinteraction yang tidak menghambat.
- Mengelompokkan informasi agar lebih mudah dipindai.
- Mengusulkan chart yang tetap berasal dari data nyata.

AI tidak boleh:

- Mengubah Pocketly menjadi bank, e-wallet, investasi, pinjaman, atau paylater.
- Menambahkan saldo rekening nyata, transfer, QR payment, atau rekomendasi investasi.
- Menghapus fallback PIN, konfirmasi, validasi, atau warning privasi.
- Menganggap cloud/account sudah tersedia.
- Menampilkan data sebelum autentikasi.
- Mengubah simulasi target menjadi transaksi asli tanpa konfirmasi pengguna.
- Menggunakan dark pattern, rasa malu, ranking kekayaan, atau copy menghakimi.
- Menghapus state loading, empty, error, archived, atau lockout.

## 12. Data contoh untuk mockup

Gunakan data realistis Indonesia:

1. **Dana Darurat 6 Bulan**
   - Kategori: Finansial.
   - Frekuensi: Bulanan.
   - Saldo: Rp15.000.000.
   - Target: Rp15.000.000.
   - Progress: 100%.
   - Prioritas: ya.

2. **Beli MacBook Pro M3**
   - Kategori: Elektronik.
   - Frekuensi: Mingguan.
   - Saldo: Rp14.500.000.
   - Target: Rp28.000.000.
   - Progress: 52%.
   - Tenggat: Oktober 2026.
   - Prioritas: ya.

3. **DP Mobil Listrik**
   - Kategori: Kendaraan.
   - Frekuensi: Bulanan.
   - Saldo: Rp25.000.000.
   - Target: Rp100.000.000.
   - Prioritas: tidak.

4. **Sertifikasi AWS Cloud**
   - Kategori: Edukasi.
   - Frekuensi: Insidental/Fleksibel.
   - Saldo: Rp2.200.000.
   - Target: Rp2.200.000.
   - Prioritas: tidak.

## 13. Master prompt untuk AI UI design

Salin prompt berikut dan tambahkan nama layar yang ingin dibuat:

```text
Design a high-fidelity mobile UI for Pocketly, an Indonesian local-first
personal savings-goal tracker. Pocketly records savings but never holds or
transfers real money. The visual personality is modern, premium, friendly,
private, calm, and motivating without being childish or judgmental.

Use a clean white/off-white background, primary purple #9A6AFF, dark ink
#1E2029, soft lavender surfaces, subtle borders, rounded 18–30 px corners,
gentle shadows, generous spacing, and Material-style rounded icons. Use a
modern sans-serif for UI and an elegant serif display font selectively for the
Target page and goal names. Rupiah amounts must be highly scannable with
tabular figures.

Preserve Pocketly's floating five-item bottom navigation: Beranda, Target,
center elevated Tambah button, Laporan, and Profil. Respect safe areas,
44 px minimum touch targets, large-text accessibility, WCAG AA contrast, and
scrollable layouts for small devices.

Keep all real product functions and states from Design.md. Do not add bank
accounts, transfers, investments, loans, paylater, cloud sync, or real-money
custody. PIN must always remain available as biometric fallback. Never show
financial data before authentication. Use native system biometric prompts.

Create the following screen/state:
[INSERT SCREEN NAME AND STATE]

Include realistic Indonesian copy and Rupiah data. Show the complete visual
hierarchy, component states, validation/feedback, and bottom navigation or app
bar where relevant. Produce a polished implementation-ready mobile design,
not a generic dashboard template.
```

## 14. Prompt khusus halaman Target

```text
Design Pocketly's Target screen using the supplied references. The header has
the purple eyebrow POCKETLY, a large editorial serif title “Target”, a purple
rounded add button, and a segmented control Aktif (count) / Arsip (count).

Only priority goals use a large purple gradient card with a PRIORITAS badge,
decorative translucent circle, white progress bar, current/target Rupiah
amounts, category, frequency, deadline, and completion percentage. Regular
goals use compact white cards with a lavender icon container, dark serif goal
name, category/frequency metadata, thin purple progress bar, current amount /
target amount, and subtle more icon. Archived goals use the regular card with
muted colors.

When a card is tapped, show a white rounded modal bottom sheet with a drag
handle, goal identity, close/menu actions, radial progress, balance and
remaining amount, frequency, deadline, recommended saving system, motivational
note, and a non-destructive saving simulation. Keep edit, detail,
archive/restore, and delete available through the management menu.

Use references/card-target.png, references/card-target-biasa.png, and
references/sheet_dialog_target.png as visual direction while preserving the
Pocketly color system, accessibility, and functionality described in
Design.md.
```

## 15. Checklist evaluasi hasil AI

Sebelum menerima desain AI, periksa:

- [ ] Brand Pocketly dan palet warna konsisten.
- [ ] Hierarki layar jelas dalam tiga detik pertama.
- [ ] CTA utama mudah ditemukan dan dijangkau.
- [ ] Tidak ada fitur bank/cloud yang belum tersedia.
- [ ] Semua data dan label menggunakan konteks Indonesia.
- [ ] Card prioritas dan card biasa mudah dibedakan.
- [ ] PIN fallback dan warning keamanan tetap ada.
- [ ] Empty/loading/error/disabled/success state disertakan.
- [ ] Kontras, touch target, text scaling, dan semantics diperhatikan.
- [ ] Desain dapat diimplementasikan di Flutter tanpa efek visual yang tidak realistis.
- [ ] Copy mendukung pengguna dan tidak menghakimi.

