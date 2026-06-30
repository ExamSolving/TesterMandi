import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const _rcLatestVersion = 'latest_version';
  static const _rcForceUpdate   = 'force_update';
  static const _rcWhatsNew      = 'whats_new';
  static const _rcUpdateMessage = 'update_message';

  /// Call this from HomeController.onInit after login.
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await rc.setDefaults({
        _rcLatestVersion: '1.0.0',
        _rcForceUpdate:   false,
        _rcWhatsNew:      '• Performance improvements\n• Bug fixes',
        _rcUpdateMessage: 'A new version of TesterMandi is available with improvements and new features.',
      });
      await rc.fetchAndActivate();

      final latestVersion = rc.getString(_rcLatestVersion).trim();
      final forceUpdate   = rc.getBool(_rcForceUpdate);
      final whatsNew      = rc.getString(_rcWhatsNew).trim();
      final message       = rc.getString(_rcUpdateMessage).trim();

      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version.trim();

      if (!_isNewer(latestVersion, currentVersion)) return;

      // If user snoozed and it's not a force update — skip
      if (!forceUpdate && StorageService().isUpdateSnoozed) return;

      if (!context.mounted) return;
      _showUpdateDialog(
        context: context,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        forceUpdate: forceUpdate,
        whatsNew: whatsNew,
        message: message,
      );
    } catch (_) {
      // Silent fail — update check must never crash the app
    }
  }

  /// Returns true if [latest] is strictly newer than [current].
  bool _isNewer(String latest, String current) {
    try {
      final l = _parseVersion(latest);
      final c = _parseVersion(current);
      for (var i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  List<int> _parseVersion(String v) {
    final parts = v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) { parts.add(0); }
    return parts;
  }

  void _showUpdateDialog({
    required BuildContext context,
    required String latestVersion,
    required String currentVersion,
    required bool forceUpdate,
    required String whatsNew,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => UpdateDialog(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        forceUpdate: forceUpdate,
        whatsNew: whatsNew,
        message: message,
      ),
    );
  }
}

// ── Premium Update Dialog ───────────────────────────────────────────────────

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.currentVersion,
    required this.forceUpdate,
    required this.whatsNew,
    required this.message,
  });

  final String latestVersion;
  final String currentVersion;
  final bool forceUpdate;
  final String whatsNew;
  final String message;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    StorageService().clearUpdateSnooze();
    Get.back();
    // Opens app's own Play Store page
    final info = await PackageInfo.fromPlatform();
    final url  = Uri.parse(
        'https://play.google.com/store/apps/details?id=${info.packageName}');
    // ignore: deprecated_member_use
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _remindLater() {
    StorageService().saveUpdateRemindLater();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1E1B4B) : Colors.white;
    final lines  = widget.whatsNew
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Gradient hero ──────────────────────
                  _Hero(forceUpdate: widget.forceUpdate, isDark: isDark),

                  // ── Body ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Version badge row
                        Row(
                          children: [
                            _VersionChip(
                              label: 'Current',
                              version: 'v${widget.currentVersion}',
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFF3F4F6),
                              textColor: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                            _VersionChip(
                              label: 'Latest',
                              version: 'v${widget.latestVersion}',
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                              textColor: const Color(0xFF4F46E5),
                              isHighlight: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Message
                        Text(
                          widget.message,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // What's new
                        if (lines.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded,
                                    color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "What's New",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
                                  : const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: lines.map((line) {
                                final text = line.startsWith('•')
                                    ? line.substring(1).trim()
                                    : line;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.only(top: 5, right: 8),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4F46E5),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            height: 1.5,
                                            color: isDark
                                                ? const Color(0xFFC4B5FD)
                                                : const Color(0xFF3730A3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Update Now button ───────────
                        GestureDetector(
                          onTap: _update,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.system_update_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Update Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Remind Later ─────────────────
                        if (!widget.forceUpdate) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _remindLater,
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: isDark
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF6B7280),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remind Me Later',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }
}

// ── Hero section ────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.forceUpdate, required this.isDark});
  final bool forceUpdate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 148,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          // Glow
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Icon with ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (forceUpdate)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'REQUIRED UPDATE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      const Text(
                        'Update Available!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        forceUpdate
                            ? 'Please update to continue using the app'
                            : 'A new version of TesterMandi is ready',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    const gap = 28.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Version chip ────────────────────────────────────────────────────────────

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.version,
    required this.color,
    required this.textColor,
    this.isHighlight = false,
  });
  final String label;
  final String version;
  final Color color;
  final Color textColor;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: isHighlight
            ? Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          Text(
            version,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

