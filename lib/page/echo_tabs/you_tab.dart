import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_design_system.dart';
import 'package:chatmcp/echo/echo_product_contracts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/local_model_setup_screen.dart';
import 'package:chatmcp/page/echo_tabs/growth_timeline_screen.dart';
import 'package:chatmcp/page/echo_tabs/opportunities_screen.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/page/echo_tabs/discovery_insight_screen.dart';
import 'package:chatmcp/page/echo_tabs/what_echo_uses_screen.dart';
import 'package:chatmcp/provider/provider_manager.dart';

class YouTab extends StatefulWidget {
  const YouTab({super.key});

  @override
  State<YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<YouTab> {
  Map<String, dynamic>? _thesis;
  Map<String, dynamic>? _trainingSummary;
  Map<String, dynamic>? _growthTimeline;
  Map<String, dynamic>? _revelationStatus;
  Map<String, dynamic>? _proofData;
  Map<String, dynamic>? _opportunityData;

  String? _trainingLane() {
    final model = ProviderManager.chatModelProvider.currentModel;
    final name = model.name.toLowerCase().replaceAll('-', '_');
    if (model.providerId == 'echo' && name == 'gemma4_e2b') {
      return 'gemma4_e2b';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    EchoLoopState().addListener(_onLoopStateChanged);
    _load();
  }

  void _onLoopStateChanged() {
    if (!mounted) return;
    final loop = EchoLoopState();
    setState(() {
      _thesis = loop.thesis ?? _thesis;
    });
  }

  @override
  void dispose() {
    EchoLoopState().removeListener(_onLoopStateChanged);
    super.dispose();
  }

  Future<void> _load() async {
    if (EchoRuntimeService().isDevice) {
      final loop = EchoLoopState();
      if (!mounted) return;
      setState(() {
        _thesis = loop.thesis ?? _thesis;
        _trainingSummary = loop.trainingSummary ?? _trainingSummary;
        _growthTimeline = loop.growthTimeline ?? _growthTimeline;
        _proofData = null;
        _opportunityData = null;
      });
      return;
    }
    final results = await Future.wait([
      EchoApiClient().getCurrentThesis(),
      EchoApiClient().getTrainingSummary(lane: _trainingLane()),
      EchoApiClient().getGrowthTimeline(),
      EchoApiClient().getRevelationStatus(),
      EchoApiClient().getProofItems(limit: 6),
      EchoApiClient().getOpportunities(),
    ]);
    if (!mounted) return;
    setState(() {
      _thesis = results[0];
      _trainingSummary = results[1];
      _growthTimeline = results[2];
      _revelationStatus = results[3];
      _proofData = results[4];
      _opportunityData = results[5];
    });
    EchoLoopState().apply(thesis: _thesis);
  }

  Future<void> _openTrainingScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NightlyTrainingScreen()));
    if (!mounted) return;
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  Future<void> _openTournamentScreen({String? initialPrompt}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShadowTournamentScreen(initialPrompt: initialPrompt)));
    if (!mounted) return;
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  Future<void> _openOpportunitiesScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OpportunitiesScreen()));
    if (!mounted) return;
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  Future<void> _openProofBuilderScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProofBuilderScreen()));
    if (!mounted) return;
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
              children: [
                _buildYouHeader(),
                const SizedBox(height: 14),
                _buildThesisCard(context),
                const SizedBox(height: 12),
                _buildPrimaryActionRow(context),
                const SizedBox(height: 14),
                _buildLoopSnapshotStrip(),
                const SizedBox(height: 22),
                _sectionHeader('Proof', 'Turn real actions into evidence someone else can understand.'),
                const SizedBox(height: 10),
                _responsivePair(_buildProofBuilderEntry(context), _buildNextMissingProofCard(context)),
                const SizedBox(height: 22),
                _sectionHeader('Place', 'Where your proof could matter next.'),
                const SizedBox(height: 10),
                _buildOpportunityCard(context),
                const SizedBox(height: 22),
                _sectionHeader('Trust', 'What Echo uses, what it is unsure about, and where it thinks.'),
                const SizedBox(height: 10),
                _buildWhatEchoUsesEntry(context),
                const SizedBox(height: 10),
                _buildSignalsCard(context),
                const SizedBox(height: 10),
                _responsivePair(_buildLabEntry(context), _buildDeviceEntry(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYouHeader() {
    final runtime = EchoRuntimeService();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You', style: EchoText.title(size: 25)),
              const SizedBox(height: 5),
              Text(
                'Your path, proof, and places Echo can help you grow.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.35, color: EchoColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ListenableBuilder(
          listenable: runtime,
          builder: (context, _) => _quietStatusChip(Icons.hub_outlined, runtime.modeLabel, EchoColors.primaryAi),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionRow(BuildContext context) {
    final trainingReady = (_trainingSummary?['can_train_now'] as bool?) ?? (_trainingSummary?['ready_for_training'] as bool? ?? false);
    return Row(
      children: [
        Expanded(
          child: _compactActionButton(
            icon: Icons.psychology_alt_rounded,
            label: 'Practice a situation',
            color: EchoColors.practice,
            onTap: () => _openTournamentScreen(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactActionButton(icon: Icons.inventory_2_outlined, label: 'Add proof', color: EchoColors.proof, onTap: _openProofBuilderScreen),
        ),
        if (trainingReady) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _compactActionButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Improve Echo',
              color: EchoColors.memory,
              onTap: _openTrainingScreen,
            ),
          ),
        ],
      ],
    );
  }

  Widget _compactActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.28)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 11.4, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildLoopSnapshotStrip() {
    final proofSummary = Map<String, dynamic>.from((_proofData?['summary'] as Map?) ?? {});
    final proofCount = (proofSummary['count'] as num?)?.toInt() ?? ((_proofData?['items'] as List?)?.length ?? 0);
    final opportunity = _firstOpportunity();
    final missing = (opportunity?['missing_proof'] as List? ?? []).length;
    final confidence = _thesis?['confidence_label'] as String? ?? 'early';
    final lessons = (_trainingSummary?['dpo_ready_pairs'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(child: _miniMetric('Read', confidence, EchoColors.memory)),
          _miniDivider(),
          Expanded(child: _miniMetric('Proof', '$proofCount', EchoColors.proof)),
          _miniDivider(),
          Expanded(child: _miniMetric('Missing', missing > 0 ? '$missing' : '0', EchoColors.opportunity)),
          _miniDivider(),
          Expanded(child: _miniMetric('Lessons', '$lessons', EchoColors.practice)),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(fontSize: 8.5, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _miniDivider() => Container(width: 1, height: 26, color: EchoColors.borderSubtle);

  Widget _sectionHeader(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
        ),
        const SizedBox(height: 4),
        Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: EchoColors.textMuted)),
      ],
    );
  }

  Widget _responsivePair(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 10), right]);
      },
    );
  }

  Widget _buildSignalsCard(BuildContext context) {
    final status = _revelationStatus ?? {};
    final ready = status['ready'] as bool? ?? false;
    final headline = status['headline'] as String? ?? 'Echo is still collecting enough signal to make stronger claims.';
    final weeks = (status['weeks_watched'] as num?)?.toInt() ?? 0;
    final patternTitle = status['title'] as String? ?? 'New pattern detected';
    final patternBody = status['body'] as String? ?? headline;
    final patternId = status['pattern_id'] as String?;

    return GestureDetector(
      onTap: () {
        if (ready) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DiscoveryInsightScreen(title: patternTitle, body: patternBody, patternId: patternId),
            ),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrowthTimelineScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? EchoColors.practice.withValues(alpha: 0.28) : EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (ready ? EchoColors.practice : EchoColors.primaryAi).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (ready ? EchoColors.practice : EchoColors.primaryAi).withValues(alpha: 0.20)),
              ),
              child: Icon(
                ready ? Icons.auto_awesome_rounded : Icons.timeline_rounded,
                size: 18,
                color: ready ? EchoColors.practice : EchoColors.primaryAi,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ready ? 'Discovery ready' : 'Signals forming',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.35, color: EchoColors.textGhost),
                  ),
                ],
              ),
            ),
            if (weeks > 0) ...[const SizedBox(width: 8), _quietStatusChip(Icons.calendar_today_outlined, '${weeks}w', EchoColors.textGhost)],
          ],
        ),
      ),
    );
  }

  Widget _quietStatusChip(IconData icon, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _firstOpportunity() {
    final backendOpportunities = (_opportunityData?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final opportunities = backendOpportunities.isNotEmpty ? backendOpportunities : echoOpportunitySeeds.map((seed) => seed.toJson()).toList();
    return opportunities.isNotEmpty ? opportunities.first : null;
  }

  Widget _buildOpportunityCard(BuildContext context) {
    final opportunity = _firstOpportunity();
    final direction = _thesis?['title'] as String? ?? 'Direction still forming';
    final statement = _thesis?['statement'] as String? ?? 'Keep using Talk and Today so Echo can connect your outcomes to real proof.';
    final title = opportunity?['title'] as String? ?? 'Find a place for: $direction';
    final body = opportunity?['description'] as String? ?? statement;
    final nextStep = opportunity?['next_step'] as String? ?? 'Create one proof item from a real action today.';
    final nextStepPill = nextStep.length > 30 ? 'next step ready' : nextStep;
    final proofSummary = Map<String, dynamic>.from((_opportunityData?['proof_summary'] as Map?) ?? (_proofData?['summary'] as Map?) ?? {});
    final proofCount = (proofSummary['count'] as num?)?.toInt() ?? 0;
    final missing = (opportunity?['missing_proof'] as List? ?? []).length;

    return GestureDetector(
      onTap: _openOpportunitiesScreen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.alphaBlend(EchoColors.opportunity.withValues(alpha: 0.05), EchoColors.bgSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place_outlined, size: 17, color: EchoColors.opportunity),
                const SizedBox(width: 8),
                Text(
                  'PLACE PLAN',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.opportunity),
                ),
                const Spacer(),
                Text('$proofCount proof', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textVeryGhost)),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary, height: 1.35),
            ),
            const SizedBox(height: 7),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.2, color: EchoColors.textMuted, height: 1.45),
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _loopPill(Icons.inventory_2_outlined, '$proofCount proof items'),
                _loopPill(Icons.assignment_turned_in_outlined, missing > 0 ? '$missing missing' : 'proof ready'),
                _loopPill(Icons.arrow_forward_rounded, nextStepPill),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Where this proof can matter next',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: EchoColors.opportunity),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: EchoColors.opportunity),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _passportActionButton(icon: Icons.add_task_rounded, label: 'Add proof', onTap: _openProofBuilderScreen),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _passportActionButton(icon: Icons.emoji_events_outlined, label: 'Open places', onTap: _openOpportunitiesScreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _passportActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
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

  Widget _buildProofBuilderEntry(BuildContext context) {
    final items = (_proofData?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final summary = Map<String, dynamic>.from(_proofData?['summary'] as Map? ?? {});
    final proofCount = (summary['count'] as num?)?.toInt() ?? items.length;
    final latest = items.isNotEmpty ? items.first['title'] as String? : null;
    final body = latest == null ? 'Save one artifact, outcome, practice result, or piece of feedback.' : 'Latest proof: $latest';
    return GestureDetector(
      onTap: _openProofBuilderScreen,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: EchoColors.proof.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: EchoColors.proof.withValues(alpha: 0.18)),
              ),
              child: Icon(Icons.inventory_2_outlined, size: 18, color: EchoColors.proof),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proofCount > 0 ? 'Proof record - $proofCount saved' : 'Proof record',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.35, color: EchoColors.textGhost),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMissingProofCard(BuildContext context) {
    final backendOpportunities = (_opportunityData?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final opportunities = backendOpportunities.isNotEmpty ? backendOpportunities : echoOpportunitySeeds.map((seed) => seed.toJson()).toList();
    final opportunity = opportunities.isNotEmpty ? opportunities.first : null;
    final missing = (opportunity?['missing_proof'] as List? ?? []).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    final gap = missing.isNotEmpty ? missing.first : 'one concrete outcome';
    final place = (opportunity?['type'] as String? ?? 'personal_goal').replaceAll('_', ' ');
    final title = 'Next missing proof';
    final body = 'Add $gap for $place so Echo can point your proof toward a real place.';

    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => ProofBuilderScreen(
                  initialIntent: ProofBuilderIntent(
                    title: gap,
                    description: 'Proof gap for $place',
                    category: gap.toLowerCase().contains('feedback') ? 'feedback' : 'artifact',
                    opportunityType: opportunity?['type'] as String? ?? 'personal_goal',
                    skillTags: ['proof gap', place],
                    sourceLabel: 'Place plan',
                  ),
                  autoOpenDraft: true,
                ),
              ),
            )
            .then((_) => _load());
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color.alphaBlend(EchoColors.proof.withValues(alpha: 0.05), EchoColors.bgSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.proof.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_task_rounded, size: 19, color: EchoColors.proof),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.35, color: EchoColors.textGhost)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatEchoUsesEntry(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhatEchoUsesScreen())),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color.alphaBlend(EchoColors.memory.withValues(alpha: 0.06), EchoColors.bgSurface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.memory.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: EchoColors.memory.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: EchoColors.memory.withValues(alpha: 0.20)),
              ),
              child: Icon(Icons.verified_user_outlined, size: 18, color: EchoColors.memory),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What Echo uses',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Review memories, rules, and records that shape your read.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.35, color: EchoColors.textGhost),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildLabEntry(BuildContext context) {
    final canStart = _trainingSummary?['can_train_now'] as bool? ?? false;
    final dataReady = _trainingSummary?['data_ready_for_training'] as bool? ?? (_trainingSummary?['ready_for_training'] as bool? ?? false);
    final dpoReady = (_trainingSummary?['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (_trainingSummary?['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    final signalReady = dataReady || dpoReady >= dpoRequired;
    final lessonsLabel = dpoReady >= dpoRequired ? '$dpoReady lessons saved' : '$dpoReady/$dpoRequired lessons';
    final title = canStart
        ? 'Echo is ready for an update'
        : signalReady
        ? 'Home Brain needed'
        : 'Improve Echo';
    return GestureDetector(
      onTap: _openTrainingScreen,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: canStart ? EchoColors.amber.withValues(alpha: 0.30) : EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(canStart ? Icons.science_outlined : Icons.hub_outlined, size: 18, color: canStart ? EchoColors.amber : EchoColors.textGhost),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your outcomes and choices become lessons for Echo. Practice Versions is ready when enough useful moments are saved. $lessonsLabel.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceEntry(BuildContext context) {
    final runtime = EchoRuntimeService();
    return ListenableBuilder(
      listenable: runtime,
      builder: (context, _) {
        final active = runtime.isDevice;
        final ready = runtime.isDeviceReady;
        final title = active
            ? ready
                  ? 'This Device is ready offline'
                  : 'This Device needs Offline Echo'
            : 'Where Echo Thinks';
        final body = ready
            ? '${runtime.deviceModelVersion.isEmpty ? 'Offline Echo' : runtime.deviceModelVersion} is selected for Talk without Wi-Fi.'
            : 'Import an offline model so Echo can work without Wi-Fi.';
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalModelSetupScreen())),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: active ? EchoColors.amber.withValues(alpha: 0.07) : EchoColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: active ? EchoColors.amber.withValues(alpha: 0.28) : EchoColors.borderSubtle),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded, size: 18, color: active ? EchoColors.amber : EchoColors.textGhost),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleThesisAction() async {
    final action = Map<String, dynamic>.from(_thesis?['next_action'] as Map? ?? {});
    final payload = Map<String, dynamic>.from(action['payload'] as Map? ?? {});
    final type = action['type'] as String? ?? 'none';
    HapticFeedback.lightImpact();

    if (type == 'run_tournament') {
      await _openTournamentScreen(initialPrompt: payload['prompt'] as String?);
      return;
    }

    await _openProofBuilderScreen();
    if (mounted) _load();
  }

  Future<void> _recordThesisFeedback(String outcome, double score) async {
    final thesisId = _thesis?['id'] as String?;
    HapticFeedback.selectionClick();
    await EchoApiClient().recordOutcome(
      subjectType: 'thesis',
      subjectId: thesisId,
      outcome: outcome,
      score: score,
      note: 'Feedback from Echo current read card',
    );
    await EchoLoopState().refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: EchoColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            outcome == 'not_true' ? 'Correction saved. Echo will adjust the read.' : 'Outcome saved. Echo updated You.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
          ),
        ),
      );
      _load();
    }
  }

  Widget _buildThesisCard(BuildContext context) {
    final hasThesis = _thesis != null;
    final title = _thesis?['title'] as String? ?? 'Still Forming';
    final statement = _thesis?['statement'] as String? ?? 'Echo is waiting for enough real moments to form a thesis.';
    final stage = _thesis?['stage'] as String? ?? 'forming';
    final confidence = _thesis?['confidence_label'] as String? ?? 'early';
    final evidenceCount = (_thesis?['evidence_count'] as num?)?.toInt() ?? 0;
    final evidence = (_thesis?['evidence'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(3).toList();
    final action = Map<String, dynamic>.from(_thesis?['next_action'] as Map? ?? {});
    final actionLabel = _cleanActionLabel(action['label'] as String? ?? 'Open potential');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_motion_rounded, size: 17, color: EchoColors.amber.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                'ECHO\'S CURRENT READ',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.amber),
              ),
              const Spacer(),
              Text('$evidenceCount outcomes', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textVeryGhost)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            statement,
            style: GoogleFonts.lora(fontSize: 16, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _loopPill(Icons.timeline_rounded, stage),
              _loopPill(Icons.query_stats_rounded, confidence),
              _loopPill(Icons.fact_check_rounded, '$evidenceCount evidence'),
            ],
          ),
          if (hasThesis) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _handleThesisAction,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.psychology_alt_rounded, size: 15, color: EchoColors.amber.withValues(alpha: 0.75)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      actionLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: EchoColors.amber.withValues(alpha: 0.86),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: EchoColors.amber.withValues(alpha: 0.45)),
                ],
              ),
            ),
          ],
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Text(
              'Evidence behind this read',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 9),
            Wrap(spacing: 8, runSpacing: 8, children: evidence.map(_evidenceChip).toList()),
          ],
          if (hasThesis) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Text(
              'What would change this read',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 6),
            Text(
              'A perspective choice, a completed rep, or a correction from you.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _thesisFeedbackChip('True', 'true', 1.0),
                _thesisFeedbackChip('Partly', 'partly_true', 0.45),
                _thesisFeedbackChip('Not true', 'not_true', -0.6),
                _thesisEditChip(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _thesisFeedbackChip(String label, String outcome, double score) {
    return GestureDetector(
      onTap: () => _recordThesisFeedback(outcome, score),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
        ),
      ),
    );
  }

  Widget _thesisEditChip() {
    return GestureDetector(
      onTap: _openThesisCorrectionSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: EchoColors.risk.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EchoColors.risk.withValues(alpha: 0.22)),
        ),
        child: Text(
          'Edit',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: EchoColors.risk),
        ),
      ),
    );
  }

  Widget _evidenceChip(Map<String, dynamic> item) {
    final summary = (item['summary'] as String? ?? item['text'] as String? ?? 'Evidence').trim();
    final label = summary.length > 34 ? '${summary.substring(0, 31)}...' : summary;
    return GestureDetector(
      onTap: () => _showEvidenceDetail(item),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: EchoColors.memory.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: EchoColors.memory.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, size: 13, color: EchoColors.memory),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 11.2, fontWeight: FontWeight.w700, color: EchoColors.memory),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEvidenceDetail(Map<String, dynamic> item) async {
    final summary = item['summary'] as String? ?? item['text'] as String? ?? 'Evidence';
    final source = item['source'] as String? ?? item['source_type'] as String? ?? 'Echo evidence';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EchoColors.bgSurface,
        title: Text(
          'Evidence',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
        ),
        content: Text('$summary\n\nSource: $source', style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45, color: EchoColors.textMuted)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _openThesisCorrectionSheet() async {
    final wrongCtrl = TextEditingController();
    final correctedCtrl = TextEditingController(text: _thesis?['statement'] as String? ?? '');
    String saveAs = 'correction';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border(top: BorderSide(color: EchoColors.borderSubtle)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correct Echo',
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell Echo what it got wrong so the read becomes more useful.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: EchoColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    _correctionField(wrongCtrl, 'What is wrong?', 'Example: this is about school, not work'),
                    const SizedBox(height: 10),
                    _correctionField(correctedCtrl, 'Better read', 'What should Echo understand instead?', minLines: 2),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _correctionTypeChip('correction', 'Correction', saveAs, (v) => setSheetState(() => saveAs = v)),
                        _correctionTypeChip('memory', 'Memory', saveAs, (v) => setSheetState(() => saveAs = v)),
                        _correctionTypeChip('rule', 'Rule', saveAs, (v) => setSheetState(() => saveAs = v)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Save correction'),
                        style: FilledButton.styleFrom(
                          backgroundColor: EchoColors.risk,
                          foregroundColor: EchoColors.bg,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    final wrong = wrongCtrl.text.trim();
    final corrected = correctedCtrl.text.trim();
    wrongCtrl.dispose();
    correctedCtrl.dispose();
    if (saved != true || (wrong.isEmpty && corrected.isEmpty)) return;
    await EchoApiClient().recordOutcome(
      subjectType: 'thesis_correction',
      subjectId: _thesis?['id'] as String?,
      outcome: 'edited_read',
      score: 0.7,
      note: jsonEncode({'wrong': wrong, 'corrected': corrected, 'save_as': saveAs}),
    );
    await EchoLoopState().refresh();
    if (!mounted) return;
    _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correction saved. Echo will adjust the read.')));
  }

  Widget _correctionField(TextEditingController controller, String label, String hint, {int minLines = 1}) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: minLines + 2,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textVeryGhost),
        filled: true,
        fillColor: EchoColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: EchoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: EchoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: EchoColors.risk),
        ),
      ),
    );
  }

  Widget _correctionTypeChip(String value, String label, String selected, ValueChanged<String> onSelected) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: active ? EchoColors.risk.withValues(alpha: 0.10) : EchoColors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? EchoColors.risk.withValues(alpha: 0.35) : EchoColors.borderSubtle),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: active ? EchoColors.risk : EchoColors.textGhost),
        ),
      ),
    );
  }

  Widget _loopPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: EchoColors.textGhost),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: EchoColors.textMuted),
          ),
        ],
      ),
    );
  }

  String _cleanActionLabel(String label) {
    return label
        .replaceAll('Send clones', 'Start Practice Versions')
        .replaceAll('send clones', 'start Practice Versions')
        .replaceAll('Run tournament', 'Start Practice Versions')
        .replaceAll('run tournament', 'start Practice Versions')
        .replaceAll('Open talent', 'Open potential')
        .replaceAll('clone', 'practice')
        .replaceAll('Clone', 'Practice');
  }
}
