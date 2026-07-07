import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementasi konkrit AuthRepository.
///
/// Tanggung jawab: orchestrate data antara remote (Supabase) + local
/// (SecureStorage/LocalStorage). Tidak boleh kontain business rule —
/// itu di use case.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final AuthLocalDatasource _local;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required AuthLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<User> login({required String email, required String password}) async {
    final response =
        await _remote.signIn(email: email, password: password);
    if (response.user == null) {
      throw const AuthException(
        'Login gagal. Pastikan email dan password benar.',
      );
    }

    final profile = await _remote.fetchProfile(
      userId: response.user!.id,
      email: response.user!.email,
    );

    // Simpan session ke local
    await _local.saveSession(
      user: profile,
      accessToken: response.session?.accessToken,
      refreshToken: response.session?.refreshToken,
    );

    return profile;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final response = await _remote.signUp(
      email: email,
      password: password,
      name: name,
      username: username,
    );

    if (response.user == null) {
      throw const AuthException(
        'Registrasi berhasil, silakan cek email untuk verifikasi akun.',
      );
    }

    // Profile dibuat oleh SQL trigger; tunggu sebentar agar siap dibaca
    await Future.delayed(const Duration(seconds: 1));
    final profile = await _remote.fetchProfile(
      userId: response.user!.id,
      email: response.user!.email,
    );

    await _local.saveSession(
      user: profile,
      accessToken: response.session?.accessToken,
      refreshToken: response.session?.refreshToken,
    );

    return profile;
  }

  @override
  Future<void> logout() async {
    await _remote.signOut();
    await _local.clearSession();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _remote.sendPasswordResetEmail(email);

  @override
  Future<void> updatePassword(String newPassword) =>
      _remote.updatePassword(newPassword);

  @override
  Future<bool> verifyCurrentPassword(String email, String password) async {
    try {
      await _remote.signIn(email: email, password: password);
      return true;
    } on AuthException {
      return false;
    }
  }

  @override
  Future<User?> getCachedUser() => _local.getCachedUser();

  @override
  Future<User?> refreshProfile() async {
    final userId = _remote.currentAuthUserId;
    final email = _remote.currentAuthEmail;
    if (userId == null) return null;

    try {
      final profile = await _remote.fetchProfile(userId: userId, email: email);
      await _local.updateCachedUser(profile);
      return profile;
    } catch (_) {
      return null;
    }
  }

  @override
  String? getCurrentAuthEmail() => _remote.currentAuthEmail;
}
