import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/widgets/tm_button.dart';
import '../../../../core/widgets/tm_text_field.dart';
import '../../domain/entities/app_listing.dart';
import '../controllers/apps_controller.dart';
import 'app_posted_sheet.dart';

// ── Country / Language data ───────────────────────────────────────────────────

const _kCountries = [
  'All', 'US', 'IN', 'GB', 'CA', 'AU', 'DE', 'FR', 'JP', 'BR',
  'MX', 'KR', 'SG', 'AE', 'PK', 'NG', 'ZA', 'IT', 'ES', 'NL',
  'SE', 'NO', 'DK', 'PL', 'AR', 'TR', 'ID', 'TH', 'PH', 'MY',
  'SA', 'RU', 'PT', 'BE', 'NZ', 'FI', 'EG', 'VN', 'BD', 'CO',
];

const _kLanguages = [
  'English', 'Hindi', 'Spanish', 'French', 'German', 'Portuguese',
  'Japanese', 'Korean', 'Arabic', 'Italian', 'Russian', 'Dutch',
  'Turkish', 'Polish', 'Swedish', 'Chinese', 'Bengali', 'Urdu',
  'Indonesian', 'Malay', 'Thai', 'Vietnamese', 'Filipino',
];

const _kAndroidLevels = [
  'Android 5.0 (API 21)', 'Android 6.0 (API 23)', 'Android 7.0 (API 24)',
  'Android 8.0 (API 26)', 'Android 9.0 (API 28)', 'Android 10 (API 29)',
  'Android 11 (API 30)', 'Android 12 (API 31)', 'Android 13 (API 33)',
  'Android 14 (API 34)',
];

const _kStepLabels = ['Package', 'Details', 'Submit'];

// ── Main View ─────────────────────────────────────────────────────────────────

class AddAppView extends StatefulWidget {
  const AddAppView({super.key});

  @override
  State<AddAppView> createState() => _AddAppViewState();
}

class _AddAppViewState extends State<AddAppView> {
  late final AppsController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<AppsController>();
    // Always start clean — handles both fresh opens and back-navigation returns.
    ctrl.resetAddAppForm();
  }

  @override
  void dispose() {
    ctrl.resetAddAppForm();
    super.dispose();
  }

  void _showTestingGuide(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TestingGuideSheet(isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          TKeys.addAppTitle.tr,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        leading: Obx(() => ctrl.currentStep.value > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: ctrl.prevStep,
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: Get.back,
              )),
        actions: [
          IconButton(
            tooltip: TKeys.testingGuideTitle.tr,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
            ),
            onPressed: () => _showTestingGuide(context, isDark),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _StepProgressBar(ctrl: ctrl, isDark: isDark),
          Expanded(
            child: Form(
              key: ctrl.formKey,
              child: Obx(() {
                final step = ctrl.currentStep.value;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  layoutBuilder: (child, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, ?child],
                  ),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: anim,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(step),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      child: step == 0
                          ? _PackageStep(ctrl: ctrl, isDark: isDark)
                          : step == 1
                              ? _DetailsStep(ctrl: ctrl, isDark: isDark)
                              : _SetupStep(ctrl: ctrl, isDark: isDark),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomNavRow(ctrl: ctrl, isDark: isDark),
    );
  }
}

// ── Step Progress Bar ─────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Obx(() {
        final step = ctrl.currentStep.value;
        return Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              _StepCircle(index: i, currentStep: step, isDark: isDark),
              if (i < 2)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: step > i
                          ? const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)])
                          : null,
                      color: step > i ? null : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.currentStep,
    required this.isDark,
  });
  final int index;
  final int currentStep;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final done = index < currentStep;
    final current = index == currentStep;
    final color = done
        ? const Color(0xFF059669)
        : current
            ? AppColors.primary
            : (isDark ? const Color(0xFF2D3748) : const Color(0xFFCBD5E1));
    final labelColor = done
        ? const Color(0xFF059669)
        : current
            ? AppColors.primary
            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: current
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: (current || done) ? Colors.white : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _kStepLabels[index],
          style: TextStyle(
            fontSize: 10,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            color: labelColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNavRow extends StatelessWidget {
  const _BottomNavRow({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Obx(() {
        final step = ctrl.currentStep.value;
        final isLast = step == 2;
        final nextBlocked = step == 0 && ctrl.packageAlreadyListed.value;
        return Row(
          children: [
            if (step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: ctrl.prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            if (step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: isLast
                  ? Obx(() => TMButton(
                        label: TKeys.addAppSubmit.tr,
                        isLoading: ctrl.isLoading.value,
                        onPressed: ctrl.groupConfirmed.value
                            ? () async {
                                final name = await ctrl.submitApp();
                                if (name != null) {
                                  Get.back();
                                  // ignore: use_build_context_synchronously
                                  final ctx = Get.overlayContext;
                                  if (ctx != null) {
                                    await showModalBottomSheet(
                                      context: ctx,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) =>
                                          AppPostedSheet(appName: name),
                                    );
                                  }
                                }
                              }
                            : null,
                        icon: Icons.rocket_launch_rounded,
                      ))
                  : ElevatedButton(
                      onPressed: nextBlocked ? null : () => ctrl.nextStep(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nextBlocked
                            ? (isDark ? const Color(0xFF1E2030) : const Color(0xFFE2E8F0))
                            : AppColors.primary,
                        disabledBackgroundColor: isDark
                            ? const Color(0xFF1E2030)
                            : const Color(0xFFE2E8F0),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Next: ${_kStepLabels[step + 1]}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP 1 — Package
// ══════════════════════════════════════════════════════════════════════════════

class _PackageStep extends StatelessWidget {
  const _PackageStep({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SectionLabel('Package ID', required: true, isDark: isDark),
        const SizedBox(height: 8),
        _PackageSearchRow(ctrl: ctrl, isDark: isDark),
        const SizedBox(height: 12),
        _LookupResultBanner(ctrl: ctrl),
        const SizedBox(height: 16),

        // Icon section — hidden when this package ID is already listed
        Obx(() => ctrl.packageAlreadyListed.value
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('App Icon', isDark: isDark),
                  const SizedBox(height: 8),
                  _IconPreview(ctrl: ctrl, isDark: isDark),
                  const SizedBox(height: 20),
                ],
              )),

        _SectionLabel('App Name', required: true, isDark: isDark),
        const SizedBox(height: 8),
        Obx(() => TMTextField(
              controller: ctrl.nameCtrl,
              label: '',
              hint: 'e.g. My Awesome App',
              prefixIcon: Icons.android_rounded,
              enabled: !ctrl.packageAlreadyListed.value,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? TKeys.validationRequired.tr : null,
            )),
        const SizedBox(height: 20),

        _SectionLabel('Short Description', isDark: isDark, badge: 'Optional'),
        const SizedBox(height: 8),
        Obx(() => TMTextField(
              controller: ctrl.descCtrl,
              label: '',
              hint: 'Briefly describe what your app does and what testers should focus on…',
              maxLines: 4,
              enabled: !ctrl.packageAlreadyListed.value,
            )),
        const SizedBox(height: 8),
        Obx(() {
          final failed = ctrl.lookupResult.value == false;
          final deviceFound = ctrl.deviceAppFound.value == true;
          // Don't show "fill manually" hint when it failed due to duplicate
          if (ctrl.packageAlreadyListed.value) return const SizedBox.shrink();
          if (!failed || deviceFound) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'App not found online or on device — please fill the name and description manually above.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP 2 — Details
// ══════════════════════════════════════════════════════════════════════════════

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Category', required: true, isDark: isDark),
        const SizedBox(height: 4),
        Text(
          'Select the category that best fits your app.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => _CategoryChips(
              selected: ctrl.selectedAppCategory.value,
              onSelect: (c) => ctrl.selectedAppCategory.value = c,
              isDark: isDark,
            )),
        const SizedBox(height: 24),

        _SectionLabel('Target Countries', isDark: isDark, badge: 'Optional'),
        const SizedBox(height: 4),
        Text(
          'Select all countries where you want testers from.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => _HorizontalChips(
              items: _kCountries,
              selected: ctrl.selectedCountries.toSet(),
              onTap: ctrl.toggleCountry,
              isDark: isDark,
              primaryColor: AppColors.primary,
            )),
        const SizedBox(height: 24),

        _SectionLabel('App Language', isDark: isDark, badge: 'Optional'),
        const SizedBox(height: 4),
        Text(
          'Languages your app supports.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => _HorizontalChips(
              items: _kLanguages,
              selected: ctrl.selectedLanguages.toSet(),
              onTap: ctrl.toggleLanguage,
              isDark: isDark,
              primaryColor: const Color(0xFF8B5CF6),
            )),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STEP 3 — Setup & Submit
// ══════════════════════════════════════════════════════════════════════════════

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF232345) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3D6E) : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _SetupInstructionCard(isDark: isDark),
        const SizedBox(height: 12),

        // ── Mandatory confirmation (right below the instruction card) ─────────
        Obx(() {
          final confirmed = ctrl.groupConfirmed.value;
          final activeBorder = const Color(0xFF059669);
          final borderCol = confirmed
              ? activeBorder
              : (isDark ? const Color(0xFF3A3D6E) : AppColors.borderLight);
          final bgCol = confirmed
              ? activeBorder.withValues(alpha: 0.07)
              : (isDark ? const Color(0xFF1C1E3A) : Colors.white);

          return GestureDetector(
            onTap: () => ctrl.groupConfirmed.value = !confirmed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgCol,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol, width: confirmed ? 1.5 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: confirmed ? activeBorder : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: confirmed
                            ? activeBorder
                            : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        width: 2,
                      ),
                    ),
                    child: confirmed
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I confirm both steps are done',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: confirmed
                                ? activeBorder
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '✓  I have joined the platform tester group\n'
                          '✓  I have added the group email to my Play Console closed testing',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        if (!confirmed) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Required before submitting your app',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),

        // ── Testing metadata ─────────────────────────────────────────────────
        _SectionCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Latest Version', isDark: isDark, badge: 'Optional'),
              const SizedBox(height: 8),
              TMTextField(
                controller: ctrl.latestVersionCtrl,
                label: '',
                hint: 'e.g. 1.0.3',
                prefixIcon: Icons.new_releases_outlined,
              ),
              const SizedBox(height: 20),

              _SectionLabel('Minimum Android Level', isDark: isDark, badge: 'Optional'),
              const SizedBox(height: 8),
              Obx(() => _DropdownField(
                    value: ctrl.selectedMinAndroid.value,
                    items: _kAndroidLevels,
                    hint: 'Select minimum Android version',
                    icon: Icons.android_rounded,
                    isDark: isDark,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    onChanged: (v) => ctrl.selectedMinAndroid.value = v,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Tester Group Link', isDark: isDark, badge: 'Optional'),
              const SizedBox(height: 4),
              Text(
                'Your Play Store opt-in link for closed testing.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
              ),
              const SizedBox(height: 8),
              TMTextField(
                controller: ctrl.optInCtrl,
                label: '',
                hint: 'https://groups.google.com/g/your',
                prefixIcon: Icons.group_add_rounded,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),

              _SectionLabel('Testing Instructions', isDark: isDark, badge: 'Optional'),
              const SizedBox(height: 4),
              Text(
                'Tell testers what to focus on, known issues, or how to report bugs.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                ),
              ),
              const SizedBox(height: 8),
              TMTextField(
                controller: ctrl.testingInstructionsCtrl,
                label: '',
                hint: 'e.g. Test the login flow and report any crashes on the home screen…',
                maxLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SectionCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('Testers Needed', required: true, isDark: isDark),
              const SizedBox(height: 8),
              Obx(() => _TestersSlider(
                    value: ctrl.testersNeeded.value,
                    onChange: (v) => ctrl.testersNeeded.value = v,
                    isDark: isDark,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(
    this.text, {
    this.required = false,
    this.badge,
    required this.isDark,
  });
  final String text;
  final bool required;
  final String? badge;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            letterSpacing: 0.2,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 14),
          ),
        if (badge != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge!,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E3A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3D6E) : AppColors.borderLight),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: child,
    );
  }
}

// ── Horizontal multi-select chips ─────────────────────────────────────────────

class _HorizontalChips extends StatelessWidget {
  const _HorizontalChips({
    required this.items,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
  });
  final List<String> items;
  final Set<String> selected;
  final void Function(String) onTap;
  final bool isDark;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = items[i];
          final isSelected = selected.contains(item);
          return GestureDetector(
            onTap: () => onTap(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.onChanged,
  });
  final String? value;
  final List<String> items;
  final String hint;
  final IconData icon;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textHintDark : AppColors.textHintLight)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor),
          dropdownColor: cardColor,
          style: TextStyle(fontSize: 14, color: textColor),
          items: items
              .map((l) => DropdownMenuItem(value: l, child: Text(l, style: TextStyle(color: textColor))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PACKAGE SEARCH ROW (StatefulWidget — uses GetX Worker to avoid Obx in Row)
// ══════════════════════════════════════════════════════════════════════════════

class _PackageSearchRow extends StatefulWidget {
  const _PackageSearchRow({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  State<_PackageSearchRow> createState() => _PackageSearchRowState();
}

class _PackageSearchRowState extends State<_PackageSearchRow> {
  bool _loading = false;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    _worker = ever(widget.ctrl.isLookingUp, (val) {
      if (mounted) setState(() => _loading = val);
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final isDark = widget.isDark;
    final cardColor = isDark ? const Color(0xFF232345) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3D6E) : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: ctrl.packageCtrl,
            keyboardType: TextInputType.url,
            style: TextStyle(color: textColor, fontSize: 14),
            onFieldSubmitted: (_) => ctrl.lookupAppDetails(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return TKeys.validationRequired.tr;
              if (!v.contains('.')) return TKeys.validationUrlInvalid.tr;
              return null;
            },
            decoration: InputDecoration(
              hintText: 'e.g. com.example.myapp',
              hintStyle: TextStyle(color: hintColor, fontSize: 13),
              prefixIcon: Icon(Icons.code_rounded, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDC2626))),
              focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          width: 100,
          child: ElevatedButton(
            onPressed: _loading ? null : ctrl.lookupAppDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFF334155),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_rounded, size: 18),
                      SizedBox(width: 5),
                      Text('Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LOOKUP RESULT BANNER
// ══════════════════════════════════════════════════════════════════════════════

class _LookupResultBanner extends StatelessWidget {
  const _LookupResultBanner({required this.ctrl});
  final AppsController ctrl;

  Widget _banner({
    required Color color,
    required Color textColor,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: textColor, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final result = ctrl.lookupResult.value;
      final isChecking = ctrl.isCheckingDevice.value;

      // ── Duplicate package ──────────────────────────────────────────────────
      if (ctrl.packageAlreadyListed.value) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Package already listed',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'This app is already on TesterMandi. Each package ID can only be listed once.',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        ctrl.packageCtrl.clear();
                        ctrl.packageAlreadyListed.value = false;
                        ctrl.lookupResult.value = null;
                      },
                      child: const Text(
                        'Clear and try a different package',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFDC2626),
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

      // Checking device…
      if (isChecking) {
        return _banner(
          color: AppColors.primary,
          textColor: AppColors.primary,
          icon: Icons.phone_android_rounded,
          title: 'Checking device…',
          subtitle: 'Looking for the app installed on this device.',
        );
      }

      if (result == null) return const SizedBox.shrink();

      // Found on public Play Store
      if (result == true && ctrl.fetchedIsPublic.value) {
        final hasIcon = ctrl.fetchedIconUrl.value != null;
        return _banner(
          color: const Color(0xFF059669),
          textColor: const Color(0xFF047857),
          icon: Icons.check_circle_rounded,
          title: 'App details fetched from Play Store ✓',
          subtitle: 'Name, description${hasIcon ? ", and icon" : ""} filled in — review and edit if needed.',
        );
      }

      // Found only on device
      if (result == true && ctrl.deviceAppFound.value == true) {
        return _banner(
          color: const Color(0xFF0EA5E9),
          textColor: const Color(0xFF0369A1),
          icon: Icons.phone_android_rounded,
          title: 'App found on your device ✓',
          subtitle: 'Name filled from installed app. Icon and description not available — please enter them manually.',
        );
      }

      // Found via testing/apkcombo
      if (result == true && !ctrl.fetchedIsPublic.value) {
        final hasIcon = ctrl.fetchedIconUrl.value != null;
        return _banner(
          color: const Color(0xFF0EA5E9),
          textColor: const Color(0xFF0369A1),
          icon: Icons.science_outlined,
          title: 'Closed testing app found ✓',
          subtitle: 'Name${hasIcon ? " and icon" : ""} fetched — please enter a description manually.',
        );
      }

      // Nothing found anywhere
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App not found',
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Not found on Play Store or this device. Fill in the details manually below.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: ctrl.lookupAppDetails,
                    child: const Text('Try again', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DASHED BORDER PAINTER
// ══════════════════════════════════════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.6,
    this.radius = 16.0,
  });
  final Color color;
  final double strokeWidth;
  final double radius;

  static const double _dash = 7.0;
  static const double _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final source = Path()..addRRect(rrect);

    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? _dash : _gap;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, (distance + len).clamp(0, metric.length)),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dest, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}

// ══════════════════════════════════════════════════════════════════════════════
// ICON PREVIEW
// ══════════════════════════════════════════════════════════════════════════════

class _IconPreview extends StatelessWidget {
  const _IconPreview({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  void _clearIcon() {
    ctrl.fetchedIconUrl.value = null;
    ctrl.pickedIconFile.value = null;
    ctrl.iconFetchFailed.value = false;
    ctrl.manualIconUrlCtrl.clear();
  }

  Widget _netImageThumb(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          placeholder: (_, _) => _thumb(),
          errorWidget: (_, _, _) => _thumb(),
        ),
      );

  Widget _thumb() => Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.android_rounded, color: Colors.white, size: 30),
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isFetching = ctrl.isFetchingIcon.value;
      final iconUrl = ctrl.fetchedIconUrl.value;
      final pickedFile = ctrl.pickedIconFile.value;
      final hasSearched = ctrl.lookupResult.value != null;

      // ── Fetching spinner ───────────────────────────────────────────────────
      if (isFetching) {
        return _DashedBox(
          isDark: isDark,
          locked: false,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary)),
              SizedBox(width: 10),
              Text('Fetching icon…',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ],
          ),
        );
      }

      // ── Local file picked ──────────────────────────────────────────────────
      if (pickedFile != null) {
        return _ResolvedIconRow(
          image: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(File(pickedFile.path),
                width: 64, height: 64, fit: BoxFit.cover),
          ),
          label: 'Icon uploaded from gallery ✓',
          source: 'Gallery · tap to change',
          isDark: isDark,
          onClear: _clearIcon,
          onTap: ctrl.pickIconFromGallery,
        );
      }

      // ── Network URL resolved ───────────────────────────────────────────────
      if (iconUrl != null) {
        return _ResolvedIconRow(
          image: _netImageThumb(iconUrl),
          label: 'App icon fetched ✓',
          source: 'Play Store',
          isDark: isDark,
          onClear: _clearIcon,
          onTap: null,
        );
      }

      // ── Locked: not yet searched ───────────────────────────────────────────
      if (!hasSearched) {
        return _DashedBox(
          isDark: isDark,
          locked: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    size: 22,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              ),
              const SizedBox(height: 8),
              Text(
                'Search a package ID first',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Icon options unlock after search',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        );
      }

      // ── Active: searched but no icon found ─────────────────────────────────
      return _ActiveUploadZone(ctrl: ctrl, isDark: isDark);
    });
  }
}

// ── Dashed box container ──────────────────────────────────────────────────────

class _DashedBox extends StatelessWidget {
  const _DashedBox({
    required this.isDark,
    required this.locked,
    required this.child,
  });
  final bool isDark;
  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor = locked
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
        : AppColors.primary.withValues(alpha: 0.35);
    final bgColor = locked
        ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA))
        : AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.03);

    return CustomPaint(
      painter: _DashedBorderPainter(color: borderColor, radius: 16),
      child: Container(
        width: double.infinity,
        height: 108,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Active upload zone (dotted rectangle + both options) ──────────────────────

class _ActiveUploadZone extends StatelessWidget {
  const _ActiveUploadZone({required this.ctrl, required this.isDark});
  final AppsController ctrl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF232345) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3D6E) : AppColors.borderLight;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHintLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final dividerColor = isDark ? const Color(0xFF2D2F52) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Dotted upload zone ─────────────────────────────────────────────
        GestureDetector(
          onTap: ctrl.pickIconFromGallery,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: AppColors.primary.withValues(alpha: 0.5),
              radius: 16,
              strokeWidth: 1.8,
            ),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.05 : 0.03),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_rounded,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload app icon',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'JPG or PNG  ·  Max 512 × 512',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── OR divider ─────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(child: Divider(color: dividerColor, thickness: 1)),
          ],
        ),
        const SizedBox(height: 14),

        // ── URL field ──────────────────────────────────────────────────────
        TextFormField(
          controller: ctrl.manualIconUrlCtrl,
          keyboardType: TextInputType.url,
          style: TextStyle(color: textColor, fontSize: 13),
          onChanged: (url) {
            final t = url.trim();
            if (t.startsWith('http')) {
              ctrl.fetchedIconUrl.value = t;
              ctrl.pickedIconFile.value = null;
            } else {
              ctrl.fetchedIconUrl.value = null;
            }
          },
          decoration: InputDecoration(
            hintText: 'Enter icon URL  (https://…)',
            hintStyle: TextStyle(color: hintColor, fontSize: 12),
            prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

// ── Resolved icon row (shown once an icon is set from either source) ──────────

class _ResolvedIconRow extends StatelessWidget {
  const _ResolvedIconRow({
    required this.image,
    required this.label,
    required this.source,
    required this.isDark,
    required this.onClear,
    this.onTap,
  });
  final Widget image;
  final String label;
  final String source;
  final bool isDark;
  final VoidCallback onClear;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Tapping the thumbnail re-triggers the picker (if gallery source)
        GestureDetector(onTap: onTap, child: image),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 12, color: Color(0xFF059669)),
                  const SizedBox(width: 4),
                  Text(source,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight)),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CATEGORY CHIPS (single-select horizontal scroll)
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelect, required this.isDark});
  final AppCategory? selected;
  final void Function(AppCategory) onSelect;
  final bool isDark;

  static const _accent = Color(0xFFEA580C); // orange-600

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = AppCategory.values[i];
          final isSelected = selected != null && cat == selected;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? _accent
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
              ),
              child: Text(
                cat.categoryLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TESTERS SLIDER
// ══════════════════════════════════════════════════════════════════════════════

class _TestersSlider extends StatelessWidget {
  const _TestersSlider({required this.value, required this.onChange, required this.isDark});
  final int value;
  final void Function(int) onChange;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$value testers',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Max 100',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: AppColors.primary,
          inactiveColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
          onChanged: (v) => onChange(v.round()),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SETUP INSTRUCTION CARD
// ══════════════════════════════════════════════════════════════════════════════

class _SetupInstructionCard extends StatelessWidget {
  const _SetupInstructionCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1C1E3A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3D6E) : AppColors.borderLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.groups_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Tester Group',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Required for closed testing to work',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.textHintDark : AppColors.textHintLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Step(
            num: '1',
            title: 'Testers join once',
            description: 'Share this link with your testers — they join one time and can test all apps on the platform:',
            highlight: AppConstants.platformGroupUrl,
            isDark: isDark,
            isLink: true,
          ),
          const SizedBox(height: 12),
          _Step(
            num: '2',
            title: 'Add the group to your Play Console',
            description: 'In Play Console → Testing → Closed testing → Testers, add this email as a tester group:',
            highlight: AppConstants.platformGroupEmail,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TESTING GUIDE SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _TestingGuideSheet extends StatelessWidget {
  const _TestingGuideSheet({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.science_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          TKeys.testingGuideTitle.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          TKeys.testingGuideSubtitle.tr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Sections ──────────────────────────────────────────────
                  _GuideSection(
                    icon: Icons.timer_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: TKeys.testingGuideWindowTitle.tr,
                    bullets: [
                      TKeys.testingGuideWindow1.tr,
                      TKeys.testingGuideWindow2.tr,
                      TKeys.testingGuideWindow3.tr,
                    ],
                    cardBg: cardBg,
                    border: border,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _GuideSection(
                    icon: Icons.pause_circle_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: TKeys.testingGuideEndsTitle.tr,
                    bullets: [
                      TKeys.testingGuideEnds1.tr,
                      TKeys.testingGuideEnds2.tr,
                      TKeys.testingGuideEnds3.tr,
                    ],
                    cardBg: cardBg,
                    border: border,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _GuideSection(
                    icon: Icons.photo_camera_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: TKeys.testingGuideProofsTitle.tr,
                    bullets: [
                      TKeys.testingGuideProofs1.tr,
                      TKeys.testingGuideProofs2.tr,
                      TKeys.testingGuideProofs3.tr,
                    ],
                    cardBg: cardBg,
                    border: border,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _GuideSection(
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    title: TKeys.testingGuidePrivacyTitle.tr,
                    bullets: [
                      TKeys.testingGuidePrivacy1.tr,
                      TKeys.testingGuidePrivacy2.tr,
                      TKeys.testingGuidePrivacy3.tr,
                    ],
                    cardBg: cardBg,
                    border: border,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _GuideSection(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFF472B6),
                    title: TKeys.testingGuideRemTitle.tr,
                    bullets: [
                      TKeys.testingGuideRem1.tr,
                      TKeys.testingGuideRem2.tr,
                      TKeys.testingGuideRem3.tr,
                    ],
                    cardBg: cardBg,
                    border: border,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  _GuideSection(
                    icon: Icons.rocket_launch_rounded,
                    iconColor: const Color(0xFF34D399),
                    title: TKeys.testingGuideNextTitle.tr,
                    bullets: [
                      TKeys.testingGuideNext1.tr,
                      TKeys.testingGuideNext2.tr,
                      TKeys.testingGuideNext3.tr,
                    ],
                    cardBg: cardBg,
                    border: border,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 28),

                  // ── Got It button ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        TKeys.testingGuideGotIt.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single guide section card ─────────────────────────────────────────────────

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.bullets,
    required this.cardBg,
    required this.border,
    required this.isDark,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> bullets;
  final Color cardBg;
  final Color border;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bullet points
          ...bullets.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatefulWidget {
  const _Step({
    required this.num,
    required this.title,
    required this.description,
    required this.isDark,
    this.highlight,
    this.isLink = false,
  });
  final String num;
  final String title;
  final String description;
  final bool isDark;
  final String? highlight;
  final bool isLink;

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  bool _copied = false;

  Future<void> _handleTap() async {
    if (widget.highlight == null) return;
    if (widget.isLink) {
      await launchUrl(Uri.parse(widget.highlight!), mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: widget.highlight!));
      if (!mounted) return;
      setState(() => _copied = true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(widget.num,
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              if (widget.highlight != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _handleTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: _copied
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _copied
                            ? const Color(0xFF059669)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.highlight!,
                            style: TextStyle(
                              color: _copied
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF7DD3FC),
                              fontSize: 12,
                              fontFamily: 'monospace',
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        widget.isLink
                            ? const Icon(Icons.open_in_new_rounded,
                                key: ValueKey('open'),
                                size: 15,
                                color: Color(0xFF818CF8))
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: _copied
                                    ? const Icon(Icons.check_rounded,
                                        key: ValueKey('check'),
                                        size: 15,
                                        color: Color(0xFF34D399))
                                    : Icon(Icons.copy_rounded,
                                        key: const ValueKey('copy'),
                                        size: 15,
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8)),
                              ),
                      ],
                    ),
                  ),
                ),
                if (_copied && !widget.isLink)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Copied to clipboard',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF34D399),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
