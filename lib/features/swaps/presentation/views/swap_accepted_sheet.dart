import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../home/presentation/controllers/home_controller.dart';

class SwapAcceptedSheet extends StatefulWidget {
  const SwapAcceptedSheet({
    super.key,
    required this.myAppName,
    required this.theirAppName,
    required this.theirName,
  });
  final String myAppName;
  final String theirAppName;
  final String theirName;

  @override
  State<SwapAcceptedSheet> createState() => _SwapAcceptedSheetState();
}

class _SwapAcceptedSheetState extends State<SwapAcceptedSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A1A), Color(0xFF0F1629), Color(0xFF1A1040)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            const _SparkleLayer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Pulsing handshake icon ──────────────────────
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: 1.0 + _pulseCtrl.value * 0.07,
                      child: child,
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.5),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handshake_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1.0, 1.0),
                        duration: 650.ms,
                        curve: Curves.elasticOut,
                      )
                      .fade(duration: 300.ms),

                  const SizedBox(height: 20),

                  // ── Congratulations headline ─────────────────────
                  const Text(
                    'Congratulations! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 280.ms)
                      .fade(duration: 450.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),

                  const SizedBox(height: 6),

                  // ── Subtitle ────────────────────────────────────
                  Text(
                    'You & ${widget.theirName} are now\nmutual testers!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 360.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // ── App exchange badge ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _AppBadge(
                          name: widget.myAppName,
                          color: const Color(0xFF6366F1),
                          label: 'Your App',
                          delay: 440,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF059669).withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: Color(0xFF34D399),
                            size: 20,
                          ),
                        )
                            .animate(delay: 560.ms)
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              duration: 350.ms,
                              curve: Curves.elasticOut,
                            )
                            .fade(duration: 200.ms),
                      ),
                      Expanded(
                        child: _AppBadge(
                          name: widget.theirAppName,
                          color: const Color(0xFF10B981),
                          label: 'Their App',
                          delay: 500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── What to do next ──────────────────────────────
                  Row(
                    children: [
                      _NextStep(
                        icon: Icons.download_rounded,
                        color: const Color(0xFF6366F1),
                        text: 'Install\nTheir App',
                        delay: 600,
                      ),
                      const SizedBox(width: 10),
                      _NextStep(
                        icon: Icons.fact_check_rounded,
                        color: const Color(0xFFFBBF24),
                        text: 'Submit\nDaily Proofs',
                        delay: 700,
                      ),
                      const SizedBox(width: 10),
                      _NextStep(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFF472B6),
                        text: 'Earn\nReviews',
                        delay: 800,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── CTA buttons ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            child: const Text('Close'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              Get.find<HomeController>().changeTab(2);
                            },
                            icon: const Icon(Icons.rocket_launch_rounded,
                                size: 16),
                            label: const Text('Start Testing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(delay: 880.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.15, curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.15,
          end: 0.0,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .fade(duration: 300.ms);
  }
}

// ── App badge ─────────────────────────────────────────────────────────────────

class _AppBadge extends StatelessWidget {
  const _AppBadge({
    required this.name,
    required this.color,
    required this.label,
    required this.delay,
  });
  final String name;
  final Color color;
  final String label;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fade(duration: 400.ms)
        .slideY(begin: 0.2, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
        );
  }
}

// ── Next step card ────────────────────────────────────────────────────────────

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.color,
    required this.text,
    required this.delay,
  });
  final IconData icon;
  final Color color;
  final String text;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: delay))
          .fade(duration: 350.ms)
          .slideY(begin: 0.2, curve: Curves.easeOut),
    );
  }
}

// ── Sparkle layer ─────────────────────────────────────────────────────────────

class _SparkleLayer extends StatelessWidget {
  const _SparkleLayer();

  static const _sparks = [
    _Spark(x: 0.10, y: 0.08, color: Color(0xFF34D399), size: 6, angle: 20),
    _Spark(x: 0.88, y: 0.06, color: Color(0xFF6366F1), size: 5, angle: -35),
    _Spark(x: 0.05, y: 0.30, color: Color(0xFFFBBF24), size: 7, angle: 55),
    _Spark(x: 0.92, y: 0.25, color: Color(0xFFF472B6), size: 5, angle: -50),
    _Spark(x: 0.75, y: 0.12, color: Color(0xFF34D399), size: 6, angle: 30),
    _Spark(x: 0.25, y: 0.05, color: Color(0xFF818CF8), size: 4, angle: -15),
    _Spark(x: 0.60, y: 0.20, color: Color(0xFFFBBF24), size: 5, angle: 70),
    _Spark(x: 0.40, y: 0.10, color: Color(0xFFF472B6), size: 6, angle: -60),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: _sparks
            .asMap()
            .entries
            .map((e) => _buildSpark(
                  e.value,
                  constraints.maxWidth,
                  constraints.maxHeight,
                  e.key * 100,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSpark(_Spark s, double w, double h, int delayMs) {
    return Positioned(
      left: s.x * w,
      top: s.y * h,
      child: Transform.rotate(
        angle: s.angle * math.pi / 180,
        child: Container(
          width: s.size.toDouble(),
          height: s.size.toDouble(),
          decoration: BoxDecoration(
            color: s.color.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(s.size / 3),
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: Duration(milliseconds: delayMs),
            )
            .fade(begin: 0.2, end: 0.85, duration: 1400.ms)
            .moveY(begin: 0, end: -12, duration: 1600.ms,
                curve: Curves.easeInOut),
      ),
    );
  }
}

class _Spark {
  const _Spark({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.angle,
  });
  final double x;
  final double y;
  final Color color;
  final int size;
  final double angle;
}
