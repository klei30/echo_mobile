import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class ProgressMapScreen extends StatefulWidget {
  const ProgressMapScreen({super.key});

  @override
  State<ProgressMapScreen> createState() => _ProgressMapScreenState();
}

class _ProgressMapScreenState extends State<ProgressMapScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  late final List<_Particle> _particles;
  late final List<AnimationController> _particleCtrl;

  @override
  void initState() {
    super.initState();
    final rng = Random(7);
    _particles = List.generate(
      5,
      (i) => _Particle(
        left: 0.10 + rng.nextDouble() * 0.80,
        top: 0.20 + rng.nextDouble() * 0.60,
        dur: 4.0 + rng.nextDouble() * 2.5,
        delay: rng.nextDouble() * 3.5,
      ),
    );
    _particleCtrl = _particles.map((p) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (p.dur * 1000).round()),
      );
      Future.delayed(Duration(milliseconds: (p.delay * 1000).round()), () {
        if (mounted) ctrl.repeat();
      });
      return ctrl;
    }).toList();
    _load();
  }

  @override
  void dispose() {
    for (final c in _particleCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final data = await EchoApiClient().getUserStats();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final practices = (_data?['practices'] as num?)?.toInt() ?? (_data?['outcomes'] as num?)?.toInt() ?? 0;
    final proof = (_data?['proof_count'] as num?)?.toInt() ?? 0;
    final readiness = (_data?['xp'] as num?)?.toInt() ?? (practices * 15 + proof * 25);
    final stage = (readiness / 100).floor() + 1;
    final readinessInStage = readiness % 100;
    final progressPct = readinessInStage.clamp(0, 100);
    final totalPairs = (_data?['total_pairs'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF090e0c),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.0,
                  colors: [EchoColors.primaryAi.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),

            // Particles
            ..._particles.asMap().entries.map((e) {
              final p = e.value;
              final ctrl = _particleCtrl[e.key];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final x = p.left * constraints.maxWidth;
                  final y = p.top * constraints.maxHeight;
                  return AnimatedBuilder(
                    animation: ctrl,
                    builder: (_, __) {
                      final t = ctrl.value;
                      final opacity = t < 0.25
                          ? t / 0.25 * 0.55
                          : t > 0.85
                          ? (1 - t) / 0.15 * 0.55
                          : 0.55;
                      return Positioned(
                        left: x,
                        top: y - t * 52,
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: Container(
                            width: 2,
                            height: 2,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: EchoColors.primaryAi.withValues(alpha: 0.65)),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }),

            // Content
            if (_loading)
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: EchoColors.primaryAi.withValues(alpha: 0.5)),
                ),
              )
            else
              ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: [EchoColors.opportunity.withValues(alpha: 0.24), EchoColors.practice.withValues(alpha: 0.18)],
                          ),
                          border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.28)),
                        ),
                        child: Text(
                          'Stage $stage · $readiness readiness',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: EchoColors.opportunity,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$progressPct% ready',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 190),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EchoColors.bgSurface.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: EchoColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'GROWTH STAGE $stage',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: EchoColors.textGhost,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Proof unlocks opportunity.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: EchoColors.textPrimary, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Progress is measured by useful evidence, not vanity streaks.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            height: 5,
                            color: EchoColors.bgSurface,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (readinessInStage / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(gradient: LinearGradient(colors: [EchoColors.practice, EchoColors.primaryAi])),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Metrics row
                  Row(
                    children: [
                      _darkMetric('$practices', 'practices'),
                      const SizedBox(width: 8),
                      _darkMetric('$proof', 'proof'),
                      const SizedBox(width: 8),
                      _darkMetric('$totalPairs', 'turns'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Practice list header
                  Text(
                    'MOMENTUM',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
                  ),
                  const SizedBox(height: 10),

                  // Readiness card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: EchoColors.bgSurface.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EchoColors.practice.withValues(alpha: 0.24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'READINESS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                            color: EchoColors.practice.withValues(alpha: 0.70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${min(100, readiness)}% to opportunity-ready',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            height: 7,
                            color: EchoColors.bgSurface,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: min(1.0, readiness / 100),
                              child: Container(
                                decoration: BoxDecoration(gradient: LinearGradient(colors: [EchoColors.practice, EchoColors.primaryAi])),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _darkMetric(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: EchoColors.proof,
                shadows: [Shadow(color: EchoColors.proof.withValues(alpha: 0.55), blurRadius: 16)],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: EchoColors.textGhost),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double left;
  final double top;
  final double dur;
  final double delay;
  const _Particle({required this.left, required this.top, required this.dur, required this.delay});
}
