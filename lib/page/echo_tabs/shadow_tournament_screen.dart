import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_theme.dart';

enum _TournamentPhase { input, loading, result, saved }

class ShadowTournamentScreen extends StatefulWidget {
  final String? initialPrompt;

  const ShadowTournamentScreen({super.key, this.initialPrompt});

  @override
  State<ShadowTournamentScreen> createState() => _ShadowTournamentScreenState();
}

class _ShadowTournamentScreenState extends State<ShadowTournamentScreen>
    with TickerProviderStateMixin {
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
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
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
        _error = 'Echo could not run the tournament.';
      });
      return;
    }

    setState(() {
      _runId = result['run_id'] as String?;
      _topic = result['topic'] as String?;
      _candidates = (result['candidates'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: AppBar(
        backgroundColor: EchoColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: EchoColors.textMuted,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shadow Tournament',
          style: GoogleFonts.plusJakartaSans(
            color: EchoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _buildBody(),
      ),
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
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textPrimary,
                fontSize: 15,
                height: 1.45,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Describe a situation, decision, fear, project, or pattern...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textGhost,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFE06A4F),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _primaryButton('Run four shadows', Icons.military_tech_rounded, _run),
          const SizedBox(height: 18),
          _hintRow(Icons.psychology_alt_rounded,
              'Pick the answer that actually helps. Echo turns that choice into clone-training signal.'),
        ],
      ),
    );
  }

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Four versions of your shadow will compete.',
          style: GoogleFonts.lora(
            color: EchoColors.textPrimary,
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Strategist, Challenger, Mirror, and Builder each try to help in a different way. Your choice teaches Echo which version moves you forward.',
          style: GoogleFonts.plusJakartaSans(
            color: EchoColors.textMuted,
            fontSize: 13.5,
            height: 1.55,
          ),
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
                    border: Border.all(
                      color: EchoColors.amber.withValues(alpha: 0.22 + _pulse.value * 0.24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: 0.12 + _pulse.value * 0.16),
                        blurRadius: 34 + _pulse.value * 24,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_motion_rounded,
                      color: EchoColors.amber, size: 28),
                ),
                const SizedBox(height: 28),
                Text(
                  'The shadows are competing.',
                  style: GoogleFonts.plusJakartaSans(
                    color: EchoColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Four responses. One signal.',
                  style: GoogleFonts.plusJakartaSans(
                    color: EchoColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
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
                  _topic == null ? 'Choose the winner' : 'Choose the winner - $_topic',
                  style: GoogleFonts.plusJakartaSans(
                    color: EchoColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Reset',
                    style: GoogleFonts.plusJakartaSans(
                      color: EchoColors.textGhost,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final candidate in _candidates) ...[
            _candidateCard(candidate),
            const SizedBox(height: 12),
          ],
          if (_error != null)
            Text(
              _error!,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFE06A4F),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _candidateCard(Map<String, dynamic> candidate) {
    final style = candidate['style'] as String? ?? 'Shadow';
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        style,
                        style: GoogleFonts.plusJakartaSans(
                          color: EchoColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: EchoColors.textGhost,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_outline_rounded,
                    color: color.withValues(alpha: 0.55), size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              response,
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textSecondary,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaved() {
    final winner = _winner ?? 'Shadow';
    final color = _styleColors[winner] ?? EchoColors.amber;
    final learning = _learningSummary ??
        'Echo learned which version helped most here. That choice updates your current read and becomes training signal.';

    return SafeArea(
      key: const ValueKey('saved'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
                border: Border.all(color: color.withValues(alpha: 0.32)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 42,
                  ),
                ],
              ),
              child: Icon(Icons.military_tech_rounded, color: color, size: 34),
            ),
            const SizedBox(height: 26),
            Text(
              '$winner won.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                color: EchoColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              learning,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textMuted,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            _primaryButton('Run another battle', Icons.refresh_rounded, _reset),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Back to Echo',
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textGhost,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.amber,
                fontSize: 14,
                fontWeight: FontWeight.w800,
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
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: EchoColors.textGhost,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
