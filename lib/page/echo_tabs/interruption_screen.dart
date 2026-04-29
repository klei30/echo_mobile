import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';

/// Full-screen interruption from Echo. A single truth, nothing else.
/// Cannot be swiped away — only dismissed with an explicit choice.
class InterruptionScreen extends StatefulWidget {
  final String statement;
  const InterruptionScreen({super.key, required this.statement});

  @override
  State<InterruptionScreen> createState() => _InterruptionScreenState();
}

class _InterruptionScreenState extends State<InterruptionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeAnim;

  bool _orbVisible = false;
  bool _textVisible = false;
  bool _buttonsVisible = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
    _scheduleReveal();
  }

  Future<void> _scheduleReveal() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _orbVisible = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _textVisible = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _buttonsVisible = true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _dismiss(String choice) {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Breathing orb
                AnimatedOpacity(
                  opacity: _orbVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: _BreathingOrb(),
                ),

                const SizedBox(height: 56),

                // The truth
                AnimatedOpacity(
                  opacity: _textVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  child: AnimatedSlide(
                    offset: _textVisible ? Offset.zero : const Offset(0, 0.04),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    child: Text(
                      widget.statement,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Action buttons
                AnimatedOpacity(
                  opacity: _buttonsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 700),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () => _dismiss('think'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'I need to think about this',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => _dismiss('dismiss'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Dismiss',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.30),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingOrb extends StatefulWidget {
  @override
  State<_BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<_BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EchoColors.amber.withValues(alpha: 0.06 + t * 0.04),
            boxShadow: [
              BoxShadow(
                color: EchoColors.amber.withValues(alpha: 0.10 + t * 0.12),
                blurRadius: 28 + t * 16,
                spreadRadius: t * 6,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.amber.withValues(alpha: 0.18 + t * 0.14),
                boxShadow: [
                  BoxShadow(
                    color: EchoColors.amber.withValues(alpha: 0.18 + t * 0.20),
                    blurRadius: 12 + t * 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
