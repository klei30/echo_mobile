import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/page/echo_connections/connections_page.dart';
import 'package:chatmcp/page/echo_tabs/emergence_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/experiment_screen.dart';
import 'package:chatmcp/page/echo_tabs/after_meeting_screen.dart';
import 'package:chatmcp/page/echo_tabs/anniversary_screen.dart';
import 'package:chatmcp/page/echo_tabs/memories_screen.dart';
import 'package:chatmcp/page/echo_tabs/operating_system_screen.dart';
import 'package:chatmcp/page/echo_tabs/permanent_record_screen.dart';
import 'package:chatmcp/page/echo_tabs/talent_screen.dart';
import 'package:chatmcp/page/echo_tabs/daily_checkin_screen.dart';
import 'package:chatmcp/page/echo_tabs/twin_screen.dart';
import 'package:chatmcp/page/echo_tabs/council_screen.dart';
import 'package:chatmcp/page/echo_tabs/presence_screen.dart';
import 'package:chatmcp/page/echo_tabs/parallel_self_screen.dart';

// ─── Arc painter ─────────────────────────────────────────────────────────────

class _CloneArcPainter extends CustomPainter {
  final double progress; // 0.0–1.0
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

    // Amber progress arc — clockwise from top
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

// ─── Widget ──────────────────────────────────────────────────────────────────

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
  bool _loading = true;
  bool _loggedThisSession = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      EchoApiClient().getUserSignal(),
      EchoApiClient().getPracticeToday(),
      EchoApiClient().getNotableQuote(),
      EchoApiClient().getUserStats(),
    ]);
    if (!mounted) return;
    setState(() {
      _signal = results[0];
      _practice = results[1];
      _quote = results[2];
      _stats = results[3];
      _loggedThisSession = _practice?['logged'] as bool? ?? false;
      _loading = false;
    });

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
          ..._practice ?? {},
          'logged': true,
          'done': done,
          'week_completions': result['week_completions'] ?? _practice?['week_completions'] ?? 0,
        };
      });
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
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final dt = DateTime.parse(iso).toLocal();
      return 'trained ${m[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  // ─── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: EchoColors.amber,
          backgroundColor: EchoColors.bgSurface,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ─── CLONE HERO ────────────────────────────────────────────
              _buildCloneHero(context),
              // ─── ECHO'S SIGNAL ─────────────────────────────────────────
              _buildSignalZone(),
              // ─── TODAY'S REP ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildPracticeSection(),
              ),
              // ─── YOUR HIDDEN TALENT ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildTalentSection(context),
              ),
              // ─── ASK YOUR TWIN ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildTwinSection(context),
              ),
              // ─── THE COUNCIL ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildCouncilSection(context),
              ),
              // ─── ECHO PRESENCE ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildPresenceSection(context),
              ),
              // ─── TWO PATHS ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildTwoPathsSection(context),
              ),
              // ─── GO DEEPER ─────────────────────────────────────────────
              _buildGoDeeper(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CLONE HERO ─────────────────────────────────────────────────────────────

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
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NightlyTrainingScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(0, 36, 0, 32),
        decoration: recently
            ? BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    EchoColors.amber.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
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
                  // Progress arc — animates from 0 to real value on load
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: EchoColors.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: EchoColors.amber.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '$pct% you',
                          style: GoogleFonts.lora(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: EchoColors.amber,
                            letterSpacing: -0.1,
                          ),
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                letterSpacing: 1.1,
                color: EchoColors.textGhost,
                fontWeight: FontWeight.w500,
              ),
            ),

            if (firstName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                weeks > 0
                    ? '$firstName · week $weeks'
                    : firstName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: EchoColors.textVeryGhost,
                ),
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
                  if (lastTrained != null)
                    _statPill(_trainedLabel(lastTrained),
                        highlight: recently),
                ],
              )
            else if (_loading)
              Container(
                width: 180,
                height: 22,
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

            // "trained last night" glow pill
            if (!_loading && recently) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: EchoColors.amber.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EchoColors.amber.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'your clone learned something new last night',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: EchoColors.amber.withValues(alpha: 0.85),
                      ),
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
        color: highlight
            ? EchoColors.amber.withValues(alpha: 0.07)
            : EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? EchoColors.amber.withValues(alpha: 0.2)
              : EchoColors.borderSubtle,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: highlight ? EchoColors.amberText : EchoColors.textGhost,
        ),
      ),
    );
  }

  // ─── ECHO'S SIGNAL ──────────────────────────────────────────────────────────

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
                Container(
                    height: 22, width: 260,
                    color: EchoColors.bgSurface,
                    margin: const EdgeInsets.only(bottom: 8)),
                Container(height: 18, width: 200, color: EchoColors.bgSurface),
              ],
            )
          else if (signal != null) ...[
            Text(
              '"$signal"',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: EchoColors.textPrimary,
                height: 1.5,
                letterSpacing: -0.3,
              ),
            ),
            if (quote != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"',
                      style: GoogleFonts.lora(
                          fontSize: 13, color: EchoColors.amber)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      quote,
                      style: GoogleFonts.lora(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: EchoColors.textGhost,
                        height: 1.6,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text('"',
                      style: GoogleFonts.lora(
                          fontSize: 13, color: EchoColors.amber)),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '— something you said',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5, color: EchoColors.textVeryGhost),
              ),
            ],
          ] else
            Text(
              'Keep talking.\nEcho is forming your signal.',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: EchoColors.textGhost,
                height: 1.55,
              ),
            ),
          const SizedBox(height: 22),
          Container(height: 1, color: EchoColors.borderSubtle),
        ],
      ),
    );
  }

  // ─── TODAY'S REP ────────────────────────────────────────────────────────────

  Widget _buildPracticeSection() {
    final observation = _practice?['observation'] as String?;
    final repTitle = _practice?['rep_title'] as String?;
    final repInstruction = _practice?['rep_instruction'] as String?;
    final arcLabel = _practice?['arc_label'] as String?;
    final repId = _practice?['rep_id'] as String?;
    final logged = _loggedThisSession || (_practice?['logged'] as bool? ?? false);
    final done = _practice?['done'] as bool?;
    final weekCompletions = _practice?['week_completions'] as int? ?? 0;

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
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: EchoColors.amber),
                ),
                const SizedBox(width: 7),
                Text(
                  'TODAY\'S REP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: EchoColors.amber,
                  ),
                ),
                const Spacer(),
                if (arcLabel != null)
                  Text(
                    arcLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: EchoColors.textGhost,
                    ),
                  ),
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
                  Text(
                    'ECHO OBSERVED',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      letterSpacing: 0.8,
                      color: EchoColors.textGhost,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '"$observation"',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: EchoColors.textMuted,
                      height: 1.55,
                    ),
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
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: EchoColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  if (repInstruction != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      repInstruction,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.65,
                        color: EchoColors.textMuted,
                      ),
                    ),
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
                          decoration: BoxDecoration(
                            color: EchoColors.amber,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Center(
                            child: Text(
                              'Done today',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF060504),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _logPractice(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: EchoColors.border),
                        ),
                        child: Text(
                          'Not today',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: EchoColors.textGhost,
                          ),
                        ),
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
                        color: done == true
                            ? EchoColors.amber.withValues(alpha: 0.15)
                            : EchoColors.bgSurface,
                        border: Border.all(
                          color: done == true
                              ? EchoColors.amber
                              : EchoColors.border,
                        ),
                      ),
                      child: done == true
                          ? const Icon(Icons.check_rounded,
                              size: 12, color: EchoColors.amber)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      done == true ? 'Logged today' : 'Skipped today',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: EchoColors.textGhost,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _buildWeekDots(weekCompletions),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                'Keep chatting — Echo needs more conversations\nto generate your practice.',
                style: GoogleFonts.lora(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: EchoColors.textGhost,
                  height: 1.6,
                ),
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
        Text(
          '$completions of $total this week',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            color: EchoColors.textGhost,
          ),
        ),
      ],
    );
  }

  // ─── YOUR HIDDEN TALENT ─────────────────────────────────────────────────────

  Widget _buildTalentSection(BuildContext context) {
    final totalPairs = _signal?['total_pairs'] as int? ?? 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TalentScreen())),
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: EchoColors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalPairs > 40
                        ? '"Something keeps appearing across $totalPairs conversations.\nI want to name it."'
                        : 'Echo is still watching. Keep talking.',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: EchoColors.textPrimary,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What Echo found →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: EchoColors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.psychology_rounded,
                color: EchoColors.amber.withValues(alpha: 0.4), size: 28),
          ],
        ),
      ),
    );
  }

  // ─── ASK YOUR TWIN ──────────────────────────────────────────────────────────

  Widget _buildTwinSection(BuildContext context) {
    final totalPairs = _signal?['total_pairs'] as int? ?? 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TwinScreen())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.borderCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ASK YOUR TWIN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: EchoColors.indigo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EchoColors.indigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BETA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: EchoColors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalPairs > 0
                        ? 'Your shadow clone has trained on $totalPairs conversations.\nAsk both — see which one sounds more like you.'
                        : 'Keep chatting to train your shadow clone.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.6,
                      color: EchoColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ask something →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: EchoColors.indigoLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.people_outline_rounded,
                color: EchoColors.indigo.withValues(alpha: 0.4), size: 26),
          ],
        ),
      ),
    );
  }

  // ─── THE COUNCIL ────────────────────────────────────────────────────────────

  Widget _buildCouncilSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CouncilScreen())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.borderCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE COUNCIL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: EchoColors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Five distinct voices. Bring a decision.\nThey will disagree. That\'s the point.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: EchoColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.groups_outlined,
                color: EchoColors.amber.withValues(alpha: 0.4), size: 26),
          ],
        ),
      ),
    );
  }

  // ─── ECHO PRESENCE ──────────────────────────────────────────────────────────

  Widget _buildPresenceSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PresenceScreen())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.borderCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ECHO PRESENCE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: EchoColors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The 4-state view. Echo speaks when it has something to say.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: EchoColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.circle_outlined,
                color: EchoColors.amber.withValues(alpha: 0.4), size: 26),
          ],
        ),
      ),
    );
  }

  // ─── TWO PATHS ──────────────────────────────────────────────────────────────

  Widget _buildTwoPathsSection(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ParallelSelfScreen())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EchoColors.borderCard),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TWO PATHS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: EchoColors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Where your current patterns lead. And the path you keep avoiding.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: EchoColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.fork_right_outlined,
                color: EchoColors.indigo.withValues(alpha: 0.4), size: 26),
          ],
        ),
      ),
    );
  }

  // ─── GO DEEPER ──────────────────────────────────────────────────────────────

  Widget _buildGoDeeper(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 36),
      child: GestureDetector(
        onTap: () => _showMoreSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: EchoColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EchoColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Go deeper',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: EchoColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: EchoColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MORE SHEET ─────────────────────────────────────────────────────────────

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: EchoColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: EchoColors.textGhost,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _sheetRow(ctx, 'Memory Vault', Icons.grain_rounded,
                  EchoColors.indigo,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MemoriesScreen()))),
              _sheetRow(ctx, 'Your Rules', Icons.tonality_rounded,
                  const Color(0xFF9A6AB4),
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const OperatingSystemScreen()))),
              _sheetRow(ctx, 'Training Detail', Icons.model_training_rounded,
                  EchoColors.amber,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const NightlyTrainingScreen()))),
              _sheetRow(ctx, 'Evening Signal', Icons.nights_stay_rounded,
                  const Color(0xFF7A8A9A),
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const DailyCheckinScreen()))),
              _sheetRow(ctx, 'Patterns', Icons.auto_awesome_rounded,
                  EchoColors.amber,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EmergenceScreen()))),
              _sheetRow(ctx, 'Experiment', Icons.science_outlined,
                  const Color(0xFF6A9A7A),
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ExperimentProposalScreen(
                            experiment: const EchoExperiment(
                              number: 1,
                              trigger: 'Echo noticed a pattern worth exploring.',
                              hypothesis:
                                  'A small change in behavior reveals something true about you.',
                              title: 'Speak without hedging. Just once a day.',
                              body:
                                  'Once a day — say your point without hedging. Just once.',
                              followup: "I'll check in.",
                            ),
                            onAccept: () => Navigator.of(context).pop(),
                            onSkip: () => Navigator.of(context).pop(),
                          )))),
              _sheetRow(ctx, 'Permanent Record', Icons.history_edu_rounded,
                  EchoColors.indigo,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PermanentRecordScreen()))),
              _sheetRow(ctx, 'Meetings', Icons.groups_outlined,
                  const Color(0xFF7A5A30),
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AfterMeetingScreen()))),
              _sheetRow(ctx, 'Journey', Icons.celebration_outlined,
                  EchoColors.amber,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AnniversaryScreen()))),
              _sheetRow(ctx, 'Connections', Icons.link_rounded,
                  EchoColors.textMuted,
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ConnectionsPage()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetRow(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.75)),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: EchoColors.textMuted,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 14, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }
}
