// ignore_for_file: unused_element

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/echo_lab_screen.dart';
import 'package:chatmcp/page/echo_tabs/growth_timeline_screen.dart';
import 'package:chatmcp/page/echo_tabs/memories_screen.dart';
import 'package:chatmcp/page/echo_tabs/operating_system_screen.dart';
import 'package:chatmcp/page/echo_tabs/permanent_record_screen.dart';
import 'package:chatmcp/page/echo_tabs/talent_screen.dart';
import 'package:chatmcp/page/echo_tabs/daily_checkin_screen.dart';
import 'package:chatmcp/page/echo_tabs/mirror_tab.dart';
import 'package:chatmcp/page/echo_tabs/experiment_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/page/echo_tabs/twin_screen.dart';
import 'package:chatmcp/provider/provider_manager.dart';

// ─── Vault item model ─────────────────────────────────────────────────────────

class _VaultItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _VaultItem(this.label, this.subtitle, this.icon, this.color, this.onTap);
}

// â”€â”€â”€ Arc painter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CloneArcPainter extends CustomPainter {
  final double progress; // 0.0â€“1.0
  const _CloneArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Faint full-circle track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = EchoColors.amber.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    if (progress <= 0) return;

    // Amber progress arc â€” clockwise from top
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = EchoColors.amber.withValues(alpha: 0.80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CloneArcPainter old) => old.progress != progress;
}

// â”€â”€â”€ Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class YouTab extends StatefulWidget {
  const YouTab({super.key});

  @override
  State<YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<YouTab> {
  Map<String, dynamic>? _signal;
  Map<String, dynamic>? _practice;
  Map<String, dynamic>? _quote;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _report;
  Map<String, dynamic>? _experiment;
  Map<String, dynamic>? _thesis;
  Map<String, dynamic>? _trainingSummary;
  Map<String, dynamic>? _rank;
  Map<String, dynamic>? _growthTimeline;
  Map<String, dynamic>? _revelationStatus;
  bool _loading = true;
  bool _loggedThisSession = false;

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
    _loadExperiment();
  }

  void _onLoopStateChanged() {
    if (!mounted) return;
    final loop = EchoLoopState();
    setState(() {
      _thesis = loop.thesis ?? _thesis;
      _practice = loop.practice ?? _practice;
      _rank = loop.rank ?? _rank;
    });
  }

  @override
  void dispose() {
    EchoLoopState().removeListener(_onLoopStateChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      EchoApiClient().getUserSignal(),
      EchoApiClient().getPracticeToday(),
      EchoApiClient().getNotableQuote(),
      EchoApiClient().getUserStats(),
      EchoApiClient().getUserReport(),
      EchoApiClient().getCurrentThesis(),
      EchoApiClient().getTrainingSummary(lane: _trainingLane()),
      EchoApiClient().getUserRank(),
      EchoApiClient().getGrowthTimeline(),
      EchoApiClient().getRevelationStatus(),
    ]);
    if (!mounted) return;
    setState(() {
      _signal = results[0];
      _practice = results[1];
      _quote = results[2];
      _stats = results[3];
      _report = results[4];
      _thesis = results[5];
      _trainingSummary = results[6];
      _rank = results[7];
      _growthTimeline = results[8];
      _revelationStatus = results[9];
      _loggedThisSession = _practice?['logged'] as bool? ?? false;
      _loading = false;
    });
    EchoLoopState().apply(thesis: _thesis);
  }

  Future<void> _loadExperiment() async {
    final data = await EchoApiClient().getExperiment();
    if (!mounted) return;
    setState(() => _experiment = data);
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

  Future<void> _logPractice(bool done) async {
    final repId = _practice?['rep_id'] as String?;
    if (repId == null) return;
    HapticFeedback.lightImpact();
    setState(() => _loggedThisSession = true);
    final result = await EchoApiClient().logPractice(repId, done);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _practice = {
          ...(_practice ?? {}),
          'logged': true,
          'done': done,
          'week_completions': result['week_completions'] ?? _practice?['week_completions'] ?? 0,
        };
      });
      await EchoLoopState().refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EchoColors.bgCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              done ? 'Rep saved. Echo updated your read.' : 'Skipped saved. Echo will adjust.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
            ),
          ),
        );
      }
    }
  }

  bool _wasTrainedRecently(String? iso) {
    if (iso == null) return false;
    try {
      return DateTime.now().difference(DateTime.parse(iso).toLocal()).inHours < 36;
    } catch (_) {
      return false;
    }
  }

  String _trainedLabel(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inHours < 2) return 'trained just now';
      if (diff.inHours < 12) return 'trained ${diff.inHours}h ago';
      if (diff.inHours < 36) return 'trained last night';
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final dt = DateTime.parse(iso).toLocal();
      return 'trained ${m[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  // â”€â”€â”€ build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: RefreshIndicator(
              color: EchoColors.amber,
              backgroundColor: EchoColors.bgSurface,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 40),
                children: [
                  _buildCloneHero(context),
                  _buildRankBar(),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 4), child: _buildPrimaryActions(context)),

                  _chapterLabel('CURRENT READ'),
                  if (_thesis != null) Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: _buildThesisCard(context)),

                  _chapterLabel('REVELATION'),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: _buildRevelationReadinessCard(context)),

                  _chapterLabel('GROWTH TIMELINE'),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: _buildTimelinePreview(context)),

                  _chapterLabel('EVIDENCE'),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: _buildEvidenceSection()),

                  _chapterLabel('TRUST'),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 10), child: _buildTrustSection()),

                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: _buildLabEntry(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceSection() {
    final evidence = (_thesis?['evidence'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(4).toList();
    final evidenceCount = (_thesis?['evidence_count'] as num?)?.toInt() ?? evidence.length;

    if (evidence.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Text(
          'Keep talking and choosing outcomes. Echo will show the signals behind its read here.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: EchoColors.textMuted),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
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
              const Icon(Icons.fact_check_rounded, size: 17, color: EchoColors.amber),
              const SizedBox(width: 8),
              Text(
                '$evidenceCount signals behind the read',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...evidence.map((item) {
            final summary = item['summary'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 7, right: 9),
                    decoration: BoxDecoration(color: EchoColors.amber.withValues(alpha: 0.55), shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(summary, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textMuted, height: 1.4)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSendClonesButton(context)),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EchoLabScreen())),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: EchoColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EchoColors.borderSubtle),
            ),
            child: const Icon(Icons.science_outlined, color: EchoColors.textMuted, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildRevelationReadinessCard(BuildContext context) {
    final status = _revelationStatus ?? {};
    final state = status['state'] as String? ?? 'watching';
    final ready = status['ready'] as bool? ?? false;
    final score = (status['score'] as num?)?.toDouble() ?? 0.0;
    final headline = status['headline'] as String? ?? 'Echo is still watching for the deeper pattern.';
    final weeks = (status['weeks_watched'] as num?)?.toInt() ?? 0;
    final requirements = (status['requirements'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    return GestureDetector(
      onTap: ready ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TalentScreen())) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ready ? const Color(0xFF1A1510) : EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? EchoColors.amber.withValues(alpha: 0.38) : EchoColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ready ? Icons.auto_awesome_rounded : Icons.radar_rounded, size: 17, color: ready ? EchoColors.amber : EchoColors.textGhost),
                const SizedBox(width: 8),
                Text(
                  state == 'revealed'
                      ? 'REVELATION DELIVERED'
                      : ready
                      ? 'REVELATION READY'
                      : 'REVELATION FORMING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: ready ? EchoColors.amber : EchoColors.textGhost,
                  ),
                ),
                const Spacer(),
                if (weeks > 0) Text('$weeks wk', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textVeryGhost)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              headline,
              style: GoogleFonts.lora(fontSize: 17, height: 1.4, fontStyle: FontStyle.italic, color: EchoColors.textPrimary),
            ),
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: EchoColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(ready ? EchoColors.amber : EchoColors.amber.withValues(alpha: 0.55)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: requirements.map((r) {
                final complete = r['complete'] == true;
                final label = r['label'] as String? ?? 'Signal';
                final current = (r['current'] as num?)?.toInt() ?? 0;
                final target = (r['target'] as num?)?.toInt() ?? 1;
                return _loopPill(complete ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded, '$label $current/$target');
              }).toList(),
            ),
            const SizedBox(height: 13),
            Text(
              ready ? 'Open Revelation' : 'Echo is waiting for enough signal before naming this.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: ready ? EchoColors.amber : EchoColors.textGhost),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelinePreview(BuildContext context) {
    final headline = _growthTimeline?['headline'] as String? ?? 'Proof is still forming.';
    final stats = Map<String, dynamic>.from(_growthTimeline?['stats'] as Map? ?? {});
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrowthTimelineScreen())),
      child: Container(
        padding: const EdgeInsets.all(15),
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
                const Icon(Icons.timeline_rounded, size: 17, color: EchoColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headline,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _loopPill(Icons.flag_outlined, '${stats['milestones'] ?? 0} milestones'),
                _loopPill(Icons.bolt_outlined, '${stats['practice_done'] ?? 0} reps'),
                _loopPill(Icons.military_tech_outlined, '${stats['clone_battles'] ?? 0} battles'),
                _loopPill(Icons.memory_outlined, '${stats['model_updates'] ?? 0} updates'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustSection() {
    final evidenceCount = (_thesis?['evidence_count'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(15),
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
              const Icon(Icons.verified_user_outlined, size: 17, color: EchoColors.indigo),
              const SizedBox(width: 8),
              Text(
                'You can correct Echo',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Major reads show their evidence and include Not true feedback. Echo should adapt to corrections, not declare identity as fact.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.3, height: 1.45, color: EchoColors.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _loopPill(Icons.fact_check_outlined, '$evidenceCount evidence'),
              _loopPill(Icons.lock_outline_rounded, 'local-first'),
              _loopPill(Icons.cancel_outlined, 'Not true enabled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabEntry(BuildContext context) {
    final ready = _trainingSummary?['ready_for_training'] as bool? ?? false;
    final dpoReady = (_trainingSummary?['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (_trainingSummary?['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EchoLabScreen())),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? EchoColors.amber.withValues(alpha: 0.30) : EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.science_outlined, size: 18, color: ready ? EchoColors.amber : EchoColors.textGhost),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ready ? 'Lab has a clone update ready' : 'Open Lab',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Training, DPO $dpoReady/$dpoRequired, memory, system health, and connections.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingStateSection(BuildContext context) {
    final totalPairs = (_stats?['total_pairs'] as num?)?.toInt() ?? 0;
    final untrained = (_trainingSummary?['untrained_pairs'] as num?)?.toInt() ?? 0;
    final battles = (_trainingSummary?['tournament_battles'] as num?)?.toInt() ?? 0;
    final dpoReady = (_trainingSummary?['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (_trainingSummary?['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    final ready = _trainingSummary?['ready_for_training'] as bool? ?? false;
    final lastTrained = _trainedLabel(_stats?['last_trained'] as String?);
    final adapter = Map<String, dynamic>.from(_trainingSummary?['adapter'] as Map? ?? {});
    final adapterLoaded = adapter['loaded'] as bool? ?? false;
    final adapterExists = adapter['exists'] as bool? ?? false;
    final adapterLabel = adapterLoaded
        ? 'your clone is live'
        : adapterExists
        ? 'clone trained, waiting'
        : 'learning from scratch';

    return GestureDetector(
      onTap: _openTrainingScreen,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ready ? EchoColors.amber.withValues(alpha: 0.35) : EchoColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.model_training_rounded, size: 18, color: ready ? EchoColors.amber : EchoColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ready ? 'Ready to update your clone' : 'Collecting training signal',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _loopPill(Icons.chat_bubble_outline_rounded, '$totalPairs moments'),
                _loopPill(Icons.hourglass_bottom_rounded, '$untrained new since train'),
                _loopPill(Icons.military_tech_rounded, '$battles battles'),
                _loopPill(Icons.compare_arrows_rounded, '$dpoReady/$dpoRequired DPO-ready'),
                _loopPill(Icons.memory_rounded, adapterLabel),
                if (lastTrained.isNotEmpty) _loopPill(Icons.check_circle_outline_rounded, lastTrained),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ CLONE HERO â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildCloneHero(BuildContext context) {
    final avgConf = (_stats?['avg_confidence'] as num?)?.toDouble() ?? 0.0;
    final totalPairs = _stats?['total_pairs'] as int? ?? 0;
    final lastTrained = _stats?['last_trained'] as String?;
    final recently = _wasTrainedRecently(lastTrained);
    final pct = (avgConf * 100).round();
    final weeks = _signal?['weeks'] as int? ?? 0;

    final username = AuthService().username ?? '';
    final firstName = username.isNotEmpty ? username.split(' ').first : '';

    return GestureDetector(
      onTap: _openTrainingScreen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(0, 36, 0, 32),
        decoration: recently
            ? BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [EchoColors.amber.withValues(alpha: 0.04), Colors.transparent],
                ),
              )
            : null,
        child: Column(
          children: [
            // Orb + arc
            SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress arc â€” animates from 0 to real value on load
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _loading ? 0.0 : avgConf),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (context2, value, child2) => CustomPaint(
                      size: const Size(176, 176),
                      painter: _CloneArcPainter(progress: value),
                    ),
                  ),
                  // Orb centered inside
                  const EchoOrb(size: 64, rings: 3),
                  // Percentage badge at bottom of arc
                  if (!_loading && pct > 0)
                    Positioned(
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: EchoColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '$pct% you',
                          style: GoogleFonts.lora(fontSize: 11, fontStyle: FontStyle.italic, color: EchoColors.amber, letterSpacing: -0.1),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Label
            Text(
              'your shadow clone',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, letterSpacing: 1.1, color: EchoColors.textGhost, fontWeight: FontWeight.w500),
            ),

            if (firstName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                weeks > 0 ? '$firstName Â· week $weeks' : firstName,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textVeryGhost),
              ),
            ],

            const SizedBox(height: 14),

            // Stats row
            if (!_loading && totalPairs > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _statPill('$totalPairs conversations'),
                  const SizedBox(width: 8),
                  if (lastTrained != null) _statPill(_trainedLabel(lastTrained), highlight: recently),
                ],
              )
            else if (_loading)
              Container(
                width: 180,
                height: 22,
                decoration: BoxDecoration(color: EchoColors.bgSurface, borderRadius: BorderRadius.circular(6)),
              ),

            // "trained last night" glow pill
            if (!_loading && recently) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: EchoColors.amber.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'your clone learned something new last night',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.amber.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statPill(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? EchoColors.amber.withValues(alpha: 0.07) : EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? EchoColors.amber.withValues(alpha: 0.2) : EchoColors.borderSubtle),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: highlight ? EchoColors.amberText : EchoColors.textGhost)),
    );
  }

  // â”€â”€â”€ ECHO'S SIGNAL â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSignalZone() {
    final signal = _signal?['signal'] as String?;
    final quote = _quote?['quote'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: EchoColors.borderSubtle),
          const SizedBox(height: 22),
          if (_loading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 22, width: 260, color: EchoColors.bgSurface, margin: const EdgeInsets.only(bottom: 8)),
                Container(height: 18, width: 200, color: EchoColors.bgSurface),
              ],
            )
          else if (signal != null) ...[
            Text(
              '"$signal"',
              style: GoogleFonts.lora(fontSize: 20, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3),
            ),
            if (quote != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"', style: GoogleFonts.lora(fontSize: 13, color: EchoColors.amber)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      quote,
                      style: GoogleFonts.lora(fontSize: 12.5, fontStyle: FontStyle.italic, color: EchoColors.textGhost, height: 1.6),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('"', style: GoogleFonts.lora(fontSize: 13, color: EchoColors.amber)),
                ],
              ),
              const SizedBox(height: 3),
              Text('â€” something you said', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: EchoColors.textVeryGhost)),
            ],
          ] else
            Text(
              'Keep talking.\nEcho is forming your signal.',
              style: GoogleFonts.lora(fontSize: 18, fontStyle: FontStyle.italic, color: EchoColors.textGhost, height: 1.55),
            ),
          const SizedBox(height: 22),
          Container(height: 1, color: EchoColors.borderSubtle),
        ],
      ),
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

    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TalentScreen()));
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
            outcome == 'not_true' ? 'Correction saved. Echo will adjust the read.' : 'Signal saved. Echo updated the loop.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
          ),
        ),
      );
      _load();
    }
  }

  Widget _buildThesisCard(BuildContext context) {
    final title = _thesis?['title'] as String? ?? 'Still Forming';
    final statement = _thesis?['statement'] as String? ?? 'Echo is waiting for enough real moments to form a thesis.';
    final stage = _thesis?['stage'] as String? ?? 'forming';
    final confidence = _thesis?['confidence_label'] as String? ?? 'early';
    final evidenceCount = (_thesis?['evidence_count'] as num?)?.toInt() ?? 0;
    final action = Map<String, dynamic>.from(_thesis?['next_action'] as Map? ?? {});
    final actionLabel = action['label'] as String? ?? 'Open talent';

    return GestureDetector(
      onTap: _handleThesisAction,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10100E),
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
                Text('$evidenceCount signals', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textVeryGhost)),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.military_tech_rounded, size: 15, color: EchoColors.amber.withValues(alpha: 0.75)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: EchoColors.amber.withValues(alpha: 0.86)),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: EchoColors.amber.withValues(alpha: 0.45)),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Text(
              'What would change this read',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 6),
            Text(
              'A shadow choice, a completed rep, or a correction from you.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _thesisFeedbackChip('True', 'true', 1.0),
                const SizedBox(width: 8),
                _thesisFeedbackChip('Partly', 'partly_true', 0.45),
                const SizedBox(width: 8),
                _thesisFeedbackChip('Not true', 'not_true', -0.6),
              ],
            ),
          ],
        ),
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

  // â”€â”€â”€ TODAY'S REP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildPracticeSection() {
    final observation = _practice?['observation'] as String?;
    final repTitle = _practice?['rep_title'] as String?;
    final repInstruction = _practice?['rep_instruction'] as String?;
    final arcLabel = _practice?['arc_label'] as String?;
    final repId = _practice?['rep_id'] as String?;
    final logged = _loggedThisSession || (_practice?['logged'] as bool? ?? false);
    final done = _practice?['done'] as bool?;
    final weekCompletions = _practice?['week_completions'] as int? ?? 0;
    final thesisTitle = _thesis?['title'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: EchoColors.amber),
                ),
                const SizedBox(width: 7),
                Text(
                  'TODAY\'S REP',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: EchoColors.amber),
                ),
                const Spacer(),
                if (thesisTitle != null)
                  Flexible(
                    child: Text(
                      'Trains: $thesisTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: EchoColors.textGhost),
                    ),
                  )
                else if (arcLabel != null)
                  Text(arcLabel, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: EchoColors.textGhost)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 200, color: EchoColors.bgSurface),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 160, color: EchoColors.bgSurface),
                ],
              ),
            )
          else if (observation != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ECHO OBSERVED', style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 0.8, color: EchoColors.textGhost)),
                  const SizedBox(height: 5),
                  Text(
                    '"$observation"',
                    style: GoogleFonts.lora(fontSize: 14, fontStyle: FontStyle.italic, color: EchoColors.textMuted, height: 1.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repTitle != null)
                    Text(
                      repTitle,
                      style: GoogleFonts.lora(fontSize: 18, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, letterSpacing: -0.2),
                    ),
                  if (repInstruction != null) ...[
                    const SizedBox(height: 8),
                    Text(repInstruction, style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.65, color: EchoColors.textMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!logged && repId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _logPractice(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(color: EchoColors.amber, borderRadius: BorderRadius.circular(40)),
                          child: Center(
                            child: Text(
                              'Done today',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF060504)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _logPractice(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: EchoColors.border),
                        ),
                        child: Text('Not today', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: EchoColors.textGhost)),
                      ),
                    ),
                  ],
                ),
              )
            else if (logged)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done == true ? EchoColors.amber.withValues(alpha: 0.15) : EchoColors.bgSurface,
                        border: Border.all(color: done == true ? EchoColors.amber : EchoColors.border),
                      ),
                      child: done == true ? const Icon(Icons.check_rounded, size: 12, color: EchoColors.amber) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      done == true ? 'Logged today' : 'Skipped today',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textGhost),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 0), child: _buildWeekDots(weekCompletions)),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                'Keep chatting â€” Echo needs more conversations\nto generate your practice.',
                style: GoogleFonts.lora(fontSize: 13, fontStyle: FontStyle.italic, color: EchoColors.textGhost, height: 1.6),
              ),
            ),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildWeekDots(int completions) {
    const total = 7;
    final weekday = DateTime.now().weekday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (i) {
            final filled = i < completions;
            final isToday = i == weekday - 1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isToday ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: filled
                      ? EchoColors.amber
                      : isToday
                      ? EchoColors.amber.withValues(alpha: 0.25)
                      : const Color(0xFF1A1815),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text('$completions of $total this week', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
      ],
    );
  }

  // â”€â”€â”€ YOUR HIDDEN TALENT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTalentSection(BuildContext context) {
    final totalPairs = _signal?['total_pairs'] as int? ?? 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TalentScreen())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1510),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR HIDDEN TALENT',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: EchoColors.amber),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalPairs > 40
                        ? '"Something keeps appearing across $totalPairs conversations.\nI want to name it."'
                        : 'Echo is still watching. Keep talking.',
                    style: GoogleFonts.lora(fontSize: 14, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, height: 1.55),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What Echo found â†’',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: EchoColors.amber),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.psychology_rounded, color: EchoColors.amber.withValues(alpha: 0.4), size: 28),
          ],
        ),
      ),
    );
  }

  // â”€â”€â”€ CHAPTER HELPERS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _chapterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: EchoColors.textGhost),
      ),
    );
  }

  Widget _depthRow(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.75)),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: EchoColors.textMuted)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 16, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  // ─── WEEKLY CARD ─────────────────────────────────────────────────────────────

  Widget _buildWeeklyCard(BuildContext context) {
    final headline = _report?['headline'] as String? ?? '';
    final rawObs = _report?['observations'] as List?;
    final observations = rawObs?.map((o) => o.toString()).take(2).toList() ?? [];
    final sitWith = _report?['sit_with_this'] as String? ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MirrorTab())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0A08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: EchoColors.amber),
                ),
                const SizedBox(width: 7),
                Text(
                  'THIS WEEK ECHO NOTICED',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: EchoColors.amber),
                ),
                const Spacer(),
                Text('Full report →', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EchoColors.textGhost)),
              ],
            ),
            if (headline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '"$headline"',
                style: GoogleFonts.lora(fontSize: 15, fontStyle: FontStyle.italic, color: EchoColors.textPrimary, height: 1.55),
              ),
            ],
            if (observations.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...observations.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: GoogleFonts.lora(fontSize: 10.5, fontStyle: FontStyle.italic, color: EchoColors.amber),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.6, color: EchoColors.textMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (sitWith.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EchoColors.borderSubtle),
                ),
                child: Text(
                  sitWith,
                  style: GoogleFonts.lora(fontSize: 12, fontStyle: FontStyle.italic, color: EchoColors.textGhost, height: 1.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── EXPERIMENT CARD ──────────────────────────────────────────────────────────

  Widget _buildExperimentCard(BuildContext context) {
    final title = _experiment?['title'] as String? ?? '';
    final body = _experiment?['body'] as String? ?? '';
    final number = (_experiment?['number'] as num?)?.toInt() ?? 1;
    final days = (_experiment?['duration_days'] as num?)?.toInt() ?? 7;
    final trigger = _experiment?['trigger'] as String? ?? '';
    final hypothesis = _experiment?['hypothesis'] as String? ?? '';
    final followup = _experiment?['followup'] as String? ?? '';

    final experiment = EchoExperiment(
      number: number,
      trigger: trigger,
      hypothesis: hypothesis,
      title: title,
      body: body,
      followup: followup,
      durationDays: days,
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExperimentProposalScreen(experiment: experiment))),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0A08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E1815)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF131009),
                    border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: EchoColors.amber),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'EXPERIMENT · $days DAYS',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: const Color(0xFF4A4038)),
                ),
                const Spacer(),
                Text('See details →', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EchoColors.textGhost)),
              ],
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: EchoColors.textPrimary,
                  height: 1.45,
                  letterSpacing: -0.2,
                ),
              ),
            ],
            if (body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                body.length > 120 ? '${body.substring(0, 120)}…' : body,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.65, color: EchoColors.textGhost),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLabTools(BuildContext context) {
    final experimentTitle = _experiment?['title'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        children: [
          _toolRow(
            'Send clones',
            'Test the current read against one real situation.',
            Icons.military_tech_rounded,
            EchoColors.amber,
            () => _openTournamentScreen(),
          ),
          if (_experiment != null) ...[
            _rowDivider(),
            _toolRow(
              experimentTitle?.isNotEmpty == true ? experimentTitle! : 'Personal experiment',
              'Turn a pattern into a 7-day test.',
              Icons.science_rounded,
              const Color(0xFF5A8DEE),
              () {
                final experiment = EchoExperiment(
                  number: (_experiment?['number'] as num?)?.toInt() ?? 1,
                  trigger: _experiment?['trigger'] as String? ?? '',
                  hypothesis: _experiment?['hypothesis'] as String? ?? '',
                  title: _experiment?['title'] as String? ?? '',
                  body: _experiment?['body'] as String? ?? '',
                  followup: _experiment?['followup'] as String? ?? '',
                  durationDays: (_experiment?['duration_days'] as num?)?.toInt() ?? 7,
                );
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExperimentProposalScreen(experiment: experiment)));
              },
            ),
          ],
          _rowDivider(),
          _toolRow(
            'Evening check-in',
            'Tell Echo what happened so the read can update.',
            Icons.nights_stay_rounded,
            const Color(0xFF7A8A9A),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRows(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 36),
      child: Container(
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Column(
          children: [
            _toolRow(
              'Memories',
              'What Echo remembers.',
              Icons.grain_rounded,
              EchoColors.indigo,
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoriesScreen())),
            ),
            _rowDivider(),
            _toolRow(
              'Operating system',
              'Rules and preferences Echo follows.',
              Icons.tonality_rounded,
              const Color(0xFF9A6AB4),
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatingSystemScreen())),
            ),
            _rowDivider(),
            _toolRow('Training', 'Clone battles, pairs, and adapter progress.', Icons.model_training_rounded, EchoColors.amber, _openTrainingScreen),
            _rowDivider(),
            _toolRow(
              'Permanent record',
              'Long-term evidence and history.',
              Icons.history_edu_rounded,
              EchoColors.indigo,
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolRow(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.08)),
              child: Icon(icon, size: 16, color: color.withValues(alpha: 0.78)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: EchoColors.textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, size: 16, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _rowDivider() {
    return Container(height: 1, margin: const EdgeInsets.only(left: 56), color: EchoColors.borderSubtle);
  }

  // ─── ARCHIVE CHIPS ───────────────────────────────────────────────────────────

  Widget _buildArchiveChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 36),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _archiveChip(
            'Memory',
            Icons.grain_rounded,
            EchoColors.indigo,
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoriesScreen())),
          ),
          _archiveChip(
            'Rules',
            Icons.tonality_rounded,
            const Color(0xFF9A6AB4),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatingSystemScreen())),
          ),
          _archiveChip('Training', Icons.model_training_rounded, EchoColors.amber, _openTrainingScreen),
          _archiveChip(
            'Record',
            Icons.history_edu_rounded,
            EchoColors.indigo,
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen())),
          ),
        ],
      ),
    );
  }

  Widget _archiveChip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color.withValues(alpha: 0.70)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost)),
          ],
        ),
      ),
    );
  }

  // ─── RANK BAR ────────────────────────────────────────────────────────────────

  Widget _buildRankBar() {
    final rankName = _rank?['rank'] as String? ?? 'Genin';
    final title = _rank?['title'] as String? ?? 'First Clone';
    final xp = (_rank?['xp'] as num?)?.toInt() ?? 0;
    final xpToNext = (_rank?['xp_to_next'] as num?)?.toInt() ?? 0;
    final progress = (_rank?['progress'] as num?)?.toDouble() ?? 0.0;
    final isKage = rankName == 'Kage';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    rankName,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: EchoColors.amber, letterSpacing: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Text('· $title', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost)),
                ],
              ),
              Text(
                isKage ? '$xp XP' : '$xp XP · $xpToNext to next',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textVeryGhost),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _loading ? 0.0 : progress),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              builder: (_, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: EchoColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(EchoColors.amber.withValues(alpha: 0.80)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SEND CLONES BUTTON ───────────────────────────────────────────────────────

  Widget _buildSendClonesButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _openTournamentScreen(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: EchoColors.amber.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.military_tech_rounded, size: 18, color: EchoColors.amber.withValues(alpha: 0.90)),
            const SizedBox(width: 10),
            Text(
              'SEND CLONES',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.amber, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  // ─── VAULTS GRID ─────────────────────────────────────────────────────────────

  Widget _buildVaultsGrid(BuildContext context) {
    final vaults = [
      _VaultItem(
        'Mirror',
        'Weekly reflection',
        Icons.remove_red_eye_rounded,
        const Color(0xFF9A6AB4),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MirrorTab())),
      ),
      _VaultItem(
        'Twin',
        'Two paths, one choice',
        Icons.people_outline_rounded,
        const Color(0xFF5A8DEE),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TwinScreen())),
      ),
      _VaultItem(
        'Memories',
        'What Echo holds',
        Icons.grain_rounded,
        EchoColors.indigo,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoriesScreen())),
      ),
      _VaultItem(
        'Record',
        'Long-term evidence',
        Icons.history_edu_rounded,
        EchoColors.indigo,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen())),
      ),
      _VaultItem(
        'Rules',
        'Operating system',
        Icons.tonality_rounded,
        const Color(0xFF9A6AB4),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatingSystemScreen())),
      ),
      _VaultItem('Training', 'Clone sessions', Icons.model_training_rounded, EchoColors.amber, _openTrainingScreen),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: vaults.map(_buildVaultTile).toList(),
    );
  }

  Widget _buildVaultTile(_VaultItem v) {
    return GestureDetector(
      onTap: v.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: v.color.withValues(alpha: 0.08)),
              child: Icon(v.icon, size: 14, color: v.color.withValues(alpha: 0.80)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    v.label,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: EchoColors.textMuted),
                  ),
                  Text(
                    v.subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EchoColors.textGhost),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
