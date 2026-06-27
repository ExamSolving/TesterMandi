import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/admob_config.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../../../testing/domain/entities/test_participation.dart';
import '../controllers/proofs_controller.dart';

class SubmitProofView extends StatelessWidget {
  const SubmitProofView({super.key, required this.participation});
  final TestParticipation participation;

  int get _dayNumber {
    final joinDate = DateTime(
      participation.joinedAt.toDate().year,
      participation.joinedAt.toDate().month,
      participation.joinedAt.toDate().day,
    );
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return (today.difference(joinDate).inDays + 1).clamp(1, 14);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProofsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        foregroundColor: isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit Proof',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              'Day $_dayNumber of 14',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AppHeader(participation: participation, isDark: isDark),
            const SizedBox(height: 24),
            _DayProgressBar(dayNumber: _dayNumber, isDark: isDark),
            const SizedBox(height: 24),
            _SectionLabel(
                text: 'Screenshots', subtitle: 'Add up to 3 screenshots', isDark: isDark),
            const SizedBox(height: 12),
            _ScreenshotPicker(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 24),
            _SectionLabel(
                text: 'Feedback',
                subtitle: 'Describe your testing experience',
                isDark: isDark),
            const SizedBox(height: 12),
            _FeedbackField(ctrl: ctrl, isDark: isDark),
            const SizedBox(height: 20),
            const BannerAdWidget(
              placement: BannerPlacement.submitProof,
              margin: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            _SubmitButton(ctrl: ctrl, participation: participation, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── App Header Card ────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.participation, required this.isDark});
  final TestParticipation participation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardDarkElevated
                  : AppColors.dividerLight,
              borderRadius: BorderRadius.circular(12),
              image: participation.iconUrl != null
                  ? DecorationImage(
                      image: NetworkImage(participation.iconUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: participation.iconUrl == null
                ? Icon(
                    Icons.android_rounded,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participation.appName,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'by ${participation.appOwnerName}',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Testing',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day Progress Bar ───────────────────────────────────────────────────────────

class _DayProgressBar extends StatelessWidget {
  const _DayProgressBar({required this.dayNumber, required this.isDark});
  final int dayNumber;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = dayNumber / 14;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Testing Progress',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$dayNumber / 14 days',
                style: TextStyle(
                  color: isDark
                      ? AppColors.primaryLight
                      : AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
      {required this.text, required this.subtitle, required this.isDark});
  final String text;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: isDark
                ? AppColors.textHintDark
                : AppColors.textHintLight,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Screenshot Picker ──────────────────────────────────────────────────────────

class _ScreenshotPicker extends StatelessWidget {
  const _ScreenshotPicker({required this.ctrl, required this.isDark});
  final ProofsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final images = ctrl.selectedImages;
      return Column(
        children: [
          if (images.isNotEmpty)
            SizedBox(
              height: 122,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 8, right: 8),
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        images[i],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => ctrl.removeImage(i),
                        child: Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.close,
                              size: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (images.length < 3)
            GestureDetector(
              onTap: ctrl.pickImages,
              child: Container(
                margin: EdgeInsets.only(top: images.isNotEmpty ? 12 : 0),
                width: double.infinity,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      images.isEmpty
                          ? 'Tap to add screenshots'
                          : 'Add more (${3 - images.length} left)',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ── Feedback TextField ─────────────────────────────────────────────────────────

class _FeedbackField extends StatelessWidget {
  const _FeedbackField({required this.ctrl, required this.isDark});
  final ProofsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl.feedbackCtrl,
      maxLines: 6,
      minLines: 4,
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText:
            'Describe what you tested today, any bugs found, or overall experience...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Submit Button ──────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton(
      {required this.ctrl,
      required this.participation,
      required this.isDark});
  final ProofsController ctrl;
  final TestParticipation participation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final submitting = ctrl.isSubmitting.value;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: submitting
              ? null
              : () async {
                  await ctrl.submitProof(participation);
                  if (AdmobConfig.showInterstitialOnProofSubmit) {
                    AdService.to.showInterstitial();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.primaryLight : AppColors.primary,
            // Keep the same active color while loading so the spinner stays
            // visible — the dark borderDark colour made the spinner invisible
            disabledBackgroundColor: isDark
                ? AppColors.primaryLight.withValues(alpha: 0.7)
                : AppColors.primary.withValues(alpha: 0.7),
            foregroundColor:
                isDark ? const Color(0xFF1E1B4B) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: submitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // In dark mode the button bg is primaryLight (light purple)
                    // so use a dark contrasting colour; in light mode use white
                    color: isDark
                        ? const Color(0xFF1E1B4B)
                        : Colors.white,
                  ),
                )
              : const Text(
                  'Submit Proof',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      );
    });
  }
}
