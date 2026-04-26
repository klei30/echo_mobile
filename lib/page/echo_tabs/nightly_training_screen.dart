import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class NightlyTrainingScreen extends StatefulWidget {
  const NightlyTrainingScreen({super.key});

  @override
  State<NightlyTrainingScreen> createState() => _NightlyTrainingScreenState();
}

class _NightlyTrainingScreenState extends State<NightlyTrainingScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await EchoApiClient().getUserInsights();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  String _nextMirrorLabel() {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    if (daysUntilSunday == 0) return 'tonight';
    if (daysUntilSunday == 1) return 'tomorrow · 9pm';
    return 'Sunday · 9pm · $daysUntilSunday days away';
  }

  @override
  Widget build(BuildContext context) {
    final turnsAnalyzed = _stats?['turns_analyzed'] as int? ?? 0;
    final newPatterns = _stats?['new_patterns'] as int? ?? 0;
    final accuracyStr = _stats?['accuracy_delta'] as String? ?? '—';
    final newPattern = _stats?['latest_pattern'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF060504),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
              child: Text(
                'OVERNIGHT · TRAINING COMPLETE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: const Color(0xFF2A2520),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: EchoOrb(size: 36, rings: 2))
                  : _buildContent(
                      turnsAnalyzed: turnsAnalyzed,
                      newPatterns: newPatterns,
                      accuracyStr: accuracyStr,
                      newPattern: newPattern,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required int turnsAnalyzed,
    required int newPatterns,
    required String accuracyStr,
    required String newPattern,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrbRow(),
          _buildTitle(),
          _buildSub(),
          _buildStats(turnsAnalyzed, newPatterns, accuracyStr),
          _buildInsight(newPattern),
          _buildCloneCard(),
          _buildNextMirror(),
        ],
      ),
    );
  }

  Widget _buildOrbRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(child: EchoOrb(size: 56, rings: 3)),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        'Echo got smarter\nabout you tonight.',
        style: GoogleFonts.lora(
          fontSize: 22, fontWeight: FontWeight.w400,
          color: EchoColors.textPrimary, letterSpacing: -0.3,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildSub() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(
        'While you slept, your model trained on today\'s conversations and updated your portrait.',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5, color: EchoColors.textGhost, height: 1.5,
        ),
      ),
    );
  }

  Widget _buildStats(int turns, int patterns, String accuracy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          _statTile('$turns', 'turns analyzed'),
          const SizedBox(width: 8),
          _statTile('$patterns', 'new patterns'),
          const SizedBox(width: 8),
          _statTile(accuracy, 'model accuracy',
              valueColor: const Color(0xFF6A9A7A)),
        ],
      ),
    );
  }

  Widget _statTile(String value, String label, {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0806),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFF161210)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22, fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: valueColor ?? EchoColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: EchoColors.textGhost, height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsight(String pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0806),
        borderRadius: BorderRadius.circular(14),
        border: const Border(
          left: BorderSide(color: EchoColors.amber, width: 2),
          right: BorderSide(color: Color(0xFF161210)),
          top: BorderSide(color: Color(0xFF161210)),
          bottom: BorderSide(color: Color(0xFF161210)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW PATTERN FOUND',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: const Color(0xFF7A5A30),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            pattern,
            style: GoogleFonts.lora(
              fontSize: 13.5, fontStyle: FontStyle.italic,
              height: 1.65, color: const Color(0xFFA8A4A0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloneCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080706),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF161210)),
      ),
      child: Row(
        children: [
          const Text('⟳', style: TextStyle(fontSize: 13, color: Color(0xFF6A6560))),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: const Color(0xFF4A4540), height: 1.5,
                ),
                children: const [
                  TextSpan(
                    text: '4 specialist models',
                    style: TextStyle(color: Color(0xFF6A6560), fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: ' trained in parallel last night. The strongest merged into your main Echo.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMirror() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5, color: const Color(0xFF3A3530),
          ),
          children: [
            const TextSpan(text: 'Next mirror: '),
            TextSpan(
              text: _nextMirrorLabel(),
              style: const TextStyle(color: Color(0xFF7A5A30)),
            ),
          ],
        ),
      ),
    );
  }
}
