import '../auth_exceptions.dart';
import '../repositories/auth_repository.dart';

/// Use case: ubah password.
///
/// Business rules:
/// - Mode normal (`isRecovery=false`): wajib [currentPassword], di-verify
///   via re-login. Password baru tidak boleh sama dengan lama.
/// - Mode recovery (`isRecovery=true`): tidak perlu [currentPassword]
///   karena session sudah diset oleh deep link recovery dari email.
class UpdatePasswordUseCase {
  final AuthRepository _repository;

  UpdatePasswordUseCase(this._repository);

  Future<void> call({
    String? currentPassword,
    required String newPassword,
    bool isRecovery = false,
  }) async {
    if (!isRecovery) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw const WrongCurrentPasswordException(
          'Password saat ini wajib diisi',
        );
      }
      final email = _repository.getCurrentAuthEmail();
      if (email == null || email.isEmpty) {
        throw const InvalidSessionException();
      }

      final valid = await _repository.verifyCurrentPassword(
        email,
        currentPassword,
      );
      if (!valid) throw const WrongCurrentPasswordException();

      if (currentPassword == newPassword) {
        throw const SamePasswordException();
      }
    }

    await _repository.updatePassword(newPassword);
  }
}
