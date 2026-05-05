import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/page/echo_tabs/ask_screen.dart';
import 'package:chatmcp/page/echo_tabs/daily_checkin_screen.dart';
import 'package:chatmcp/page/echo_tabs/mirror_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/revelation_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

enum _TodayState { silence, checking, morningCheckin, interruption, council, revelation }

class _TodayScreenState extends State<TodayScreen> with TickerProviderStateMixin {
  _TodayState _state = _TodayState.checking;

  // Content fields
  String? _statement;
  String? _letter;

  // Thread fields — populated from /v1/echo/decide
  String? _threadId;
  String? _threadName;
  int _threadDay = 0;
  int _escalationLevel = 0;
  String? _threadContext;

  // Digest fields — shown in silence state
  Map<String, dynamic>? _signal;
  Map<String, dynamic>? _practice;
  Map<String, dynamic>? _priority;
  Map<String, dynamic>? _mission;

  // XP pill
  String? _xpMessage;
  late final AnimationController _xpFade;

  late final AnimationController _orbPulse;
  late final AnimationController _contentFade;

  @override
  void initState() {
    super.initState();
    _orbPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);

    _contentFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _xpFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    EchoLoopState().addListener(_onLoopStateChanged);
    _checkState();
  }

  void _onLoopStateChanged() {
    if (!mounted) return;
    final loop = EchoLoopState();
    setState(() {
      _priority = loop.todayPriority ?? _priority;
      _practice = loop.practice ?? _practice;
      _mission = loop.mission ?? _mission;
    });
  }

  void _showXp(String message) {
    if (!mounted) return;
    setState(() => _xpMessage = message);
    _xpFade.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _xpFade.reverse().then((_) {
        if (mounted) setState(() => _xpMessage = null);
      });
    });
  }

  @override
  void dispose() {
    EchoLoopState().removeListener(_onLoopStateChanged);
    _xpFade.dispose();
    _orbPulse.dispose();
    _contentFade.dispose();
    super.dispose();
  }

  Future<void> _checkState() async {
    setState(() => _state = _TodayState.checking);

    final results = await Future.wait([
      EchoApiClient().decideState(),
      EchoApiClient().getCheckinStatus(),
      EchoApiClient().getUserSignal(),
      EchoApiClient().getPracticeToday(),
      EchoApiClient().getTodayMission(),
      EchoApiClient().getTodayPriority(),
    ]);
    if (!mounted) return;

    final decision = results[0] as Map<String, dynamic>?;
    final checkinDone = results[1] as bool;
    _signal = results[2] as Map<String, dynamic>?;
    _practice = results[3] as Map<String, dynamic>?;
    _mission = results[4] as Map<String, dynamic>?;
    _priority = results[5] as Map<String, dynamic>?;
    EchoLoopState().apply(todayPriority: _priority, mission: _mission);
    if (!mounted) return;

    // Morning check-in gate: before 14:00 local time and not done today
    if (!checkinDone && DateTime.now().hour < 14) {
      setState(() => _state = _TodayState.morningCheckin);
      _contentFade.forward();
      return;
    }

    final echoState = decision?['state'] as String? ?? 'silence';
    final speakNow = decision?['speak_now'] as bool? ?? false;

    // Always capture thread metadata when present
    final threadId = decision?['thread_id'] as String?;
    final threadName = decision?['thread_name'] as String?;
    final threadDay = (decision?['thread_day'] as num?)?.toInt() ?? 0;
    final escalationLevel = (decision?['escalation_level'] as num?)?.toInt() ?? 0;
    final threadContext = decision?['thread_context'] as String?;

    if (!speakNow || echoState == 'silence') {
      setState(() {
        _state = _TodayState.silence;
        _threadId = threadId;
        _threadName = threadName;
        _threadDay = threadDay;
        _escalationLevel = escalationLevel;
      });
      _contentFade.forward();
      return;
    }

    switch (echoState) {
      case 'interruption':
        setState(() {
          _statement = decision?['statement'] as String?;
          _threadId = threadId;
          _threadName = threadName;
          _threadDay = threadDay;
          _escalationLevel = escalationLevel;
          _state = _TodayState.interruption;
        });
        break;
      case 'revelation':
        setState(() {
          _letter = decision?['letter'] as String?;
          _threadId = threadId;
          _threadName = threadName;
          _threadDay = threadDay;
          _escalationLevel = escalationLevel;
          _state = _TodayState.revelation;
        });
        break;
      case 'council':
        setState(() {
          _threadId = threadId;
          _threadName = threadName;
          _threadDay = threadDay;
          _escalationLevel = escalationLevel;
          _threadContext = threadContext;
          _state = _TodayState.council;
        });
        break;
      default:
        setState(() => _state = _TodayState.silence);
    }
    _contentFade.forward();
  }

  // Orb glow params per escalation level
  ({double base, double pulse, double blur}) _orbParams() {
    switch (_escalationLevel) {
      case 5:
        return (base: 0.38, pulse: 0.24, blur: 80);
      case 4:
        return (base: 0.28, pulse: 0.20, blur: 70);
      case 3:
        return (base: 0.18, pulse: 0.15, blur: 60);
      case 2:
        return (base: 0.10, pulse: 0.08, blur: 55);
      case 1:
        return (base: 0.05, pulse: 0.05, blur: 50);
      default:
        return (base: 0.04, pulse: 0.04, blur: 45);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAsk = _state == _TodayState.silence || _state == _TodayState.interruption;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Orb zone — fixed at ~42% of screen height
                    SizedBox(
                      height: screenHeight * 0.42,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildOrbBackground()),
                          // Refresh — top right corner
                          Positioned(
                            top: 12,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                _contentFade.value = 0;
                                _checkState();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
                                child: Icon(Icons.refresh_rounded, size: 14, color: Colors.white.withValues(alpha: 0.22)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content zone — fills remaining space
                    Expanded(
                      child: AnimatedSwitcher(duration: const Duration(milliseconds: 500), child: _buildStateContent()),
                    ),
                    // Ask pill — pinned at bottom, only in silence/interruption
                    if (showAsk)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 28, top: 8),
                        child: Center(child: _buildAskPill()),
                      ),
                  ],
                ),
                // XP feedback pill — floats at top center
                if (_xpMessage != null)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FadeTransition(
                        opacity: _xpFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EchoColors.amber.withValues(alpha: 0.40)),
                          ),
                          child: Text(
                            _xpMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: EchoColors.amberLight,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrbBackground() {
    return AnimatedBuilder(
      animation: _orbPulse,
      builder: (context, child) {
        final t = _orbPulse.value;
        final p = _orbParams();

        return Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow — intensity from escalation level
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: p.base + t * p.pulse),
                        blurRadius: p.blur + t * 30,
                        spreadRadius: t * (_escalationLevel >= 3 ? 12 : 6),
                      ),
                    ],
                  ),
                ),
                // Mid ring — visible at level 2+
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: (_escalationLevel >= 2 ? 0.04 : 0.02) + t * 0.03),
                    border: Border.all(color: EchoColors.amber.withValues(alpha: (_escalationLevel >= 2 ? 0.14 : 0.06) + t * 0.10), width: 1.0),
                  ),
                ),
                // Second ring at level 4+
                if (_escalationLevel >= 4)
                  Container(
                    width: 155,
                    height: 155,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: EchoColors.amber.withValues(alpha: 0.06 + t * 0.08), width: 0.5),
                    ),
                  ),
                // Core
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: (_escalationLevel >= 3 ? 0.10 : 0.06) + t * 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: p.base + t * p.pulse),
                        blurRadius: 20 + t * 12,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // "Day N" thread label — shows when thread is day 2+
  Widget _buildThreadLabel() {
    if (_threadDay < 2 || _threadName == null) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          'Day $_threadDay',
          style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.45), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case _TodayState.checking:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.2, color: EchoColors.amber.withValues(alpha: 0.30))),
              const SizedBox(height: 12),
              Text(
                'echo is reading',
                style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.12), fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w300),
              ),
            ],
          ),
        );

      case _TodayState.morningCheckin:
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('morningCheckin'),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Good morning.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Echo is listening.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const DailyCheckinScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                          transitionDuration: const Duration(milliseconds: 500),
                          fullscreenDialog: true,
                        ),
                      );
                      if (mounted) {
                        _showXp('+10 XP - Check-in complete');
                        _contentFade.value = 0;
                        _checkState();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: EchoColors.amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        'Begin',
                        style: GoogleFonts.plusJakartaSans(color: EchoColors.amber, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case _TodayState.silence:
        final hasThread = _escalationLevel >= 1 && _threadName != null;
        final signal = _signal?['signal'] as String?;
        final practiceTitle = _practice?['rep_title'] as String?;
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('silence'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Signal quote — what Echo sees as your core nature
                if (signal != null) ...[
                  Text(
                    '"$signal"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.62),
                      height: 1.65,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('— what echo sees', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.16), fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                ] else ...[
                  Text(
                    hasThread ? 'Still watching.' : 'Nothing yet.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.18), fontSize: 13, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 30),
                ],

                // Active thread — compact row
                if (hasThread)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AskScreen(threadId: _threadId)));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.14)),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: EchoColors.amber.withValues(alpha: 0.50)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _threadName!,
                              style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.42), fontSize: 12.5, fontWeight: FontWeight.w300),
                            ),
                          ),
                          Text(
                            _threadDay >= 2 ? 'Day $_threadDay' : 'lv $_escalationLevel',
                            style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.28), fontSize: 10, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (hasThread) const SizedBox(height: 10),

                if (_mission != null) _buildDailyMissionCard(_mission!),

                if (_priority != null && _mission == null) _buildPriorityCard(_priority!),

                // Practice hint — compact, low-key
                if (practiceTitle != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.015),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "TODAY'S REP",
                          style: GoogleFonts.plusJakartaSans(
                            color: EchoColors.amber.withValues(alpha: 0.35),
                            fontSize: 8.5,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            practiceTitle,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.32), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!hasThread && signal == null) ...[
                  const SizedBox(height: 8),
                  Text('Keep talking.', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.10), fontSize: 12, letterSpacing: 0.3)),
                ],
              ],
            ),
          ),
        );

      case _TodayState.interruption:
        final statement = _statement ?? '';
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('interruption'),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThreadLabel(),
                  Text(
                    statement,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontSize: 21,
                      fontWeight: FontWeight.w300,
                      height: 1.55,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildInterruptionActions(),
                ],
              ),
            ),
          ),
        );

      case _TodayState.revelation:
        final letter = _letter ?? '';
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('revelation'),
          child: GestureDetector(
            onTap: () async {
              if (letter.isNotEmpty) {
                await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => RevelationScreen(letter: letter, threadId: _threadId),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 700),
                    fullscreenDialog: true,
                  ),
                );
                if (mounted) _showXp('+30 XP - Insight received');
              }
            },
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThreadLabel(),
                    Text(
                      'R E V E L A T I O N',
                      style: GoogleFonts.plusJakartaSans(
                        color: EchoColors.amber.withValues(alpha: 0.40),
                        fontSize: 10,
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Echo has something to tell you.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.65), fontSize: 16, fontWeight: FontWeight.w300, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text('Tap to read', style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.45), fontSize: 12, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        );

      case _TodayState.council:
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('council'),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThreadLabel(),
                  Text(
                    _threadContext != null ? 'Echo called the council.' : 'The council is ready.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.70), fontSize: 18, fontWeight: FontWeight.w300, height: 1.5),
                  ),
                  if (_threadContext != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _threadContext!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.35), fontSize: 12, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AskScreen(threadId: _threadId, threadContext: _threadContext),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: EchoColors.amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.30)),
                      ),
                      child: Text(
                        _threadContext != null ? 'Open perspectives' : 'Bring your question',
                        style: GoogleFonts.plusJakartaSans(color: EchoColors.amber, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Future<void> _handlePriorityAction(Map<String, dynamic> priority) async {
    final action = Map<String, dynamic>.from(priority['action'] as Map? ?? {});
    final payload = Map<String, dynamic>.from(action['payload'] as Map? ?? {});
    final type = action['type'] as String? ?? 'none';
    HapticFeedback.lightImpact();

    switch (type) {
      case 'daily_checkin':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen()));
        if (mounted) _showXp('+10 XP - Check-in complete');
        break;
      case 'run_tournament':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShadowTournamentScreen(initialPrompt: payload['prompt'] as String?)));
        await EchoLoopState().refresh();
        if (mounted) _showXp('+15 XP - Perspectives saved');
        break;
      case 'open_council':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AskScreen(threadId: payload['thread_id'] as String?, threadContext: payload['thread_context'] as String?),
          ),
        );
        break;
      case 'log_practice':
        final repId = payload['rep_id'] as String?;
        if (repId != null) {
          await EchoApiClient().logPractice(repId, true);
          await EchoLoopState().refresh();
          if (mounted) _showXp('+20 XP - Rep complete');
        }
        break;
      case 'open_training':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NightlyTrainingScreen()));
        break;
      case 'open_mirror':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MirrorScreen()));
        break;
      default:
        await _recordPriorityOutcome(priority, 'acknowledged', 0.5);
        return;
    }

    if (mounted) {
      _contentFade.value = 0;
      _checkState();
    }
  }

  Future<void> _recordPriorityOutcome(Map<String, dynamic> priority, String outcome, double score) async {
    HapticFeedback.selectionClick();
    final subjectType = (priority['subject_type'] as String?) ?? (priority['kind'] as String?) ?? 'today_priority';
    await EchoApiClient().recordOutcome(
      subjectType: subjectType,
      subjectId: priority['subject_id'] as String?,
      outcome: outcome,
      score: score,
      note: 'Feedback from Today priority card',
    );
    await EchoLoopState().refresh();
    if (mounted) {
      _showXp(outcome == 'not_true' ? 'Correction saved. Echo will adjust.' : 'Signal saved. Echo updated the loop.');
      _contentFade.value = 0;
      _checkState();
    }
  }

  Widget _buildDailyMissionCard(Map<String, dynamic> mission) {
    final headline = mission['headline'] as String? ?? 'Echo has one mission today.';
    final why = mission['why'] as String? ?? '';
    final priority = mission['priority'] is Map ? Map<String, dynamic>.from(mission['priority'] as Map) : <String, dynamic>{};
    final perspectiveMission = mission['clone_mission'] is Map ? Map<String, dynamic>.from(mission['clone_mission'] as Map) : null;
    final reality = mission['reality_check'] is Map ? Map<String, dynamic>.from(mission['reality_check'] as Map) : null;
    final growth = mission['growth'] is Map ? Map<String, dynamic>.from(mission['growth'] as Map) : null;
    final action = Map<String, dynamic>.from(priority['action'] as Map? ?? {});
    final actionType = action['type'] as String? ?? 'none';
    final actionLabel = _cleanActionLabel(action['label'] as String? ?? 'Start');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.022),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 15, color: EchoColors.amber.withValues(alpha: 0.58)),
              const SizedBox(width: 8),
              Text(
                'DAILY MISSION',
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.amber.withValues(alpha: 0.42),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            headline,
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.72), fontSize: 16, fontWeight: FontWeight.w500, height: 1.35),
          ),
          if (why.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(why, style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.36), fontSize: 12.5, height: 1.45)),
          ],
          if (perspectiveMission != null) ...[
            const SizedBox(height: 12),
            _missionLine(Icons.psychology_alt_outlined, 'Perspective ready', perspectiveMission['suggested_action'] as String? ?? 'A decision prompt is ready.'),
          ],
          if (reality != null) ...[
            const SizedBox(height: 8),
            _missionLine(Icons.fact_check_outlined, 'Reality check', reality['title'] as String? ?? 'Echo is comparing words and behavior.'),
          ],
          if (growth != null) ...[
            const SizedBox(height: 8),
            _missionLine(Icons.timeline_outlined, 'Proof', growth['headline'] as String? ?? 'Growth proof is forming.'),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (actionType != 'none')
                GestureDetector(
                  onTap: () => _handlePriorityAction(priority),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                    decoration: BoxDecoration(
                      color: EchoColors.amber.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EchoColors.amber.withValues(alpha: 0.24)),
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.78), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const Spacer(),
              if (priority.isNotEmpty) ...[
                _miniOutcome(priority, 'helped', 'Helpful', 1.0),
                const SizedBox(width: 8),
                _miniOutcome(priority, 'not_true', 'Not true', -0.5),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionLine(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.22)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.30), fontSize: 11.5, height: 1.35),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: EchoColors.amber.withValues(alpha: 0.42)),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityCard(Map<String, dynamic> priority) {
    final title = priority['title'] as String? ?? 'Echo has a next step.';
    final body = priority['body'] as String? ?? '';
    final kind = priority['kind'] as String? ?? 'signal';
    final evidence = (priority['evidence_count'] as num?)?.toInt() ?? 0;
    final confidence = priority['confidence'] as String? ?? 'emerging';
    final action = Map<String, dynamic>.from(priority['action'] as Map? ?? {});
    final actionLabel = _cleanActionLabel(action['label'] as String? ?? 'Open');
    final actionType = action['type'] as String? ?? 'none';
    IconData icon = Icons.auto_awesome_motion_rounded;
    if (kind == 'practice') {
      icon = Icons.bolt_rounded;
    } else if (kind == 'training_ready') {
      icon = Icons.model_training_rounded;
    } else if (kind == 'tournament' || kind == 'thread_tournament' || kind == 'tournament_result') {
      icon = Icons.psychology_alt_rounded;
    } else if (kind == 'council') {
      icon = Icons.forum_rounded;
    } else if (kind == 'mirror') {
      icon = Icons.auto_stories_rounded;
    } else if (kind == 'thesis_test') {
      icon = Icons.psychology_alt_rounded;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.018),
        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: EchoColors.amber.withValues(alpha: 0.52)),
              const SizedBox(width: 8),
              Text(
                confidence.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.amber.withValues(alpha: 0.38),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (evidence > 0) Text('$evidence signals', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.18), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.68), fontSize: 15, fontWeight: FontWeight.w500, height: 1.35),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(body, style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.34), fontSize: 12, height: 1.45)),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              if (actionType != 'none')
                GestureDetector(
                  onTap: () => _handlePriorityAction(priority),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: EchoColors.amber.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EchoColors.amber.withValues(alpha: 0.22)),
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.74), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const Spacer(),
              _miniOutcome(priority, 'helped', 'Helpful', 1.0),
              const SizedBox(width: 8),
              _miniOutcome(priority, 'not_true', 'Not true', -0.5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniOutcome(Map<String, dynamic> priority, String outcome, String label, double score) {
    return GestureDetector(
      onTap: () => _recordPriorityOutcome(priority, outcome, score),
      child: Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.24), fontSize: 11)),
    );
  }

  String _cleanActionLabel(String label) {
    return label
        .replaceAll('Send clones', 'Run perspectives')
        .replaceAll('send clones', 'run perspectives')
        .replaceAll('Open council', 'Open perspectives')
        .replaceAll('Enter council', 'Open perspectives')
        .replaceAll('Run tournament', 'Run perspectives')
        .replaceAll('run tournament', 'run perspectives')
        .replaceAll('clone', 'model')
        .replaceAll('Clone', 'Model');
  }

  Widget _buildInterruptionActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _state = _TodayState.silence);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text('I need to think about this', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.80), fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _state = _TodayState.silence);
          },
          child: Text('Dismiss', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.25), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildAskPill() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AskScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Text('Ask Echo', style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.40), fontSize: 13, letterSpacing: 0.3)),
      ),
    );
  }
}
