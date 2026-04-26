import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';

class AfterMeetingObservation {
  final String icon;
  final String text;
  final bool dimmed;
  const AfterMeetingObservation({
    required this.icon,
    required this.text,
    this.dimmed = false,
  });
}

class AfterMeetingScreen extends StatelessWidget {
  final String meetingTitle;
  final String meetingDuration;
  final int weekNumber;
  final List<AfterMeetingObservation> observations;
  final String verdict;
  final VoidCallback? onTalkAboutThis;

  const AfterMeetingScreen({
    super.key,
    this.meetingTitle = 'product call',
    this.meetingDuration = '90 min',
    this.weekNumber = 11,
    this.observations = const [],
    this.verdict = '',
    this.onTalkAboutThis,
  });

  static const _defaultObservations = [
    AfterMeetingObservation(
      icon: '⟳',
      text: 'You had the **right answer three times** and deferred to Marcus anyway. You said "I might be wrong but—" before each one.',
    ),
    AfterMeetingObservation(
      icon: '⟴',
      text: 'The one moment you spoke **without hedging**, everyone stopped talking. The room listened.',
    ),
    AfterMeetingObservation(
      icon: '◌',
      text: 'You mentioned the architecture idea twice — and dropped it both times when Marcus changed the subject.',
      dimmed: true,
    ),
  ];

  static const _defaultVerdict =
      'Confidence isn\'t the thing you need to learn. You already have the answers. You\'re just still asking permission to say them.';

  @override
  Widget build(BuildContext context) {
    final obs = observations.isEmpty ? _defaultObservations : observations;
    final verd = verdict.isEmpty ? _defaultVerdict : verdict;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _buildMeetingHeader(),
                  const SizedBox(height: 14),
                  Text(
                    'WHAT I SAW',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.0, color: EchoColors.textGhost,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...obs.map((o) => _buildObservation(o)),
                  _buildVerdict(verd),
                  const SizedBox(height: 14),
                  _buildCta(context),
                ],
              ),
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
                      const TextSpan(text: ' · ambient mode'),
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

  Widget _buildMeetingHeader() {
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
                'Echo was listening',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: const Color(0xFF7A5A30), letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                '$meetingDuration · $meetingTitle',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: EchoColors.textGhost,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Here\'s what I noticed.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: const Color(0xFF5A5550),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservation(AfterMeetingObservation obs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080706),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: obs.dimmed ? const Color(0xFF1E1B17) : EchoColors.amber,
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
          Text(
            obs.icon,
            style: TextStyle(
              fontSize: 16,
              color: obs.dimmed ? const Color(0xFF2A2520) : const Color(0xFF9A9590),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, height: 1.65,
                  color: obs.dimmed ? const Color(0xFF5A5550) : const Color(0xFF9A9590),
                ),
                children: _parseText(obs.text, obs.dimmed),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseText(String text, bool dimmed) {
    final parts = text.split('**');
    return List.generate(parts.length, (i) => TextSpan(
      text: parts[i],
      style: i.isOdd && !dimmed
          ? const TextStyle(
              color: Color(0xFFD8D4CE), fontWeight: FontWeight.w500)
          : null,
    ));
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
            'MY READ',
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
      onTap: onTalkAboutThis ?? () => Navigator.of(context).pop(),
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
