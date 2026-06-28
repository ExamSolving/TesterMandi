import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
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
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            _HeroAppBar(app: app, isDark: isDark),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick links ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _QuickLinks(app: app, isDark: isDark, onLaunch: _launch),
                  ),
                  // ── Developer card ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _DeveloperCard(app: app, isDark: isDark),
                  ),
                  // ── Stats row ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _StatsRow(app: app, isDark: isDark),
                  ),
                  // ── Description ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _Section(
                      icon: Icons.description_outlined,
                      title: 'About this app',
                      isDark: isDark,
                      child: Text(
                        app.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.65,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  // ── Testing Instructions (only if provided) ─────
                  if (app.testingInstructions != null &&
                      app.testingInstructions!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _TestingInstructionsCard(
                        instructions: app.testingInstructions!.trim(),
                        isDark: isDark,
                      ),
                    ),
                  // ── App info grid ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _AppInfoGrid(app: app, isDark: isDark),
                  ),
                  // ── Countries & Languages ───────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _TagsSection(app: app, isDark: isDark),
                  ),
                  // ── Action button ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: _ActionArea(
                      app: app,
                      isDark: isDark,
                      isOwner: isOwner,
                      checking: _checking,
                      alreadyTesting: _alreadyTesting,
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

// ── Hero App Bar ────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

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

// ── Quick Links ─────────────────────────────────────────────────────────────

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({required this.app, required this.isDark, required this.onLaunch});
  final AppListing app;
  final bool isDark;
  final Future<void> Function(String) onLaunch;

  @override
  Widget build(BuildContext context) {
    final hasGroup = app.optInUrl.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: _QuickLinkBtn(
            icon: Icons.play_arrow_rounded,
            label: 'Install App',
            sublabel: 'Play Store',
            gradient: const [Color(0xFF0EA5E9), Color(0xFF2563EB)],
            onTap: () => onLaunch(
              'https://play.google.com/store/apps/details?id=${app.packageName}',
            ),
          ),
        ),
        if (hasGroup) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _QuickLinkBtn(
              icon: Icons.group_add_rounded,
              label: 'Join Group',
              sublabel: 'Tester Community',
              gradient: const [Color(0xFF7C3AED), Color(0xFFDB2777)],
              onTap: () => onLaunch(app.optInUrl),
            ),
          ),
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
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradient;
  final VoidCallback onTap;

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

// ── Developer Card ──────────────────────────────────────────────────────────

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final initials = app.ownerName.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
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
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.ownerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'App Developer',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
                ),
              ],
            ),
          ),
          // Package name copy pill
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
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded,
                      size: 12, color: AppColors.primary),
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
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = (app.testerCount / app.testersNeeded).clamp(0.0, 1.0);
    final daysUrgent = app.daysLeft <= 3;
    final daysColor = daysUrgent ? const Color(0xFFDC2626) : const Color(0xFF059669);

    return Column(
      children: [
        // Tester progress card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.people_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tester Slots',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Text(
                    '${app.testerCount} / ${app.testersNeeded} joined',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Gradient progress bar
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
              const SizedBox(height: 8),
              Text(
                app.isFull
                    ? 'All slots filled — no new testers accepted'
                    : '${app.testersNeeded - app.testerCount} slot${(app.testersNeeded - app.testerCount) == 1 ? '' : 's'} remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: app.isFull
                      ? const Color(0xFFDC2626)
                      : (isDark
                            ? AppColors.textHintDark
                            : AppColors.textHintLight),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Secondary stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.schedule_rounded,
                iconColor: daysColor,
                label: 'Days Left',
                value: '${app.daysLeft}',
                sublabel: daysUrgent ? 'Ending soon!' : 'Remaining',
                isDark: isDark,
                urgent: daysUrgent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF0891B2),
                label: 'Listed On',
                value: _formatDate(app.createdAt.toDate()),
                sublabel: 'Posted date',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.isDark,
    this.urgent = false,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String sublabel;
  final bool isDark;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent
            ? const Color(0xFFDC2626).withValues(alpha: isDark ? 0.12 : 0.06)
            : (isDark ? AppColors.cardDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: urgent
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textHintDark
                      : AppColors.textHintLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: iconColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textHintDark : AppColors.textHintLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section wrapper ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.3,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
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

// ── App Info Grid ───────────────────────────────────────────────────────────

class _AppInfoGrid extends StatelessWidget {
  const _AppInfoGrid({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      _InfoItem(
        icon: Icons.category_outlined,
        label: 'Category',
        value: app.categoryLabel,
      ),
      if (app.latestVersion != null && app.latestVersion!.isNotEmpty)
        _InfoItem(
          icon: Icons.new_releases_outlined,
          label: 'Version',
          value: 'v${app.latestVersion}',
        ),
      if (app.minAndroidLevel != null && app.minAndroidLevel!.isNotEmpty)
        _InfoItem(
          icon: Icons.android_rounded,
          label: 'Min Android',
          value: 'Android ${app.minAndroidLevel}+',
        ),
      _InfoItem(
        icon: Icons.schedule_rounded,
        label: 'Testing Period',
        value: '14 days',
      ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return _Section(
      icon: Icons.info_outline_rounded,
      title: 'App Details',
      isDark: isDark,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
        ),
        itemBuilder: (_, i) => _InfoGridCell(item: items[i], isDark: isDark),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _InfoGridCell extends StatelessWidget {
  const _InfoGridCell({required this.item, required this.isDark});
  final _InfoItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textHintDark
                        : AppColors.textHintLight,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tags Section (Countries + Languages) ────────────────────────────────────

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.app, required this.isDark});
  final AppListing app;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasCountries = app.targetCountries.isNotEmpty &&
        !(app.targetCountries.length == 1 && app.targetCountries.first == 'All');
    final hasLangs = app.appLanguages.isNotEmpty;
    if (!hasCountries && !hasLangs) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCountries) ...[
          _TagGroup(
            icon: Icons.public_rounded,
            title: 'Target Countries',
            tags: app.targetCountries,
            isDark: isDark,
            tagColor: const Color(0xFF0891B2),
          ),
        ],
        if (hasCountries && hasLangs) const SizedBox(height: 14),
        if (hasLangs)
          _TagGroup(
            icon: Icons.translate_rounded,
            title: 'App Languages',
            tags: app.appLanguages,
            isDark: isDark,
            tagColor: const Color(0xFF7C3AED),
          ),
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.icon,
    required this.title,
    required this.tags,
    required this.isDark,
    required this.tagColor,
  });
  final IconData icon;
  final String title;
  final List<String> tags;
  final bool isDark;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: tagColor),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: tags.map((t) => _Tag(label: t, color: tagColor, isDark: isDark)).toList(),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, required this.isDark});
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? color.withValues(alpha: 0.9) : color,
        ),
      ),
    );
  }
}

// ── Action Area ─────────────────────────────────────────────────────────────

class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.app,
    required this.isDark,
    required this.isOwner,
    required this.checking,
    required this.alreadyTesting,
  });
  final AppListing app;
  final bool isDark;
  final bool isOwner;
  final bool checking;
  final bool alreadyTesting;

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return _StatusBanner(
        icon: Icons.verified_rounded,
        label: 'This is your app',
        sublabel: 'You posted this listing',
        gradient: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      );
    }

    if (checking) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (alreadyTesting) {
      return Column(
        children: [
          _StatusBanner(
            icon: Icons.check_circle_rounded,
            label: 'You\'re already testing',
            sublabel: 'You\'re an active tester for this app',
            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
          ),
          const SizedBox(height: 14),
          _GradientButton(
            icon: Icons.download_rounded,
            label: 'Install App Now',
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

    final swapCtrl = Get.find<SwapController>();
    final hasPendingSwap = swapCtrl.sentRequests
        .any((r) => r.toAppId == app.id && r.status == SwapStatus.pending);

    if (hasPendingSwap) {
      return _StatusBanner(
        icon: Icons.hourglass_top_rounded,
        label: 'Swap Request Sent',
        sublabel: 'Waiting for the developer\'s response',
        gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.08)
                : const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Send a swap request to join testing. You\'ll test each other\'s apps.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF3730A3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
