import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/tm_button.dart';
import '../../../../core/widgets/tm_text_field.dart';
import '../controllers/auth_controller.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

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
            child: Column(
              children: [
                _buildTopBar(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildHeader(isDark),
                        const SizedBox(height: 32),
                        _buildForm(isDark, context),
                        const SizedBox(height: 28),
                        _buildDivider(isDark),
                        const SizedBox(height: 20),
                        _buildGoogleButton(),
                        const SizedBox(height: 32),
                        _buildLoginLink(isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
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
          top: -60,
          left: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: 80,
          right: -60,
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

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TKeys.authCreateAccount.tr,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ).animate(delay: 50.ms).fade(duration: 500.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          TKeys.authRegisterSubtitle.tr,
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ).animate(delay: 100.ms).fade(duration: 500.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildForm(bool isDark, BuildContext context) {
    return Form(
      key: controller.registerFormKey,
      child: Column(
        children: [
          TMTextField(
            controller: controller.registerNameCtrl,
            label: TKeys.labelFullName.tr,
            hint: TKeys.hintFullName.tr,
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: Validators.name,
          ).animate(delay: 150.ms).fade(duration: 500.ms).slideY(begin: 0.3),
          const SizedBox(height: 16),
          TMTextField(
            controller: controller.registerEmailCtrl,
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
            controller: controller.registerPasswordCtrl,
            label: TKeys.labelPassword.tr,
            hint: TKeys.hintPassword.tr,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
          ).animate(delay: 250.ms).fade(duration: 500.ms).slideY(begin: 0.3),
          const SizedBox(height: 16),
          TMPasswordField(
            controller: controller.registerConfirmCtrl,
            label: TKeys.labelConfirmPassword.tr,
            hint: TKeys.hintConfirmPassword.tr,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.confirmPassword(
              v,
              controller.registerPasswordCtrl.text,
            ),
            onSubmitted: (_) => controller.register(),
          ).animate(delay: 300.ms).fade(duration: 500.ms).slideY(begin: 0.3),
          const SizedBox(height: 28),
          Obx(() => TMButton(
                label: TKeys.btnRegister.tr,
                onPressed: controller.register,
                isLoading: controller.isLoading.value,
              )).animate(delay: 350.ms).fade(duration: 500.ms).slideY(begin: 0.3),
          const SizedBox(height: 16),
          _buildTermsText(isDark),
        ],
      ),
    );
  }

  Widget _buildTermsText(bool isDark) {
    final mutedColor =
        isDark ? AppColors.textHintDark : AppColors.textHintLight;
    final linkColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: TKeys.authTermsPrefix.tr,
        style: TextStyle(fontSize: 12, color: mutedColor),
        children: [
          TextSpan(
            text: TKeys.authTerms.tr,
            style: TextStyle(
              color: linkColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: TKeys.authAnd.tr,
            style: TextStyle(color: mutedColor),
          ),
          TextSpan(
            text: TKeys.authPrivacy.tr,
            style: TextStyle(
              color: linkColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fade(duration: 500.ms);
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
    ).animate(delay: 450.ms).fade(duration: 500.ms);
  }

  Widget _buildGoogleButton() {
    return Obx(() => TMGoogleButton(
          label: TKeys.btnGoogleSignin.tr,
          onPressed: controller.loginWithGoogle,
          isLoading: controller.isGoogleLoading.value,
        )).animate(delay: 500.ms).fade(duration: 500.ms).slideY(begin: 0.3);
  }

  Widget _buildLoginLink(bool isDark) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: TKeys.authHaveAccount.tr,
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
                onTap: Get.back,
                child: Text(
                  TKeys.authSignIn.tr,
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
    ).animate(delay: 550.ms).fade(duration: 500.ms);
  }
}
