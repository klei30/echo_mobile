import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await EchoApiClient().getOpportunities();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    final saved = await EchoApiClient().generateOpportunity();
    if (!mounted) return;
    setState(() => _generating = false);
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not generate an opportunity. Check your Echo connection.')));
      return;
    }
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  Future<void> _openProofBuilder() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProofBuilderScreen()));
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = (_data?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final proofSummary = Map<String, dynamic>.from(_data?['proof_summary'] as Map? ?? {});
    final proofCount = (proofSummary['count'] as num?)?.toInt() ?? 0;
    final byCategory = (proofSummary['by_category'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: EchoColors.amber,
          backgroundColor: EchoColors.bgSurface,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
              _header(context),
              const SizedBox(height: 20),
              Text(
                'What can your current proof unlock next?',
                style: GoogleFonts.lora(fontSize: 24, height: 1.28, fontStyle: FontStyle.italic, color: EchoColors.textPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                'Echo maps your direction and evidence into a practical opportunity plan. The goal is not only self-knowledge; it is a visible path toward work, study, projects, scholarships, or a personal milestone.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.55, color: EchoColors.textMuted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.inventory_2_outlined, '$proofCount proof items'),
                  ...byCategory.take(3).map((cat) => _pill(Icons.label_outline_rounded, '${cat['category']} ${cat['cnt']}')),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(_generating ? 'Generating...' : 'Generate plan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: EchoColors.amber,
                        foregroundColor: EchoColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openProofBuilder,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Build proof'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EchoColors.amber,
                        side: BorderSide(color: EchoColors.amber.withValues(alpha: 0.28)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 44),
                  child: Center(child: CircularProgressIndicator(color: EchoColors.amber)),
                )
              else if (items.isEmpty)
                _empty()
              else
                ...items.map(_opportunityCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Opportunities',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: EchoColors.textGhost),
        ),
      ],
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Text(
        'No opportunity plan yet. Add one proof item or generate from your current Passport.',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: EchoColors.textMuted),
      ),
    );
  }

  Widget _opportunityCard(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Opportunity';
    final type = item['type'] as String? ?? 'personal_goal';
    final description = item['description'] as String? ?? '';
    final nextStep = item['next_step'] as String? ?? '';
    final generated = item['generated'] == true;
    final required = (item['required_proof'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final missing = (item['missing_proof'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(type), size: 17, color: EchoColors.amber),
              const SizedBox(width: 8),
              Text(
                generated ? 'SUGGESTED' : type.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: EchoColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.35, fontWeight: FontWeight.w900, color: EchoColors.textPrimary)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: EchoColors.textMuted)),
          ],
          if (required.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionTitle('Proof needed'),
            const SizedBox(height: 8),
            ...required.take(4).map((text) => _checkLine(text, !missing.contains(text))),
          ],
          if (nextStep.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 16, color: EchoColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextStep,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'job' => Icons.work_outline_rounded,
      'school' => Icons.school_outlined,
      'scholarship' => Icons.workspace_premium_outlined,
      'project' => Icons.handyman_outlined,
      _ => Icons.public_rounded,
    };
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: EchoColors.textGhost));
  }

  Widget _checkLine(String text, bool complete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(complete ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded, size: 15, color: complete ? EchoColors.amber : EchoColors.textGhost),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: complete ? EchoColors.textMuted : EchoColors.textGhost)),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: EchoColors.amber.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
        ],
      ),
    );
  }
}
