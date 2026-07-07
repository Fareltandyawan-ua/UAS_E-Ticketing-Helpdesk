import 'dart:convert';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Data source untuk semua operasi auth yang menyentuh penyimpanan lokal:
/// `SecureStorage` (token sensitif) dan `LocalStorage` (user data non-sensitif).
class AuthLocalDatasource {
  /// Ambil cached user dari LocalStorage. Null jika belum ada.
  Future<UserModel?> getCachedUser() async {
    final raw = await LocalStorage.getUserData();
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Simpan user + token ke storage lokal.
  Future<void> saveSession({
    required UserModel user,
    String? accessToken,
    String? refreshToken,
  }) async {
    if (accessToken != null) await SecureStorage.saveToken(accessToken);
    if (refreshToken != null) {
      await SecureStorage.saveRefreshToken(refreshToken);
    }
    await SecureStorage.saveUserId(user.id);
    await SecureStorage.saveUserRole(user.role);
    await LocalStorage.saveUserData(jsonEncode(user.toJson()));
  }

  /// Hapus semua data session lokal.
  Future<void> clearSession() async {
    await SecureStorage.clearAll();
    await LocalStorage.clearUserData();
  }

  /// Update cache user setelah refresh profile (tanpa ganti token).
  Future<void> updateCachedUser(UserModel user) async {
    await LocalStorage.saveUserData(jsonEncode(user.toJson()));
  }
}
