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
  Map<String, dynamic>? _insights;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    final data = await EchoApiClient().getUserInsights();
    if (!mounted) return;
    setState(() {
      _insights = data;
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
                Text(
                  'recent patterns · what I noticed',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: EchoColors.textGhost),
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
    final latestPattern = _insights?['latest_pattern'] as String? ?? '';
    final rawObs = (_insights?['observations'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final sitWith = _insights?['sit_with_this'] as String? ?? '';

    // If insights has no observations, show latest_pattern as a single observation
    final displayObs = rawObs.isNotEmpty
        ? rawObs
        : (latestPattern.isNotEmpty ? [latestPattern] : <String>[]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _buildMeetingHeader(latestPattern),
        const SizedBox(height: 14),
        if (displayObs.isNotEmpty) ...[
          Text(
            'WHAT I NOTICED',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: EchoColors.textGhost,
            ),
          ),
          const SizedBox(height: 12),
          ...displayObs.asMap().entries.map((e) => _buildObservation(e.value, e.key)),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Keep talking — Echo is still forming patterns.',
              style: GoogleFonts.lora(
                fontSize: 14, fontStyle: FontStyle.italic,
                color: EchoColors.textGhost, height: 1.6,
              ),
            ),
          ),
        if (sitWith.isNotEmpty) _buildVerdict(sitWith),
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
