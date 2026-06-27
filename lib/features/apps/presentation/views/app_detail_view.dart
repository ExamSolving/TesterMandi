import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../swaps/domain/entities/swap_request.dart';
import '../../../swaps/presentation/controllers/swap_controller.dart';
import '../../../swaps/presentation/views/swap_pick_app_sheet.dart';
import '../../../testing/presentation/controllers/testing_controller.dart';
import '../../domain/entities/app_listing.dart';

class AppDetailView extends StatefulWidget {
  const AppDetailView({super.key});

  @override
  State<AppDetailView> createState() => _AppDetailViewState();
}

class _AppDetailViewState extends State<AppDetailView> {
  bool _alreadyTesting = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkParticipation();
  }

  Future<void> _checkParticipation() async {
    final app = Get.arguments as AppListing?;
    if (app == null) return;
    final result =
        await Get.find<TestingController>().isAlreadyTesting(app.id);
    if (mounted) {
      setState(() {
        _alreadyTesting = result;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Get.arguments as AppListing?;
    if (app == null) return const Scaffold(body: SizedBox.shrink());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final uid = Get.find<AuthController>().currentUser.value?.uid ?? '';
    final isOwner = app.ownerId == uid;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(app, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOwnerRow(app, isDark),
                  const SizedBox(height: 20),
                  _buildProgress(app, isDark),
                  const SizedBox(height: 20),
                  _buildInfoChips(app, isDark),
                  const SizedBox(height: 20),
                  _buildDescription(app, isDark),
                  const SizedBox(height: 28),
                  _buildActionButton(app, isDark, isOwner),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(AppListing app, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 16),
        ),
        onPressed: Get.back,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: app.iconUrl != null && app.iconUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: app.iconUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => const Icon(
                              Icons.android_rounded,
                              color: Colors.white,
                              size: 40),
                          errorWidget: (_, _, _) => const Icon(
                              Icons.android_rounded,
                              color: Colors.white,
                              size: 40),
                        )
                      : const Icon(Icons.android_rounded,
                          color: Colors.white, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  app.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  app.categoryLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerRow(AppListing app, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              app.ownerName.isNotEmpty
                  ? app.ownerName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.ownerName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                app.packageName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        _DaysChip(daysLeft: app.daysLeft),
      ],
    );
  }

  Widget _buildProgress(AppListing app, bool isDark) {
    final progress = (app.testerCount / app.testersNeeded).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                TKeys.detailTesterProgress.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                '${app.testerCount} / ${app.testersNeeded}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips(AppListing app, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoChip(
          icon: Icons.category_outlined,
          label: app.categoryLabel,
          isDark: isDark,
        ),
        _InfoChip(
          icon: Icons.schedule_rounded,
          label: '${app.daysLeft} ${TKeys.browseDaysLeft.tr}',
          isDark: isDark,
        ),
        _InfoChip(
          icon: Icons.people_outline_rounded,
          label:
              '${app.testerCount} ${TKeys.browseTesters.tr}',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildDescription(AppListing app, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          app.description,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(AppListing app, bool isDark, bool isOwner) {
    if (isOwner) {
      return _OutlinedChipButton(
        label: TKeys.detailYourApp.tr,
        icon: Icons.verified_rounded,
        color: AppColors.primary,
      );
    }

    if (_checking) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_alreadyTesting) {
      final testCtrl = Get.find<TestingController>();
      return Column(
        children: [
          _OutlinedChipButton(
            label: TKeys.detailAlreadyTesting.tr,
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => testCtrl.installApp(app.packageName),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text(
                'Install App',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    if (app.isFull) {
      return _OutlinedChipButton(
        label: TKeys.detailTestingFull.tr,
        icon: Icons.block_rounded,
        color: AppColors.textSecondaryLight,
      );
    }

    // Show "Swap Sent" if user already has a pending request for this app.
    final swapCtrl = Get.find<SwapController>();
    final hasPendingSwap = swapCtrl.sentRequests
        .any((r) => r.toAppId == app.id && r.status == SwapStatus.pending);

    if (hasPendingSwap) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top_rounded, size: 20),
          label: const Text(
            'Swap Request Sent — Awaiting Response',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            disabledForegroundColor: const Color(0xFF6366F1),
            side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _showSwapBottomSheet(app),
        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
        label: const Text(
          'Request Swap to Join Testing',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _showSwapBottomSheet(AppListing theirApp) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwapPickAppSheet(theirApp: theirApp),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.daysLeft});
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final urgent = daysLeft <= 3;
    final color = urgent ? const Color(0xFFDC2626) : const Color(0xFF059669);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '${daysLeft}d left',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedChipButton extends StatelessWidget {
  const _OutlinedChipButton(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

