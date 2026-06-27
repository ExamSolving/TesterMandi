import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/services/settings_controller.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/tm_button.dart';
import '../../../../core/widgets/tm_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(isDark, size),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.06),
                  _buildHeader(isDark),
                  const SizedBox(height: 36),
                  _buildForm(isDark),
                  const SizedBox(height: 28),
                  _buildDivider(isDark),
                  const SizedBox(height: 20),
                  _buildGoogleButton(),
                  const SizedBox(height: 32),
                  _buildRegisterLink(isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // ── Language picker (top-right) ────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: _AuthLangButton(isDark: isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark, Size size) {
    return Stack(
      children: [
        Container(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        ),
        Positioned(
          top: -size.height * 0.1,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.15,
          left: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: isDark ? 0.06 : 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'TM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              TKeys.appName.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ).animate().fade(duration: 500.ms).slideY(begin: -0.2),
        const SizedBox(height: 36),
        Text(
          TKeys.authWelcomeBack.tr,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ).animate(delay: 100.ms).fade(duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          TKeys.authLoginSubtitle.tr,
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ).animate(delay: 150.ms).fade(duration: 500.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: controller.loginFormKey,
      child: Column(
        children: [
          TMTextField(
            controller: controller.loginEmailCtrl,
            label: TKeys.labelEmail.tr,
            hint: TKeys.hintEmail.tr,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ).animate(delay: 200.ms).fade(duration: 500.ms).slideY(begin: 0.3),
          const SizedBox(height: 16),
          TMPasswordField(
            controller: controller.loginPasswordCtrl,
            label: TKeys.labelPassword.tr,
            hint: TKeys.hintPassword.tr,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: Validators.password,
            onSubmitted: (_) => controller.login(),
          ).animate(delay: 260.ms).fade(duration: 500.ms).slideY(begin: 0.3),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                TKeys.authForgotPassword.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ).animate(delay: 300.ms).fade(duration: 500.ms),
          const SizedBox(height: 24),
          Obx(() => TMButton(
                label: TKeys.btnLogin.tr,
                onPressed: controller.login,
                isLoading: controller.isLoading.value,
              )).animate(delay: 350.ms).fade(duration: 500.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    final color =
        isDark ? AppColors.textHintDark : AppColors.textHintLight;
    return Row(
      children: [
        Expanded(child: Divider(color: color, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            TKeys.authOr.tr,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    ).animate(delay: 400.ms).fade(duration: 500.ms);
  }

  Widget _buildGoogleButton() {
    return Obx(() => TMGoogleButton(
          label: TKeys.btnGoogleSignin.tr,
          onPressed: controller.loginWithGoogle,
          isLoading: controller.isGoogleLoading.value,
        )).animate(delay: 450.ms).fade(duration: 500.ms).slideY(begin: 0.3);
  }

  Widget _buildRegisterLink(bool isDark) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: TKeys.authNoAccount.tr,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.register),
                child: Text(
                  TKeys.authSignUp.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 500.ms).fade(duration: 500.ms);
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    final isDark = Get.isDarkMode;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(Get.context!).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              TKeys.authForgotPassword.tr,
              style: Theme.of(Get.context!).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              TKeys.authLoginSubtitle.tr,
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
            const SizedBox(height: 24),
            TMTextField(
              controller: emailCtrl,
              label: TKeys.labelEmail.tr,
              hint: TKeys.hintEmail.tr,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TMButton(
              label: TKeys.btnSubmit.tr,
              onPressed: () async {
                if (emailCtrl.text.isNotEmpty) {
                  Get.back();
                }
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ── Auth language picker button ───────────────────────────────────────────────

class _AuthLangButton extends StatelessWidget {
  const _AuthLangButton({required this.isDark});
  final bool isDark;

  static const _langs = [
    (code: 'en', flag: '🇬🇧', label: 'EN'),
    (code: 'hi', flag: '🇮🇳', label: 'HI'),
    (code: 'es', flag: '🇪🇸', label: 'ES'),
  ];

  String _flagFor(String code) =>
      _langs.firstWhere((l) => l.code == code, orElse: () => _langs.first).flag;

  String _labelFor(String code) =>
      _langs.firstWhere((l) => l.code == code, orElse: () => _langs.first).label;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Obx(() {
      final code = settings.locale.value;
      return GestureDetector(
        onTap: () => _showSheet(context, settings),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.cardDark.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_flagFor(code), style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                _labelFor(code),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 14,
                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
            ],
          ),
        ).animate().fade(duration: 400.ms).slideX(begin: 0.3),
      );
    });
  }

  void _showSheet(BuildContext ctx, SettingsController settings) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AuthLangSheet(settings: settings, isDark: isDark),
    );
  }
}

// ── Language selection sheet used on auth screens ─────────────────────────────

class _AuthLangSheet extends StatelessWidget {
  const _AuthLangSheet({required this.settings, required this.isDark});
  final SettingsController settings;
  final bool isDark;

  static const _langs = [
    (code: 'en', flag: '🇬🇧', native: 'English', name: 'English'),
    (code: 'hi', flag: '🇮🇳', native: 'हिंदी', name: 'Hindi'),
    (code: 'es', flag: '🇪🇸', native: 'Español', name: 'Spanish'),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.backgroundDark : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 12, 24,
        MediaQuery.of(context).viewInsets.bottom + 36,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          // Header
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.language_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TKeys.langSelectTitle.tr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    TKeys.langSelectSubtitle.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Language options
          Obx(() => Column(
            children: _langs.asMap().entries.map((entry) {
              final i = entry.key;
              final l = entry.value;
              final selected = settings.locale.value == l.code;
              return GestureDetector(
                onTap: () {
                  settings.setLocale(l.code);
                  Get.back();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: EdgeInsets.only(bottom: i < _langs.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.07)
                        : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Flag
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : (isDark ? AppColors.cardDarkElevated : Colors.white),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          boxShadow: selected
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Text(l.flag, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.native,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              ),
                            ),
                            Text(
                              l.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Selected indicator
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: selected
                            ? Container(
                                key: const ValueKey('check'),
                                width: 26, height: 26,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                              )
                            : Container(
                                key: const ValueKey('empty'),
                                width: 26, height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )),
        ],
      ),
    );
  }
}
