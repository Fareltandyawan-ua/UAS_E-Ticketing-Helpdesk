/// Exception domain-specific untuk fitur auth.
///
/// Dipakai oleh use cases untuk komunikasikan kegagalan business rule
/// (bukan exception teknis dari Supabase/HTTP).

class AccountDeactivatedException implements Exception {
  final String message;
  const AccountDeactivatedException([
    this.message =
        'Akun Anda telah dinonaktifkan. Hubungi admin untuk informasi lebih lanjut.',
  ]);

  @override
  String toString() => message;
}

class WrongCurrentPasswordException implements Exception {
  final String message;
  const WrongCurrentPasswordException([this.message = 'Password saat ini salah']);

  @override
  String toString() => message;
}

class SamePasswordException implements Exception {
  final String message;
  const SamePasswordException([
    this.message = 'Password baru harus berbeda dengan password saat ini',
  ]);

  @override
  String toString() => message;
}

class InvalidSessionException implements Exception {
  final String message;
  const InvalidSessionException([
    this.message = 'Sesi tidak valid. Silakan login ulang.',
  ]);

  @override
  String toString() => message;
}
