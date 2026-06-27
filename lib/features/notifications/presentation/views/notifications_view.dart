import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/admob_config.dart';
import '../../../../core/widgets/banner_ad_widget.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: ctrl.reload,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        displacement: 80,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(ctrl, isDark),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 32),
              sliver: Obx(() {
                if (ctrl.isLoading.value) return _buildShimmer(isDark);
                if (ctrl.notifications.isEmpty) return _buildEmpty(isDark);
                return _buildList(ctrl, isDark);
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(NotificationsController ctrl, bool isDark) {
    final bg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SliverAppBar(
      pinned: true,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leadingWidth: 52,
      leading: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => Get.back(),
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: textPrimary,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Obx(() {
            final count = ctrl.unreadCount;
            return Text(
              count > 0 ? '$count unread' : 'All caught up',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: count > 0 ? AppColors.primary : textSecondary,
              ),
            );
          }),
        ],
      ),
      actions: [
        Obx(() => ctrl.unreadCount > 0
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => ctrl.markAllAsRead(),
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.primaryLight
                          : AppColors.primary,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  // ── Grouped list ───────────────────────────────────────────────────────────

  Widget _buildList(NotificationsController ctrl, bool isDark) {
    final groups = _groupByDate(ctrl.notifications);
    final items = <Object>[];
    for (final entry in groups.entries) {
      items.add(entry.key);
      items.addAll(entry.value);
    }

    // Index 0 is a banner ad; real notification items start at index 1.
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i == 0) {
            return const BannerAdWidget(
              placement: BannerPlacement.notifications,
            );
          }
          final item = items[i - 1];
          if (item is String) {
            return _DateHeader(label: item, isDark: isDark)
                .animate()
                .fadeIn(duration: 200.ms);
          }
          final notif = item as AppNotification;
          return _NotificationTile(
            key: ValueKey(notif.id),
            notification: notif,
            isDark: isDark,
            onDismissed: () => ctrl.delete(notif.id),
            onTap: () => _handleTap(notif, ctrl),
          )
              .animate(delay: Duration(milliseconds: 30 * (i % 12)))
              .fadeIn(duration: 250.ms)
              .slideY(
                  begin: 0.04,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut);
        },
        childCount: items.length + 1, // +1 for banner
      ),
    );
  }

  void _handleTap(AppNotification notif, NotificationsController ctrl) {
    if (!notif.isRead) ctrl.markAsRead(notif.id);

    switch (notif.type) {
      case NotificationType.proofSubmitted:
      case NotificationType.proofApproved:
      case NotificationType.proofRejected:
      case NotificationType.swapRequest:
      case NotificationType.swapAccepted:
      case NotificationType.swapDenied:
      case NotificationType.dailyReminder:
        Get.back();
        break;

      case NotificationType.newMessage:
        Get.back();
        break;

      case NotificationType.newApp:
        final appId = notif.data['appId'];
        Get.back();
        if (appId != null && appId.isNotEmpty) {
          Get.toNamed(AppRoutes.appDetail, arguments: appId);
        }
        break;

      case NotificationType.general:
        break;
    }
  }

  Map<String, List<AppNotification>> _groupByDate(
      List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));
    final result = <String, List<AppNotification>>{};
    for (final n in notifications) {
      final d = n.createdAt.toDate();
      final date = DateTime(d.year, d.month, d.day);
      final key = !date.isBefore(today)
          ? 'Today'
          : !date.isBefore(yesterday)
              ? 'Yesterday'
              : !date.isBefore(weekAgo)
                  ? 'This Week'
                  : 'Earlier';
      result.putIfAbsent(key, () => []).add(n);
    }
    return result;
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.accent.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          )
              .animate()
              .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 420.ms,
                  curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 22),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              letterSpacing: -0.2,
            ),
          ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ).animate(delay: 130.ms).fadeIn(),
        ],
      ),
    );
  }

  // ── Shimmer — mirrors the real tile layout exactly ─────────────────────────

  Widget _buildShimmer(bool isDark) {
    final base =
        isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight;
    final hi =
        isDark ? AppColors.shimmerHighDark : AppColors.shimmerHighLight;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, _) => Shimmer.fromColors(
          baseColor: base,
          highlightColor: hi,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container skeleton
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with unread dot
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 13,
                                decoration: BoxDecoration(
                                  color: base,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: base,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        // Body line 1
                        Container(
                          height: 11,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Body line 2 (shorter)
                        Container(
                          height: 11,
                          width: 200,
                          decoration: BoxDecoration(
                            color: base,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Badge + time row
                        Row(
                          children: [
                            Container(
                              height: 18,
                              width: 72,
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 10,
                              width: 50,
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(6),
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
          ),
        ),
        childCount: 6,
      ),
    );
  }
}

// ── Date header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    super.key,
    required this.notification,
    required this.isDark,
    required this.onDismissed,
    required this.onTap,
  });

  final AppNotification notification;
  final bool isDark;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, accent) = _style(notification.type);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text(
              'Delete',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onTap(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUnread
                  ? (isDark ? AppColors.cardDark : AppColors.cardLight)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? accent.withValues(alpha: isDark ? 0.22 : 0.16)
                    : (isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                width: isUnread ? 1.5 : 1,
              ),
              boxShadow: isUnread && !isDark
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon ──
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.18),
                        accent.withValues(alpha: 0.07),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Icon(icon, color: accent, size: 21),
                ),
                const SizedBox(width: 12),
                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.45),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _typeLabel(notification.type),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accent,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(notification.createdAt.toDate()),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight,
                            ),
                          ),
                          const Spacer(),
                          if (_hasNavigation(notification.type))
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.textHintDark
                                  : AppColors.textHintLight,
                            ),
                        ],
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

  bool _hasNavigation(NotificationType type) =>
      type != NotificationType.general;

  (IconData, Color) _style(NotificationType type) {
    switch (type) {
      case NotificationType.swapRequest:
        return (Icons.swap_horiz_rounded, const Color(0xFF4F46E5));
      case NotificationType.swapAccepted:
        return (Icons.handshake_rounded, const Color(0xFF059669));
      case NotificationType.swapDenied:
        return (Icons.cancel_rounded, const Color(0xFFDC2626));
      case NotificationType.proofSubmitted:
        return (Icons.upload_file_rounded, const Color(0xFFF59E0B));
      case NotificationType.proofApproved:
        return (Icons.verified_rounded, const Color(0xFF059669));
      case NotificationType.proofRejected:
        return (Icons.unpublished_rounded, const Color(0xFFDC2626));
      case NotificationType.newMessage:
        return (Icons.chat_bubble_rounded, const Color(0xFF0891B2));
      case NotificationType.dailyReminder:
        return (Icons.alarm_rounded, const Color(0xFF7C3AED));
      case NotificationType.newApp:
        return (Icons.rocket_launch_rounded, const Color(0xFF4F46E5));
      case NotificationType.general:
        return (Icons.notifications_rounded, const Color(0xFF6366F1));
    }
  }

  String _typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.swapRequest: return 'Swap Request';
      case NotificationType.swapAccepted: return 'Swap Accepted';
      case NotificationType.swapDenied: return 'Swap Denied';
      case NotificationType.proofSubmitted: return 'New Proof';
      case NotificationType.proofApproved: return 'Approved';
      case NotificationType.proofRejected: return 'Rejected';
      case NotificationType.newMessage: return 'Message';
      case NotificationType.dailyReminder: return 'Reminder';
      case NotificationType.newApp: return 'New App';
      case NotificationType.general: return 'Info';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
