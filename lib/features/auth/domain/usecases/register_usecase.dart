import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<User> call({
    required String email,
    required String password,
    required String name,
    required String username,
  }) {
    return _repository.register(
      email: email,
      password: password,
      name: name,
      username: username,
    );
  }
}
