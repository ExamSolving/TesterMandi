import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;

  Future<UserEntity> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserEntity> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserEntity?> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateFcmToken(String uid, String token);

  Future<UserEntity?> getUserById(String uid);

  Future<UserEntity?> fetchCurrentUser();
}
