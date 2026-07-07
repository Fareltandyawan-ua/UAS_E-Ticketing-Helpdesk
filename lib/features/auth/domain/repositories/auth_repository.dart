import '../entities/user.dart';

/// Kontrak repository auth — domain layer hanya bergantung ke abstract ini,
/// tidak ke Supabase atau library lain.
///
/// Implementasinya ada di `lib/features/auth/data/repositories/auth_repository_impl.dart`.
abstract class AuthRepository {
  /// Login dengan email + password. Mengembalikan User profile lengkap.
  /// Tidak melakukan validasi business rule (mis. cek isActive) —
  /// itu tanggung jawab use case.
  Future<User> login({
    required String email,
    required String password,
  });

  /// Register akun baru. Membuat profile + simpan session.
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String username,
  });

  /// Logout: hapus session di remote + local.
  Future<void> logout();

  /// Kirim email link reset password (Supabase recovery flow).
  Future<void> sendPasswordResetEmail(String email);

  /// Update password user yang sedang login. Asumsi caller (use case) sudah
  /// melakukan validasi password lama via [verifyCurrentPassword] jika perlu.
  Future<void> updatePassword(String newPassword);

  /// Verifikasi password saat ini dengan re-sign in. Return true kalau cocok.
  Future<bool> verifyCurrentPassword(String email, String password);

  /// Ambil cached user dari local storage (untuk auto-login saat app start).
  Future<User?> getCachedUser();

  /// Fetch ulang profile dari remote + update cache.
  Future<User?> refreshProfile();

  /// Email user yang sedang authenticated di Supabase (untuk re-auth).
  String? getCurrentAuthEmail();
}
