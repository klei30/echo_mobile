import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';

/// Revelation: rare, earned prose letter delivered as a slow typewriter.
/// No stats, no UI chrome. Just the letter.
class RevelationScreen extends StatefulWidget {
  final String letter;
  const RevelationScreen({super.key, required this.letter});

  @override
  State<RevelationScreen> createState() => _RevelationScreenState();
}

class _RevelationScreenState extends State<RevelationScreen>
    with SingleTickerProviderStateMixin {
  String _displayed = '';
  bool _done = false;
  Timer? _typeTimer;

  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Start typewriter after fade-in
    Future.delayed(const Duration(milliseconds: 1600), _startTypewriter);
  }

  void _startTypewriter() {
    int index = 0;
    const charDelay = Duration(milliseconds: 22);
    _typeTimer = Timer.periodic(charDelay, (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (index >= widget.letter.length) {
        t.cancel();
        setState(() => _done = true);
        return;
      }
      setState(() {
        _displayed = widget.letter.substring(0, index + 1);
      });
      index++;
    });
  }

  void _skipToEnd() {
    _typeTimer?.cancel();
    setState(() {
      _displayed = widget.letter;
      _done = true;
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: GestureDetector(
        onTap: _done ? null : _skipToEnd,
        child: FadeTransition(
          opacity: _fadeCtrl,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "REVELATION" label — faint, top
                        Text(
                          'R E V E L A T I O N',
                          style: GoogleFonts.inter(
                            color: EchoColors.amber.withValues(alpha: 0.25),
                            fontSize: 10,
                            letterSpacing: 3.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Letter text — typewriter
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _displayed,
                                style: GoogleFonts.lora(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 18,
                                  height: 1.85,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              if (!_done)
                                TextSpan(
                                  text: '|',
                                  style: GoogleFonts.lora(
                                    color: EchoColors.amber.withValues(alpha: 0.70),
                                    fontSize: 18,
                                    height: 1.85,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (!_done) ...[
                          const SizedBox(height: 48),
                          Center(
                            child: Text(
                              'tap to reveal',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.15),
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Close — only visible after letter finishes
                AnimatedOpacity(
                  opacity: _done ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 1000),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Center(
                          child: Text(
                            'Carry this',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
