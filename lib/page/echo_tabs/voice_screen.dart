import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/voice/voice_service.dart';

/// Full-screen real-time voice UI. Opened when the mic button is tapped
/// AFTER VoiceService.connect() succeeds. Closing this screen also disconnects.
class EchoVoiceScreen extends StatefulWidget {
  const EchoVoiceScreen({super.key});

  @override
  State<EchoVoiceScreen> createState() => _EchoVoiceScreenState();
}

class _EchoVoiceScreenState extends State<EchoVoiceScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _durationCtrl;
  int _elapsedSeconds = 0;

  String _userText = '';
  String _statusLabel = 'Echo is listening';
  bool _echoSpeaking = false;
  bool _popping = false;

  StreamSubscription<({String role, String text})>? _transcriptSub;
  StreamSubscription<VoiceState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _waveCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
          ..repeat(reverse: true);
    _durationCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            if (_durationCtrl.status == AnimationStatus.completed) {
              setState(() => _elapsedSeconds++);
              _durationCtrl.forward(from: 0);
            }
          });
    _durationCtrl.forward();

    _transcriptSub = VoiceService().transcriptStream.listen((t) {
      if (!mounted) return;
      setState(() {
        if (t.role == 'user') _userText = t.text;
      });
    });

    _stateSub = VoiceService().stateStream.listen((vs) {
      if (!mounted) return;
      setState(() {
        _echoSpeaking = vs == VoiceState.speaking;
        _statusLabel = switch (vs) {
          VoiceState.listening => 'Echo is listening',
          VoiceState.speaking => 'Echo is speaking',
          VoiceState.connecting => 'Connecting...',
          VoiceState.idle => 'Disconnected',
          _ => 'Echo is listening',
        };
      });
      if (vs == VoiceState.idle && !_popping) {
        _popping = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _durationCtrl.dispose();
    _transcriptSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  String get _durationLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && !_popping) {
          _popping = true;
          await VoiceService().disconnect();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF050403),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOrb(),
                    const SizedBox(height: 28),
                    _buildEchoStatus(),
                  ],
                ),
              ),
              _buildUserStrip(),
              const Divider(color: Color(0xFF0F0E0C), height: 1, indent: 28, endIndent: 28),
              const SizedBox(height: 14),
              _buildWaveform(),
              _buildStatusLabel(),
              const SizedBox(height: 24),
              _buildEndButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: [
          StreamBuilder<VoiceState>(
            stream: VoiceService().stateStream,
            initialData: VoiceService().state,
            builder: (ctx, snap) {
              final connected = snap.data != VoiceState.idle &&
                  snap.data != VoiceState.connecting;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? EchoColors.amber : const Color(0xFF3A3530),
                  boxShadow: connected
                      ? [BoxShadow(color: EchoColors.amber.withValues(alpha: 0.6), blurRadius: 8)]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'real-time voice',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: const Color(0xFF6A5A40), letterSpacing: 0.3),
          ),
          const Spacer(),
          Text(
            _durationLabel,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2A2520)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() => EchoOrb(size: 46, rings: 3);

  Widget _buildEchoStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _echoSpeaking
            ? Text(
                'Echo is speaking...',
                key: const ValueKey('speaking'),
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 17, fontStyle: FontStyle.italic,
                  color: const Color(0xFFB8B4AE), height: 1.65,
                ),
              )
            : Text(
                'Speak whenever you\'re ready.',
                key: const ValueKey('waiting'),
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 17, fontStyle: FontStyle.italic,
                  color: const Color(0xFF3A3530), height: 1.65,
                ),
              ),
      ),
    );
  }

  Widget _buildUserStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOU SAID',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: const Color(0xFF2A2720),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _userText.isEmpty ? '—' : _userText,
              key: ValueKey(_userText),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _userText.isEmpty
                      ? const Color(0xFF2A2720)
                      : const Color(0xFF5A5550),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    const bars = [6.0, 10.0, 18.0, 14.0, 24.0, 20.0, 32.0, 26.0, 38.0, 30.0,
                  42.0, 34.0, 38.0, 28.0, 24.0, 34.0, 22.0, 30.0, 20.0, 16.0,
                  26.0, 14.0, 10.0, 18.0, 8.0];
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(bars.length, (i) {
              final isActive = _echoSpeaking ? i > 8 : i > 16;
              final scale = isActive
                  ? (1.0 + 0.4 * math.sin(_waveCtrl.value * math.pi * 2 + i * 0.3))
                  : 1.0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.25),
                child: Transform.scale(
                  scaleY: scale,
                  child: Container(
                    width: 4,
                    height: bars[i],
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: isActive
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFC4783A), Color(0xFFE8AE60)],
                            )
                          : null,
                      color: isActive ? null : const Color(0xFF1A1710).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStatusLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        _statusLabel,
        style: GoogleFonts.plusJakartaSans(
            fontSize: 11, color: const Color(0xFF3A3530), letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEndButton() {
    return GestureDetector(
      onTap: () async {
        if (_popping) return;
        _popping = true;
        await VoiceService().disconnect();
        if (mounted) Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.3)),
        ),
        child: Text(
          'End voice',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, fontWeight: FontWeight.w500, color: EchoColors.amber),
        ),
      ),
    );
  }
}
