import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../apps/domain/entities/app_listing.dart';
import '../../../apps/presentation/controllers/apps_controller.dart';
import '../controllers/swap_controller.dart';

/// Bottom sheet for choosing which of YOUR apps to offer in a swap request.
class SwapPickAppSheet extends StatefulWidget {
  const SwapPickAppSheet({super.key, required this.theirApp});
  final AppListing theirApp;

  @override
  State<SwapPickAppSheet> createState() => _SwapPickAppSheetState();
}

class _SwapPickAppSheetState extends State<SwapPickAppSheet> {
  AppListing? _selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final myApps = Get.find<AppsController>().myApps;
    final swapCtrl = Get.find<SwapController>();

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, -8))],
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Swap',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    Text(
                      'Pick your app to offer in exchange',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Their app summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: widget.theirApp.iconUrl != null
                      ? Image.network(widget.theirApp.iconUrl!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (ctx, e, s) => _iconFallback(40))
                      : _iconFallback(40),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.theirApp.appName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF6366F1))),
                      Text('by ${widget.theirApp.ownerName}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF6366F1)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Your app to offer:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          // My apps list
          if (myApps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rocket_launch_outlined, size: 40, color: isDark ? AppColors.textHintDark : AppColors.textHintLight),
                    const SizedBox(height: 8),
                    Text(
                      'You need to post an app first\nbefore requesting a swap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: myApps.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final app = myApps[i];
                  final isSelected = _selected?.id == app.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = app),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1).withValues(alpha: 0.08)
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6366F1) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: app.iconUrl != null
                                ? Image.network(app.iconUrl!, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (ctx, e, s) => _iconFallback(36))
                                : _iconFallback(36),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(app.appName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                Text(app.categoryLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // Send button
          Obx(() {
            final isSending = swapCtrl.isSending.value;
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_selected == null || isSending)
                    ? null
                    : () async {
                        await swapCtrl.sendSwapRequest(
                          myApp: _selected!,
                          theirApp: widget.theirApp,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                icon: isSending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.swap_horiz_rounded, size: 20),
                label: Text(
                  isSending ? 'Sending Request…' : 'Send Swap Request',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF334155),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _iconFallback(double size) => Container(
        width: size, height: size,
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(size * 0.25)),
        child: Icon(Icons.android_rounded, color: Colors.white, size: size * 0.55),
      );
}
