import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_product_contracts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/outcome_capture_sheet.dart';
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

  Future<void> _openProofBuilder({Map<String, dynamic>? opportunity, String? gap}) async {
    final intent = opportunity == null ? null : _intentForGap(opportunity, gap);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProofBuilderScreen(
          initialIntent: intent,
          autoOpenDraft: intent != null,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _logOpportunityOutcome(Map<String, dynamic> opportunity) async {
    final title = opportunity['title'] as String? ?? 'Opportunity';
    final type = opportunity['type'] as String? ?? 'personal_goal';
    final nextStep = opportunity['next_step'] as String? ?? '';
    final description = opportunity['description'] as String? ?? '';
    final saved = await OutcomeCaptureSheet.show(
      context,
      title: 'Did you move "$title" forward?',
      subjectType: 'opportunity',
      subjectId: title,
      contextNote: nextStep.isNotEmpty ? nextStep : description,
      doneLabel: 'Moved forward',
      skippedLabel: 'Blocked',
      createProof: true,
      proofCategory: 'outcome',
      opportunityType: type,
      proofTitle: 'Outcome for $title',
    );
    if (!mounted || saved != true) return;
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  ProofBuilderIntent _intentForGap(Map<String, dynamic> opportunity, String? gap) {
    final opportunityTitle = opportunity['title'] as String? ?? 'Opportunity';
    final type = opportunity['type'] as String? ?? 'personal_goal';
    final nextStep = opportunity['next_step'] as String? ?? '';
    final description = opportunity['description'] as String? ?? '';
    final target = gap?.trim().isNotEmpty == true ? gap!.trim() : 'next proof';
    final category = _categoryForGap(target);
    final tags = [type.replaceAll('_', ' '), category, target].where((e) => e.isNotEmpty).toList();
    return ProofBuilderIntent(
      title: '${_titleCase(target)} for $opportunityTitle',
      description: _descriptionForGap(target, opportunityTitle, nextStep),
      evidence: description,
      category: category,
      opportunityType: type,
      skillTags: tags,
      sourceLabel: opportunityTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawItems = (_data?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final items = rawItems.isNotEmpty ? rawItems : echoOpportunitySeeds.map((seed) => seed.toJson()).toList();
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
                      onPressed: () => _openProofBuilder(),
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
                Padding(
                  padding: const EdgeInsets.only(top: 44),
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
          icon: Icon(Icons.close_rounded, color: EchoColors.textGhost),
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
        'No opportunity plan yet. Add one proof item or generate from your current read.',
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
    final seeded = item['seeded'] == true;
    final required = (item['required_proof'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final missing = (item['missing_proof'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    final readiness = (item['readiness'] as num?)?.toInt() ?? _readiness(required, missing);
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
                generated
                    ? 'SUGGESTED'
                    : seeded
                    ? 'SEED PLAN'
                    : type.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: EchoColors.amber),
              ),
              const Spacer(),
              _readinessPill(readiness),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.35, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
          ),
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
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _sectionTitle('Build next'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: missing.take(3).map((gap) => _gapButton(item, gap)).toList(),
            ),
          ],
          if (nextStep.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_forward_rounded, size: 16, color: EchoColors.amber),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _cardAction(
                  Icons.add_task_rounded,
                  missing.isNotEmpty ? 'Build first gap' : 'Add proof',
                  () => _openProofBuilder(opportunity: item, gap: missing.isNotEmpty ? missing.first : null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cardAction(
                  Icons.fact_check_outlined,
                  'Log outcome',
                  () => _logOpportunityOutcome(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'job' => Icons.work_outline_rounded,
      'school' => Icons.school_outlined,
      'scholarship' => Icons.workspace_premium_outlined,
      'portfolio' => Icons.account_tree_outlined,
      'project' => Icons.handyman_outlined,
      _ => Icons.public_rounded,
    };
  }

  String _categoryForGap(String gap) {
    final text = gap.toLowerCase();
    if (text.contains('feedback') || text.contains('quote') || text.contains('review')) return 'feedback';
    if (text.contains('artifact') || text.contains('link') || text.contains('patch') || text.contains('public')) return 'artifact';
    if (text.contains('result') || text.contains('trend') || text.contains('baseline')) return 'outcome';
    if (text.contains('plan') || text.contains('narrative') || text.contains('statement') || text.contains('ask')) return 'story';
    return 'practice';
  }

  String _descriptionForGap(String gap, String opportunityTitle, String nextStep) {
    final text = gap.toLowerCase();
    if (text.contains('feedback') || text.contains('quote')) {
      return 'Paste one sentence of feedback from someone who saw the work. Keep it specific and safe to share.';
    }
    if (text.contains('public') || text.contains('link')) {
      return 'Create or paste a public-safe version of the work so this opportunity has visible evidence.';
    }
    if (text.contains('narrative') || text.contains('story') || text.contains('plan')) {
      return 'Write the short version of why this matters, what changed, and what you are ready to do next.';
    }
    if (text.contains('trend') || text.contains('baseline') || text.contains('result')) {
      return 'Record the before/after, repeated practice, or measurable result behind this opportunity.';
    }
    if (nextStep.isNotEmpty) return nextStep;
    return 'Add one concrete piece of proof for $opportunityTitle.';
  }

  String _titleCase(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part.length == 1 ? part.toUpperCase() : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Widget _gapButton(Map<String, dynamic> opportunity, String gap) {
    final category = _categoryForGap(gap);
    final color = switch (category) {
      'feedback' => EchoColors.memory,
      'artifact' => EchoColors.proof,
      'outcome' => EchoColors.practice,
      'story' => EchoColors.opportunity,
      _ => EchoColors.textSecondary,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _openProofBuilder(opportunity: opportunity, gap: gap),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              gap,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardAction(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: EchoColors.textPrimary,
        side: BorderSide(color: EchoColors.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11.2, fontWeight: FontWeight.w800),
      ),
    );
  }

  int _readiness(List<String> required, List<String> missing) {
    if (required.isEmpty) return 0;
    final done = (required.length - missing.length).clamp(0, required.length);
    return ((done / required.length) * 100).round();
  }

  Widget _readinessPill(int readiness) {
    final color = readiness >= 70
        ? EchoColors.practice
        : readiness >= 40
        ? EchoColors.opportunity
        : EchoColors.textGhost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$readiness% ready',
        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, color: EchoColors.textGhost),
    );
  }

  Widget _checkLine(String text, bool complete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            complete ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: complete ? EchoColors.amber : EchoColors.textGhost,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: complete ? EchoColors.textMuted : EchoColors.textGhost),
            ),
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
