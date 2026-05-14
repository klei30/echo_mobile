import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'echo_theme.dart';

/// Animated Echo orb with sonar-ring pulse effect.
/// [size] = diameter of the innermost ring.
/// [rings] = 1, 2, or 3 visible rings around the core.
class EchoOrb extends StatefulWidget {
  final double size;
  final int rings;

  const EchoOrb({super.key, this.size = 32, this.rings = 2});

  @override
  State<EchoOrb> createState() => _EchoOrbState();
}

class _EchoOrbState extends State<EchoOrb> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Sinusoidal oscillation between [min] and [max] with a phase offset
  double _pulse(double t, double phase, double min, double max) {
    final v = (1 + math.sin(2 * math.pi * t + phase)) / 2;
    return min + v * (max - min);
  }

  double get _containerSize {
    if (widget.rings >= 3) return widget.size * 1.9;
    if (widget.rings >= 2) return widget.size * 1.5;
    return widget.size;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final cs = _containerSize;
    final coreSize = s * 0.45;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final glowAlpha = 0.30 + 0.20 * _pulse(t, 0, 0, 1);

        return SizedBox(
          width: cs,
          height: cs,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer far ring — only for rings >= 3
              if (widget.rings >= 3) _ring(s * 1.9, _pulse(t, math.pi, 0.05, 0.15), 1.0),
              // Middle ring — only for rings >= 2
              if (widget.rings >= 2) _ring(s * 1.5, _pulse(t, math.pi / 2, 0.12, 0.40), 1.0),
              // Inner ring — always present
              _ring(s, _pulse(t, 0, 0.28, 1.0), 1.5),
              // Amber radial core
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [EchoColors.amberGlow, EchoColors.amber, EchoColors.amberDark],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.amber.withValues(alpha: glowAlpha),
                      blurRadius: s * 0.4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double diameter, double opacity, double strokeWidth) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: EchoColors.amber.withValues(alpha: opacity),
          width: strokeWidth,
        ),
      ),
    );
  }
}
