import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../swaps/presentation/controllers/swap_controller.dart';
import '../../../swaps/presentation/views/swap_pick_app_sheet.dart';
import '../../../testing/presentation/controllers/testing_controller.dart';
import '../../domain/entities/app_listing.dart';
import '../controllers/apps_controller.dart';
import 'add_app_view.dart';

class AppDetailView extends StatefulWidget {
  const AppDetailView({super.key});

  @override
  State<AppDetailView> createState() => _AppDetailViewState();
}

class _AppDetailViewState extends State<AppDetailView>
    with SingleTickerProviderStateMixin {
  bool _alreadyTesting = false;
  bool _checking = true;
  late final AnimationController _heroAnim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _checkParticipation();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  Future<void> _checkParticipation() async {
    final app = Get.arguments as AppListing?;
    if (app == null) return;
    final result = await Get.find<TestingController>().isAlreadyTesting(app.id);
    if (mounted) setState(() { _alreadyTesting = result; _checking = false; });
  }

  Future<void> _launch(String url) async {
    var raw = url.trim();
    if (raw.isEmpty) return;
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Get.arguments as AppListing?;
    if (app == null) return const Scaffold(body: SizedBox.shrink());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = Get.find<AuthController>().currentUser.value?.uid ?? '';
    final isOwner = app.ownerId == uid;
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          slivers: [
            _HeroAppBar(
              app: app,
              isDark: isDark,
              showDays: _alreadyTesting,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick links — non-owner only
                    if (!isOwner) ...[
                      _QuickLinks(app: app, isDark: isDark, onLaunch: _launch),
                      const SizedBox(height: 16),
                    ],
                    // Overview card
                    if (!isOwner)
                      _OverviewCard(app: app, isDark: isDark, showDays: _alreadyTesting)
                    else
                      _OwnerStatsCard(app: app, isDark: isDark),
                    const SizedBox(height: 14),
                    // About
                    _AboutCard(app: app, isDark: isDark),
                    const SizedBox(height: 14),
                    // Testing instructions
                    if (app.testingInstructions != null && app.testingInstructions!.trim().isNotEmpty) ...[
                      _TestingInstructionsCard(instructions: app.testingInstructions!.trim(), isDark: isDark),
                      const SizedBox(height: 14),
                    ],
                    // Listing details
                    _ListingDetailsCard(app: app, isDark: isDark),
                    const SizedBox(height: 20),
                    // Action
                    if (isOwner)
                      _OwnerActionPanel(app: app, isDark: isDark)
                    else
                      _SwapActionArea(app: app, isDark: isDark, checking: _checking, alreadyTesting: _alreadyTesting),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero App Bar ────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.app, required this.isDark, required this.showDays});
  final AppListing app;
  final bool isDark;
  final bool showDays;

  @override
  Widget build(BuildContext context) {
    final statusColor = app.isFull
        ? const Color(0xFFDC2626)
        : app.daysLeft <= 3
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF4F46E5),
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: Get.back,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Subtle pattern overlay
            Opacity(
              opacity: 0.06,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/pattern.png'),
                    repeat: ImageRepeat.repeat,
                    scale: 2,
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 0, right: 0, bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App icon with glow
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: app.iconUrl != null && app.iconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: app.iconUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => _IconFallback(name: app.appName),
                            errorWidget: (_, _, _) => _IconFallback(name: app.appName),
                          )
                        : _IconFallback(name: app.appName),
                  ),
                  const SizedBox(height: 14),
                  // App name
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      app.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Badge row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _HeroBadge(
                        label: app.categoryLabel,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      if (showDays) ...[
                        const SizedBox(width: 8),
                        _HeroBadge(
                          label: app.isFull
                              ? 'Testing Full'
                              : app.daysLeft <= 3
                                  ? '⚠ ${app.daysLeft}d left'
                                  : '${app.daysLeft}d left',
                          color: statusColor.withValues(alpha: 0.85),
                          isSolid: true,
                        ),
                      ],
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

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF4F46E5).withValues(alpha: 0.6),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.color, this.isSolid = false});
  final String label;
  final Color color;
  final bool isSolid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: isSolid ? null : Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Overview Card (non-owner) ────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.app, required this.isDark, required this.showDays});
  final AppListing app;
  final bool isDark;
  final bool showDays;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final initials = app.ownerName.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    final progress = (app.testerCount / app.testersNeeded).clamp(0.0, 1.0);
    final slotsLeft = app.testersNeeded - app.testerCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Developer row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.isNotEmpty ? initials : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Developer',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Copy package pill
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: app.packageName));
                  Get.snackbar('Copied', app.packageName,
                      duration: const Duration(seconds: 2),
                      snackPosition: SnackPosition.BOTTOM);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          app.packageName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          // Tester progress
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.people_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tester Slots',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                '${app.testerCount} / ${app.testersNeeded}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: app.isFull
                        ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                        : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            app.isFull
                ? 'All slots filled'
                : '$slotsLeft slot${slotsLeft == 1 ? '' : 's'} remaining',
            style: TextStyle(
              fontSize: 11,
              color: app.isFull
                  ? const Color(0xFFDC2626)
                  : (isDark ? AppColors.textHintDark : AppColors.textHintLight),
            ),
          ),
          const Divider(height: 20),
          // Listed date row
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 15,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Listed ${_formatDate(app.createdAt.toDate())}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              if (showDays)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (app.daysLeft <= 3 ? const Color(0xFFDC2626) : const Color(0xFF059669))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (app.daysLeft <= 3 ? const Color(0xFFDC2626) : const Color(0xFF059669))
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${app.daysLeft}d left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: app.daysLeft <= 3 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Owner Stats Card (owner view) ────────────────────────────────────────────

class _OwnerStatsCard extends StatelessWidget {
  const _OwnerStatsCard({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (app.testerCount / app.testersNeeded).clamp(0.0, 1.0);
    final slotsLeft = app.testersNeeded - app.testerCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tester progress
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.people_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tester Slots',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              Text(
                '${app.testerCount} / ${app.testersNeeded}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: app.isFull
                        ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                        : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            app.isFull
                ? 'All slots filled'
                : '$slotsLeft slot${slotsLeft == 1 ? '' : 's'} remaining',
            style: TextStyle(
              fontSize: 11,
              color: app.isFull
                  ? const Color(0xFFDC2626)
                  : (isDark ? AppColors.textHintDark : AppColors.textHintLight),
            ),
          ),
          const Divider(height: 20),
          // Listed date row
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 15,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              const SizedBox(width: 8),
              Text(
                'Listed ${_formatDate(app.createdAt.toDate())}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── About Card ───────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 10),
          app.description.trim().isEmpty
              ? Text(
                  'No description provided.',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.7,
                    color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
                  ),
                )
              : Text(
                  app.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Listing Details Card ─────────────────────────────────────────────────────

class _ListingDetailsCard extends StatelessWidget {
  const _ListingDetailsCard({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasCountries = app.targetCountries.isNotEmpty &&
        !(app.targetCountries.length == 1 && app.targetCountries.first == 'All');
    final hasLangs = app.appLanguages.isNotEmpty;

    final showVersion = app.latestVersion != null && app.latestVersion!.isNotEmpty;
    final showMinAndroid = app.minAndroidLevel != null && app.minAndroidLevel!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LISTING DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: app.categoryLabel,
            isDark: isDark,
          ),
          if (showVersion) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.new_releases_outlined,
              label: 'Version',
              value: 'v${app.latestVersion}',
              isDark: isDark,
            ),
          ],
          if (showMinAndroid) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.android_rounded,
              label: 'Min Android',
              value: app.minAndroidLevel!,
              isDark: isDark,
            ),
          ],
          if (hasCountries) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.public_rounded, size: 15, color: const Color(0xFF0891B2)),
                const SizedBox(width: 7),
                Text(
                  'Target Countries',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: app.targetCountries
                  .map((c) => _MiniTag(c, const Color(0xFF0891B2), isDark))
                  .toList(),
            ),
          ],
          if (hasLangs) ...[
            SizedBox(height: hasCountries ? 12 : 0),
            if (!hasCountries) const Divider(height: 24),
            if (hasCountries) const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.translate_rounded, size: 15, color: const Color(0xFF7C3AED)),
                const SizedBox(width: 7),
                Text(
                  'Languages',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: app.appLanguages
                  .map((l) => _MiniTag(l, const Color(0xFF7C3AED), isDark))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value, required this.isDark});
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
      ],
    );
  }
}

// ── Mini Tag ─────────────────────────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label, this.color, this.isDark);
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Quick Links ─────────────────────────────────────────────────────────────

class _QuickLinks extends StatefulWidget {
  const _QuickLinks({required this.app, required this.isDark, required this.onLaunch});
  final AppListing app;
  final bool isDark;
  final Future<void> Function(String) onLaunch;

  @override
  State<_QuickLinks> createState() => _QuickLinksState();
}

class _QuickLinksState extends State<_QuickLinks> with WidgetsBindingObserver {
  bool _isInstalled = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInstalled();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user returns from Play Store / app launcher.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isInstalled) {
      _checkInstalled();
    }
  }

  Future<void> _checkInstalled() async {
    final installed = await Get.find<AppsController>()
        .checkIsInstalled(widget.app.packageName);
    if (mounted) setState(() { _isInstalled = installed; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    final hasGroup = widget.app.optInUrl.isNotEmpty;

    // Second button priority:
    //   1. Installed → Open App
    //   2. Not installed + has group URL → Join Group
    //   3. Neither → Install App takes full width
    Widget? secondBtn;
    if (_isInstalled) {
      secondBtn = _QuickLinkBtn(
        icon: Icons.open_in_new_rounded,
        label: 'Open App',
        sublabel: 'Already Installed',
        gradient: const [Color(0xFF059669), Color(0xFF10B981)],
        onTap: () => Get.find<AppsController>().launchApp(widget.app.packageName),
      );
    } else if (hasGroup) {
      secondBtn = _QuickLinkBtn(
        icon: Icons.group_add_rounded,
        label: 'Join Group',
        sublabel: 'Tester Community',
        gradient: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
        onTap: () => widget.onLaunch(widget.app.optInUrl),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _QuickLinkBtn(
            icon: _checking
                ? Icons.hourglass_empty_rounded
                : Icons.play_arrow_rounded,
            label: 'Install App',
            sublabel: _checking ? 'Checking…' : 'Play Store',
            gradient: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
            onTap: _checking
                ? null
                : () => widget.onLaunch(
                      'https://play.google.com/store/apps/details?id=${widget.app.packageName}',
                    ),
          ),
        ),
        if (secondBtn != null) ...[
          const SizedBox(width: 12),
          Expanded(child: secondBtn),
        ],
      ],
    );
  }
}

class _QuickLinkBtn extends StatelessWidget {
  const _QuickLinkBtn({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 14, color: Colors.white.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }
}

// ── Testing Instructions Card ───────────────────────────────────────────────

class _TestingInstructionsCard extends StatefulWidget {
  const _TestingInstructionsCard({
    required this.instructions,
    required this.isDark,
  });
  final String instructions;
  final bool isDark;

  @override
  State<_TestingInstructionsCard> createState() =>
      _TestingInstructionsCardState();
}

class _TestingInstructionsCardState extends State<_TestingInstructionsCard> {
  bool _expanded = false;
  static const _previewLines = 4;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.checklist_rounded,
                  size: 15, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'Testing Instructions',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: 0.25)),
              ),
              child: const Text(
                'Required',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF059669).withValues(alpha: 0.07)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Text(
                  widget.instructions,
                  maxLines: _previewLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.65,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF14532D),
                  ),
                ),
                secondChild: Text(
                  widget.instructions,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.65,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF14532D),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: const Color(0xFF059669),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Swap Action Area (non-owner) ─────────────────────────────────────────────

class _SwapActionArea extends StatelessWidget {
  const _SwapActionArea({
    required this.app,
    required this.isDark,
    required this.checking,
    required this.alreadyTesting,
  });
  final AppListing app;
  final bool isDark;
  final bool checking;
  final bool alreadyTesting;

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
    }

    if (alreadyTesting) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.check_circle_rounded,
            label: "You're testing this app",
            sublabel: "You're an active tester",
            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
          ),
          const SizedBox(height: 14),
          _GradientButton(
            icon: Icons.download_rounded,
            label: 'Install App',
            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
            onTap: () => Get.find<TestingController>().installApp(app.packageName),
          ),
        ],
      );
    }

    if (app.isFull) {
      return _StatusBanner(
        icon: Icons.people_rounded,
        label: 'Testing slots are full',
        sublabel: 'All tester slots have been filled',
        gradient: const [Color(0xFF6B7280), Color(0xFF9CA3AF)],
      );
    }

    final pendingReq = Get.find<SwapController>().pendingSentRequestTo(app.id);
    if (pendingReq != null) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.hourglass_top_rounded,
            label: 'Swap Request Sent',
            sublabel: 'Waiting for developer response',
            gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.find<SwapController>().cancelRequest(pendingReq),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text(
                'Cancel Request',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      );
    }

    // Default: can request swap
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Send a swap request to join testing. Both devs test each other\'s apps.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF3730A3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _GradientButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Request Swap to Join Testing',
          gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SwapPickAppSheet(theirApp: app),
          ),
        ),
      ],
    );
  }
}

// ── Owner Action Panel ──────────────────────────────────────────────────────
class _OwnerActionPanel extends StatelessWidget {
  const _OwnerActionPanel({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  void _openEditSheet(BuildContext context) {
    Get.find<AppsController>().fillFormForEdit(app);
    Get.to(() => const AddAppView());
  }

  Future<void> _confirmDelete() async {
    final confirmed = await Get.dialog<bool>(
      _DeleteConfirmDialog(app: app, isDark: isDark),
      barrierColor: Colors.black.withValues(alpha: 0.65),
      barrierDismissible: false,
    );
    if (confirmed != true) return;
    final ok = await Get.find<AppsController>().deleteApp(app);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final appsCtrl = Get.find<AppsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Action row: Share + Edit Details ───────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                  'Check out ${app.appName} on Play Store!\nhttps://play.google.com/store/apps/details?id=${app.packageName}',
                  subject: app.appName,
                ),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text(
                  'Share',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0891B2),
                  side: BorderSide(
                      color: const Color(0xFF0891B2)
                          .withValues(alpha: 0.45)),
                  backgroundColor:
                      const Color(0xFF0891B2).withValues(alpha: 0.06),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  minimumSize: const Size(0, 46),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5)
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openEditSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 7),
                          Text(
                            'Edit Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Pause / Resume card ────────────────────────────────────────
        Obx(() {
          final latest =
              appsCtrl.myApps.firstWhereOrNull((a) => a.id == app.id) ??
                  app;
          final isPaused = latest.paused;
          final activeColor = isPaused
              ? const Color(0xFFDC2626)
              : const Color(0xFF059669);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: activeColor.withValues(alpha: 0.30),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPaused
                        ? Icons.pause_circle_rounded
                        : Icons.play_circle_rounded,
                    color: activeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPaused ? 'Listing Paused' : 'Listing Active',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: activeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPaused
                            ? 'Hidden from browse — toggle to resume'
                            : 'Visible to all testers in browse',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: !isPaused,
                  onChanged: (_) => appsCtrl.togglePauseListing(latest),
                  activeThumbColor: const Color(0xFF059669),
                  activeTrackColor:
                      const Color(0xFF059669).withValues(alpha: 0.30),
                  inactiveThumbColor: const Color(0xFFDC2626),
                  inactiveTrackColor:
                      const Color(0xFFDC2626).withValues(alpha: 0.25),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
        // ── Delete listing ─────────────────────────────────────────────
        GestureDetector(
            onTap: _confirmDelete,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                    : const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Color(0xFFDC2626), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delete App Listing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Permanently removes app and all related data',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                      size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Delete Confirmation Dialog ───────────────────────────────────────────────

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _dismiss([bool result = false]) async {
    await _anim.reverse();
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    const red = Color(0xFFDC2626);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 40,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Gradient header ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_forever_rounded,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Delete App?',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.app.appName,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                // ── Warning body ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: red.withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: red.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: red.withValues(alpha: 0.85), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This action is permanent and cannot be undone.',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: red.withValues(alpha: 0.85),
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The following will be permanently deleted:',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 10),
                      ...[
                        (Icons.apps_rounded, 'App listing & all details'),
                        (Icons.swap_horiz_rounded, 'All swap requests'),
                        (Icons.people_rounded, 'All tester participations'),
                        (Icons.photo_library_rounded, 'All proof screenshots'),
                        (Icons.notifications_rounded, 'All related notifications'),
                        (Icons.image_rounded, 'App icon from storage'),
                      ].map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(e.$1,
                                      size: 14,
                                      color: red.withValues(alpha: 0.7)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  e.$2,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                // ── Buttons ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _dismiss(false),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            foregroundColor: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: red.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _dismiss(true),
                              borderRadius: BorderRadius.circular(14),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_forever_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text('Delete',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
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
        ),
      ),
    );
  }
}


class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
