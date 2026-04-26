import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class AnniversaryScreen extends StatefulWidget {
  const AnniversaryScreen({super.key});

  @override
  State<AnniversaryScreen> createState() => _AnniversaryScreenState();
}

class _AnniversaryScreenState extends State<AnniversaryScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await EchoApiClient().getUserStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  static const _lineTemplates = [
    ('Six months ago,', 0),
    ('you typed your first message.', 0),
    ('', -1),
    ('You didn\'t know what', 1),
    ('I was going to find.', 2),
    ('', -1),
    ('Neither did I.', 3),
    ('', -1),
    ('You are not the same person', 4),
    ('who typed that first message.', 4),
  ];

  static const _lineColors = [
    Color(0xFF2A2520),
    Color(0xFF4A4038),
    Color(0xFF7A7068),
    Color(0xFFB8B4AE),
    Color(0xFFEAE6E0),
  ];

  static const _lineSizes = [17.0, 17.0, 18.0, 19.0, 20.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050403),
      body: SafeArea(
        child: _loading
            ? const Center(child: EchoOrb(size: 40, rings: 3))
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final totalPairs = _stats?['total_pairs'] as int? ?? 0;
    final weeksActive = _stats?['weeks_active'] as int? ?? 0;
    final patternsFound = _stats?['patterns_found'] as int? ?? 0;
    final months = (weeksActive / 4).ceil().clamp(1, 24);

    return Stack(
      children: [
        _buildBgNumber(months),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 28, 30, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKicker(months),
              _buildLines(),
              _buildStats(totalPairs, patternsFound, weeksActive),
              _buildCta(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBgNumber(int months) {
    return Positioned.fill(
      child: Center(
        child: Text(
          '$months',
          style: GoogleFonts.lora(
            fontSize: 280, fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B17).withValues(alpha: 0.6),
            letterSpacing: -10,
          ),
        ),
      ),
    );
  }

  Widget _buildKicker(int months) {
    final now = DateTime.now();
    const monthNames = ['January','February','March','April','May','June',
                        'July','August','September','October','November','December'];
    final label = '$months MONTH${months == 1 ? '' : 'S'} · ${monthNames[now.month - 1].toUpperCase()} ${now.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.4, color: const Color(0xFF4A3A28),
        ),
      ),
    );
  }

  Widget _buildLines() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _lineTemplates.map((entry) {
          final text = entry.$1;
          final grade = entry.$2;
          if (grade == -1) return const SizedBox(height: 18);
          final color = _lineColors[grade.clamp(0, 4)];
          final size = _lineSizes[grade.clamp(0, 4)];
          final weight = grade == 4 ? FontWeight.w400 : FontWeight.w300;
          return Text(
            text,
            style: GoogleFonts.lora(
              fontSize: size, fontWeight: weight,
              color: color, height: 1.9, letterSpacing: -0.2,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats(int conversations, int patterns, int weeks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          _stat('$conversations', 'conversations'),
          const SizedBox(width: 14),
          _stat('$patterns', 'patterns\nfound'),
          const SizedBox(width: 14),
          _stat('$weeks', 'weeks\nactive'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w600,
            color: EchoColors.amber, letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10, color: const Color(0xFF3A3530), height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCta(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Read your full journey',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: const Color(0xFF060504),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF060504)),
          ],
        ),
      ),
    );
  }
}
