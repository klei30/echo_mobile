import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';

class DiscoveryInsightScreen extends StatefulWidget {
  final String title;
  final String body;
  final String? patternId;

  const DiscoveryInsightScreen({super.key, required this.title, required this.body, this.patternId});

  @override
  State<DiscoveryInsightScreen> createState() => _DiscoveryInsightScreenState();
}

class _DiscoveryInsightScreenState extends State<DiscoveryInsightScreen> with TickerProviderStateMixin {
  late final AnimationController _slowRing;
  late final AnimationController _medRing;
  bool _acted = false;

  @override
  void initState() {
    super.initState();
    _slowRing = AnimationController(vsync: this, duration: const Duration(seconds: 72))..repeat();
    _medRing = AnimationController(vsync: this, duration: const Duration(seconds: 44))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _slowRing.dispose();
    _medRing.dispose();
    super.dispose();
  }

  Future<void> _turnIntoToday() async {
    setState(() => _acted = true);
    if (widget.patternId != null) {
      await EchoApiClient().recordOutcome(
        subjectType: 'discovery_pattern',
        subjectId: widget.patternId,
        outcome: 'turn_into_today',
        score: 0.9,
        note: 'User chose to turn discovery into Today step',
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop('today');
  }

  Future<void> _saveToProof() async {
    setState(() => _acted = true);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProofBuilderScreen(
          initialIntent: ProofBuilderIntent(
            title: widget.title,
            description: widget.body,
            category: 'insight',
            opportunityType: 'personal_goal',
            skillTags: ['self-awareness', 'pattern recognition'],
            sourceLabel: 'Echo Discovery',
          ),
          autoOpenDraft: true,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop('proof');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current read changed',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EchoColors.textGhost, letterSpacing: 0.5),
                        ),
                        Text(
                          'Discovery',
                          style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: EchoColors.opportunity.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.28)),
                    ),
                    child: Center(
                      child: Text('✦', style: TextStyle(fontSize: 13, color: EchoColors.opportunity)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Gold card with mini orb
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [EchoColors.opportunity.withValues(alpha: 0.18), EchoColors.proof.withValues(alpha: 0.10)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.30)),
                  ),
                  child: Stack(
                    children: [
                      // Mini orb in top-right
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Opacity(
                            opacity: 0.45,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_slowRing, _medRing]),
                              builder: (_, __) => CustomPaint(
                                painter: _MiniOrbPainter(slowAngle: _slowRing.value * 2 * pi, medAngle: -_medRing.value * 2 * pi),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'NEW PATTERN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: EchoColors.textGhost,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.title,
                            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: EchoColors.textPrimary, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          Text(widget.body, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _acted ? null : _turnIntoToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [EchoColors.primaryAi, EchoColors.primaryAi.withValues(alpha: 0.80)]),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          'Turn into Today',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _acted ? null : _saveToProof,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: EchoColors.bgSurface,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: EchoColors.borderSubtle),
                        ),
                        child: Text(
                          'Save to Proof',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EchoColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniOrbPainter extends CustomPainter {
  final double slowAngle;
  final double medAngle;

  _MiniOrbPainter({required this.slowAngle, required this.medAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    void drawDashedCircle(double radius, Color color, double dash, double gap, double rotation) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      final circumference = 2 * pi * radius;
      final dashAngle = (dash / circumference) * 2 * pi;
      final gapAngle = (gap / circumference) * 2 * pi;
      final count = (circumference / (dash + gap)).floor();
      for (int i = 0; i < count; i++) {
        final start = rotation + i * (dashAngle + gapAngle);
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, dashAngle, false, paint);
      }
    }

    drawDashedCircle(36, const Color(0x4DC59A34), 3, 10, slowAngle);
    drawDashedCircle(24, const Color(0x73C59A34), 2, 7, medAngle);

    // Core dot
    canvas.drawCircle(center, 6, Paint()..color = const Color(0x2EC59A34));
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = const Color(0x80C59A34)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_MiniOrbPainter old) => old.slowAngle != slowAngle || old.medAngle != medAngle;
}
