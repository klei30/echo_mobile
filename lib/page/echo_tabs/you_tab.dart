import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
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

class YouTab extends StatefulWidget {
  const YouTab({super.key});

  @override
  State<YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<YouTab> {
  Map<String, dynamic>? _signal;
  Map<String, dynamic>? _practice;
  Map<String, dynamic>? _quote;
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
    ]);
    if (!mounted) return;
    setState(() {
      _signal = results[0];
      _practice = results[1];
      _quote = results[2];
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
              // ─── USER HEADER ──────────────────────────────────────────
              _buildUserHeader(),
              // ─── YOUR SIGNAL ──────────────────────────────────────────
              _buildSignalSection(),
              // ─── TODAY — The Practice ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildPracticeSection(),
              ),
              // ─── YOUR HIDDEN TALENT ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildTalentSection(context),
              ),
              // ─── ASK YOUR TWIN ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _buildTwinSection(context),
              ),
              // ─── DEPTHS ───────────────────────────────────────────────
              _buildDepthsSection(context),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ─── USER HEADER ───────────────────────────────────────────────────────────

  Widget _buildUserHeader() {
    final username = AuthService().username ?? 'You';
    final firstName = username.split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'Y';
    final totalPairs = _signal?['total_pairs'] as int? ?? 0;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB86A28), Color(0xFFE8AE60)],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF060504),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName.',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: EchoColors.textPrimary,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  totalPairs > 0
                      ? '$totalPairs conversations with Echo'
                      : 'Start talking to build your shadow clone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: EchoColors.textGhost,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── YOUR SIGNAL ───────────────────────────────────────────────────────────

  Widget _buildSignalSection() {
    final signal = _signal?['signal'] as String?;
    final totalPairs = _signal?['total_pairs'] as int? ?? 0;
    final weeks = _signal?['weeks'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                weeks > 0 ? 'WEEK $weeks' : 'ECHO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: EchoColors.amber,
                ),
              ),
              if (totalPairs > 0) ...[
                const SizedBox(width: 8),
                Container(width: 3, height: 3,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: EchoColors.textGhost)),
                const SizedBox(width: 8),
                Text(
                  '$totalPairs conversations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5, letterSpacing: 0.5, color: EchoColors.textGhost,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            Container(
              height: 26,
              width: 220,
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else if (signal != null)
            Text(
              '"$signal"',
              style: GoogleFonts.lora(
                fontSize: 19, fontStyle: FontStyle.italic,
                color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3,
              ),
            )
          else
            Text(
              'Keep talking — Echo is forming your signal.',
              style: GoogleFonts.lora(
                fontSize: 16, fontStyle: FontStyle.italic,
                color: EchoColors.textGhost, height: 1.5,
              ),
            ),
          // Notable quote
          if (!_loading && _quote?['quote'] != null) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('"', style: GoogleFonts.lora(
                    fontSize: 14, color: EchoColors.amber)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _quote!['quote'] as String,
                    style: GoogleFonts.lora(
                      fontSize: 12.5, fontStyle: FontStyle.italic,
                      color: EchoColors.textGhost, height: 1.6,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text('"', style: GoogleFonts.lora(
                    fontSize: 14, color: EchoColors.amber)),
              ],
            ),
            Text(
              '— something you said',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5, color: EchoColors.textVeryGhost,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: EchoColors.borderSubtle),
        ],
      ),
    );
  }

  // ─── TODAY — The Practice ──────────────────────────────────────────────────

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
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: EchoColors.amber),
                ),
                const SizedBox(width: 7),
                Text(
                  'TODAY\'S REP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.1, color: EchoColors.amber,
                  ),
                ),
                const Spacer(),
                if (arcLabel != null)
                  Text(
                    arcLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5, color: EchoColors.textGhost,
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
                  Container(height: 14, width: 200,
                      color: EchoColors.bgSurface),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 160, color: EchoColors.bgSurface),
                ],
              ),
            )
          else if (observation != null) ...[
            // Echo observed
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ECHO OBSERVED',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, letterSpacing: 0.8,
                      color: EchoColors.textGhost,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '"$observation"',
                    style: GoogleFonts.lora(
                      fontSize: 14, fontStyle: FontStyle.italic,
                      color: EchoColors.textMuted, height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.borderSubtle),
            const SizedBox(height: 14),

            // Rep title + instruction
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repTitle != null)
                    Text(
                      repTitle,
                      style: GoogleFonts.lora(
                        fontSize: 18, fontStyle: FontStyle.italic,
                        color: EchoColors.textPrimary, letterSpacing: -0.2,
                      ),
                    ),
                  if (repInstruction != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      repInstruction,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, height: 1.65,
                        color: EchoColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons (if not yet logged)
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
                                fontSize: 13.5, fontWeight: FontWeight.w600,
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
                            fontSize: 13.5, color: EchoColors.textGhost,
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
                      width: 22, height: 22,
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
                        fontSize: 12.5, color: EchoColors.textGhost,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Week tracker
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
                  fontSize: 13, fontStyle: FontStyle.italic,
                  color: EchoColors.textGhost, height: 1.6,
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
    final weekday = DateTime.now().weekday; // 1=Mon, 7=Sun
    final daysPassed = weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (i) {
            final filled = i < completions;
            final isToday = i == daysPassed - 1;
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
            fontSize: 10.5, color: EchoColors.textGhost,
          ),
        ),
      ],
    );
  }

  // ─── YOUR HIDDEN TALENT ────────────────────────────────────────────────────

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
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.1, color: EchoColors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalPairs > 40
                        ? '"Something keeps appearing across $totalPairs conversations.\nI want to name it."'
                        : 'Echo is still watching. Keep talking.',
                    style: GoogleFonts.lora(
                      fontSize: 14, fontStyle: FontStyle.italic,
                      color: EchoColors.textPrimary, height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What Echo found →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w500,
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

  // ─── ASK YOUR TWIN ─────────────────────────────────────────────────────────

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
                          fontSize: 9.5, fontWeight: FontWeight.w700,
                          letterSpacing: 1.1, color: EchoColors.indigo,
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
                            fontSize: 8, fontWeight: FontWeight.w700,
                            letterSpacing: 0.8, color: EchoColors.indigo,
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
                      fontSize: 13, height: 1.6, color: EchoColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ask something →',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w500,
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

  // ─── DEPTHS ────────────────────────────────────────────────────────────────

  Widget _buildDepthsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXPLORE DEEPER',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: EchoColors.textGhost,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              _depthTile(context, 'Evening Signal', Icons.nights_stay_rounded,
                  EchoColors.amber, () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DailyCheckinScreen()),
                  )),
              _depthTile(context, 'Memories', Icons.memory_rounded,
                  EchoColors.indigo, () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MemoriesScreen()),
                  )),
              _depthTile(context, 'Rules', Icons.rule_rounded,
                  const Color(0xFF9A6AB4), () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OperatingSystemScreen()),
                  )),
              _depthTile(context, 'Patterns', Icons.auto_awesome_rounded,
                  EchoColors.amber, () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergenceScreen()),
                  )),
              _depthTile(context, 'Training', Icons.model_training_rounded,
                  EchoColors.indigo, () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NightlyTrainingScreen()),
                  )),
              _depthTile(context, 'Experiment', Icons.science_outlined,
                  const Color(0xFF6A9A7A), () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ExperimentProposalScreen(
                      experiment: const EchoExperiment(
                        number: 1,
                        trigger: 'Echo noticed a pattern worth exploring.',
                        hypothesis: 'A small change in behavior reveals something true about you.',
                        title: 'Speak without hedging. Just once a day.',
                        body: 'Once a day — say your point without hedging. Just once.',
                        followup: "I'll check in.",
                      ),
                      onAccept: () => Navigator.of(context).pop(),
                      onSkip: () => Navigator.of(context).pop(),
                    )),
                  )),
              _depthTile(context, 'Permanent\nRecord', Icons.history_edu_rounded,
                  EchoColors.amber, () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PermanentRecordScreen()),
                  )),
              _depthTile(context, 'Meetings', Icons.groups_outlined,
                  const Color(0xFF7A5A30), () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AfterMeetingScreen()),
                  )),
              _depthTile(context, 'Journey', Icons.celebration_outlined,
                  EchoColors.amber, () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnniversaryScreen()),
                  )),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectionsPage())),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EchoColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 14, color: EchoColors.textGhost),
                  const SizedBox(width: 8),
                  Text(
                    'Connections',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5, color: EchoColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Not connected',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: EchoColors.textGhost,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: EchoColors.textGhost),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _depthTile(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5, color: EchoColors.textMuted,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
