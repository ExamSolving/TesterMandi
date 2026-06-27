import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  SignInUseCase(this._repository);
  final AuthRepository _repository;

  Future<UserEntity> call({
    required String email,
    required String password,
  }) =>
      _repository.signInWithEmailPassword(email: email, password: password);
}
