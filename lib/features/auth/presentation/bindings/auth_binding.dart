import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Already registered as permanent — skip to avoid recreating on every route.
    if (Get.isRegistered<AuthController>()) return;

    final dataSource = AuthRemoteDataSource(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      googleSignIn: GoogleSignIn(),
    );
    final repo = AuthRepositoryImpl(dataSource);

    Get.put(
      AuthController(
        signIn: SignInUseCase(repo),
        signUp: SignUpUseCase(repo),
        googleSignIn: GoogleSignInUseCase(repo),
        signOut: SignOutUseCase(repo),
        authRepository: repo,
        storage: Get.find<StorageService>(),
      ),
      permanent: true,
    );
  }
}
