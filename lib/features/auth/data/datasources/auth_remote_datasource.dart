import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../models/user_model.dart';

/// Data source untuk semua operasi auth yang berhubungan dengan Supabase
/// (network/remote). Tidak menyentuh storage lokal.
class AuthRemoteDatasource {
  final SupabaseClient _client = SupabaseService.client;

  /// Sign in via Supabase Auth. Return [AuthResponse] supaya caller
  /// (repository) bisa ambil session token.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Sign up via Supabase Auth dengan metadata profile.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'username': username,
        'role': 'user',
      },
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _client.auth.resetPasswordForEmail(email);

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Ambil profile dari tabel `profiles` berdasarkan user id.
  Future<UserModel> fetchProfile({required String userId, String? email}) async {
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson({
      ...profile,
      if (email != null) 'email': email,
    });
  }

  String? get currentAuthEmail => _client.auth.currentUser?.email;
  String? get currentAuthUserId => _client.auth.currentUser?.id;
}
