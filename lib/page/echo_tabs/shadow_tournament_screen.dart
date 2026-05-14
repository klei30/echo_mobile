import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/memory_consent_sheet.dart';
import 'package:chatmcp/page/echo_tabs/outcome_capture_sheet.dart';

enum _TournamentPhase { input, loading, result, saved }

class ShadowTournamentScreen extends StatefulWidget {
  final String? initialPrompt;

  const ShadowTournamentScreen({super.key, this.initialPrompt});

  @override
  State<ShadowTournamentScreen> createState() => _ShadowTournamentScreenState();
}

class _ShadowTournamentScreenState extends State<ShadowTournamentScreen> with TickerProviderStateMixin {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  late final AnimationController _pulse;

  _TournamentPhase _phase = _TournamentPhase.input;
  String? _runId;
  String? _topic;
  String? _winner;
  String? _learningSummary;
  List<Map<String, dynamic>> _candidates = [];
  String? _error;

  static const _styleColors = {
    'Strategist': Color(0xFF5A8DEE),
    'Challenger': Color(0xFFE06A4F),
    'Mirror': Color(0xFFB18CE0),
    'Builder': Color(0xFFC4783A),
  };

  static const _styleIcons = {
    'Strategist': Icons.timeline_rounded,
    'Challenger': Icons.bolt_rounded,
    'Mirror': Icons.visibility_rounded,
    'Builder': Icons.architecture_rounded,
  };

  static const _styleSubtitles = {
    'Strategist': 'turns the situation into a next move',
    'Challenger': 'names the avoidance or weak assumption',
    'Mirror': 'reflects the deeper pattern back',
    'Builder': 'creates a system or rep',
  };

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialPrompt ?? '';
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    setState(() {
      _phase = _TournamentPhase.loading;
      _error = null;
      _winner = null;
      _learningSummary = null;
    });

    final result = await EchoApiClient().runTournament(prompt);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _phase = _TournamentPhase.input;
        _error = 'Echo could not run the comparison.';
      });
      return;
    }

    setState(() {
      _runId = result['run_id'] as String?;
      _topic = result['topic'] as String?;
      _candidates = (result['candidates'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _phase = _TournamentPhase.result;
    });
  }

  Future<void> _choose(Map<String, dynamic> candidate) async {
    final runId = _runId;
    final candidateId = candidate['id'] as String?;
    if (runId == null || candidateId == null) return;
    HapticFeedback.selectionClick();

    final result = await EchoApiClient().chooseTournamentCandidate(runId, candidateId);
    if (!mounted) return;
    if (result == null) {
      setState(() => _error = 'Echo could not save that choice.');
      return;
    }

    setState(() {
      _winner = result['winning_style'] as String? ?? candidate['style'] as String?;
      _learningSummary = result['learning_summary'] as String?;
      _phase = _TournamentPhase.saved;
    });
    await EchoLoopState().refresh();
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = _TournamentPhase.input;
      _runId = null;
      _topic = null;
      _winner = null;
      _learningSummary = null;
      _candidates = [];
      _error = null;
    });
  }

  Future<void> _saveLessonAsProof() async {
    final learning = _learningSummary ?? 'Practice Versions helped compare several approaches and choose what fit best.';
    final saved = await OutcomeCaptureSheet.show(
      context,
      title: 'Save this Practice Versions lesson?',
      subjectType: 'shadow_training',
      subjectId: _runId,
      contextNote: learning,
      doneLabel: 'Save proof',
      skippedLabel: 'Not useful',
      createProof: true,
      proofCategory: 'practice',
      proofTitle: _topic == null ? 'Practice Versions lesson' : 'Practice Versions: $_topic',
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Practice Versions saved as proof.')));
  }

  Future<void> _rememberLesson() async {
    final learning = _learningSummary ?? 'This Practice Versions run showed which kind of help fit the situation.';
    final saved = await MemoryConsentSheet.show(context, proposedMemory: learning, sourceType: 'shadow_training');
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson sent to Echo memory.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: AppBar(
        backgroundColor: EchoColors.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, size: 18), color: EchoColors.textMuted, onPressed: () => Navigator.pop(context)),
        title: Text(
          'Practice Versions',
          style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _TournamentPhase.input:
        return _buildInput();
      case _TournamentPhase.loading:
        return _buildLoading();
      case _TournamentPhase.result:
        return _buildResult();
      case _TournamentPhase.saved:
        return _buildSaved();
    }
  }

  Widget _buildInput() {
    return SafeArea(
      key: const ValueKey('input'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        children: [
          _intro(),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: EchoColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              minLines: 5,
              maxLines: 8,
              style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 15, height: 1.45),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Describe a situation, decision, fear, project, or pattern...',
                hintStyle: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 14),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE06A4F), fontSize: 12)),
          ],
          const SizedBox(height: 18),
          _primaryButton('Start practice versions', Icons.psychology_alt_rounded, _run),
          const SizedBox(height: 18),
          _hintRow(
            Icons.psychology_alt_rounded,
            'Practice several versions of one hard thing. Pick what actually helped, and Echo saves the lesson.',
          ),
        ],
      ),
    );
  }

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice many versions of one hard thing.',
          style: GoogleFonts.lora(color: EchoColors.textPrimary, fontSize: 26, height: 1.2, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Echo creates several versions of a response or next move. Choose the one that would actually help in real life.',
          style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 13.5, height: 1.55),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return SafeArea(
      key: const ValueKey('loading'),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72 + _pulse.value * 18,
                  height: 72 + _pulse.value * 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: 0.08 + _pulse.value * 0.05),
                    border: Border.all(color: EchoColors.amber.withValues(alpha: 0.22 + _pulse.value * 0.24)),
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: 0.12 + _pulse.value * 0.16),
                        blurRadius: 34 + _pulse.value * 24,
                      ),
                    ],
                  ),
                  child: Icon(Icons.auto_awesome_motion_rounded, color: EchoColors.amber, size: 28),
                ),
                const SizedBox(height: 28),
                Text(
                  'Echo is comparing practice versions.',
                  style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text('Several attempts. One useful lesson.', style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12.5)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResult() {
    return SafeArea(
      key: const ValueKey('result'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                Text(
                  _topic == null ? 'Choose what helped' : 'Choose what helped - $_topic',
                  style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: Text('Reset', style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 12)),
                ),
              ],
            ),
          ),
          for (final candidate in _candidates) ...[_candidateCard(candidate), const SizedBox(height: 12)],
          if (_error != null) Text(_error!, style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE06A4F), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _candidateCard(Map<String, dynamic> candidate) {
    final style = candidate['style'] as String? ?? 'Perspective';
    final response = candidate['response'] as String? ?? '';
    final color = _styleColors[style] ?? EchoColors.amber;
    final icon = _styleIcons[style] ?? Icons.auto_awesome_rounded;
    final subtitle = _styleSubtitles[style] ?? 'tries a different route';

    return GestureDetector(
      onTap: () => _choose(candidate),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EchoColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style,
                        style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_outline_rounded, color: color.withValues(alpha: 0.55), size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(response, style: GoogleFonts.plusJakartaSans(color: EchoColors.textSecondary, fontSize: 13.5, height: 1.55)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaved() {
    final winner = _winner ?? 'Perspective';
    final color = _styleColors[winner] ?? EchoColors.amber;
    final learning =
        _learningSummary ??
        'Echo learned which attempt helped most here. That choice updates your current read and can become proof for future guidance.';

    return SafeArea(
      key: const ValueKey('saved'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
        children: [
          Column(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.10),
                  border: Border.all(color: color.withValues(alpha: 0.32)),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 42)],
                ),
                child: Icon(Icons.psychology_alt_rounded, color: color, size: 34),
              ),
              const SizedBox(height: 26),
              Text(
                '$winner helped most.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(color: EchoColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                learning,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 13.5, height: 1.55),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: _secondaryButton('Save proof', Icons.inventory_2_outlined, _saveLessonAsProof)),
                  const SizedBox(width: 10),
                  Expanded(child: _secondaryButton('Remember', Icons.lock_outline_rounded, _rememberLesson)),
                ],
              ),
              const SizedBox(height: 10),
              _primaryButton('Run again', Icons.refresh_rounded, _reset),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Back to Today',
                  style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: EchoColors.amber.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.34)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: EchoColors.amber),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(color: EchoColors.amber, fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: EchoColors.textPrimary),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hintRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: EchoColors.textGhost),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 12, height: 1.45)),
        ),
      ],
    );
  }
}
