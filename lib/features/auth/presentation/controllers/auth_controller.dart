import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../app/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/services/notification_service.dart';

class AuthController extends GetxController {
  AuthController({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required GoogleSignInUseCase googleSignIn,
    required SignOutUseCase signOut,
    required AuthRepository authRepository,
    required StorageService storage,
  })  : _signIn = signIn,
        _signUp = signUp,
        _googleSignIn = googleSignIn,
        _signOut = signOut,
        _authRepository = authRepository,
        _storage = storage;

  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final GoogleSignInUseCase _googleSignIn;
  final SignOutUseCase _signOut;
  final AuthRepository _authRepository;
  final StorageService _storage;

  // ── State ──────────────────────────────────────────────
  final isLoading = false.obs;
  final isGoogleLoading = false.obs;
  final currentUser = Rxn<UserEntity>();

  // ── Form: Login ────────────────────────────────────────
  final loginFormKey = GlobalKey<FormState>();
  final loginEmailCtrl = TextEditingController();
  final loginPasswordCtrl = TextEditingController();

  // ── Form: Register ─────────────────────────────────────
  final registerFormKey = GlobalKey<FormState>();
  final registerNameCtrl = TextEditingController();
  final registerEmailCtrl = TextEditingController();
  final registerPasswordCtrl = TextEditingController();
  final registerConfirmCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _authRepository.currentUser;
    if (currentUser.value == null) {
      _restoreSession();
    }
    ever(currentUser, _onUserChanged);
  }

  @override
  void onClose() {
    loginEmailCtrl.dispose();
    loginPasswordCtrl.dispose();
    registerNameCtrl.dispose();
    registerEmailCtrl.dispose();
    registerPasswordCtrl.dispose();
    registerConfirmCtrl.dispose();
    super.onClose();
  }

  void _onUserChanged(UserEntity? user) {
    if (user != null) {
      _storage.saveCachedUserId(user.uid);
      Get.find<NotificationService>().uploadFcmToken(user.uid);
    } else {
      _storage.clearUserSession();
    }
  }

  Future<void> _restoreSession() async {
    try {
      final user = await _authRepository.fetchCurrentUser();
      if (user != null) currentUser.value = user;
    } catch (_) {}
  }

  // ── Login ──────────────────────────────────────────────
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final user = await _signIn(
        email: loginEmailCtrl.text.trim(),
        password: loginPasswordCtrl.text,
      );
      currentUser.value = user;
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Register ───────────────────────────────────────────
  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final user = await _signUp(
        email: registerEmailCtrl.text.trim(),
        password: registerPasswordCtrl.text,
        displayName: registerNameCtrl.text.trim(),
      );
      currentUser.value = user;
      _showSuccess(TKeys.successRegistered.tr);
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────
  Future<void> loginWithGoogle() async {
    isGoogleLoading.value = true;
    try {
      final user = await _googleSignIn();
      if (user == null) return;
      currentUser.value = user;
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _showError(e.toString());
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // ── Sign Out ───────────────────────────────────────────
  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: _LogoutDialog(),
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    await _signOut();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  void _showError(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFDC2626),
      colorText: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
      titleText: const SizedBox.shrink(),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF059669),
      colorText: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
      titleText: const SizedBox.shrink(),
    );
  }
}

// ── Premium Logout Dialog ──────────────────────────────────────────────────

class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ────────────────────────────────────────────────
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────
            Text(
              'Log Out?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),

            // ── Subtitle ─────────────────────────────────────────────
            Text(
              TKeys.profileLogoutConfirm.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── Buttons ──────────────────────────────────────────────
            Row(
              children: [
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textSecondary,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(TKeys.btnCancel.tr),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Log Out
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Log Out'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
