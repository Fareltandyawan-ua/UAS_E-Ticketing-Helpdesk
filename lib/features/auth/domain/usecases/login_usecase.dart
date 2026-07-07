import '../auth_exceptions.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case: login user.
///
/// Business rule yang ditambahkan di sini:
/// - Cek `isActive` user → kalau false, sign out + throw [AccountDeactivatedException].
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<User> call({
    required String email,
    required String password,
  }) async {
    final user = await _repository.login(email: email, password: password);

    if (!user.isActive) {
      // Rollback session — user nonaktif tidak boleh tetap login
      await _repository.logout();
      throw const AccountDeactivatedException();
    }

    return user;
  }
}
