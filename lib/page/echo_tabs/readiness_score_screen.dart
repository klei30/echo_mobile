import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';

class ReadinessScoreScreen extends StatelessWidget {
  final String opportunityTitle;
  final int score;
  final String? why;
  final List<Map<String, dynamic>> parts;

  const ReadinessScoreScreen({
    super.key,
    required this.opportunityTitle,
    required this.score,
    this.why,
    this.parts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final doneCount = parts.where((p) => p['done'] == true).length;
    final missingCount = parts.where((p) => p['done'] != true).length;
    final scoreColor = score >= 70 ? EchoColors.opportunity : score >= 40 ? EchoColors.amber : EchoColors.textGhost;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunityTitle,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost, letterSpacing: 0.5),
                      ),
                      Text(
                        '$score% ready',
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w900, color: scoreColor, height: 1.1),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: scoreColor.withValues(alpha: 0.28)),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.w700, color: scoreColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Score explanation card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EchoColors.opportunity.withValues(alpha: 0.14),
                    EchoColors.bgSurface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHY THIS SCORE?',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.opportunity.withValues(alpha: 0.70)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    doneCount > 0
                        ? '$doneCount part${doneCount == 1 ? '' : 's'} ready. $missingCount part${missingCount == 1 ? '' : 's'} missing.'
                        : 'Start with the first proof item to move this score.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EchoColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    why ?? 'Echo should never hide the formula. You must know the next concrete move.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 6,
                color: EchoColors.bgSurface,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (score / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [EchoColors.practice, EchoColors.opportunity],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Parts list
            Text(
              'WHAT ECHO IS CHECKING',
              style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 12),

            if (parts.isEmpty) ...[
              _defaultPart(context, true, Icons.inventory_2_outlined, EchoColors.proof, 'Proof items', 'Save 3+ real outcomes', 'done'),
              const SizedBox(height: 8),
              _defaultPart(context, false, Icons.link_rounded, EchoColors.opportunity, 'Public artifact', 'Missing link or note', 'gap'),
              const SizedBox(height: 8),
              _defaultPart(context, false, Icons.format_quote_rounded, EchoColors.primaryAi, 'Feedback quote', 'Ask one person', 'gap'),
            ] else
              ...parts.asMap().entries.map((e) {
                final p = e.value;
                final done = p['done'] == true;
                final label = p['label'] as String? ?? 'Requirement ${e.key + 1}';
                final sub = p['description'] as String? ?? '';
                final tag = done ? 'done' : 'gap';
                final color = done ? EchoColors.practice : EchoColors.risk;
                final icon = done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _defaultPart(context, done, icon, color, label, sub, tag),
                );
              }),

            const SizedBox(height: 24),

            // Primary action
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProofBuilderScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: EchoColors.proof,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  'Build missing proof',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultPart(BuildContext context, bool done, IconData icon, Color color, String label, String sub, String tag) {
    final tagBg = tag == 'done'
        ? EchoColors.practice.withValues(alpha: 0.12)
        : tag == 'gap'
        ? EchoColors.risk.withValues(alpha: 0.11)
        : EchoColors.bgSurface;
    final tagFg = tag == 'done' ? EchoColors.practice : tag == 'gap' ? EchoColors.risk : EchoColors.textGhost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: EchoColors.textPrimary)),
                if (sub.isNotEmpty)
                  Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tagFg.withValues(alpha: 0.28)),
            ),
            child: Text(
              tag,
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: tagFg),
            ),
          ),
        ],
      ),
    );
  }
}
