import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class AfterMeetingScreen extends StatefulWidget {
  const AfterMeetingScreen({super.key});

  @override
  State<AfterMeetingScreen> createState() => _AfterMeetingScreenState();
}

class _AfterMeetingScreenState extends State<AfterMeetingScreen> {
  Map<String, dynamic>? _mirror;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    final data = await EchoApiClient().getWeeklyMirror();
    if (!mounted) return;
    setState(() {
      _mirror = data;
      _loading = false;
      _error = data == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavHeader(context),
            Expanded(
              child: _loading
                  ? _buildLoading()
                  : _error
                      ? _buildError()
                      : _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavHeader(BuildContext context) {
    final weekNumber = _mirror?['week_number'] as int? ?? 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      decoration: const BoxDecoration(
        color: EchoColors.bg,
        border: Border(bottom: BorderSide(color: EchoColors.borderNav)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: EchoColors.textMuted),
          ),
          const SizedBox(width: 10),
          EchoOrb(size: 32, rings: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Echo', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: EchoColors.textPrimary, letterSpacing: -0.3)),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: EchoColors.textGhost),
                    children: [
                      TextSpan(
                        text: 'week $weekNumber',
                        style: const TextStyle(color: Color(0xFF9A7048), fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' · what I noticed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EchoOrb(size: 36, rings: 2),
          const SizedBox(height: 18),
          Text(
            'Echo is reflecting...',
            style: GoogleFonts.lora(
              fontSize: 15, fontStyle: FontStyle.italic,
              color: EchoColors.textGhost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Couldn\'t reach Echo.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textGhost)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Text('Tap to retry',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final headline = _mirror?['headline'] as String? ?? '';
    final rawObs = (_mirror?['observations'] as List? ?? []).cast<String>();
    final sitWith = _mirror?['sit_with_this'] as String? ?? '';
    final experiment = _mirror?['experiment'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildMeetingHeader(headline),
        const SizedBox(height: 14),
        Text(
          'WHAT I SAW THIS WEEK',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5, fontWeight: FontWeight.w700,
            letterSpacing: 1.0, color: EchoColors.textGhost,
          ),
        ),
        const SizedBox(height: 12),
        ...rawObs.asMap().entries.map((e) => _buildObservation(e.value, e.key)),
        if (sitWith.isNotEmpty) _buildVerdict(sitWith),
        if (experiment.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildExperiment(experiment),
        ],
        const SizedBox(height: 14),
        _buildCta(context),
      ],
    );
  }

  Widget _buildMeetingHeader(String headline) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0806),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: EchoColors.amber),
              ),
              const SizedBox(width: 8),
              Text(
                'Echo was watching',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF7A5A30), letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (headline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              headline,
              style: GoogleFonts.lora(
                fontSize: 13.5, fontStyle: FontStyle.italic,
                height: 1.6, color: EchoColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObservation(String text, int index) {
    final icons = ['⟳', '⟴', '◌', '→'];
    final icon = icons[index % icons.length];
    final dimmed = index >= 2;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080706),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: dimmed ? const Color(0xFF1E1B17) : EchoColors.amber,
            width: 2,
          ),
          right: const BorderSide(color: Color(0xFF080706)),
          top: const BorderSide(color: Color(0xFF080706)),
          bottom: const BorderSide(color: Color(0xFF080706)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon,
              style: TextStyle(
                fontSize: 16,
                color: dimmed ? const Color(0xFF2A2520) : const Color(0xFF9A9590),
              )),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, height: 1.65,
                color: dimmed ? const Color(0xFF5A5550) : const Color(0xFF9A9590),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdict(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIT WITH THIS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: const Color(0xFF5A4A38),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 14.5, fontStyle: FontStyle.italic,
              height: 1.65, color: const Color(0xFFB8B4AE),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperiment(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080706),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: EchoColors.indigo.withValues(alpha: 0.5), width: 2),
          right: const BorderSide(color: Color(0xFF080706)),
          top: const BorderSide(color: Color(0xFF080706)),
          bottom: const BorderSide(color: Color(0xFF080706)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRY THIS WEEK',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: const Color(0xFF3A4A6A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, height: 1.6,
              color: const Color(0xFF7A8AAA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
          ),
        ),
        child: Center(
          child: Text(
            'Talk about this',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF060504),
            ),
          ),
        ),
      ),
    );
  }
}
