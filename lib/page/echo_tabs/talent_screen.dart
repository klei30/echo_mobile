import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class TalentScreen extends StatefulWidget {
  const TalentScreen({super.key});

  @override
  State<TalentScreen> createState() => _TalentScreenState();
}

class _TalentScreenState extends State<TalentScreen> {
  Map<String, dynamic>? _talent;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final data = await EchoApiClient().getTalent();
    if (!mounted) return;
    setState(() {
      _talent = data;
      _loading = false;
      _error = data == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EchoOrb(size: 48, rings: 3),
          const SizedBox(height: 24),
          Text(
            'Echo is looking for you\nacross all your conversations...',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(fontSize: 15, fontStyle: FontStyle.italic, color: EchoColors.textGhost, height: 1.6),
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
          Text('Couldn\'t reach Echo.', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textGhost)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Text('Tap to retry', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final traitName = _talent?['trait_name'] as String? ?? '';
    final narrative = _talent?['narrative'] as String? ?? '';
    final evidence = (_talent?['evidence'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final rarityPct = _talent?['rarity_pct'] as int?;
    final whatItMeans = _talent?['what_it_means'] as String? ?? '';
    final weeksActive = _talent?['weeks_active'] as int? ?? 1;
    final totalPairs = _talent?['total_pairs'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(weeksActive, totalPairs),
          const SizedBox(height: 32),
          _buildRevealIntro(),
          const SizedBox(height: 24),
          _buildTraitName(traitName, rarityPct),
          const SizedBox(height: 28),
          _buildNarrative(narrative),
          if (evidence.isNotEmpty) ...[const SizedBox(height: 28), _buildEvidence(evidence)],
          if (whatItMeans.isNotEmpty) ...[const SizedBox(height: 28), _buildWhatItMeans(whatItMeans)],
          const SizedBox(height: 24),
          _buildCorrectionRow(),
          const SizedBox(height: 32),
          _buildFooter(weeksActive, totalPairs),
        ],
      ),
    );
  }

  Widget _buildHeader(int weeks, int pairs) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What Echo Sees',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: EchoColors.textPrimary, letterSpacing: -0.3),
              ),
              const SizedBox(height: 2),
              Text(
                '$pairs conversations · $weeks ${weeks == 1 ? 'week' : 'weeks'}',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close, color: EchoColors.textGhost, size: 20),
        ),
      ],
    );
  }

  Widget _buildRevealIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'THE HIDDEN GIFT',
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: EchoColors.amber),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: EchoColors.borderSubtle)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Echo has been building a picture of how you think.',
          style: GoogleFonts.lora(fontSize: 19, fontStyle: FontStyle.italic, height: 1.5, color: EchoColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Not what you think about — how.',
          style: GoogleFonts.lora(fontSize: 19, fontStyle: FontStyle.italic, height: 1.5, color: EchoColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Here\'s what I found.',
          style: GoogleFonts.lora(fontSize: 19, fontStyle: FontStyle.italic, height: 1.5, color: EchoColors.amberText),
        ),
      ],
    );
  }

  Widget _buildTraitName(String name, int? rarityPct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1510),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR COGNITIVE GIFT',
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: EchoColors.amber),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.lora(fontSize: 26, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, letterSpacing: -0.3),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  rarityPct == null ? 'Personal baseline' : 'Top $rarityPct% pattern',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: EchoColors.amberText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNarrative(String text) {
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT I SEE',
          style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: EchoColors.textGhost),
        ),
        const SizedBox(height: 12),
        ...paragraphs.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(p.trim(), style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.72, color: EchoColors.textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidence(List<String> evidence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT I NOTICED',
          style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: EchoColors.textGhost),
        ),
        const SizedBox(height: 12),
        ...evidence.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: e.key == 0
                          ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [EchoColors.amber, Colors.transparent])
                          : null,
                      color: e.key == 0 ? null : EchoColors.borderSubtle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(e.value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.65, color: EchoColors.textMuted)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatItMeans(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHAT THIS MEANS FOR YOU',
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: EchoColors.amber),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.lora(fontSize: 13, fontStyle: FontStyle.italic, height: 1.72, color: const Color(0xFFA8A4A0)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int weeks, int pairs) {
    return Center(
      child: Text(
        'Built from $pairs conversations over $weeks ${weeks == 1 ? 'week' : 'weeks'}.\nEcho gets sharper every day.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.6, color: EchoColors.textGhost),
      ),
    );
  }

  Widget _buildCorrectionRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await EchoApiClient().recordOutcome(
                subjectType: 'talent_read',
                outcome: 'not_true',
                score: -0.8,
                note: 'User rejected talent revelation',
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: EchoColors.bgCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    'Correction saved. Echo will adjust the deeper read.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EchoColors.borderSubtle),
              ),
              child: Center(
                child: Text(
                  'This does not fit me',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
