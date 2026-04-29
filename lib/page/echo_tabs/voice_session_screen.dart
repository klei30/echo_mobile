import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/voice/voice_service.dart';

class VoiceSessionScreen extends StatefulWidget {
  const VoiceSessionScreen({super.key});

  @override
  State<VoiceSessionScreen> createState() => _VoiceSessionScreenState();
}

class _VoiceSessionScreenState extends State<VoiceSessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _orbPulse;
  late final AnimationController _ripple;
  late final StreamSubscription<VoiceState> _stateSub;
  late final StreamSubscription<({String role, String text})> _transcriptSub;

  VoiceState _voiceState = VoiceService().state;
  String _userTranscript = '';
  String _echoTranscript = '';
  bool _connecting = false;
  String? _error;
  Timer? _agentJoinTimeout;

  @override
  void initState() {
    super.initState();

    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _stateSub = VoiceService().stateStream.listen((s) {
      if (!mounted) return;
      setState(() => _voiceState = s);
      if (s == VoiceState.idle && _error == null) {
        // Session ended cleanly — close screen after brief delay
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });

    _transcriptSub = VoiceService().transcriptStream.listen((t) {
      if (!mounted) return;
      _agentJoinTimeout?.cancel(); // Agent is active, cancel timeout
      setState(() {
        if (t.role == 'user') _userTranscript = t.text;
        if (t.role == 'agent') _echoTranscript = t.text;
      });
    });

    _startSession();
  }

  Future<void> _startSession() async {
    if (VoiceService().state != VoiceState.idle) return;
    setState(() {
      _connecting = true;
      _error = null;
    });
    final ok = await VoiceService().connect();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _error = VoiceService().lastError ?? 'Failed to connect';
        _connecting = false;
      });
    } else {
      setState(() => _connecting = false);
      // If no agent joins within 20s, show an actionable error.
      _agentJoinTimeout = Timer(const Duration(seconds: 20), () {
        if (!mounted) return;
        if (_echoTranscript.isEmpty && _voiceState == VoiceState.listening) {
          setState(() => _error = 'Voice agent not responding.\nMake sure start_voice_agent.bat is running on the server.');
        }
      });
    }
  }

  Future<void> _endSession() async {
    HapticFeedback.mediumImpact();
    await VoiceService().disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _agentJoinTimeout?.cancel();
    _stateSub.cancel();
    _transcriptSub.cancel();
    _orbPulse.dispose();
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Close row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _endSession,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Voice',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 32), // balance
                ],
              ),
            ),

            const Spacer(),

            // Orb
            _buildOrb(),

            const SizedBox(height: 32),

            // Status label
            _buildStatusLabel(),

            const SizedBox(height: 24),

            // Transcript
            _buildTranscript(),

            const Spacer(),

            // End session button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: _buildEndButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbPulse, _ripple]),
      builder: (context, _) {
        final t = _orbPulse.value;
        final r = _ripple.value;

        final isSpeaking = _voiceState == VoiceState.speaking;
        final isListening = _voiceState == VoiceState.listening;

        final glowAlpha = isSpeaking
            ? 0.22 + t * 0.18
            : isListening
                ? 0.10 + t * 0.10
                : 0.04 + t * 0.04;
        final glowBlur = isSpeaking ? 70.0 + t * 30 : 50.0 + t * 20;
        final coreAlpha = isSpeaking
            ? 0.18 + t * 0.12
            : isListening
                ? 0.08 + t * 0.08
                : 0.04 + t * 0.04;

        // Ripple rings — only when active
        final showRipple = isListening || isSpeaking;
        final rippleColor = isSpeaking ? const Color(0xFF4A9EDB) : EchoColors.amber;

        return SizedBox(
          width: 220, height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple ring
              if (showRipple)
                Opacity(
                  opacity: (1 - r).clamp(0.0, 1.0),
                  child: Container(
                    width: 160 + r * 60,
                    height: 160 + r * 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: rippleColor.withValues(alpha: 0.25 * (1 - r)),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),

              // Outer glow ring
              Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.amber.withValues(alpha: glowAlpha),
                      blurRadius: glowBlur,
                      spreadRadius: isSpeaking ? 10 : 0,
                    ),
                  ],
                ),
              ),

              // Mid ring
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.amber.withValues(alpha: coreAlpha * 0.5),
                  border: Border.all(
                    color: EchoColors.amber.withValues(
                        alpha: isListening || isSpeaking ? 0.18 + t * 0.10 : 0.06),
                    width: 1.0,
                  ),
                ),
              ),

              // Core
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.amber.withValues(alpha: coreAlpha),
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.amber.withValues(alpha: glowAlpha),
                      blurRadius: 24 + t * 12,
                    ),
                  ],
                ),
                child: isSpeaking
                    ? _buildSpeakingWave(t)
                    : isListening
                        ? Icon(Icons.hearing_rounded,
                            size: 26,
                            color: Colors.black.withValues(alpha: 0.55))
                        : Icon(Icons.mic_none_rounded,
                            size: 26,
                            color: Colors.black.withValues(alpha: 0.35)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeakingWave(double t) {
    return CustomPaint(
      painter: _WavePainter(t),
    );
  }

  Widget _buildStatusLabel() {
    if (_error != null) {
      return Text(
        _error!,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: Colors.red.withValues(alpha: 0.70),
          fontSize: 13,
        ),
      );
    }

    final label = switch (_voiceState) {
      VoiceState.connecting    => 'Connecting...',
      VoiceState.listening     => 'Listening',
      VoiceState.speaking      => 'Echo is speaking',
      VoiceState.disconnecting => 'Ending session...',
      _                        => _connecting ? 'Connecting...' : '',
    };

    final color = switch (_voiceState) {
      VoiceState.speaking => const Color(0xFF4A9EDB),
      VoiceState.listening => EchoColors.amber,
      _ => Colors.white.withValues(alpha: 0.30),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        label,
        key: ValueKey(label),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTranscript() {
    if (_userTranscript.isEmpty && _echoTranscript.isEmpty) {
      return Text(
        _voiceState == VoiceState.listening
            ? 'Go ahead and speak...'
            : '',
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.15),
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          if (_userTranscript.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Text(
                '"$_userTranscript"',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          if (_echoTranscript.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4A9EDB).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4A9EDB).withValues(alpha: 0.15)),
              ),
              child: Text(
                _echoTranscript,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF4A9EDB).withValues(alpha: 0.80),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEndButton() {
    return GestureDetector(
      onTap: _endSession,
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Icon(
          Icons.call_end_rounded,
          size: 24,
          color: Colors.red.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  const _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const bars = 5;
    const spacing = 5.0;
    final totalWidth = (bars - 1) * spacing;
    final startX = cx - totalWidth / 2;

    for (int i = 0; i < bars; i++) {
      final phase = (i / bars) * math.pi * 2;
      final amp = 8.0 * math.sin(t * math.pi * 2 + phase).abs().clamp(0.15, 1.0);
      final x = startX + i * spacing;
      canvas.drawLine(
        Offset(x, cy - amp),
        Offset(x, cy + amp),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}
