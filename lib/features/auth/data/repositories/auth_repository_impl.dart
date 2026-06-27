import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);
  final AuthRemoteDataSource _dataSource;

  UserModel? _cachedUser;

  @override
  UserEntity? get currentUser => _cachedUser;

  @override
  Stream<UserEntity?> get authStateChanges =>
      _dataSource.authStateChanges.asyncMap((firebaseUser) async {
        if (firebaseUser == null) {
          _cachedUser = null;
          return null;
        }
        final user = await _dataSource.getUserById(firebaseUser.uid);
        _cachedUser = user;
        return user;
      });

  @override
  Future<UserEntity> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _cachedUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<UserEntity> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _dataSource.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _cachedUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<UserEntity?> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      _cachedUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    } catch (_) {
      throw Exception(TKeys.errorGoogleSignin.tr);
    }
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
    _cachedUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  @override
  Future<void> updateFcmToken(String uid, String token) =>
      _dataSource.updateFcmToken(uid, token);

  @override
  Future<UserEntity?> getUserById(String uid) =>
      _dataSource.getUserById(uid);

  @override
  Future<UserEntity?> fetchCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    final firebaseUser = _dataSource.currentFirebaseUser;
    if (firebaseUser == null) return null;
    _cachedUser = await _dataSource.getUserById(firebaseUser.uid);
    return _cachedUser;
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => TKeys.errorEmailInUse.tr,
      'wrong-password' || 'invalid-credential' => TKeys.errorWrongPassword.tr,
      'user-not-found' => TKeys.errorUserNotFound.tr,
      'weak-password' => TKeys.errorWeakPassword.tr,
      'invalid-email' => TKeys.errorInvalidEmail.tr,
      'operation-not-allowed' => TKeys.errorPermissionDenied.tr,
      'network-request-failed' => TKeys.errorNetwork.tr,
      _ => TKeys.errorGeneric.tr,
    };
  }
}
