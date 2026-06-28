import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/translation_keys.dart';
import '../../../../core/services/settings_controller.dart';
import '../../../../core/widgets/tm_button.dart';
import '../../../apps/domain/entities/app_listing.dart';
import '../../../apps/presentation/controllers/apps_controller.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../proofs/domain/entities/daily_proof.dart';
import '../../../proofs/presentation/controllers/proofs_controller.dart';
import '../../../proofs/presentation/views/submit_proof_view.dart';
import '../../../swaps/domain/entities/swap_request.dart';
import '../../../swaps/presentation/controllers/swap_controller.dart';
import '../../../swaps/presentation/views/swap_accepted_sheet.dart';
import '../../../swaps/presentation/views/swap_pick_app_sheet.dart';
import '../../../testing/domain/entities/test_participation.dart';
import '../../../chat/domain/entities/chat_room.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../testing/presentation/controllers/testing_controller.dart';
import '../controllers/home_controller.dart';
import '../../../../core/config/admob_config.dart';
import '../../../../core/widgets/banner_ad_widget.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ctrl = Get.find<HomeController>();
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: ctrl.currentTabIndex.value,
          children: [
            _DashboardTab(isDark: isDark),
            _MyAppsTab(isDark: isDark),
            _BrowseTab(isDark: isDark),
            _ChatTab(isDark: isDark),
            _ProfileTab(isDark: isDark),
          ],
        ),
      ),
      floatingActionButton: Obx(() {
        // Show FAB only on Dashboard and My Apps tabs
        if (ctrl.currentTabIndex.value > 1) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          heroTag: 'post_app_fab',
          onPressed: () => Get.toNamed(AppRoutes.uploadApp),
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Post App',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        );
      }),
      bottomNavigationBar: _BottomNav(isDark: isDark),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  iconOutlined: Icons.home_outlined,
                  label: TKeys.navHome.tr,
                  index: 0,
                  current: ctrl.currentTabIndex.value,
                  isDark: isDark,
                  onTap: ctrl.changeTab,
                ),
                _NavItem(
                  icon: Icons.apps_rounded,
                  iconOutlined: Icons.apps_outlined,
                  label: TKeys.navMyApps.tr,
                  index: 1,
                  current: ctrl.currentTabIndex.value,
                  isDark: isDark,
                  onTap: ctrl.changeTab,
                ),
                _NavItem(
                  icon: Icons.explore_rounded,
                  iconOutlined: Icons.explore_outlined,
                  label: TKeys.navBrowse.tr,
                  index: 2,
                  current: ctrl.currentTabIndex.value,
                  isDark: isDark,
                  onTap: ctrl.changeTab,
                ),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  iconOutlined: Icons.chat_bubble_outline_rounded,
                  label: TKeys.navChat.tr,
                  index: 3,
                  current: ctrl.currentTabIndex.value,
                  isDark: isDark,
                  onTap: ctrl.changeTab,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  iconOutlined: Icons.person_outline_rounded,
                  label: TKeys.navProfile.tr,
                  index: 4,
                  current: ctrl.currentTabIndex.value,
                  isDark: isDark,
                  onTap: ctrl.changeTab,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashboard Tab ──────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final apps = Get.find<AppsController>();
    final testing = Get.find<TestingController>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        final proofs = Get.find<ProofsController>();
        await Future.wait([
          apps.loadAll(),
          testing.loadMyParticipations(),
          proofs.refreshAll(),
          Get.find<SwapController>().loadRequests(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(auth, apps, testing)),
          SliverToBoxAdapter(child: _buildHowItWorks()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildSwapRequestsSection()),
          SliverToBoxAdapter(child: _buildActivitySection(apps, testing)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

  Widget _buildHero(
    AuthController auth,
    AppsController apps,
    TestingController testing,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF06050F), Color(0xFF0E0D22), Color(0xFF080820)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF5B21B6), Color(0xFF3730A3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circles
          Positioned(right: -60, top: -60, child: _circle(260, 0.04)),
          Positioned(left: -30, bottom: -20, child: _circle(180, 0.03)),
          Positioned(right: 80, bottom: 50, child: _circle(60, 0.06)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: greeting + avatar
                  Obx(() {
                    final user = auth.currentUser.value;
                    final name = user?.displayName.split(' ').first ?? '';
                    final hour = DateTime.now().hour;
                    final greeting = hour < 12
                        ? TKeys.homeGreetingMorning.tr
                        : hour < 17
                        ? TKeys.homeGreetingAfternoon.tr
                        : TKeys.homeGreetingEvening.tr;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge pill: TesterMandi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF34D399),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Beta Testing Exchange',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                name.isNotEmpty ? name : 'Welcome',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          children: [
                            _NotificationBell(isDark: isDark),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () =>
                                  Get.find<HomeController>().changeTab(4),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFBB9FFF), Color(0xFF818CF8)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    user?.initials ?? '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  // Stat row
                  _buildHeroStats(apps, testing),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  Widget _buildHeroStats(AppsController apps, TestingController testing) {
    return Obx(() {
      if (!apps.myAppsLoaded.value || !testing.dataLoaded.value) {
        return const _GlassStatShimmer();
      }
      final totalApps = apps.myApps.length;
      final totalTesters = apps.myApps.fold(0, (s, a) => s + a.testerCount);
      final activeTests = testing.myParticipations
          .where((p) => p.isActive)
          .length;

      return Row(
        children: [
          _GlassStatTile(
            value: '$totalApps',
            label: TKeys.homeStatsApps.tr,
            icon: Icons.rocket_launch_rounded,
          ),
          const _GlassDivider(),
          _GlassStatTile(
            value: '$totalTesters',
            label: TKeys.homeStatsTesters.tr,
            icon: Icons.people_outline_rounded,
          ),
          const _GlassDivider(),
          _GlassStatTile(
            value: '$activeTests',
            label: 'Active Tests',
            icon: Icons.science_rounded,
          ),
        ],
      ).animate(delay: 200.ms).fade(duration: 600.ms).slideY(begin: 0.3);
    });
  }

  // ── How it works strip ────────────────────────────────────────────────────

  Widget _buildHowItWorks() {
    final steps = [
      (icon: Icons.rocket_launch_rounded, color: const Color(0xFF6366F1),
       label: 'Post App', sub: 'List your app'),
      (icon: Icons.swap_horiz_rounded, color: const Color(0xFF0891B2),
       label: 'Swap & Test', sub: 'Exchange testing'),
      (icon: Icons.verified_rounded, color: const Color(0xFF059669),
       label: 'Submit Proof', sub: 'Screenshot proof'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ],
                ),
              );
            }
            final s = steps[i ~/ 2];
            return Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(s.icon, size: 18, color: s.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    s.sub,
                    style: TextStyle(
                      fontSize: 9,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ),
      ).animate(delay: 150.ms).fade(duration: 500.ms).slideY(begin: 0.15),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              title: 'Post Your App',
              subtitle: 'Get real testers fast',
              icon: Icons.add_circle_outline_rounded,
              gradient: AppColors.primaryGradient,
              shadowColor: AppColors.primaryShadow,
              onTap: () => Get.toNamed(AppRoutes.uploadApp),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              title: 'Discover Apps',
              subtitle: 'Join & test as tester',
              icon: Icons.explore_outlined,
              gradient: AppColors.testerCardGradient,
              shadowColor: AppColors.secondary.withValues(alpha: 0.25),
              onTap: () => Get.find<HomeController>().changeTab(2),
            ),
          ),
        ],
      ).animate(delay: 250.ms).fade(duration: 500.ms).slideY(begin: 0.2),
    );
  }

  // ── Swap requests ─────────────────────────────────────────────────────────

  Widget _buildSwapRequestsSection() {
    final swaps = Get.find<SwapController>();
    return Obx(() {
      final pending = swaps.pendingReceived;
      if (pending.isEmpty) return const SizedBox.shrink();
      return _PendingSwapsBanner(requests: pending, isDark: isDark);
    });
  }

  // ── Activity section ──────────────────────────────────────────────────────

  Widget _buildActivitySection(AppsController apps, TestingController testing) {
    return Obx(() {
      final appsReady = apps.myAppsLoaded.value;
      final testsReady = testing.dataLoaded.value;

      if (!appsReady && !testsReady) {
        return Column(
          children: [
            const SizedBox(height: 8),
            _TestTileShimmer(isDark: isDark),
            _TestTileShimmer(isDark: isDark),
          ],
        );
      }

      final myParticipations =
          testing.myParticipations.where((p) => p.isActive).toList();
      final deactivatedParticipations =
          testing.myParticipations.where((p) => p.isDeactivated).toList();
      final myTesters =
          testing.myAppTesters.where((p) => p.isActive).toList();
      final myApps = apps.myApps.toList();
      final allEmpty = myApps.isEmpty &&
          myParticipations.isEmpty &&
          myTesters.isEmpty &&
          deactivatedParticipations.isEmpty;

      if (allEmpty) return _EmptyDashboard(isDark: isDark);

      if (testsReady && (myParticipations.isNotEmpty || myTesters.isNotEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.find<ProofsController>().checkSubmittedToday([
            ...myParticipations,
            ...myTesters,
          ]);
        });
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tasks you need to do: Submit proof ──────────────────
          _DashSectionHeader(
            icon: Icons.upload_file_rounded,
            title: 'Your Testing Tasks',
            subtitle: 'Submit screenshot proof daily',
            count: myParticipations.length,
            accentColor: AppColors.primary,
            isDark: isDark,
          ),
          if (myParticipations.isNotEmpty)
            SizedBox(
              height: 176,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: myParticipations.length,
                itemBuilder: (_, i) => _CompactTestCard(
                  participation: myParticipations[i],
                  isDark: isDark,
                ),
              ),
            )
          else if (testsReady)
            _DashEmptyCard(
              icon: Icons.search_rounded,
              message: "You haven't joined any app for testing yet.",
              cta: 'Browse Apps to Test',
              onTap: () => Get.find<HomeController>().changeTab(2),
              isDark: isDark,
              color: AppColors.primary,
            ),

          // ── Banner ad ────────────────────────────────────────────
          const BannerAdWidget(
            placement: BannerPlacement.dashboardTab,
            margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
          ),

          // ── Deactivated: reactivate within 14 days ──────────────
          if (deactivatedParticipations.isNotEmpty) ...[
            _DashSectionHeader(
              icon: Icons.pause_circle_outline_rounded,
              title: 'Paused Testing',
              subtitle: 'Reactivate before they expire',
              count: deactivatedParticipations.length,
              accentColor: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
            SizedBox(
              height: 158,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: deactivatedParticipations.length,
                itemBuilder: (_, i) => _DeactivatedTestCard(
                  participation: deactivatedParticipations[i],
                  isDark: isDark,
                ),
              ),
            ),
          ],

          // ── Testers on your apps ─────────────────────────────────
          _DashSectionHeader(
            icon: Icons.groups_rounded,
            title: 'Testers on Your Apps',
            subtitle: 'Track their progress',
            count: myTesters.length,
            accentColor: const Color(0xFF6366F1),
            isDark: isDark,
          ),
          if (myTesters.isNotEmpty)
            SizedBox(
              height: 206,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: myTesters.length,
                itemBuilder: (_, i) => _CompactThemCard(
                  participation: myTesters[i],
                  isDark: isDark,
                ),
              ),
            )
          else if (testsReady)
            _DashEmptyCard(
              icon: Icons.rocket_launch_rounded,
              message: myApps.isEmpty
                  ? 'Post your first app to start getting testers.'
                  : 'No active testers yet. Swap with more developers.',
              cta: myApps.isEmpty ? 'Post App' : 'Browse Apps',
              onTap: myApps.isEmpty
                  ? () => Get.toNamed(AppRoutes.uploadApp)
                  : () => Get.find<HomeController>().changeTab(2),
              isDark: isDark,
              color: const Color(0xFF6366F1),
            ),

          const SizedBox(height: 8),
        ],
      );
    });
  }
}

// ── Dashboard section header ───────────────────────────────────────────────

class _DashSectionHeader extends StatelessWidget {
  const _DashSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accentColor,
    required this.isDark,
  });
  final IconData icon;
  final String title, subtitle;
  final int count;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Dashboard empty card ───────────────────────────────────────────────────

class _DashEmptyCard extends StatelessWidget {
  const _DashEmptyCard({
    required this.icon,
    required this.message,
    required this.cta,
    required this.onTap,
    required this.isDark,
    required this.color,
  });
  final IconData icon;
  final String message, cta;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                cta,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Apps Tab ────────────────────────────────────────────────────────────
class _MyAppsTab extends StatelessWidget {
  const _MyAppsTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final apps = Get.find<AppsController>();
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            apps.refreshMyApps(),
            Get.find<ProofsController>().refreshAll(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // ── Premium app bar ───────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0.4,
              automaticallyImplyLeading: false,
              toolbarHeight: 64,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'My Apps',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                              letterSpacing: -0.6,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Obx(() {
                            final n = apps.myApps.length;
                            return Text(
                              n == 0
                                  ? 'Start posting your apps'
                                  : '$n ${n == 1 ? 'app' : 'apps'} listed for testing',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.uploadApp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Post App',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Apps list ─────────────────────────────────────────
            Obx(() {
              if (!apps.myAppsLoaded.value) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => _AppTileShimmer(isDark: isDark),
                      childCount: 4,
                    ),
                  ),
                );
              }
              final list = apps.myApps;
              if (list.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.rocket_launch_outlined,
                    title: TKeys.myAppsEmpty.tr,
                    subtitle: TKeys.myAppsEmptySub.tr,
                    actionLabel: TKeys.myAppsAdd.tr,
                    onAction: () => Get.toNamed(AppRoutes.uploadApp),
                    isDark: isDark,
                    color: AppColors.primary,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _AppTile(app: list[i], isDark: isDark)
                        .animate(delay: Duration(milliseconds: 55 * i))
                        .fadeIn(duration: 300.ms)
                        .slideY(
                          begin: 0.08,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOut,
                        ),
                    childCount: list.length,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Browse Tab ─────────────────────────────────────────────────────────────
class _BrowseTab extends StatefulWidget {
  const _BrowseTab({required this.isDark});
  final bool isDark;

  @override
  State<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<_BrowseTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFilterSheet(AppsController apps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BrowseFilterSheet(isDark: widget.isDark, apps: apps),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final apps = Get.find<AppsController>();
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: () async {
          _searchCtrl.clear();
          apps.updateSearch('');
          apps.clearBrowseFilters();
          await Future.wait([
            apps.refreshAll(),
            Get.find<ProofsController>().refreshAll(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: bg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              automaticallyImplyLeading: false,
              toolbarHeight: 58,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          TKeys.browseTitle.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Obx(() {
                          final count = apps.allAppsLoaded.value
                              ? apps.filteredBrowse.length
                              : null;
                          return Text(
                            count != null
                                ? '$count apps available'
                                : TKeys.browseSubtitle.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      // ── Search field ──────────────────────────────────
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: apps.updateSearch,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search apps, developers…',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight,
                              ),
                              suffixIcon: Obx(
                                () => apps.browseSearch.value.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          _searchCtrl.clear();
                                          apps.updateSearch('');
                                        },
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: isDark
                                              ? AppColors.textHintDark
                                              : AppColors.textHintLight,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // ── Filter button ─────────────────────────────────
                      Obx(() {
                        final count = apps.activeBrowseFilterCount;
                        return GestureDetector(
                          onTap: () => _openFilterSheet(apps),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: count > 0
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.cardDark
                                            : Colors.white),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: count > 0
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight),
                                  ),
                                  boxShadow: count > 0
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : (isDark
                                            ? null
                                            : [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]),
                                ),
                                child: Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: count > 0
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                ),
                              ),
                              if (count > 0)
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() {
              if (!apps.allAppsLoaded.value) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, _) => _BrowseTileShimmer(isDark: isDark),
                      childCount: 5,
                    ),
                  ),
                );
              }
              final list = apps.filteredBrowse;
              if (list.isEmpty) {
                return SliverFillRemaining(child: _EmptyBrowse(isDark: isDark));
              }
              // Insert one banner ad after the 3rd real item in the Browse list.
              const int adInsertAt = 3;
              final bool hasAd = list.length > adInsertAt;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      if (hasAd && i == adInsertAt) {
                        return const BannerAdWidget(
                          placement: BannerPlacement.browseTab,
                          margin: EdgeInsets.symmetric(vertical: 6),
                        );
                      }
                      final ri = hasAd && i > adInsertAt ? i - 1 : i;
                      return _BrowseTile(app: list[ri], isDark: isDark);
                    },
                    childCount: hasAd ? list.length + 1 : list.length,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Profile Tab ────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: Obx(() {
        final user = auth.currentUser.value;
        if (user == null) return const SizedBox.shrink();
        return CustomScrollView(
          slivers: [
            // ── Hero header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _ProfileHeroHeader(user: user, isDark: isDark),
            ),
            // ── Stats ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _ProfileStatsRow(isDark: isDark)),
            // ── Ad banner ─────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: BannerAdWidget(placement: BannerPlacement.profileTab),
            ),
            // ── Closed testing card ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _ClosedTestingCard(isDark: isDark),
              ),
            ),
            // ── Settings ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _ProfileSettingsSection(isDark: isDark)),
            // ── Logout ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _ProfileLogoutSection(isDark: isDark, auth: auth),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        );
      }),
    );
  }
}

// ── My Apps summary widgets ────────────────────────────────────────────────

// ── Shared Tiles ───────────────────────────────────────────────────────────

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  Color get _statusColor {
    switch (app.status) {
      case AppStatus.active:  return const Color(0xFF059669);
      case AppStatus.full:    return const Color(0xFF6366F1);
      case AppStatus.expired: return const Color(0xFFDC2626);
    }
  }

  List<Color> get _statusGradient {
    switch (app.status) {
      case AppStatus.active:  return [const Color(0xFF059669), const Color(0xFF10B981)];
      case AppStatus.full:    return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case AppStatus.expired: return [const Color(0xFFDC2626), const Color(0xFFEF4444)];
    }
  }

  String get _statusLabel {
    switch (app.status) {
      case AppStatus.active:  return TKeys.myAppsStatusActive.tr;
      case AppStatus.full:    return TKeys.myAppsStatusCompleted.tr;
      case AppStatus.expired: return TKeys.myAppsStatusExpired.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (app.testerCount / app.testersNeeded).clamp(0.0, 1.0);
    final sc = _statusColor;
    final sg = _statusGradient;
    final isUrgent = app.daysLeft <= 3 && app.status == AppStatus.active;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.appDetail, arguments: app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? AppColors.borderDark
                : sc.withValues(alpha: 0.12),
            width: isDark ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: sc.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient top accent bar (clipped by parent) ──────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: sg),
              ),
            ),

            // ── Card body ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: icon + name/category + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App icon
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: sc.withValues(alpha: 0.28),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _AppIcon(
                              iconUrl: app.iconUrl,
                              size: 60,
                              radius: 16,
                            ),
                          ),
                          // Status dot in bottom-right corner of icon
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: sc,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Name + category + package
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: sg.map((c) =>
                                          c.withValues(alpha: 0.14)).toList(),
                                    ),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Text(
                                    app.categoryLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: sc,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    app.packageName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? AppColors.textHintDark
                                          : AppColors.textHintLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: sg.map((c) =>
                                c.withValues(alpha: 0.14)).toList(),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: sc,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Row 2: progress header
                  Row(
                    children: [
                      Text(
                        '${app.testerCount} / ${app.testersNeeded} testers',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: sc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Gradient progress bar
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: isDark ? 0.12 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: sg),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: sc.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row 3: meta chips + arrow
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: isUrgent
                            ? '${app.daysLeft}d left!'
                            : '${app.daysLeft} days left',
                        color: isUrgent
                            ? const Color(0xFFDC2626)
                            : (isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight),
                        isDark: isDark,
                        highlight: isUrgent,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.people_outline_rounded,
                        label:
                            '${app.testerCount} tester${app.testerCount == 1 ? '' : 's'}',
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                        isDark: isDark,
                      ),
                      const Spacer(),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: sg.map((c) =>
                                c.withValues(alpha: 0.12)).toList(),
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: sc,
                        ),
                      ),
                    ],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFDC2626).withValues(alpha: 0.08)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(7),
        border: highlight
            ? Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.25))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  void _openSwapSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SwapPickAppSheet(theirApp: app),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.appDetail, arguments: app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // App info row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  _AppIcon(iconUrl: app.iconUrl, size: 50, radius: 13),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'by ${app.ownerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _MiniChip(
                              icon: Icons.people_outline_rounded,
                              label: '${app.testerCount}/${app.testersNeeded}',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _MiniChip(
                              icon: Icons.schedule_rounded,
                              label: '${app.daysLeft}d',
                              color: app.daysLeft <= 3
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF059669),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action row
            if (!app.isFull) ...[
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.dividerLight,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Obx(() {
                  final uid =
                      Get.find<AuthController>().currentUser.value?.uid ?? '';
                  final swaps = Get.find<SwapController>();
                  final chat = Get.find<ChatController>();
                  final alreadySwapped = app.testerIds.contains(uid);
                  final hasPending = swaps.hasPendingSentRequestTo(app.id);

                  // Chat room shared with this app's owner (only exists after
                  // a swap is accepted).
                  final chatRoom = alreadySwapped
                      ? chat.rooms.firstWhereOrNull(
                          (r) =>
                              r.participantIds.contains(uid) &&
                              r.participantIds.contains(app.ownerId),
                        )
                      : null;

                  final Color swapColor;
                  final IconData swapIcon;
                  final String swapLabel;
                  final VoidCallback? swapPress;

                  if (alreadySwapped) {
                    swapColor = const Color(0xFF059669);
                    swapIcon = Icons.check_circle_outline_rounded;
                    swapLabel = 'Swapped';
                    swapPress = null;
                  } else if (hasPending) {
                    swapColor = const Color(0xFFF59E0B);
                    swapIcon = Icons.hourglass_top_rounded;
                    swapLabel = 'Pending';
                    swapPress = () => Get.snackbar(
                      '',
                      'Request sent — waiting for their response.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFFF59E0B),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      duration: const Duration(seconds: 3),
                      titleText: const SizedBox.shrink(),
                    );
                  } else {
                    swapColor = const Color(0xFF6366F1);
                    swapIcon = Icons.swap_horiz_rounded;
                    swapLabel = 'Swap';
                    swapPress = () => _openSwapSheet(context);
                  }

                  return Row(
                    children: [
                      // View App button
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed(
                              AppRoutes.appDetail,
                              arguments: app,
                            ),
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                            ),
                            label: const Text(
                              'View App',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Chat button — only when swap is accepted
                      if (alreadySwapped) ...[
                        SizedBox(
                          height: 34,
                          child: OutlinedButton.icon(
                            onPressed: chatRoom != null
                                ? () => chat.openChat(chatRoom)
                                : null,
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 14,
                            ),
                            label: const Text(
                              'Chat',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0891B2),
                              side: const BorderSide(color: Color(0xFF0891B2)),
                              backgroundColor: const Color(
                                0xFF0891B2,
                              ).withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(0, 34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: swapPress,
                        icon: Icon(swapIcon, size: 14),
                        label: Text(
                          swapLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: swapColor,
                          side: BorderSide(color: swapColor),
                          backgroundColor: hasPending || alreadySwapped
                              ? swapColor.withValues(alpha: 0.08)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ] else ...[
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.dividerLight,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      size: 13,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Testing Full',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Install + Join Group row ─────────────────────────────────
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.dividerLight,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Install — always shown; opens Play Store listing
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(
                            'https://play.google.com/store/apps/details?id=${app.packageName}',
                          );
                          if (await canLaunchUrl(uri)) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(
                          Icons.install_mobile_rounded,
                          size: 14,
                        ),
                        label: const Text(
                          'Install',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          side: const BorderSide(color: Color(0xFF059669)),
                          backgroundColor:
                              const Color(0xFF059669).withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ),
                  // Join Group — only when the owner provided a group link
                  if (app.optInUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(app.optInUrl);
                            if (await canLaunchUrl(uri)) {
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.group_add_outlined,
                            size: 14,
                          ),
                          label: const Text(
                            'Join Group',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side:
                                const BorderSide(color: Color(0xFF7C3AED)),
                            backgroundColor: const Color(0xFF7C3AED)
                                .withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
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
  }
}

// ── Pending swap requests banner ───────────────────────────────────────────

class _PendingSwapsBanner extends StatelessWidget {
  const _PendingSwapsBanner({required this.requests, required this.isDark});
  final List<SwapRequest> requests;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13122A) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pending Swap Requests',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFF4338CA),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${requests.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...requests.map((r) => _SwapRequestCard(request: r, isDark: isDark)),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SwapRequestCard extends StatelessWidget {
  const _SwapRequestCard({required this.request, required this.isDark});
  final SwapRequest request;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final swaps = Get.find<SwapController>();
    return Obx(() {
      final isResponding = swaps.isResponding.value == request.id;
      return Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AppIcon(iconUrl: request.fromAppIconUrl, size: 36, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fromUserName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'wants to swap — offers ${request.fromAppName}',
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
              ],
            ),
            // "in exchange for" row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    size: 14,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'for testing your ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                  _AppIcon(iconUrl: request.toAppIconUrl, size: 16, radius: 4),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.toAppName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: isResponding
                          ? null
                          : () => swaps.denyRequest(request),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(
                          color: Color(0xFFDC2626),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: isResponding
                          ? null
                          : () {
                              // Show congratulations immediately — no await.
                              // Accept runs in the background; the stream
                              // will remove the card from the list on commit.
                              swaps.acceptRequest(request);
                              final ctx = Get.overlayContext;
                              if (ctx != null) {
                                showModalBottomSheet(
                                  context: ctx,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => SwapAcceptedSheet(
                                    myAppName: request.toAppName,
                                    theirAppName: request.fromAppName,
                                    theirName: request.fromUserName,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: isResponding
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Accept Swap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ── Browse Filter Sheet ────────────────────────────────────────────────────

class _BrowseFilterSheet extends StatefulWidget {
  const _BrowseFilterSheet({required this.isDark, required this.apps});
  final bool isDark;
  final AppsController apps;

  @override
  State<_BrowseFilterSheet> createState() => _BrowseFilterSheetState();
}

class _BrowseFilterSheetState extends State<_BrowseFilterSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _countrySearchCtrl = TextEditingController();
  String _countryQuery = '';

  static const _countries = <String, String>{
    'US': '🇺🇸 USA',
    'IN': '🇮🇳 India',
    'GB': '🇬🇧 UK',
    'CA': '🇨🇦 Canada',
    'AU': '🇦🇺 Australia',
    'DE': '🇩🇪 Germany',
    'FR': '🇫🇷 France',
    'JP': '🇯🇵 Japan',
    'BR': '🇧🇷 Brazil',
    'MX': '🇲🇽 Mexico',
    'KR': '🇰🇷 S. Korea',
    'SG': '🇸🇬 Singapore',
    'AE': '🇦🇪 UAE',
    'PK': '🇵🇰 Pakistan',
    'NG': '🇳🇬 Nigeria',
    'ZA': '🇿🇦 S. Africa',
    'IT': '🇮🇹 Italy',
    'ES': '🇪🇸 Spain',
    'NL': '🇳🇱 Netherlands',
    'ID': '🇮🇩 Indonesia',
    'TR': '🇹🇷 Turkey',
    'PH': '🇵🇭 Philippines',
    'MY': '🇲🇾 Malaysia',
    'SA': '🇸🇦 Saudi Arabia',
    'BD': '🇧🇩 Bangladesh',
    'VN': '🇻🇳 Vietnam',
    'AR': '🇦🇷 Argentina',
    'CO': '🇨🇴 Colombia',
    'EG': '🇪🇬 Egypt',
    'TH': '🇹🇭 Thailand',
  };

  static const _languages = [
    'English', 'Hindi', 'Spanish', 'French', 'German', 'Portuguese',
    'Japanese', 'Korean', 'Arabic', 'Italian', 'Russian', 'Dutch',
    'Turkish', 'Polish', 'Swedish', 'Chinese', 'Bengali', 'Urdu',
    'Indonesian', 'Malay', 'Thai', 'Vietnamese', 'Filipino',
  ];

  static const _catIcons = <AppCategory, IconData>{
    AppCategory.games: Icons.sports_esports_rounded,
    AppCategory.education: Icons.school_rounded,
    AppCategory.entertainment: Icons.movie_rounded,
    AppCategory.business: Icons.business_center_rounded,
    AppCategory.productivity: Icons.bolt_rounded,
    AppCategory.finance: Icons.account_balance_wallet_rounded,
    AppCategory.healthFitness: Icons.fitness_center_rounded,
    AppCategory.lifestyle: Icons.spa_rounded,
    AppCategory.social: Icons.people_rounded,
    AppCategory.communication: Icons.chat_bubble_rounded,
    AppCategory.travel: Icons.flight_rounded,
    AppCategory.shopping: Icons.shopping_bag_rounded,
    AppCategory.news: Icons.newspaper_rounded,
    AppCategory.music: Icons.music_note_rounded,
    AppCategory.photography: Icons.camera_alt_rounded,
    AppCategory.sports: Icons.sports_soccer_rounded,
    AppCategory.food: Icons.restaurant_rounded,
    AppCategory.personalization: Icons.palette_rounded,
    AppCategory.weather: Icons.wb_sunny_rounded,
    AppCategory.tools: Icons.build_rounded,
    AppCategory.other: Icons.apps_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _countrySearchCtrl.addListener(
      () => setState(() => _countryQuery = _countrySearchCtrl.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    _countrySearchCtrl.dispose();
    super.dispose();
  }

  bool get _isDark => widget.isDark;
  AppsController get _apps => widget.apps;

  Color get _bg => _isDark ? AppColors.backgroundDark : Colors.white;
  Color get _cardBg => _isDark ? AppColors.cardDark : const Color(0xFFF8F9FB);
  Color get _border => _isDark ? AppColors.borderDark : const Color(0xFFE5E7EB);
  Color get _textPrimary =>
      _isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  Color get _textSecondary =>
      _isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get _hintColor =>
      _isDark ? AppColors.textHintDark : AppColors.textHintLight;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight =
        (MediaQuery.of(context).size.height * 0.78).clamp(420.0, 640.0);

    return Container(
      height: sheetHeight + bottomInset,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Filter Apps',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => _apps.activeBrowseFilterCount > 0
                      ? GestureDetector(
                          onTap: _apps.clearBrowseFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab pills ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() {
              final catActive = _apps.selectedCategory.value != null;
              final countryActive = _apps.browseFilterCountry.value != null;
              final langActive = _apps.browseFilterLanguage.value != null;
              return Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _isDark
                      ? AppColors.cardDark
                      : const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: TabBar(
                  controller: _tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: EdgeInsets.zero,
                  padding: const EdgeInsets.all(4),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: _textSecondary,
                  tabs: [
                    _buildTabLabel('Category', catActive),
                    _buildTabLabel('Country', countryActive),
                    _buildTabLabel('Language', langActive),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _CategoryTab(
                  apps: _apps,
                  isDark: _isDark,
                  catIcons: _catIcons,
                  textSecondary: _textSecondary,
                  cardBg: _cardBg,
                  border: _border,
                ),
                _CountryTab(
                  apps: _apps,
                  isDark: _isDark,
                  countries: _countries,
                  searchCtrl: _countrySearchCtrl,
                  query: _countryQuery,
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  hintColor: _hintColor,
                  cardBg: _cardBg,
                  border: _border,
                ),
                _LanguageTab(
                  apps: _apps,
                  isDark: _isDark,
                  languages: _languages,
                  textSecondary: _textSecondary,
                  cardBg: _cardBg,
                  border: _border,
                ),
              ],
            ),
          ),

          // ── Apply button ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.transparent),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Obx(() {
                      final count = _apps.activeBrowseFilterCount;
                      return Text(
                        count > 0 ? 'Apply Filters ($count active)' : 'Apply Filters',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLabel(String label, bool hasActive) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (hasActive) ...[
            const SizedBox(width: 5),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Category tab ───────────────────────────────────────────────────────────

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.apps,
    required this.isDark,
    required this.catIcons,
    required this.textSecondary,
    required this.cardBg,
    required this.border,
  });
  final AppsController apps;
  final bool isDark;
  final Map<AppCategory, IconData> catIcons;
  final Color textSecondary;
  final Color cardBg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = apps.selectedCategory.value;
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemCount: AppCategory.values.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            final isAll = selected == null;
            return _CatCell(
              icon: Icons.apps_rounded,
              label: 'All',
              isSelected: isAll,
              isDark: isDark,
              cardBg: cardBg,
              border: border,
              onTap: () => apps.filterByCategory(null),
            );
          }
          final cat = AppCategory.values[i - 1];
          return _CatCell(
            icon: catIcons[cat] ?? Icons.apps_rounded,
            label: cat.categoryLabel,
            isSelected: selected == cat,
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            onTap: () => apps.filterByCategory(selected == cat ? null : cat),
          );
        },
      );
    });
  }
}

class _CatCell extends StatelessWidget {
  const _CatCell({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color cardBg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF6366F1)
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Country tab ────────────────────────────────────────────────────────────

class _CountryTab extends StatelessWidget {
  const _CountryTab({
    required this.apps,
    required this.isDark,
    required this.countries,
    required this.searchCtrl,
    required this.query,
    required this.textPrimary,
    required this.textSecondary,
    required this.hintColor,
    required this.cardBg,
    required this.border,
  });
  final AppsController apps;
  final bool isDark;
  final Map<String, String> countries;
  final TextEditingController searchCtrl;
  final String query;
  final Color textPrimary;
  final Color textSecondary;
  final Color hintColor;
  final Color cardBg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? countries.entries.toList()
        : countries.entries
            .where((e) => e.value.toLowerCase().contains(query))
            .toList();

    return Obx(() {
      final selected = apps.browseFilterCountry.value;
      return Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: border),
              ),
              child: TextField(
                controller: searchCtrl,
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: hintColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: hintColor,
                  ),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: searchCtrl.clear,
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 16,
                            color: hintColor,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Country list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // All countries
                _CountryRow(
                  flag: '🌍',
                  name: 'All Countries',
                  isSelected: selected == null,
                  isDark: isDark,
                  cardBg: cardBg,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onTap: () => apps.filterByCountry(null),
                ),
                const SizedBox(height: 8),
                ...filtered.map((e) {
                  final parts = e.value.split(' ');
                  final flag = parts.first;
                  final name = parts.skip(1).join(' ');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CountryRow(
                      flag: flag,
                      name: name,
                      isSelected: selected == e.key,
                      isDark: isDark,
                      cardBg: cardBg,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () => apps.filterByCountry(
                        selected == e.key ? null : e.key,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.flag,
    required this.name,
    required this.isSelected,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });
  final String flag;
  final String name;
  final bool isSelected;
  final bool isDark;
  final Color cardBg;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
              : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF6366F1) : textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Color(0xFF6366F1),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Language tab ───────────────────────────────────────────────────────────

class _LanguageTab extends StatelessWidget {
  const _LanguageTab({
    required this.apps,
    required this.isDark,
    required this.languages,
    required this.textSecondary,
    required this.cardBg,
    required this.border,
  });
  final AppsController apps;
  final bool isDark;
  final List<String> languages;
  final Color textSecondary;
  final Color cardBg;
  final Color border;

  static const _langFlags = <String, String>{
    'English': '🇬🇧', 'Hindi': '🇮🇳', 'Spanish': '🇪🇸',
    'French': '🇫🇷', 'German': '🇩🇪', 'Portuguese': '🇧🇷',
    'Japanese': '🇯🇵', 'Korean': '🇰🇷', 'Arabic': '🇸🇦',
    'Italian': '🇮🇹', 'Russian': '🇷🇺', 'Dutch': '🇳🇱',
    'Turkish': '🇹🇷', 'Polish': '🇵🇱', 'Swedish': '🇸🇪',
    'Chinese': '🇨🇳', 'Bengali': '🇧🇩', 'Urdu': '🇵🇰',
    'Indonesian': '🇮🇩', 'Malay': '🇲🇾', 'Thai': '🇹🇭',
    'Vietnamese': '🇻🇳', 'Filipino': '🇵🇭',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = apps.browseFilterLanguage.value;
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.65,
        ),
        itemCount: languages.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _LangCell(
              flag: '🌐',
              label: 'All',
              isSelected: selected == null,
              isDark: isDark,
              cardBg: cardBg,
              border: border,
              onTap: () => apps.filterByLanguage(null),
            );
          }
          final lang = languages[i - 1];
          return _LangCell(
            flag: _langFlags[lang] ?? '🌐',
            label: lang,
            isSelected: selected == lang,
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            onTap: () => apps.filterByLanguage(selected == lang ? null : lang),
          );
        },
      );
    });
  }
}

class _LangCell extends StatelessWidget {
  const _LangCell({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.onTap,
  });
  final String flag;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color cardBg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
              : cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile sub-widgets ────────────────────────────────────────────────────

class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({required this.user, required this.isDark});
  final UserEntity user;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF1A1040),
                  Color(0xFF0F172A),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFF7C3AED),
                  Color(0xFF6366F1),
                ],
              ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topPad + 20, 24, 32),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFA78BFA), Color(0xFF818CF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFFA78BFA),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'TesterMandi Member',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final apps = Get.find<AppsController>();
    final testing = Get.find<TestingController>();
    final swaps = Get.find<SwapController>();
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Obx(() {
      final totalTesters = apps.myApps.fold(0, (s, a) => s + a.testerCount);
      final swapsAccepted = swaps.sentRequests
          .where((r) => r.status == SwapStatus.accepted)
          .length;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _ProfileStatItem(
              value: apps.myApps.length.toString(),
              label: TKeys.profileStatApps.tr,
              icon: Icons.rocket_launch_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
            ),
            _ProfileStatDivider(isDark: isDark),
            _ProfileStatItem(
              value: testing.myParticipations.length.toString(),
              label: TKeys.profileStatTesting.tr,
              icon: Icons.science_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
            _ProfileStatDivider(isDark: isDark),
            _ProfileStatItem(
              value: totalTesters.toString(),
              label: TKeys.profileStatTesters.tr,
              icon: Icons.people_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
            _ProfileStatDivider(isDark: isDark),
            _ProfileStatItem(
              value: swapsAccepted.toString(),
              label: TKeys.profileStatSwaps.tr,
              icon: Icons.swap_horiz_rounded,
              color: const Color(0xFFF472B6),
              isDark: isDark,
            ),
          ],
        ),
      ).animate(delay: 150.ms).fade(duration: 500.ms).slideY(begin: 0.2);
    });
  }
}

class _ProfileStatItem extends StatelessWidget {
  const _ProfileStatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String value, label;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 48,
    color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(
      alpha: 0.6,
    ),
  );
}

class _ProfileSettingsSection extends StatelessWidget {
  const _ProfileSettingsSection({required this.isDark});
  final bool isDark;

  // ── Helpers ───────────────────────────────────────────

  String _themeLabel(String mode) {
    switch (mode) {
      case 'light':
        return TKeys.themeLight.tr;
      case 'dark':
        return TKeys.themeDark.tr;
      default:
        return TKeys.themeSystem.tr;
    }
  }

  IconData _themeIcon(String mode) {
    switch (mode) {
      case 'light':
        return Icons.light_mode_rounded;
      case 'dark':
        return Icons.dark_mode_rounded;
      default:
        return Icons.brightness_auto_rounded;
    }
  }

  String _localeLabel(String code) {
    switch (code) {
      case 'hi':
        return TKeys.langHindi.tr;
      case 'es':
        return TKeys.langSpanish.tr;
      default:
        return TKeys.langEnglish.tr;
    }
  }

  void _showThemeSheet(BuildContext ctx, SettingsController s) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ThemeSheet(settings: s, isDark: isDark),
    );
  }

  void _showLanguageSheet(BuildContext ctx, SettingsController s) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LanguageSheet(settings: s, isDark: isDark),
    );
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.testermandi.app',
    );
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _shareApp() {
    Share.share(
      '${TKeys.shareText.tr}\nhttps://play.google.com/store/apps/details?id=com.testermandi.app',
      subject: 'TesterMandi — Connect with Real Testers',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final settings = Get.find<SettingsController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── PREFERENCES ──────────────────────────────────────────
          _SettingsGroupLabel(
            label: TKeys.profileSectionPreferences.tr,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            children: [
              // Theme
              Obx(() => _SettingsTile(
                icon: _themeIcon(settings.themeMode.value),
                label: TKeys.profileChooseTheme.tr,
                subtitle: _themeLabel(settings.themeMode.value),
                color: const Color(0xFF6366F1),
                isDark: isDark,
                onTap: () => _showThemeSheet(context, settings),
              )),
              _SettingsDivider(isDark: isDark),
              // Language
              Obx(() => _SettingsTile(
                icon: Icons.language_rounded,
                label: TKeys.profileChooseLanguage.tr,
                subtitle: _localeLabel(settings.locale.value),
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => _showLanguageSheet(context, settings),
              )),
              _SettingsDivider(isDark: isDark),
              // Notifications
              Obx(() => _SettingsToggleTile(
                icon: settings.notificationsEnabled.value
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
                label: TKeys.profileNotifications.tr,
                subtitle: settings.notificationsEnabled.value
                    ? TKeys.profileNotificationsOn.tr
                    : TKeys.profileNotificationsOff.tr,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                value: settings.notificationsEnabled.value,
                onChanged: (_) => settings.toggleNotifications(),
              )),
            ],
          ),

          const SizedBox(height: 20),

          // ── SUPPORT ──────────────────────────────────────────────
          _SettingsGroupLabel(
            label: TKeys.profileSectionSupport.tr,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: TKeys.profileHelp.tr,
                color: const Color(0xFF6366F1),
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.helpSupport),
              ),
              _SettingsDivider(isDark: isDark),
              _SettingsTile(
                icon: Icons.star_rate_rounded,
                label: TKeys.profileRateApp.tr,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
                onTap: _rateApp,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
                      SizedBox(width: 3),
                      Text(
                        '5.0',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SettingsDivider(isDark: isDark),
              _SettingsTile(
                icon: Icons.share_rounded,
                label: TKeys.profileShareApp.tr,
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: _shareApp,
              ),
              _SettingsDivider(isDark: isDark),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: TKeys.profileAbout.tr,
                color: const Color(0xFF64748B),
                isDark: isDark,
                onTap: () => Get.toNamed(AppRoutes.about),
              ),
            ],
          ),
        ],
      ).animate(delay: 300.ms).fade(duration: 500.ms).slideY(begin: 0.2),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  const _SettingsGroupLabel({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
    ),
  );
}

// ── Reusable settings card wrapper ──────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.children,
  });
  final bool isDark;
  final Color cardBg, border;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );
}

// ── Settings tile with optional subtitle + trailing ──────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withValues(alpha: 0.06),
        highlightColor: color.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings tile with a Switch ──────────────────────────────────────────────

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textHintDark
                          : AppColors.textHintLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: color,
              inactiveThumbColor: isDark
                  ? AppColors.textHintDark
                  : AppColors.textHintLight,
              inactiveTrackColor: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 70),
    child: Divider(
      height: 1,
      color: isDark ? AppColors.borderDark : AppColors.dividerLight,
    ),
  );
}

// ── Theme picker bottom sheet ────────────────────────────────────────────────

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({required this.settings, required this.isDark});
  final SettingsController settings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.backgroundDark : Colors.white;
    final options = [
      (key: 'light', icon: Icons.light_mode_rounded, color: const Color(0xFFF59E0B)),
      (key: 'dark', icon: Icons.dark_mode_rounded, color: const Color(0xFF6366F1)),
      (key: 'system', icon: Icons.brightness_auto_rounded, color: const Color(0xFF10B981)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.palette_rounded, color: AppColors.primary, size: 19),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TKeys.profileChooseTheme.tr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Choose how TesterMandi looks',
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
          Obx(() => Column(
            children: options.map((o) {
              final selected = settings.themeMode.value == o.key;
              final label = o.key == 'light'
                  ? TKeys.themeLight.tr
                  : o.key == 'dark'
                      ? TKeys.themeDark.tr
                      : TKeys.themeSystem.tr;
              return GestureDetector(
                onTap: () {
                  settings.setTheme(o.key);
                  Get.back();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? o.color.withValues(alpha: isDark ? 0.18 : 0.08)
                        : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? o.color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: o.color.withValues(alpha: selected ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(o.icon, size: 18, color: o.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? o.color
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: o.color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
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

// ── Language picker bottom sheet ─────────────────────────────────────────────

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.settings, required this.isDark});
  final SettingsController settings;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.backgroundDark : Colors.white;
    final langs = [
      (code: 'en', flag: '🇬🇧', name: 'English', native: 'English'),
      (code: 'hi', flag: '🇮🇳', name: 'Hindi', native: 'हिंदी'),
      (code: 'es', flag: '🇪🇸', name: 'Spanish', native: 'Español'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.language_rounded, color: Color(0xFF10B981), size: 19),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TKeys.langSelectTitle.tr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      letterSpacing: -0.3,
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
          Obx(() => Column(
            children: langs.map((l) {
              final selected = settings.locale.value == l.code;
              return GestureDetector(
                onTap: () {
                  settings.setLocale(l.code);
                  Get.back();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
                        : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Flag circle
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : (isDark ? AppColors.cardDarkElevated : AppColors.backgroundLight),
                          border: Border.all(
                            color: selected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(l.flag, style: const TextStyle(fontSize: 20)),
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
                                fontSize: 15,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
                      if (selected)
                        Container(
                          width: 22, height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
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

class _ProfileLogoutSection extends StatelessWidget {
  const _ProfileLogoutSection({required this.isDark, required this.auth});
  final bool isDark;
  final AuthController auth;

  static const _logoutColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.cardDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsGroupLabel(
            label: TKeys.profileSectionAccount.tr,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _logoutColor.withValues(alpha: 0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: _logoutColor.withValues(alpha: isDark ? 0.06 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: auth.logout,
                borderRadius: BorderRadius.circular(18),
                splashColor: _logoutColor.withValues(alpha: 0.06),
                highlightColor: _logoutColor.withValues(alpha: 0.03),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _logoutColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 19,
                          color: _logoutColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          TKeys.profileLogOut.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _logoutColor,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: _logoutColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Footer
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: Text(
                          'TM',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${TKeys.profileVersion.tr}  ·  ${TKeys.appVersion.tr}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TKeys.aboutMadeWith.tr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate(delay: 380.ms).fade(duration: 500.ms).slideY(begin: 0.2),
    );
  }
}

// ── Closed Testing Instructions Card ──────────────────────────────────────

class _ClosedTestingCard extends StatelessWidget {
  const _ClosedTestingCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1C1E3A) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF3A3D6E)
        : AppColors.borderLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
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
                child: Icon(
                  Icons.groups_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Closed Testing Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Required steps for the swap system to work',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProfileStep(
            num: '1',
            title: 'Testers join once',
            description:
                'Share this link with your testers — they join one time and can test all apps on the platform:',
            highlight: AppConstants.platformGroupUrl,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _ProfileStep(
            num: '2',
            title: 'Add the group to your Play Console',
            description:
                'In Play Console → Testing → Closed testing → Testers, add this email as a tester group:',
            highlight: AppConstants.platformGroupEmail,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({
    required this.num,
    required this.title,
    required this.description,
    required this.isDark,
    this.highlight,
  });
  final String num;
  final String title;
  final String description;
  final bool isDark;
  final String? highlight;

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  bool _copied = false;

  Future<void> _handleTap() async {
    if (widget.highlight == null) return;
    await Clipboard.setData(ClipboardData(text: widget.highlight!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
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
            child: Text(
              widget.num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              if (widget.highlight != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _handleTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _copied
                              ? const Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('check'),
                                  size: 15,
                                  color: Color(0xFF34D399),
                                )
                              : Icon(
                                  Icons.copy_rounded,
                                  key: const ValueKey('copy'),
                                  size: 15,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_copied)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: const Text(
                      'Copied to clipboard',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w600,
                      ),
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

// ── Empty States ───────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.07),
                ),
              ),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Welcome to TestMandi!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Post your app to get real testers,\nor browse and test others\' apps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: TMButton(
                  label: 'Post App',
                  onPressed: () => Get.toNamed(AppRoutes.uploadApp),
                  icon: Icons.add_rounded,
                  height: 48,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TMButton(
                  label: 'Browse',
                  onPressed: () => Get.find<HomeController>().changeTab(2),
                  icon: Icons.explore_rounded,
                  height: 48,
                  gradient: AppColors.testerCardGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.isDark,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            TMButton(
              label: actionLabel,
              onPressed: onAction,
              icon: icon,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBrowse extends StatelessWidget {
  const _EmptyBrowse({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            TKeys.browseEmpty.tr,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            TKeys.browseEmptySub.tr,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass stat widgets (hero header) ──────────────────────────────────────

class _GlassStatTile extends StatelessWidget {
  const _GlassStatTile({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value, label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 17),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassDivider extends StatelessWidget {
  const _GlassDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _GlassStatShimmer extends StatelessWidget {
  const _GlassStatShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile(),
        const _GlassDivider(),
        _tile(),
        const _GlassDivider(),
        _tile(),
      ],
    )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .fade(begin: 0.3, end: 0.7, duration: 900.ms, curve: Curves.easeInOut);
  }

  Widget _tile() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // icon placeholder
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 7),
            // number placeholder
            Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 5),
            // label placeholder
            Container(
              width: 38,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App icon helper ────────────────────────────────────────────────────────

class _AppIcon extends StatelessWidget {
  const _AppIcon({
    required this.iconUrl,
    required this.size,
    required this.radius,
  });
  final String? iconUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: iconUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _fallback(),
          errorWidget: (context, url, error) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(Icons.android_rounded, color: Colors.white, size: size * 0.55),
  );
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.index,
    required this.current,
    required this.isDark,
    required this.onTap,
  });
  final IconData icon, iconOutlined;
  final String label;
  final int index, current;
  final bool isDark;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.textHintDark
        : AppColors.textHintLight;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 48 : 0,
              height: isSelected ? 3 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              isSelected ? icon : iconOutlined,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: Colors.white, size: 19),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer Utilities ──────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E2030) : const Color(0xFFE2E2E2),
      highlightColor: isDark
          ? const Color(0xFF2D3050)
          : const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

class _SBox extends StatelessWidget {
  const _SBox({this.width, this.height = 14, this.radius = 8});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── App Tile Shimmer ───────────────────────────────────────────────────────

class _AppTileShimmer extends StatelessWidget {
  const _AppTileShimmer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      isDark: isDark,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SBox(width: 46, height: 46, radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SBox(width: 130, height: 13),
                      SizedBox(height: 5),
                      _SBox(width: 70, height: 11),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _SBox(width: 56, height: 22, radius: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _SBox(width: 12, height: 12, radius: 4),
                SizedBox(width: 4),
                _SBox(width: 55, height: 11),
                Spacer(),
                _SBox(width: 12, height: 12, radius: 4),
                SizedBox(width: 4),
                _SBox(width: 50, height: 11),
              ],
            ),
            const SizedBox(height: 8),
            const _SBox(height: 5, radius: 4),
          ],
        ),
      ),
    );
  }
}

// ── Browse Tile Shimmer ────────────────────────────────────────────────────

class _BrowseTileShimmer extends StatelessWidget {
  const _BrowseTileShimmer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      isDark: isDark,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            // ── info row — mirrors padding/icon/text/chips layout ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  const _SBox(width: 50, height: 50, radius: 13),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SBox(width: 140, height: 13),
                        SizedBox(height: 4),
                        _SBox(width: 90, height: 11),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            _SBox(width: 58, height: 18, radius: 20),
                            SizedBox(width: 8),
                            _SBox(width: 44, height: 18, radius: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            // ── action row — mirrors "View App" + "Swap" buttons ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: const [
                  Expanded(child: _SBox(height: 34, radius: 9)),
                  SizedBox(width: 8),
                  _SBox(width: 76, height: 34, radius: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Test Tile Shimmer — mirrors SectionHeader2 + horizontal compact cards ──

class _TestTileShimmer extends StatelessWidget {
  const _TestTileShimmer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header skeleton — mirrors _SectionHeader2 ────
          // (4px left bar · title text · count badge pill)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: Row(
              children: const [
                // left accent bar
                _SBox(width: 4, height: 22, radius: 4),
                SizedBox(width: 10),
                // title text
                _SBox(width: 148, height: 15),
                Spacer(),
                // count badge
                _SBox(width: 28, height: 22, radius: 20),
              ],
            ),
          ),
          // ── Horizontal compact card row ──────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _CompactCardShimmer(isDark: isDark),
                _CompactCardShimmer(isDark: isDark),
                _CompactCardShimmer(isDark: isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCardShimmer extends StatelessWidget {
  const _CompactCardShimmer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── app icon + name + "Day X of 14" ──
          const Row(
            children: [
              _SBox(width: 38, height: 38, radius: 10),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SBox(width: 110, height: 12),
                    SizedBox(height: 5),
                    _SBox(width: 60, height: 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── 14-dot tracker — mirrors _MiniDotTracker ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(14, (_) => Expanded(
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 12),
          // ── action button ──
          const _SBox(height: 34, radius: 10),
        ],
      ),
    );
  }
}

// ── Chat Tab ───────────────────────────────────────────────────────────────

class _ChatTab extends StatefulWidget {
  const _ChatTab({required this.isDark});
  final bool isDark;

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get _isDark => widget.isDark;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Get.find<ChatController>();
    final bg = _isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Premium App Bar ───────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0.4,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Messages',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.6,
                            color: _isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Obx(() {
                          final n = chat.rooms.length;
                          return Text(
                            n == 0
                                ? 'No swap conversations yet'
                                : '$n swap conversation${n == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // Unread badge
                  Obx(() {
                    final unread = chat.totalUnread;
                    if (unread == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '$unread new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // ── Search bar ───────────────────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    boxShadow: _isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or app…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: _isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: _isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(
                                Icons.cancel_rounded,
                                size: 17,
                                color: _isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHintLight,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Room list ─────────────────────────────────────────
          Obx(() {
            if (!chat.roomsLoaded.value) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, _) => _ChatRoomShimmer(isDark: _isDark),
                    childCount: 5,
                  ),
                ),
              );
            }

            final myUid =
                Get.find<AuthController>().currentUser.value?.uid ?? '';
            final all = chat.rooms;
            final rooms = _query.isEmpty
                ? all
                : all.where((r) {
                    final name =
                        r.otherUserName(myUid).toLowerCase();
                    final apps =
                        '${r.fromAppName} ${r.toAppName}'.toLowerCase();
                    return name.contains(_query) || apps.contains(_query);
                  }).toList();

            if (all.isEmpty) {
              return SliverFillRemaining(
                child: _EmptyChatRooms(isDark: _isDark),
              );
            }
            if (rooms.isEmpty) {
              return SliverFillRemaining(
                child: _NoSearchResults(
                  query: _query,
                  isDark: _isDark,
                  onClear: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _ChatRoomTile(room: rooms[i], isDark: _isDark)
                      .animate(delay: Duration(milliseconds: 40 * i))
                      .fadeIn(duration: 280.ms)
                      .slideY(begin: 0.05, duration: 280.ms),
                  childCount: rooms.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Chat Room Tile ─────────────────────────────────────────────────────────

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({required this.room, required this.isDark});
  final ChatRoom room;
  final bool isDark;

  // Deterministic gradient per user initial
  static const _avatarGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF0891B2), Color(0xFF06B6D4)],
    [Color(0xFF059669), Color(0xFF10B981)],
    [Color(0xFFDC2626), Color(0xFFEF4444)],
    [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    [Color(0xFFDB2777), Color(0xFFEC4899)],
    [Color(0xFF7C3AED), Color(0xFF9333EA)],
  ];

  List<Color> _gradientFor(String name) {
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % _avatarGradients.length;
    return _avatarGradients[idx];
  }

  String _timeLabel(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final chat = Get.find<ChatController>();
    final myUid = Get.find<AuthController>().currentUser.value?.uid ?? '';
    final otherName = room.otherUserName(myUid);
    final initials = otherName.isNotEmpty
        ? otherName.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';
    final unread = room.myUnread(myUid);
    final hasUnread = unread > 0;
    final grad = _gradientFor(otherName);
    final isSentByMe = room.lastMessageSenderId == myUid;
    final timeLabel = _timeLabel(room.lastMessageAt);

    return GestureDetector(
      onTap: () => chat.openChat(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.35)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: hasUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: hasUnread ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar with unread dot ──────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: grad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: grad.first.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.textHintDark
                                        : AppColors.textHintLight),
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Swap pair pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${room.fromAppName}  ↔  ${room.toAppName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Last message
                    if (room.lastMessage != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // "You:" label when sent by me
                          if (isSentByMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                'You:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textHintDark
                                      : AppColors.textHintLight,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              room.lastMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread
                                    ? (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight)
                                    : (isDark
                                          ? AppColors.textHintDark
                                          : AppColors.textHintLight),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Text(
                        'Say hello — start the conversation!',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Chevron
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── No search results ──────────────────────────────────────────────────────

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({
    required this.query,
    required this.isDark,
    required this.onClear,
  });
  final String query;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.cardDark : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 30,
                color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching by user name or app name.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Clear Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Chat Rooms ───────────────────────────────────────────────────────

class _EmptyChatRooms extends StatelessWidget {
  const _EmptyChatRooms({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon stack
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.07),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'No Conversations Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Chat rooms are created automatically\nwhen a swap request is accepted.\nSwap your app with another developer\nto start collaborating!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            // How it works mini strip
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ChatHowStep(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Send Swap',
                    isDark: isDark,
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                    size: 16,
                  ),
                  _ChatHowStep(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Get Accepted',
                    isDark: isDark,
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                    size: 16,
                  ),
                  _ChatHowStep(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Chat Opens',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TMButton(
              label: 'Browse Apps to Swap',
              onPressed: () => Get.find<HomeController>().changeTab(2),
              icon: Icons.explore_rounded,
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHowStep extends StatelessWidget {
  const _ChatHowStep({required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Chat Room Shimmer ──────────────────────────────────────────────────────

class _ChatRoomShimmer extends StatelessWidget {
  const _ChatRoomShimmer({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      isDark: isDark,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SBox(width: 52, height: 52, radius: 26),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Expanded(child: _SBox(height: 14)),
                      SizedBox(width: 8),
                      _SBox(width: 40, height: 11),
                    ],
                  ),
                  SizedBox(height: 7),
                  _SBox(width: 150, height: 22, radius: 8),
                  SizedBox(height: 7),
                  _SBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact Test Card (horizontal dashboard scroll) ────────────────────────

class _CompactTestCard extends StatelessWidget {
  const _CompactTestCard({required this.participation, required this.isDark});
  final TestParticipation participation;
  final bool isDark;

  int get _currentDay => participation.daysElapsed.clamp(1, 14);

  @override
  Widget build(BuildContext context) {
    final proofs = Get.find<ProofsController>();
    return Obx(() {
      final approved = proofs.approvedDays[participation.id] ?? {};
      final pending = proofs.pendingDays[participation.id] ?? {};
      final isApprovedToday = approved.contains(_currentDay);
      final isPendingToday = pending.contains(_currentDay);
      final isApproaching = participation.isApproachingExpiry;
      final daysLeft = participation.daysRemaining;

      final Color warningColor = daysLeft <= 2
          ? const Color(0xFFDC2626)
          : const Color(0xFFF59E0B);

      Color accentColor = AppColors.primary;
      if (isApprovedToday) accentColor = const Color(0xFF059669);
      if (isPendingToday) accentColor = const Color(0xFFF59E0B);
      if (isApproaching && !isApprovedToday) accentColor = warningColor;

      return Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(
              alpha: isApprovedToday || isPendingToday || isApproaching ? 0.5 : 0.15,
            ),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.12 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── App icon + name + day label ──
              Row(
                children: [
                  _AppIcon(iconUrl: participation.iconUrl, size: 38, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participation.appName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day $_currentDay of 14',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── 14-day dot tracker ──
              _MiniDotTracker(
                approvedDays: approved,
                pendingDays: pending,
                currentDay: _currentDay,
                activeColor: AppColors.primary,
                isDark: isDark,
              ),
              // ── Expiry warning banner ──
              if (isApproaching) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: warningColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        daysLeft <= 2
                            ? Icons.warning_amber_rounded
                            : Icons.timer_rounded,
                        size: 11,
                        color: warningColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        daysLeft <= 1
                            ? 'Last day!'
                            : '$daysLeft days left',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // ── Status / action ──
              if (isApprovedToday)
                _StatusChip(
                  icon: Icons.verified_rounded,
                  label: 'Approved Today',
                  color: const Color(0xFF059669),
                  isDark: isDark,
                )
              else if (isPendingToday)
                _StatusChip(
                  icon: Icons.hourglass_top_rounded,
                  label: 'Pending Review',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(
                      () => SubmitProofView(participation: participation),
                    ),
                    icon: const Icon(Icons.upload_rounded, size: 14),
                    label: const Text('Submit Proof'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isApproaching
                          ? warningColor
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Deactivated Test Card (horizontal dashboard scroll) ────────────────────

class _DeactivatedTestCard extends StatelessWidget {
  const _DeactivatedTestCard({required this.participation, required this.isDark});
  final TestParticipation participation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final testing = Get.find<TestingController>();
    final daysLeft = participation.daysUntilCleanup;
    final accentColor =
        daysLeft <= 3 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _AppIcon(iconUrl: participation.iconUrl, size: 38, radius: 10),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participation.appName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${participation.proofsSubmitted} proofs submitted',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    daysLeft <= 3
                        ? Icons.warning_amber_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 11,
                    color: accentColor,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      daysLeft <= 0
                          ? 'Data deleting soon!'
                          : '$daysLeft days to reactivate',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton.icon(
                onPressed: () =>
                    testing.reactivateParticipation(participation.id),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Reactivate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact Them Card (horizontal dashboard scroll) ────────────────────────

class _CompactThemCard extends StatelessWidget {
  const _CompactThemCard({required this.participation, required this.isDark});
  final TestParticipation participation;
  final bool isDark;

  int get _currentDay => participation.daysElapsed.clamp(1, 14);

  @override
  Widget build(BuildContext context) {
    final proofs = Get.find<ProofsController>();
    return Obx(() {
      final approved = proofs.approvedDays[participation.id] ?? {};
      final pending = proofs.pendingDays[participation.id] ?? {};
      final hasPendingToday = pending.contains(_currentDay);
      final isApprovedToday = approved.contains(_currentDay);
      final isApproving = proofs.approvingId.value == participation.id;
      final isReminding = proofs.remindingId.value == participation.id;
      final isApproaching = participation.isApproachingExpiry;
      final daysLeft = participation.daysRemaining;

      final Color warningColor = daysLeft <= 2
          ? const Color(0xFFDC2626)
          : const Color(0xFFF59E0B);

      Color accentColor = hasPendingToday
          ? const Color(0xFFF59E0B)
          : isApprovedToday
          ? const Color(0xFF059669)
          : isApproaching
          ? warningColor
          : const Color(0xFF6366F1);

      return Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: hasPendingToday || isApproaching ? 0.6 : 0.2),
            width: hasPendingToday || isApproaching ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.12 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── App icon + name + day label ──
              Row(
                children: [
                  _AppIcon(iconUrl: participation.iconUrl, size: 38, radius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participation.appName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day $_currentDay of 14',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Tester chip ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: const Color(0xFF6366F1),
                      child: Text(
                        participation.testerName.isNotEmpty
                            ? participation.testerName[0].toUpperCase()
                            : 'T',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        participation.testerName.isNotEmpty
                            ? participation.testerName
                            : 'Tester',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // ── 14-day dot tracker ──
              _MiniDotTracker(
                approvedDays: approved,
                pendingDays: pending,
                currentDay: _currentDay,
                activeColor: const Color(0xFF6366F1),
                isDark: isDark,
              ),
              // ── Expiry warning ──
              if (isApproaching) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: warningColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        daysLeft <= 2
                            ? Icons.warning_amber_rounded
                            : Icons.timer_rounded,
                        size: 10,
                        color: warningColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysLeft <= 1
                            ? 'Window ends today!'
                            : '$daysLeft days left — ${participation.proofsSubmitted}/14 proofs',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // ── Action button ──
              if (isApprovedToday)
                _StatusChip(
                  icon: Icons.verified_rounded,
                  label: 'Done Today',
                  color: const Color(0xFF059669),
                  isDark: isDark,
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton.icon(
                    onPressed: (isApproving || isReminding)
                        ? null
                        : hasPendingToday
                        ? () => _openReviewSheet(context, proofs)
                        : () => proofs.sendReminderToTester(
                            participationId: participation.id,
                            testerId: participation.testerId,
                            appName: participation.appName,
                          ),
                    icon: (isApproving || isReminding)
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            hasPendingToday
                                ? Icons.rate_review_rounded
                                : Icons.notifications_rounded,
                            size: 14,
                          ),
                    label: Text(
                      isApproving
                          ? 'Processing…'
                          : isReminding
                          ? 'Sending…'
                          : hasPendingToday
                          ? 'Review & Approve'
                          : 'Remind',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasPendingToday
                          ? const Color(0xFF059669)
                          : isApproaching
                          ? warningColor
                          : const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _openReviewSheet(BuildContext context, ProofsController proofs) {
    Get.bottomSheet(
      _ProofReviewSheet(
        participationId: participation.id,
        appName: participation.appName,
        testerName: participation.testerName,
        isDark: isDark,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proof Review Sheet (owner reviews submitted proof) ────────────────────

class _ProofReviewSheet extends StatefulWidget {
  const _ProofReviewSheet({
    required this.participationId,
    required this.appName,
    required this.testerName,
    required this.isDark,
  });
  final String participationId;
  final String appName;
  final String testerName;
  final bool isDark;

  @override
  State<_ProofReviewSheet> createState() => _ProofReviewSheetState();
}

class _ProofReviewSheetState extends State<_ProofReviewSheet> {
  DailyProof? _proof;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final proof = await Get.find<ProofsController>().fetchPendingProofData(
        widget.participationId,
      );
      if (mounted) {
        setState(() {
          _proof = proof;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = widget.isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Proof',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.testerName} • ${widget.appName}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null || _proof == null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: textSecondary,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load proof.',
                    style: TextStyle(color: textSecondary),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day + submitted time
                    Row(
                      children: [
                        _ReviewInfoChip(
                          icon: Icons.calendar_today_rounded,
                          label: 'Day ${_proof!.dayNumber} of 14',
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        _ReviewInfoChip(
                          icon: Icons.access_time_rounded,
                          label: _proof!.dateLabel,
                          color: textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Screenshots
                    if (_proof!.screenshotUrls.isNotEmpty) ...[
                      Text(
                        'Screenshots',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _proof!.screenshotUrls.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => _showFullImage(
                              context,
                              _proof!.screenshotUrls[i],
                            ),
                            child: Container(
                              width: 150,
                              margin: EdgeInsets.only(
                                right: i < _proof!.screenshotUrls.length - 1
                                    ? 10
                                    : 0,
                              ),
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Image.network(
                                _proof!.screenshotUrls[i],
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                    ? child
                                    : Container(
                                        color: widget.isDark
                                            ? AppColors.cardDark
                                            : const Color(0xFFF1F5F9),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: widget.isDark
                                          ? AppColors.cardDark
                                          : const Color(0xFFF1F5F9),
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: textSecondary,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Feedback
                    if (_proof!.feedback.isNotEmpty) ...[
                      Text(
                        'Feedback',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? AppColors.backgroundDark
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          _proof!.feedback,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Approve / Reject buttons
                    Obx(() {
                      final ctrl = Get.find<ProofsController>();
                      final busy =
                          ctrl.approvingId.value == widget.participationId;
                      return Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => ctrl.rejectProof(
                                          widget.participationId,
                                        ),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(
                                    color: Color(0xFFDC2626),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => ctrl.approveProof(
                                          widget.participationId,
                                        ),
                                icon: busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 16),
                                label: Text(busy ? 'Approving…' : 'Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _ReviewInfoChip extends StatelessWidget {
  const _ReviewInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini Dot Tracker (14-day circle row) ──────────────────────────────────

class _MiniDotTracker extends StatelessWidget {
  const _MiniDotTracker({
    required this.approvedDays,
    required this.pendingDays,
    required this.currentDay,
    required this.activeColor,
    required this.isDark,
  });

  final Set<int> approvedDays;
  final Set<int> pendingDays;
  final int currentDay;
  final Color activeColor;
  final bool isDark;

  static const int _total = 14;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_total, (i) {
        final day = i + 1;
        final approved = approvedDays.contains(day);
        final pending = pendingDays.contains(day);
        final isToday = day == currentDay;
        final isFuture = day > currentDay;
        final isMissed = !approved && !pending && !isFuture && day < currentDay;

        Color fill;
        Color? border;
        Color? glowColor;
        Widget? icon;

        if (approved) {
          fill = const Color(0xFF059669);
          glowColor = const Color(0xFF059669);
          icon = const Icon(Icons.check_rounded, size: 6, color: Colors.white);
        } else if (pending) {
          fill = const Color(0xFFF59E0B);
          glowColor = const Color(0xFFF59E0B);
          icon = const Icon(
            Icons.hourglass_top_rounded,
            size: 6,
            color: Colors.white,
          );
        } else if (isMissed) {
          fill = const Color(0xFFDC2626);
          glowColor = const Color(0xFFDC2626);
          icon = const Icon(Icons.close_rounded, size: 6, color: Colors.white);
        } else if (isToday) {
          fill = activeColor.withValues(alpha: 0.15);
          border = activeColor;
          icon = Center(
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
          );
        } else {
          fill = isDark ? const Color(0xFF252540) : const Color(0xFFEEF2FF);
        }

        return Expanded(
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: border != null
                    ? Border.all(color: border, width: 1.5)
                    : null,
                boxShadow: glowColor != null
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.4),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
              child: icon != null ? Center(child: icon) : null,
            ),
          ),
        );
      }),
    );
  }
}

// ── Notification Bell ──────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    NotificationsController? ctrl;
    try {
      ctrl = Get.find<NotificationsController>();
    } catch (_) {}

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.notifications),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 21,
              color: Colors.white,
            ),
          ),
          // Positioned must be a direct Stack child — Obx goes inside it,
          // not the other way around, or Stack ignores the position constraints.
          if (ctrl != null)
            Positioned(
              top: -4,
              right: -4,
              child: Obx(() {
                final count = ctrl!.unreadCount;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
