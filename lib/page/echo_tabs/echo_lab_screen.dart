import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/daily_checkin_screen.dart';
import 'package:chatmcp/page/echo_tabs/memories_screen.dart';
import 'package:chatmcp/page/echo_tabs/mirror_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/operating_system_screen.dart';
import 'package:chatmcp/page/echo_tabs/pair_computer_screen.dart';
import 'package:chatmcp/page/echo_tabs/permanent_record_screen.dart';
import 'package:chatmcp/page/echo_tabs/remote_access_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/page/echo_tabs/twin_screen.dart';
import 'package:chatmcp/page/setting/mcp_server.dart';
import 'package:chatmcp/echo/echo_host_service.dart';
import 'package:chatmcp/provider/provider_manager.dart';

enum _LabSection { training, memory, connections, signals }

class EchoLabScreen extends StatefulWidget {
  const EchoLabScreen({super.key});

  @override
  State<EchoLabScreen> createState() => _EchoLabScreenState();
}

class _EchoLabScreenState extends State<EchoLabScreen> {
  Map<String, dynamic>? _health;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _evalData;
  bool _loading = true;
  _LabSection _section = _LabSection.training;

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
    ]);
    if (!mounted) return;
    setState(() {
      _health = results[0] as Map<String, dynamic>?;
      _summary = results[1] as Map<String, dynamic>?;
      _evalData = results[2] as Map<String, dynamic>?;
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
          children: [_header(context), const SizedBox(height: 14), _segmentControl(), const SizedBox(height: 18), ..._sectionWidgets()],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Improve Echo',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                'Improve Echo with practice, preference signal, memory, and tools.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: EchoColors.textGhost),
        ),
      ],
    );
  }

  Widget _segmentControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          _segmentButton(_LabSection.training, 'Improve', Icons.model_training_rounded),
          _segmentButton(_LabSection.memory, 'Memory', Icons.grain_rounded),
          _segmentButton(_LabSection.connections, 'Connect', Icons.hub_outlined),
          _segmentButton(_LabSection.signals, 'Signals', Icons.bolt_outlined),
        ],
      ),
    );
  }

  Widget _segmentButton(_LabSection value, String label, IconData icon) {
    final active = _section == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _section = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          decoration: BoxDecoration(
            color: active ? EchoColors.amber.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? EchoColors.amber.withValues(alpha: 0.24) : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? EchoColors.amber : EchoColors.textGhost),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? EchoColors.amber : EchoColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sectionWidgets() {
    switch (_section) {
      case _LabSection.training:
        return _trainingSection();
      case _LabSection.memory:
        return _memorySection();
      case _LabSection.connections:
        return _connectionsSection();
      case _LabSection.signals:
        return _signalsSection();
    }
  }

  List<Widget> _trainingSection() {
    return [
      _sectionHeader('Personal Model', 'Improve Echo from practice, outcomes, and proof.'),
      _statusCard(),
      const SizedBox(height: 10),
      _evalCard(),
      const SizedBox(height: 14),
      _toolRow(
        'Improve Echo',
        'Update the personal model and inspect preference readiness.',
        Icons.model_training_rounded,
        EchoColors.amber,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NightlyTrainingScreen())),
      ),
      _toolRow(
        'Decision Room',
        'Compare multiple perspectives on one real situation.',
        Icons.psychology_alt_rounded,
        EchoColors.amber,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShadowTournamentScreen())),
      ),
      _toolRow(
        'Compare Answers',
        'Pick which answer fits your context and standards.',
        Icons.people_outline_rounded,
        const Color(0xFF5A8DEE),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TwinScreen())),
      ),
    ];
  }

  List<Widget> _memorySection() {
    return [
      _sectionHeader('Memory', 'Review what Echo stores, believes, and uses as long-term evidence.'),
      _toolRow(
        'Memories',
        'What Echo remembers.',
        Icons.grain_rounded,
        EchoColors.indigo,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoriesScreen())),
      ),
      _toolRow(
        'Rules',
        'Rules and preferences Echo follows.',
        Icons.tonality_rounded,
        const Color(0xFF9A6AB4),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatingSystemScreen())),
      ),
      _toolRow(
        'Growth Record',
        'Long-term evidence and proof history.',
        Icons.history_edu_rounded,
        EchoColors.indigo,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen())),
      ),
      _toolRow(
        'Weekly reflection',
        'The latest reflection report from your signal.',
        Icons.remove_red_eye_rounded,
        const Color(0xFF9A6AB4),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MirrorScreen())),
      ),
    ];
  }

  List<Widget> _connectionsSection() {
    final host = EchoHostService();
    final connected = host.hasTunnel;
    return [
      _sectionHeader('Connections', 'Give Echo access to tools, MCP servers, and your desktop runtime.'),
      _mcpStatusCard(),
      const SizedBox(height: 10),
      _toolRow(
        'Echo MCP',
        'Install, start, and inspect MCP servers available to chat.',
        Icons.hub_outlined,
        EchoColors.amber,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _McpServerRoute())),
      ),
      _toolRow(
        'Desktop Echo',
        connected ? 'Secure private connection active.' : 'Pair Echo Desktop.',
        connected ? Icons.check_circle_rounded : Icons.computer_rounded,
        connected ? const Color(0xFF4CAF50) : EchoColors.textGhost,
        () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PairComputerScreen()));
          if (mounted) setState(() {});
        },
      ),
      _toolRow(
        'Remote access',
        'Test or update the URL your phone uses to reach your PC.',
        Icons.settings_ethernet_rounded,
        const Color(0xFF7A8A9A),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RemoteAccessScreen())),
      ),
    ];
  }

  List<Widget> _signalsSection() {
    return [
      _sectionHeader('Signals', 'Feed Echo the outcomes that make guidance less generic.'),
      _toolRow(
        'Evening check-in',
        'Structured voice or written outcome signal.',
        Icons.nights_stay_rounded,
        const Color(0xFF7A8A9A),
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen())),
      ),
      _toolRow(
        'Choose Best Path',
        'A fast comparison that creates preference signal.',
        Icons.psychology_alt_rounded,
        EchoColors.amber,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShadowTournamentScreen())),
      ),
      _toolRow(
        'Improve Echo',
        'See whether enough new signal is ready for an update.',
        Icons.model_training_rounded,
        EchoColors.amber,
        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NightlyTrainingScreen())),
      ),
    ];
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4, color: EchoColors.textMuted)),
        ],
      ),
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
                Text(
                  'System state',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                ),
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

    if (eval == null && (runStatus == 'no_runs' || runStatus.isEmpty)) {
      return _compactNotice(Icons.science_outlined, 'Model eval runs after first training.');
    }

    final skippedReason = eval?['skipped_reason'] as String?;
    if (skippedReason != null && skippedReason.isNotEmpty) {
      return _compactNotice(Icons.info_outline_rounded, 'Eval skipped: $skippedReason');
    }

    if (eval == null) return const SizedBox.shrink();

    final passed = eval['passed'] as bool? ?? true;
    final score = eval['score'] as num?;
    final nEval = (eval['n_eval'] as num?)?.toInt() ?? 0;
    final scorePct = score != null ? '${(score * 100).round()}%' : 'not run';
    final dateStr = finishedAt != null ? finishedAt.substring(0, 10) : '';
    final adapterActuallyLive = _health?['adapter_loaded'] == true;
    final effectivePassed = passed || adapterActuallyLive;

    final color = passed
        ? const Color(0xFF4CAF50)
        : adapterActuallyLive
        ? EchoColors.amber
        : Colors.redAccent;
    final icon = effectivePassed ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = passed
        ? 'Model passed eval'
        : adapterActuallyLive
        ? 'Model active - eval threshold was conservative'
        : 'Eval failed - previous adapter kept';

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
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              if (dateStr.isNotEmpty) Text(dateStr, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(Icons.bar_chart_rounded, 'Score $scorePct'),
              _pill(Icons.question_answer_outlined, '$nEval prompts'),
              _pill(effectivePassed ? Icons.memory_rounded : Icons.history_rounded, effectivePassed ? 'adapter live' : 'rolled back'),
            ],
          ),
          if (!passed && adapterActuallyLive) ...[
            const SizedBox(height: 8),
            Text(
              'Word-overlap eval is a rough check. Your personal model is running. Chat and give thumbs up/down to improve it further.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.45, color: EchoColors.textGhost),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactNotice(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: EchoColors.textGhost.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost)),
          ),
        ],
      ),
    );
  }

  Widget _mcpStatusCard() {
    return FutureBuilder<int>(
      future: ProviderManager.mcpServerProvider.installedServersCount,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        final running = ProviderManager.mcpServerProvider.clients.length;
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
                  const Icon(Icons.hub_outlined, size: 17, color: EchoColors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'MCP status',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.inventory_2_outlined, '$count installed'),
                  _pill(Icons.play_circle_outline_rounded, '$running running'),
                  _pill(Icons.security_rounded, 'approval controlled'),
                ],
              ),
            ],
          ),
        );
      },
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
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textMuted),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _McpServerRoute extends StatelessWidget {
  const _McpServerRoute();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(child: McpServer()),
    );
  }
}
