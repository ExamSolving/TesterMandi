import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/services/storage_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _navigate();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final storage = Get.find<StorageService>();
    final cachedId = storage.cachedUserId;
    if (cachedId == null) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.splashGradientDark
              : AppColors.splashGradientLight,
        ),
        child: Stack(
          children: [
            _buildDecorativeElements(isDark),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(isDark),
                  const SizedBox(height: 28),
                  _buildAppName(isDark),
                  const SizedBox(height: 10),
                  _buildTagline(isDark),
                ],
              ),
            ),
            _buildBottomLoader(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(bool isDark) {
    // Light mode: subtle indigo tint circles on white bg
    // Dark mode: subtle white circles on dark bg
    final circleColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.primary.withValues(alpha: 0.06);

    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child:
              Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: circleColor,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 3000.ms,
                    curve: Curves.easeInOut,
                  ),
        ),
        Positioned(
          bottom: -100,
          left: -60,
          child:
              Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? AppColors.accent.withValues(alpha: 0.08)
                          : AppColors.accent.withValues(alpha: 0.04),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 2500.ms,
                    curve: Curves.easeInOut,
                  ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark) {
    // Light mode: dark navy logo on white bg → use splash_logo.png
    // Dark mode:  white logo on dark bg     → use splash_logo_dark.png
    final logoAsset = isDark
        ? 'assets/images/splash_logo_dark.png'
        : 'assets/images/splash_logo.png';

    // Ring glow: blue in light mode, white-ish in dark mode
    final glowColor = isDark
        ? Colors.white.withValues(alpha: 0.08 + _glowController.value * 0.06)
        : AppColors.primary.withValues(
            alpha: 0.12 + _glowController.value * 0.08,
          );

    return AnimatedBuilder(
          animation: _glowController,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              Container(
                width: 188 + (_glowController.value * 14),
                height: 188 + (_glowController.value * 14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(
                            alpha: 0.08 + _glowController.value * 0.07,
                          )
                        : AppColors.primary.withValues(
                            alpha: 0.10 + _glowController.value * 0.07,
                          ),
                    width: 1.5,
                  ),
                ),
              ),
              // Mid ring
              Container(
                width: 162 + (_glowController.value * 8),
                height: 162 + (_glowController.value * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(
                            alpha: 0.12 + _glowController.value * 0.10,
                          )
                        : AppColors.secondary.withValues(
                            alpha: 0.14 + _glowController.value * 0.10,
                          ),
                    width: 1,
                  ),
                ),
              ),
              // Logo with glow shadow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 28 + (_glowController.value * 18),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: Image.asset(
              logoAsset,
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.35, 0.35),
          end: const Offset(1, 1),
          duration: 750.ms,
          curve: Curves.elasticOut,
          delay: 200.ms,
        )
        .fade(duration: 350.ms, delay: 200.ms);
  }

  Widget _buildAppName(bool isDark) {
    return Text(
          TKeys.appName.tr,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            letterSpacing: -0.5,
            height: 1,
          ),
        )
        .animate(delay: 500.ms)
        .slideY(begin: 0.4, end: 0, duration: 600.ms, curve: Curves.easeOut)
        .fade(duration: 500.ms);
  }

  Widget _buildTagline(bool isDark) {
    return Text(
          TKeys.tagline.tr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            letterSpacing: 1.5,
          ),
        )
        .animate(delay: 750.ms)
        .slideY(begin: 0.4, end: 0, duration: 600.ms, curve: Curves.easeOut)
        .fade(duration: 500.ms);
  }

  Widget _buildBottomLoader(bool isDark) {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            TKeys.splashLoading.tr,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ).animate(delay: 1000.ms).fade(duration: 600.ms),
    );
  }
}
