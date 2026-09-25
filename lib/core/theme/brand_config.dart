/// ============================================================
/// KONFIGURASI BRANDING — EDIT FILE INI UNTUK KLIEN BARU
/// ============================================================
/// Cuma 2 nilai di bawah ini yang perlu diganti kalau klien mau nama
/// aplikasi yang tampil BEDA di halaman login (sebelum user login,
/// jadi tidak bisa ambil dari menu Pengaturan Gym yang butuh login).
///
/// Nama gym ASLI yang klien isi sendiri lewat menu Pengaturan Gym
/// TETAP muncul di Dashboard, invoice, dst — itu terpisah dan otomatis,
/// tidak perlu disentuh di sini.
///
/// Untuk ganti WARNA brand, edit lib/core/theme/app_theme.dart
/// (cari bagian yang ditandai "<<< BRAND KLIEN").
///
/// Untuk ganti judul tab browser & favicon, edit web/index.html
/// (tag <title> dan <link rel="icon">) — ini di luar kode Dart,
/// harus diedit manual per client build.
/// ============================================================
class BrandConfig {
  BrandConfig._();

  /// Judul besar di halaman login, sebelum user masuk.
  static const appName = 'DIEGO GYM';

  /// Sub-judul kecil di bawah nama app pada halaman login.
  static const appTagline = 'Portal khusus pengelola';
}
