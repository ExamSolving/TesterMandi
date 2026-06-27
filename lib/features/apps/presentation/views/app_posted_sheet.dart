import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../core/config/admob_config.dart';
import '../../../../core/services/ad_service.dart';
import '../../../home/presentation/controllers/home_controller.dart';

class AppPostedSheet extends StatefulWidget {
  const AppPostedSheet({super.key, required this.appName});
  final String appName;

  @override
  State<AppPostedSheet> createState() => _AppPostedSheetState();
}

class _AppPostedSheetState extends State<AppPostedSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _showInterstitialOnce() {
    if (_adShown) return;
    _adShown = true;
    if (AdmobConfig.showInterstitialOnAppPosted) {
      AdService.to.showInterstitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0C29), Color(0xFF1A1040), Color(0xFF24243E)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          children: [
            // ── Confetti particles ──────────────────────────────────
            const _ConfettiLayer(),
            // ── Main content ────────────────────────────────────────
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
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Glowing rocket icon ──────────────────────────
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) {
                      final scale = 1.0 + _pulseCtrl.value * 0.08;
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.55),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fade(duration: 300.ms),

                  const SizedBox(height: 24),

                  // ── Headline ─────────────────────────────────────
                  const Text(
                    'App Posted Successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 300.ms)
                      .fade(duration: 500.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  // ── App name badge ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apps_rounded,
                            color: Color(0xFFA78BFA), size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.appName,
                            style: const TextStyle(
                              color: Color(0xFFA78BFA),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 420.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 28),

                  // ── What's next cards ────────────────────────────
                  Row(
                    children: [
                      _NextCard(
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF34D399),
                        title: 'Testers Join',
                        subtitle: 'Others swap\n& start testing',
                        delay: 500,
                      ),
                      const SizedBox(width: 10),
                      _NextCard(
                        icon: Icons.fact_check_rounded,
                        color: const Color(0xFFFBBF24),
                        title: 'Daily Proofs',
                        subtitle: 'Get screenshots\n& feedback',
                        delay: 620,
                      ),
                      const SizedBox(width: 10),
                      _NextCard(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFF472B6),
                        title: 'Reviews',
                        subtitle: '14-day real\nuser data',
                        delay: 740,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Tip banner ───────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded,
                            color: Color(0xFFFBBF24), size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Swap with other apps to get testers faster and grow your community!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 820.ms)
                      .fade(duration: 400.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // ── CTA buttons ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showInterstitialOnce();
                              Get.back();
                              Get.find<HomeController>().changeTab(1);
                            },
                            icon: const Icon(Icons.apps_rounded, size: 16),
                            label: const Text('My Apps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
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
                              _showInterstitialOnce();
                              Get.back();
                              Get.find<HomeController>().changeTab(2);
                            },
                            icon: const Icon(Icons.swap_horiz_rounded,
                                size: 16),
                            label: const Text('Browse & Swap'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
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
                      .animate(delay: 900.ms)
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

// ── What's next card ──────────────────────────────────────────────────────────

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.delay,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9.5,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: delay))
          .fade(duration: 400.ms)
          .slideY(begin: 0.25, curve: Curves.easeOut)
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.0, 1.0),
            duration: 400.ms,
          ),
    );
  }
}

// ── Confetti layer ────────────────────────────────────────────────────────────

class _ConfettiLayer extends StatelessWidget {
  const _ConfettiLayer();

  static const _particles = [
    _Particle(x: 0.08, y: 0.12, color: Color(0xFF6366F1), size: 7, angle: 35),
    _Particle(x: 0.85, y: 0.08, color: Color(0xFF34D399), size: 5, angle: -20),
    _Particle(x: 0.15, y: 0.35, color: Color(0xFFFBBF24), size: 6, angle: 60),
    _Particle(x: 0.90, y: 0.28, color: Color(0xFFF472B6), size: 8, angle: -45),
    _Particle(x: 0.05, y: 0.55, color: Color(0xFF34D399), size: 5, angle: 15),
    _Particle(x: 0.92, y: 0.50, color: Color(0xFF6366F1), size: 6, angle: 80),
    _Particle(x: 0.72, y: 0.14, color: Color(0xFFFBBF24), size: 7, angle: -30),
    _Particle(x: 0.28, y: 0.06, color: Color(0xFFF472B6), size: 5, angle: 50),
    _Particle(x: 0.60, y: 0.32, color: Color(0xFF818CF8), size: 4, angle: -65),
    _Particle(x: 0.40, y: 0.20, color: Color(0xFF34D399), size: 6, angle: 25),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Stack(
        children: _particles
            .asMap()
            .entries
            .map((e) => _buildParticle(
                  e.value,
                  constraints.maxWidth,
                  constraints.maxHeight,
                  e.key * 80,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildParticle(
      _Particle p, double w, double h, int delayMs) {
    return Positioned(
      left: p.x * w,
      top: p.y * h,
      child: Transform.rotate(
        angle: p.angle * math.pi / 180,
        child: Container(
          width: p.size.toDouble(),
          height: p.size.toDouble(),
          decoration: BoxDecoration(
            color: p.color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(p.size / 3),
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: Duration(milliseconds: delayMs),
            )
            .fade(
              begin: 0.3,
              end: 0.9,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            )
            .moveY(
              begin: 0,
              end: -10,
              duration: 1500.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
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

