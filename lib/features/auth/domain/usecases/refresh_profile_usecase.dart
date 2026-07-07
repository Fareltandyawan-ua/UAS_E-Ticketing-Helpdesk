import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RefreshProfileUseCase {
  final AuthRepository _repository;

  RefreshProfileUseCase(this._repository);

  Future<User?> call() => _repository.refreshProfile();
}
