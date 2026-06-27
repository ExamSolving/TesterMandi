import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  SignUpUseCase(this._repository);
  final AuthRepository _repository;

  Future<UserEntity> call({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _repository.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
}
