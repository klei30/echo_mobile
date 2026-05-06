import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/echo_lab_screen.dart';
import 'package:chatmcp/page/echo_tabs/local_model_setup_screen.dart';
import 'package:chatmcp/page/echo_tabs/growth_timeline_screen.dart';
import 'package:chatmcp/page/echo_tabs/opportunities_screen.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';
import 'package:chatmcp/page/echo_tabs/talent_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/provider/provider_manager.dart';

class _CloneArcPainter extends CustomPainter {
  final double progress; // 0.0-1.0
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

    // Amber progress arc - clockwise from top
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

class YouTab extends StatefulWidget {
  const YouTab({super.key});

  @override
  State<YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<YouTab> {
  Map<String, dynamic>? _signal;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _thesis;
  Map<String, dynamic>? _trainingSummary;
  Map<String, dynamic>? _rank;
  Map<String, dynamic>? _growthTimeline;
  Map<String, dynamic>? _revelationStatus;
  Map<String, dynamic>? _proofData;
  Map<String, dynamic>? _opportunityData;
  bool _loading = true;

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
    if (EchoRuntimeService().isDevice) {
      final loop = EchoLoopState();
      if (!mounted) return;
      setState(() {
        _thesis = loop.thesis ?? _thesis;
        _trainingSummary = loop.trainingSummary ?? _trainingSummary;
        _rank = loop.rank ?? _rank;
        _growthTimeline = loop.growthTimeline ?? _growthTimeline;
        _proofData = null;
        _opportunityData = null;
        _loading = false;
      });
      return;
    }
    final results = await Future.wait([
      EchoApiClient().getUserSignal(),
      EchoApiClient().getUserStats(),
      EchoApiClient().getCurrentThesis(),
      EchoApiClient().getTrainingSummary(lane: _trainingLane()),
      EchoApiClient().getUserRank(),
      EchoApiClient().getGrowthTimeline(),
      EchoApiClient().getRevelationStatus(),
      EchoApiClient().getProofItems(limit: 6),
      EchoApiClient().getOpportunities(),
    ]);
    if (!mounted) return;
    setState(() {
      _signal = results[0];
      _stats = results[1];
      _thesis = results[2];
      _trainingSummary = results[3];
      _rank = results[4];
      _growthTimeline = results[5];
      _revelationStatus = results[6];
      _proofData = results[7];
      _opportunityData = results[8];
      _loading = false;
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
                  Padding(padding: const EdgeInsets.fromLTRB(18, 16, 18, 4), child: _buildPrimaryCta(context)),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 8, 18, 4), child: _buildOpportunityCard(context)),

                  _chapterLabel('DIRECTION'),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: _buildThesisCard(context)),

                  _chapterLabel('PROOF'),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: _buildProgressCard(context)),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: _buildProofBuilderEntry(context)),

                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: _buildLabEntry(context)),
                  Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: _buildDeviceEntry(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context) {
    final opportunities = (_opportunityData?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final opportunity = opportunities.isNotEmpty ? opportunities.first : null;
    final direction = _thesis?['title'] as String? ?? 'Direction still forming';
    final statement = _thesis?['statement'] as String? ?? 'Keep using Coach and Today so Echo can connect your signals to real proof.';
    final title = opportunity?['title'] as String? ?? 'Build proof for: $direction';
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
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded, size: 17, color: EchoColors.amber),
                const SizedBox(width: 8),
                Text(
                  'NEXT OPPORTUNITY',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.amber),
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
                    'Open opportunity plan',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: EchoColors.amber),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: EchoColors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofBuilderEntry(BuildContext context) {
    final items = (_proofData?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final summary = Map<String, dynamic>.from(_proofData?['summary'] as Map? ?? {});
    final proofCount = (summary['count'] as num?)?.toInt() ?? items.length;
    final latest = items.isNotEmpty ? items.first['title'] as String? : null;
    final body = latest == null
        ? 'Save one artifact, outcome, practice result, or piece of feedback.'
        : 'Latest proof: $latest';
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
                color: EchoColors.amber.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
              ),
              child: const Icon(Icons.inventory_2_outlined, size: 18, color: EchoColors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proofCount > 0 ? 'Proof Builder - $proofCount saved' : 'Proof Builder',
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
            const Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final status = _revelationStatus ?? {};
    final state = status['state'] as String? ?? 'watching';
    final ready = status['ready'] as bool? ?? false;
    final score = (status['score'] as num?)?.toDouble() ?? 0.0;
    final headline = status['headline'] as String? ?? 'Echo is still watching for the deeper pattern.';
    final weeks = (status['weeks_watched'] as num?)?.toInt() ?? 0;
    final requirements = (status['requirements'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final timelineHeadline = _growthTimeline?['headline'] as String? ?? 'Proof is still forming.';
    final stats = Map<String, dynamic>.from(_growthTimeline?['stats'] as Map? ?? {});

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ready ? const TalentScreen() : const GrowthTimelineScreen())),
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
                      ? 'STRENGTH FOUND'
                      : ready
                      ? 'DIRECTION READY'
                      : 'PROOF FORMING',
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
              children: [
                ...requirements.take(3).map((r) {
                  final complete = r['complete'] == true;
                  final label = r['label'] as String? ?? 'Signal';
                  final current = (r['current'] as num?)?.toInt() ?? 0;
                  final target = (r['target'] as num?)?.toInt() ?? 1;
                  return _loopPill(complete ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded, '$label $current/$target');
                }),
                _loopPill(Icons.flag_outlined, '${stats['milestones'] ?? 0} milestones'),
                _loopPill(Icons.bolt_outlined, '${stats['practice_done'] ?? 0} reps'),
                _loopPill(Icons.psychology_alt_outlined, '${stats['clone_battles'] ?? 0} decisions'),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ready ? 'Open strengths' : timelineHeadline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: ready ? EchoColors.amber : EchoColors.textGhost,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, color: ready ? EchoColors.amber : EchoColors.textGhost),
              ],
            ),
          ],
        ),
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
                    ready ? 'Echo is ready to improve' : 'Improve Echo',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Your outcomes and choices become training signal. Technical details stay here when you need them. Preference signal $dpoReady/$dpoRequired.',
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
                  : 'This Device needs a model'
            : 'Offline & Privacy';
        final body = ready
            ? '${runtime.deviceModelVersion.isEmpty ? 'Gemma on device' : runtime.deviceModelVersion} is selected for offline Coach.'
            : 'Import a LiteRT-LM Gemma model so Echo can work without Wi-Fi.';
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
                const Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
              ],
            ),
          ),
        );
      },
    );
  }

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
                  // Progress arc - animates from 0 to real value on load
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
                          '$pct% aligned',
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
              'opportunity passport',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, letterSpacing: 1.1, color: EchoColors.textGhost, fontWeight: FontWeight.w500),
            ),

            if (firstName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                weeks > 0 ? '$firstName - week $weeks' : firstName,
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
                      'Echo learned something new from your recent signal',
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
    final hasThesis = _thesis != null;
    final title = _thesis?['title'] as String? ?? 'Still Forming';
    final statement = _thesis?['statement'] as String? ?? 'Echo is waiting for enough real moments to form a thesis.';
    final stage = _thesis?['stage'] as String? ?? 'forming';
    final confidence = _thesis?['confidence_label'] as String? ?? 'early';
    final evidenceCount = (_thesis?['evidence_count'] as num?)?.toInt() ?? 0;
    final evidence = (_thesis?['evidence'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).take(3).toList();
    final action = Map<String, dynamic>.from(_thesis?['next_action'] as Map? ?? {});
    final actionLabel = _cleanActionLabel(action['label'] as String? ?? 'Open potential');

    return GestureDetector(
      onTap: hasThesis ? _handleThesisAction : null,
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
            if (hasThesis) ...[
              const SizedBox(height: 14),
              Row(
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
            ],
            if (evidence.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(height: 1, color: EchoColors.borderSubtle),
              const SizedBox(height: 12),
              Text(
                'Signals behind this read',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost),
              ),
              const SizedBox(height: 9),
              ...evidence.map((item) {
                final summary = item['summary'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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

  Widget _chapterLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: EchoColors.textGhost),
      ),
    );
  }

  Widget _buildRankBar() {
    final rawRankName = _rank?['rank'] as String? ?? 'Genin';
    final rankName = _displayRank(rawRankName);
    final title = _displayTitle(_rank?['title'] as String? ?? 'First Signals');
    final xp = (_rank?['xp'] as num?)?.toInt() ?? 0;
    final xpToNext = (_rank?['xp_to_next'] as num?)?.toInt() ?? 0;
    final progress = (_rank?['progress'] as num?)?.toDouble() ?? 0.0;
    final isMaxLevel = rawRankName == 'Kage';

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
                  Text('- $title', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost)),
                ],
              ),
              Text(
                isMaxLevel ? '$xp XP' : '$xp XP - $xpToNext to next',
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

  Widget _buildPrimaryCta(BuildContext context) {
    final revelationReady = _revelationStatus?['ready'] as bool? ?? false;
    final trainingReady = _trainingSummary?['ready_for_training'] as bool? ?? false;
    final IconData icon;
    final String label;
    final VoidCallback action;

    if (revelationReady) {
      icon = Icons.auto_awesome_rounded;
      label = 'OPEN STRENGTHS';
      action = () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TalentScreen()));
      };
    } else if (trainingReady) {
      icon = Icons.model_training_rounded;
      label = 'IMPROVE ECHO';
      action = () {
        _openTrainingScreen();
      };
    } else {
      icon = Icons.psychology_alt_rounded;
      label = 'CHOOSE BEST PATH';
      action = () {
        _openTournamentScreen();
      };
    }

    return GestureDetector(
      onTap: action,
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
            Icon(icon, size: 18, color: EchoColors.amber.withValues(alpha: 0.90)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.amber, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanActionLabel(String label) {
    return label
        .replaceAll('Send clones', 'Choose best path')
        .replaceAll('send clones', 'choose best path')
        .replaceAll('Run tournament', 'Choose best path')
        .replaceAll('run tournament', 'choose best path')
        .replaceAll('Open talent', 'Open potential')
        .replaceAll('clone', 'model')
        .replaceAll('Clone', 'Model');
  }

  String _displayRank(String rank) {
    switch (rank) {
      case 'Genin':
        return 'Level 1';
      case 'Chunin':
        return 'Level 2';
      case 'Jonin':
        return 'Level 3';
      case 'Kage':
        return 'Mastery';
      default:
        return rank;
    }
  }

  String _displayTitle(String title) {
    return title
        .replaceAll('First Clone', 'First Signals')
        .replaceAll('Clone', 'Model')
        .replaceAll('clone', 'model')
        .replaceAll('Shadow', 'Signal')
        .replaceAll('shadow', 'signal');
  }
}
