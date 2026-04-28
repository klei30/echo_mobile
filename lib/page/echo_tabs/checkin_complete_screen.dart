import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';

class CheckinCompleteScreen extends StatefulWidget {
  final List<String> answers;

  /// Optional synthesis bullets from POST /v1/daily/checkin.
  /// Null = derive simple bullets from raw answers.
  final List<String>? synthesis;

  const CheckinCompleteScreen({super.key, required this.answers, this.synthesis});

  @override
  State<CheckinCompleteScreen> createState() => _CheckinCompleteScreenState();
}

class _CheckinCompleteScreenState extends State<CheckinCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<String> get _bullets {
    if (widget.synthesis != null && widget.synthesis!.isNotEmpty) {
      return widget.synthesis!;
    }
    return widget.answers.map((a) {
      final trimmed = a.trim();
      return trimmed.length > 80 ? '${trimmed.substring(0, 77)}...' : trimmed;
    }).toList();
  }

  int get _trainingPairs => widget.answers.length * 3;

  void _done() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030201),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  EchoOrb(size: 64, rings: 3),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 36),
                  _buildBullets(),
                  const SizedBox(height: 32),
                  _buildPairsCount(),
                  const Spacer(flex: 3),
                  _buildActions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'TONIGHT ECHO LEARNED',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5, fontWeight: FontWeight.w700,
            letterSpacing: 1.4, color: EchoColors.amber,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Signal received.',
          style: GoogleFonts.lora(
            fontSize: 22, fontStyle: FontStyle.italic,
            color: EchoColors.textPrimary, letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildBullets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _bullets.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: EchoColors.amber,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, height: 1.65,
                    color: EchoColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPairsCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: EchoColors.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$_trainingPairs new training pairs added tonight',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5, color: EchoColors.amberText,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _done,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                ),
              ),
              child: Center(
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: const Color(0xFF060504),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _done, // TODO: also switch to chat tab once tab controller is accessible
          child: Text(
            'Tell me more',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: EchoColors.textGhost,
            ),
          ),
        ),
      ],
    );
  }
}
