import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/daily_checkin_screen.dart';
import 'package:chatmcp/page/echo_tabs/memories_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/operating_system_screen.dart';
import 'package:chatmcp/page/echo_tabs/permanent_record_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/page/echo_tabs/pair_computer_screen.dart';
import 'package:chatmcp/echo/echo_host_service.dart';

class EchoLabScreen extends StatefulWidget {
  const EchoLabScreen({super.key});

  @override
  State<EchoLabScreen> createState() => _EchoLabScreenState();
}

class _EchoLabScreenState extends State<EchoLabScreen> {
  Map<String, dynamic>? _health;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _evalData;
  List<Map<String, dynamic>> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      EchoApiClient().getSystemHealth(),
      EchoApiClient().getTrainingSummary(lane: 'gemma4_e2b'),
      EchoApiClient().getTrainingEval(lane: 'gemma4_e2b'),
      EchoApiClient().getTrainingRuns(lane: 'gemma4_e2b'),
    ]);
    if (!mounted) return;
    setState(() {
      _health = results[0] as Map<String, dynamic>?;
      _summary = results[1] as Map<String, dynamic>?;
      _evalData = results[2] as Map<String, dynamic>?;
      _runs = results[3] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            _header(context),
            const SizedBox(height: 18),
            _statusCard(),
            const SizedBox(height: 10),
            _evalCard(),
            const SizedBox(height: 10),
            _trainingHistoryCard(),
            const SizedBox(height: 16),
            _section('Clone Training'),
            _toolRow('Training room', 'Update the local clone and inspect DPO readiness.',
                Icons.model_training_rounded, EchoColors.amber,
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NightlyTrainingScreen()))),
            _toolRow('Send clones', 'Run a tournament on one real situation.',
                Icons.military_tech_rounded, EchoColors.amber,
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShadowTournamentScreen()))),
            _toolRow('Evening check-in', 'Structured voice/written outcome signal.',
                Icons.nights_stay_rounded, const Color(0xFF7A8A9A),
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen()))),
            const SizedBox(height: 16),
            _section('Memory & System'),
            _toolRow('Memories', 'What Echo remembers.', Icons.grain_rounded,
                EchoColors.indigo, () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoriesScreen()))),
            _toolRow('Operating system', 'Rules and preferences Echo follows.',
                Icons.tonality_rounded, const Color(0xFF9A6AB4),
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatingSystemScreen()))),
            _toolRow('Permanent record', 'Long-term evidence and history.',
                Icons.history_edu_rounded, EchoColors.indigo,
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen()))),
            const SizedBox(height: 16),
            _section('Connections'),
            _toolRow(
              'My Computer',
              EchoHostService().hasTunnel
                  ? 'Secure private connection active'
                  : 'Pair Echo Desktop',
              EchoHostService().hasTunnel ? Icons.check_circle_rounded : Icons.computer_rounded,
              EchoHostService().hasTunnel ? const Color(0xFF4CAF50) : EchoColors.textGhost,
              () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PairComputerScreen()));
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('Lab',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w900, color: EchoColors.textPrimary)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: EchoColors.textGhost),
        ),
      ],
    );
  }

  Widget _statusCard() {
    final training = _summary?['status'] as String? ?? _health?['training_status'] as String? ?? 'unknown';
    final dpoReady = (_summary?['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (_summary?['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    final vllm = _health?['vllm']?.toString() ?? 'unknown';
    final adapterLoaded = _health?['adapter_loaded'] == true;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: _loading
          ? const LinearProgressIndicator(color: EchoColors.amber, minHeight: 2)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System state',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(Icons.dns_outlined, 'vLLM $vllm'),
                    _pill(Icons.memory_rounded, adapterLoaded ? 'adapter live' : 'adapter not loaded'),
                    _pill(Icons.model_training_outlined, training),
                    _pill(Icons.compare_arrows_rounded, '$dpoReady/$dpoRequired DPO-ready'),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _evalCard() {
    if (_loading) return const SizedBox.shrink();
    final eval = _evalData?['eval'] as Map<String, dynamic>?;
    final runStatus = _evalData?['status'] as String? ?? '';
    final finishedAt = _evalData?['finished_at'] as String?;

    // No runs yet
    if (eval == null && (runStatus == 'no_runs' || runStatus.isEmpty)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.science_outlined, size: 16, color: EchoColors.textGhost.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Text(
              'Clone eval runs after first training.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost),
            ),
          ],
        ),
      );
    }

    // Eval was skipped (not enough held-out pairs)
    final skippedReason = eval?['skipped_reason'] as String?;
    if (skippedReason != null && skippedReason.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: EchoColors.textGhost.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Eval skipped: $skippedReason',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
              ),
            ),
          ],
        ),
      );
    }

    if (eval == null) return const SizedBox.shrink();

    final passed = eval['passed'] as bool? ?? true;
    final score = eval['score'] as num?;
    final nEval = (eval['n_eval'] as num?)?.toInt() ?? 0;
    final scorePct = score != null ? '${(score * 100).round()}%' : '—';
    final dateStr = finishedAt != null ? finishedAt.substring(0, 10) : '';

    // Eval failed but adapter is confirmed live in vLLM — eval threshold was conservative
    final adapterActuallyLive = _health?['adapter_loaded'] == true;
    final effectivePassed = passed || adapterActuallyLive;

    final color = passed
        ? const Color(0xFF4CAF50)
        : adapterActuallyLive
            ? EchoColors.amber
            : Colors.redAccent;
    final icon = effectivePassed ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = passed
        ? 'Clone passed eval'
        : adapterActuallyLive
            ? 'Clone active — eval threshold was conservative'
            : 'Eval failed — previous adapter kept';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: color,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(Icons.bar_chart_rounded, 'Score $scorePct'),
              _pill(Icons.question_answer_outlined, '$nEval prompts'),
              _pill(
                effectivePassed ? Icons.memory_rounded : Icons.history_rounded,
                effectivePassed ? 'adapter live' : 'rolled back',
              ),
            ],
          ),
          if (!passed && adapterActuallyLive) ...[
            const SizedBox(height: 8),
            Text(
              'Word-overlap eval is a rough check. Your clone is running — just chat and give thumbs up/down to improve it further.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.45, color: EchoColors.textGhost),
            ),
          ],
        ],
      ),
    );
  }

  Widget _trainingHistoryCard() {
    if (_loading || _runs.isEmpty) return const SizedBox.shrink();
    final completed = _runs.where((r) {
      final s = r['status'] as String? ?? '';
      return s.startsWith('complete');
    }).toList();
    if (completed.isEmpty) return const SizedBox.shrink();

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
          Row(children: [
            const Icon(Icons.trending_up_rounded, size: 15, color: EchoColors.amber),
            const SizedBox(width: 7),
            Text('Training history',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w800, color: EchoColors.textPrimary)),
            const Spacer(),
            Text('${completed.length} run${completed.length == 1 ? '' : 's'}',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost)),
          ]),
          const SizedBox(height: 12),
          ...completed.take(5).map((run) {
            final score = run['eval_score'] as num?;
            final passed = run['eval_passed'] as bool?;
            final adapterLive = _health?['adapter_loaded'] == true &&
                run == completed.first;
            final status = run['status'] as String? ?? '';
            final date = (run['finished_at'] as String? ?? '').length >= 10
                ? (run['finished_at'] as String).substring(0, 10)
                : '';
            final pairs = run['pairs'] as num? ?? 0;
            final scorePct = score != null ? '${(score * 100).round()}%' : '—';
            final Color dotColor = (passed == true || adapterLive)
                ? const Color(0xFF4CAF50)
                : status == 'complete_eval_failed'
                    ? EchoColors.amber
                    : EchoColors.textGhost;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      date,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textMuted),
                    ),
                  ),
                  Text(
                    '$pairs pairs',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      score != null ? 'score $scorePct' : (adapterLive ? 'live' : status.replaceAll('_', ' ')),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: dotColor),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            'Score = word-overlap check (>25% passes). Green = adapter active. Amber = trained, eval conservative.',
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, height: 1.45, color: EchoColors.textVeryGhost),
          ),
        ],
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
              fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800, color: EchoColors.textGhost)),
    );
  }

  Widget _toolRow(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textMuted)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EchoColors.bg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: EchoColors.textGhost),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
        ],
      ),
    );
  }
}
