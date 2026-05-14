import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class DiscoveryReadyScreen extends StatefulWidget {
  final VoidCallback? onTap;
  const DiscoveryReadyScreen({super.key, this.onTap});

  @override
  State<DiscoveryReadyScreen> createState() => _DiscoveryReadyScreenState();
}

class _DiscoveryReadyScreenState extends State<DiscoveryReadyScreen> with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _slowRing;
  late final AnimationController _medRing;
  late final AnimationController _fastRing;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);
    _slowRing = AnimationController(vsync: this, duration: const Duration(seconds: 72))..repeat();
    _medRing = AnimationController(vsync: this, duration: const Duration(seconds: 44))..repeat(reverse: true);
    _fastRing = AnimationController(vsync: this, duration: const Duration(seconds: 26))..repeat();
    final rng = Random(42);
    _particles = List.generate(5, (i) => _Particle(
      left: 0.10 + rng.nextDouble() * 0.80,
      top: 0.25 + rng.nextDouble() * 0.50,
      dur: 3.9 + rng.nextDouble() * 2.4,
      delay: rng.nextDouble() * 3.2,
      gold: i >= 3,
    ));
  }

  @override
  void dispose() {
    _breathe.dispose();
    _slowRing.dispose();
    _medRing.dispose();
    _fastRing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050d0b),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap ?? () => Navigator.of(context).pop(),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Particles
              ..._particles.map((p) => _ParticleWidget(particle: p)),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gold orb with spinning rings
                    SizedBox(
                      width: 134,
                      height: 134,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow
                          Container(
                            width: 134,
                            height: 134,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0x33C59A34), blurRadius: 90, spreadRadius: 40)],
                            ),
                          ),
                          // Slow ring
                          AnimatedBuilder(
                            animation: _slowRing,
                            builder: (_, __) => Transform.rotate(
                              angle: _slowRing.value * 2 * pi,
                              child: CustomPaint(painter: _DashedCirclePainter(62, const Color(0x21C59A34), 4, 14)),
                            ),
                          ),
                          // Med ring (reverse)
                          AnimatedBuilder(
                            animation: _medRing,
                            builder: (_, __) => Transform.rotate(
                              angle: -_medRing.value * 2 * pi,
                              child: CustomPaint(painter: _DashedCirclePainter(46, const Color(0x38C59A34), 3, 9)),
                            ),
                          ),
                          // Fast ring
                          AnimatedBuilder(
                            animation: _fastRing,
                            builder: (_, __) => Transform.rotate(
                              angle: _fastRing.value * 2 * pi,
                              child: CustomPaint(painter: _DashedCirclePainter(30, const Color(0x57C59A34), 2, 7)),
                            ),
                          ),
                          // Core orb
                          AnimatedBuilder(
                            animation: _breathe,
                            builder: (_, __) => Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0x1FC59A34),
                                border: Border.all(color: const Color(0x6BC59A34), width: 1.5),
                                boxShadow: [BoxShadow(color: Color.fromRGBO(197, 154, 52, 0.12 + _breathe.value * 0.10), blurRadius: 12)],
                              ),
                            ),
                          ),
                          // Bright center dot
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xB3C59A34),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'D I S C O V E R Y',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                        color: const Color(0x99C59A34),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Echo found a pattern\nwith evidence.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xA6C3DCD7),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0x2EC59A34)),
                      ),
                      child: Text(
                        'Tap to read',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: const Color(0x8CC59A34),
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
    );
  }
}

class _Particle {
  final double left;
  final double top;
  final double dur;
  final double delay;
  final bool gold;
  const _Particle({required this.left, required this.top, required this.dur, required this.delay, required this.gold});
}

class _ParticleWidget extends StatefulWidget {
  final _Particle particle;
  const _ParticleWidget({super.key, required this.particle});

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: (widget.particle.dur * 1000).round()));
    Future.delayed(Duration(milliseconds: (widget.particle.delay * 1000).round()), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final x = widget.particle.left * constraints.maxWidth;
      final y = widget.particle.top * constraints.maxHeight;
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          final opacity = t < 0.25 ? t / 0.25 * 0.55 : t > 0.85 ? (1 - t) / 0.15 * 0.55 : 0.55;
          return Positioned(
            left: x,
            top: y - t * 52,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.particle.gold ? const Color(0xB3C59A34) : const Color(0xA683BDF2),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _DashedCirclePainter extends CustomPainter {
  final double radius;
  final Color color;
  final double dashLength;
  final double gapLength;

  const _DashedCirclePainter(this.radius, this.color, this.dashLength, this.gapLength);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * pi * radius;
    final dashCount = circumference / (dashLength + gapLength);
    final dashAngle = (dashLength / circumference) * 2 * pi;
    final gapAngle = (gapLength / circumference) * 2 * pi;

    for (int i = 0; i < dashCount.floor(); i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}
