import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_design_system.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:share_plus/share_plus.dart';

class GrowthCardScreen extends StatefulWidget {
  const GrowthCardScreen({super.key});

  @override
  State<GrowthCardScreen> createState() => _GrowthCardScreenState();
}

class _GrowthCardScreenState extends State<GrowthCardScreen> {
  Map<String, dynamic>? _card;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final card = await EchoApiClient().getGrowthCard();
    if (!mounted) return;
    setState(() {
      _card = card;
      _loading = false;
    });
  }

  Future<void> _shareCard() async {
    final direction = _card?['direction'] as String? ?? '';
    final label = _card?['confidence_label'] as String? ?? '';
    final proofCount = _card?['proof_count'] ?? 0;
    final weeksActive = _card?['weeks_active'] ?? 0;
    final signals = (_card?['strong_signals'] as List? ?? []).take(3).map((e) => '- $e').join('\n');
    final text =
        'My Echo Proof Card\n\n'
        'Direction: $direction\n'
        'Confidence: $label\n'
        'Proof built: $proofCount items - $weeksActive weeks active\n'
        'What this proves: consistent practice, useful outcomes, and shareable evidence.\n\n'
        '${signals.isNotEmpty ? 'Strong signals:\n$signals\n\n' : ''}'
        'Built with Echo - a private mentor that learns from real life.\n#EchoProof';
    await SharePlus.instance.share(ShareParams(text: text, subject: 'My Echo Proof Card'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: AppBar(
        backgroundColor: EchoColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: EchoColors.textGhost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Proof Card',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
        ),
        actions: [
          if (!_loading && _card != null)
            IconButton(icon: const Icon(Icons.share_outlined, size: 20), color: EchoColors.amber, onPressed: _shareCard),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: EchoColors.amber))
            : _card == null
            ? Center(
                child: Text(
                  'Proof card not available yet.\nBuild more proof to unlock it.',
                  textAlign: TextAlign.center,
                  style: EchoText.body(size: 14),
                ),
              )
            : _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final direction = _card!['direction'] as String? ?? 'Direction forming';
    final confidenceLabel = _card!['confidence_label'] as String? ?? 'early';
    final proofCount = (_card!['proof_count'] as num?)?.toInt() ?? 0;
    final weeksActive = (_card!['weeks_active'] as num?)?.toInt() ?? 0;
    final strongSignals = (_card!['strong_signals'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final shareableProof = (_card!['shareable_proof'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Privacy badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: EchoColors.practice.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded, size: 13, color: EchoColors.practice),
                const SizedBox(width: 6),
                Text(
                  'No private memory · No conversations',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.practice, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hero card — dual-tonal gradient (Fix #9)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(EchoColors.opportunity.withValues(alpha: 0.18), EchoColors.surface),
                  Color.alphaBlend(EchoColors.proof.withValues(alpha: 0.10), EchoColors.surface),
                ],
              ),
              borderRadius: BorderRadius.circular(EchoRadii.lg),
              border: Border.all(color: Color.alphaBlend(EchoColors.opportunity.withValues(alpha: 0.30), EchoColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EchoTag(icon: Icons.trending_up_rounded, label: 'Proof Card', color: EchoColors.amber, filled: true),
                    const Spacer(),
                    EchoTag(icon: Icons.query_stats_rounded, label: confidenceLabel, color: EchoColors.opportunity),
                  ],
                ),
                const SizedBox(height: 16),
                Text(direction, style: EchoText.serifTitle(size: 20)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    EchoMetric(value: '$proofCount', label: 'proof built', color: EchoColors.proof),
                    const SizedBox(width: 8),
                    EchoMetric(value: '$weeksActive', label: 'weeks active', color: EchoColors.practice),
                    if (strongSignals.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      EchoMetric(value: '${strongSignals.length}', label: 'signals', color: EchoColors.memory),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (strongSignals.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'WHAT THIS PROVES',
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 8),
            Text(
              'A public-safe pattern of effort, follow-through, and evidence. Private memories and raw conversations stay out of the share card.',
              style: EchoText.body(size: 12.5),
            ),
            const SizedBox(height: 18),
            Text(
              'STRONG SIGNALS',
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strongSignals.map((s) => EchoTag(icon: Icons.bolt_rounded, label: s, color: EchoColors.amber)).toList(),
            ),
          ],

          if (shareableProof.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'PROOF HIGHLIGHTS',
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, letterSpacing: 1.4, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 10),
            ...shareableProof.map((item) {
              final title = item['title'] as String? ?? '';
              final category = item['category'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EchoPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: EchoColors.proof),
                      const SizedBox(width: 10),
                      Expanded(child: Text(title, style: EchoText.body(size: 13))),
                      const SizedBox(width: 8),
                      EchoTag(icon: Icons.label_outline_rounded, label: category, color: EchoColors.textGhost),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 24),
          EchoPrimaryButton(label: 'Share Proof Card', icon: Icons.share_rounded, color: EchoColors.amber, onPressed: _shareCard),
        ],
      ),
    );
  }
}
