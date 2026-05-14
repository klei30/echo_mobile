import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_design_system.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/page/echo_tabs/ask_screen.dart';
import 'package:chatmcp/page/echo_tabs/daily_checkin_screen.dart';
import 'package:chatmcp/page/echo_tabs/mirror_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/opportunities_screen.dart';
import 'package:chatmcp/page/echo_tabs/outcome_capture_sheet.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';
import 'package:chatmcp/page/echo_tabs/revelation_screen.dart';
import 'package:chatmcp/page/echo_tabs/shadow_tournament_screen.dart';
import 'package:chatmcp/page/echo_mobile.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

enum _TodayState { silence, checking, morningCheckin, interruption, council, discovery, comeback }

class _TodayScreenState extends State<TodayScreen> with TickerProviderStateMixin {
  _TodayState _state = _TodayState.checking;

  // Content fields
  String? _statement;
  String? _letter;

  // Thread fields â€” populated from /v1/echo/decide
  String? _threadId;
  String? _threadName;
  int _threadDay = 0;
  int _escalationLevel = 0;
  String? _threadContext;

  // Digest fields â€” shown in silence state
  Map<String, dynamic>? _signal;
  Map<String, dynamic>? _practice;
  Map<String, dynamic>? _priority;
  Map<String, dynamic>? _mission;

  // Cold-start stage from backend
  Map<String, dynamic>? _onboardingState;

  late final AnimationController _orbPulse;
  late final AnimationController _contentFade;

  @override
  void initState() {
    super.initState();
    _orbPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))..repeat(reverse: true);

    _contentFade = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

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

  void _showLoopToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: EchoColors.bgSurface,
          content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted)),
        ),
      );
  }

  @override
  void dispose() {
    EchoLoopState().removeListener(_onLoopStateChanged);
    _orbPulse.dispose();
    _contentFade.dispose();
    super.dispose();
  }

  Future<void> _checkState() async {
    setState(() => _state = _TodayState.checking);

    if (EchoRuntimeService().isDevice) {
      final loop = EchoLoopState();
      if (!mounted) return;
      setState(() {
        _priority = loop.todayPriority ?? _priority;
        _practice = loop.practice ?? _practice;
        _mission = loop.mission ?? _mission;
        _state = _TodayState.silence;
      });
      _contentFade.forward();
      return;
    }

    final results = await Future.wait([
      EchoApiClient().decideState(),
      EchoApiClient().getCheckinStatus(),
      EchoApiClient().getUserSignal(),
      EchoApiClient().getPracticeToday(),
      EchoApiClient().getTodayMission(),
      EchoApiClient().getTodayPriority(),
      EchoApiClient().getOnboardingState(),
    ]);
    if (!mounted) return;

    final decision = results[0] as Map<String, dynamic>?;
    final checkinDone = results[1] as bool;
    _signal = results[2] as Map<String, dynamic>?;
    _practice = results[3] as Map<String, dynamic>?;
    _mission = results[4] as Map<String, dynamic>?;
    _priority = results[5] as Map<String, dynamic>?;
    _onboardingState = results[6] as Map<String, dynamic>?;
    EchoLoopState().apply(todayPriority: _priority, mission: _mission);
    if (!mounted) return;

    // Comeback gate: user has been away 5+ days
    final daysAway = (_onboardingState?['days_away'] as num?)?.toInt() ?? 0;
    if (daysAway >= 5) {
      setState(() => _state = _TodayState.comeback);
      _contentFade.forward();
      return;
    }

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
          _state = _TodayState.discovery;
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
    final showAsk = _state == _TodayState.silence || _state == _TodayState.interruption || _state == _TodayState.comeback;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Runtime status pill (Fix #11)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Align(alignment: Alignment.centerLeft, child: EchoRuntimePill()),
                    ),
                    // Orb zone â€” fixed at ~42% of screen height
                    SizedBox(
                      height: screenHeight * 0.42,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _buildOrbBackground()),
                          // Refresh â€” top right corner
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
                                decoration: BoxDecoration(shape: BoxShape.circle, color: EchoColors.bgSurface),
                                child: Icon(Icons.refresh_rounded, size: 14, color: EchoColors.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content zone â€” fills remaining space
                    Expanded(
                      child: AnimatedSwitcher(duration: const Duration(milliseconds: 500), child: _buildStateContent()),
                    ),
                    // Ask pill â€” pinned at bottom, only in silence/interruption
                    if (showAsk)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 8),
                        child: Center(child: _buildAskPill()),
                      ),
                    if (showAsk)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Center(child: _buildStuckButton()),
                      ),
                  ],
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
                // Outer glow â€” intensity from escalation level
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
                // Mid ring â€” visible at level 2+
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

  // "Day N" thread label â€” shows when thread is day 2+
  Widget _buildThreadLabel() {
    if (_threadDay < 2 || _threadName == null) return const SizedBox.shrink();
    return Column(
      children: [
        Text(
          'Day $_threadDay',
          style: GoogleFonts.plusJakartaSans(
            color: EchoColors.amber.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
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
                'building today\'s step',
                style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w300),
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
                    'Today',
                    style: GoogleFonts.plusJakartaSans(
                      color: EchoColors.textSecondary,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Echo has one useful step for you.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: EchoColors.textPrimary,
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
                        _showLoopToast('Check-in saved. Echo updated Today.');
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
        final signal = _cleanEchoCopy(_signal?['signal'] as String?);
        final practiceTitle = _practice?['rep_title'] as String?;
        final practiceBody = _practice?['rep_body'] as String? ?? _practice?['description'] as String?;
        final practiceId = _practice?['rep_id'] as String?;
        final stage = _onboardingState?['stage'] as String? ?? 'active';
        final daysActive = (_onboardingState?['days_active'] as num?)?.toInt() ?? 0;
        final coldStart = stage != 'active' || (!hasThread && signal == null && _mission == null && _priority == null && practiceTitle == null);
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('silence'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!coldStart && daysActive > 1) ...[_buildStreakPill(daysActive), const SizedBox(height: 16)],
                if (coldStart) ...[
                  _buildColdStartCard(),
                  const SizedBox(height: 18),
                ] else if (signal != null) ...[
                  Text(
                    '"$signal"',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: EchoColors.textPrimary,
                      height: 1.65,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('- current pattern', style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(height: 30),
                ] else ...[
                  Text(
                    hasThread ? 'A decision is forming.' : 'Ready when you are.',
                    style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 13, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 30),
                ],

                // Active thread â€” compact row
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
                        color: EchoColors.bgSurface,
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
                              style: GoogleFonts.plusJakartaSans(color: EchoColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w300),
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

                // Practice card
                if (practiceTitle != null)
                  GestureDetector(
                    onTap: () => _openPracticeOutcome(practiceId, practiceTitle),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: EchoColors.bgSurface,
                        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "TODAY'S REP",
                                style: GoogleFonts.plusJakartaSans(
                                  color: EchoColors.amber.withValues(alpha: 0.45),
                                  fontSize: 8.5,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Log outcome',
                                style: GoogleFonts.plusJakartaSans(
                                  color: EchoColors.amber.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            practiceTitle,
                            style: GoogleFonts.plusJakartaSans(
                              color: EchoColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          if (practiceBody != null && practiceBody.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              practiceBody,
                              style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12, height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                if (!hasThread && signal == null) ...[
                  const SizedBox(height: 8),
                  if (!coldStart)
                    Text('Keep talking.', style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 12, letterSpacing: 0.3)),
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
                      color: EchoColors.textPrimary,
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

      case _TodayState.discovery:
        final letter = _letter ?? '';
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('discovery'),
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
                if (mounted) _showLoopToast('Discovery saved. Echo updated Today.');
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
                      'D I S C O V E R Y',
                      style: GoogleFonts.plusJakartaSans(
                        color: EchoColors.amber.withValues(alpha: 0.40),
                        fontSize: 10,
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Echo found something worth checking.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: EchoColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w300, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to read',
                      style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.45), fontSize: 12, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case _TodayState.comeback:
        return _buildComebackContent();

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
                    _threadContext != null ? 'Echo opened perspectives.' : 'Perspectives are ready.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w300, height: 1.5),
                  ),
                  if (_threadContext != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _threadContext!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12, height: 1.5),
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

  Widget _buildColdStartCard() {
    final stage = _onboardingState?['stage'] as String? ?? 'early';
    final daysActive = (_onboardingState?['days_active'] as num?)?.toInt() ?? 0;
    final trainingPairs = (_onboardingState?['counts']?['training_pairs'] as num?)?.toInt() ?? 0;

    String tagLabel;
    String headline;
    String body;
    Color tagColor;

    switch (stage) {
      case 'day0':
        tagLabel = 'Day 1 - welcome';
        headline = 'Let\'s start building your story';
        body = 'Save one proof seed - something you did, built, or learned. Echo will use it to understand what matters to you.';
        tagColor = EchoColors.practice;
        break;
      case 'early':
        tagLabel = 'Echo is still learning';
        headline = 'What are you trying to unlock?';
        body = 'Pick one useful direction, save one tiny proof seed, then do one real practice. Echo should not pretend to know you before that.';
        tagColor = EchoColors.amber;
        break;
      case 'building':
        tagLabel = '$daysActive days in - $trainingPairs practices';
        headline = 'Building your proof';
        body = 'Add an outcome from recent practice to unlock opportunity matching. Echo needs real results, not just intentions.';
        tagColor = EchoColors.proof;
        break;
      default:
        tagLabel = 'Echo is still learning';
        headline = 'What are you trying to unlock?';
        body = 'Pick one useful direction, save one tiny proof seed, then do one real practice. Echo should not pretend to know you before that.';
        tagColor = EchoColors.amber;
    }

    return EchoPanel(
      borderColor: tagColor.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EchoTag(icon: Icons.lightbulb_outline_rounded, label: tagLabel, color: tagColor, filled: true),
          const SizedBox(height: 14),
          Text(headline, style: EchoText.title(size: 21)),
          const SizedBox(height: 8),
          Text(body, style: EchoText.body(size: 13.2)),
          if (stage == 'early') ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                EchoTag(icon: Icons.work_outline_rounded, label: 'work'),
                EchoTag(icon: Icons.school_outlined, label: 'school'),
                EchoTag(icon: Icons.workspace_premium_outlined, label: 'scholarship'),
                EchoTag(icon: Icons.handyman_outlined, label: 'project'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EchoPrimaryButton(
                  label: stage == 'building' ? 'Log an outcome' : 'Save first proof',
                  icon: stage == 'building' ? Icons.flag_outlined : Icons.inventory_2_outlined,
                  color: tagColor,
                  onPressed: stage == 'building'
                      ? () => OutcomeCaptureSheet.show(context, title: 'Log an outcome', subjectType: 'practice', onSaved: _checkState)
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProofBuilderScreen(
                              initialIntent: ProofBuilderIntent(
                                title: 'First proof seed',
                                description: 'Save one concrete thing you did, built, practiced, learned, or survived.',
                                category: 'artifact',
                                opportunityType: 'personal_goal',
                                skillTags: ['first proof', 'starting point'],
                                sourceLabel: 'Cold start',
                              ),
                              autoOpenDraft: true,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: EchoSecondaryButton(
                  label: 'Start check-in',
                  icon: Icons.fact_check_outlined,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComebackContent() {
    final daysAway = (_onboardingState?['days_away'] as num?)?.toInt() ?? 5;
    return FadeTransition(
      opacity: _contentFade,
      key: const ValueKey('comeback'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: EchoColors.opportunity.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '${daysAway}d away',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: EchoColors.opportunity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [EchoColors.opportunity.withValues(alpha: 0.12), EchoColors.bgSurface],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.opportunity.withValues(alpha: 0.30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NO GUILT LOOP',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: EchoColors.opportunity.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start with the smallest useful action.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: EchoColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Echo recovers momentum without punishment, streak shame, or fake urgency.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _comebackRow(Icons.bolt_rounded, EchoColors.practice, '1', 'Resume', 'one 10-minute practice', 'today'),
            const SizedBox(height: 8),
            _comebackRow(Icons.inventory_2_outlined, EchoColors.proof, '2', 'Recover proof', 'anything useful happened?', 'ask'),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() => _state = _TodayState.morningCheckin);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [EchoColors.opportunity.withValues(alpha: 0.80), EchoColors.amber]),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  'Restart Today',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EchoColors.bg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comebackRow(IconData icon, Color color, String num, String title, String subtitle, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, size: 15, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
                ),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tag == 'today' ? EchoColors.practice.withValues(alpha: 0.12) : EchoColors.bgSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tag == 'today' ? EchoColors.practice.withValues(alpha: 0.28) : EchoColors.borderSubtle),
            ),
            child: Text(
              tag,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: tag == 'today' ? EchoColors.practice : EchoColors.textGhost,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePriorityAction(Map<String, dynamic> priority) async {
    final action = Map<String, dynamic>.from(priority['action'] as Map? ?? {});
    final payload = Map<String, dynamic>.from(action['payload'] as Map? ?? {});
    final type = action['type'] as String? ?? 'none';
    HapticFeedback.lightImpact();

    switch (type) {
      case 'daily_checkin':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen()));
        if (mounted) _showLoopToast('Check-in saved. Echo updated Today.');
        break;
      case 'run_tournament':
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShadowTournamentScreen(initialPrompt: payload['prompt'] as String?)));
        await EchoLoopState().refresh();
        if (mounted) _showLoopToast('Practice Versions saved.');
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
          if (mounted) _showLoopToast('Practice saved. Echo updated Today.');
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
      _showLoopToast(outcome == 'not_true' ? 'Correction saved. Echo will adjust.' : 'Outcome saved. Echo updated Today.');
      _contentFade.value = 0;
      _checkState();
    }
  }

  Widget _buildDailyMissionCard(Map<String, dynamic> mission) {
    final headline = _cleanEchoCopy(mission['headline'] as String?) ?? 'Echo has one mission today.';
    final why = _cleanEchoCopy(mission['why'] as String?) ?? '';
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
        color: EchoColors.bgSurface,
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
                'NEXT STEP',
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
            style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
          ),
          if (why.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(why, style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12.5, height: 1.45)),
          ],
          if (perspectiveMission != null) ...[
            const SizedBox(height: 12),
            _missionLine(
              Icons.psychology_alt_outlined,
              'Perspective ready',
              _cleanEchoCopy(perspectiveMission['suggested_action'] as String?) ?? 'A decision prompt is ready.',
            ),
          ],
          if (reality != null) ...[
            const SizedBox(height: 8),
            _missionLine(
              Icons.fact_check_outlined,
              'Reality check',
              _cleanEchoCopy(reality['title'] as String?) ?? 'Echo is comparing words and behavior.',
            ),
          ],
          if (growth != null) ...[
            const SizedBox(height: 8),
            _missionLine(Icons.timeline_outlined, 'Proof', _cleanEchoCopy(growth['headline'] as String?) ?? 'Growth proof is forming.'),
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
                _logOutcomeAction(priority, 'Log outcome'),
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
        Icon(icon, size: 14, color: EchoColors.textGhost),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 11.5, height: 1.35),
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
    final title = _cleanEchoCopy(priority['title'] as String?) ?? 'Echo has a next step.';
    final body = _cleanEchoCopy(priority['body'] as String?) ?? '';
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
        color: EchoColors.bgSurface,
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
              if (evidence > 0) Text('$evidence outcomes', style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(body, style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12, height: 1.45)),
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
              _logOutcomeAction(priority, 'Log outcome'),
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
      child: Text(label, style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 11)),
    );
  }

  Widget _logOutcomeAction(Map<String, dynamic> priority, String label) {
    return GestureDetector(
      onTap: () => _openPriorityOutcome(priority),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(color: EchoColors.amber.withValues(alpha: 0.50), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _openPriorityOutcome(Map<String, dynamic> priority) async {
    final title = _cleanEchoCopy(priority['title'] as String?) ?? 'Today\'s step';
    final body = _cleanEchoCopy(priority['body'] as String?) ?? '';
    final subjectType = (priority['subject_type'] as String?) ?? (priority['kind'] as String?) ?? 'today_priority';
    final saved = await OutcomeCaptureSheet.show(
      context,
      title: title,
      subjectType: subjectType,
      subjectId: priority['subject_id'] as String?,
      contextNote: body,
      doneLabel: 'Did it',
      skippedLabel: 'Blocked',
      createProof: true,
      proofCategory: 'outcome',
      proofTitle: title,
    );
    if (!mounted || saved != true) return;
    _showLoopToast('Outcome saved. Proof updated.');
    _showProofCompletion('Outcome saved as proof.', openOpportunities: true);
    _contentFade.value = 0;
    _checkState();
  }

  Future<void> _openPracticeOutcome(String? repId, String title) async {
    final saved = await OutcomeCaptureSheet.show(
      context,
      title: title,
      subjectType: 'practice_rep',
      subjectId: repId,
      contextNote: _practice?['rep_instruction'] as String? ?? '',
      doneLabel: 'Practiced',
      skippedLabel: 'Blocked',
      createProof: true,
      proofCategory: 'practice',
      proofTitle: title,
    );
    if (!mounted || saved != true) return;
    if (repId != null) {
      await EchoApiClient().logPractice(repId, true);
      await EchoLoopState().refresh();
    }
    _showLoopToast('Practice outcome saved.');
    _showProofCompletion('Practice saved as proof.', openOpportunities: true);
    _contentFade.value = 0;
    _checkState();
  }

  void _showProofCompletion(String message, {bool openOpportunities = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: openOpportunities ? 'Opportunity plan' : 'Open proof',
          onPressed: () {
            if (!mounted) return;
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => openOpportunities ? const OpportunitiesScreen() : const ProofBuilderScreen()));
          },
        ),
      ),
    );
  }

  String _cleanActionLabel(String label) {
    return (_cleanEchoCopy(label) ?? label)
        .replaceAll('Send clones', 'Start Practice Versions')
        .replaceAll('send clones', 'start Practice Versions')
        .replaceAll('Open council', 'Open perspectives')
        .replaceAll('Enter council', 'Open perspectives')
        .replaceAll('Run tournament', 'Start Practice Versions')
        .replaceAll('run tournament', 'start Practice Versions')
        .replaceAll('clone', 'practice')
        .replaceAll('Clone', 'Practice');
  }

  String? _cleanEchoCopy(String? text) {
    if (text == null) return null;
    return text
        .replaceAll('Send clones into this pattern.', 'Start Practice Versions for this pattern.')
        .replaceAll('Send clones into', 'Start Practice Versions for')
        .replaceAll('send clones into', 'start Practice Versions for')
        .replaceAll('Send clones', 'Start Practice Versions')
        .replaceAll('send clones', 'start Practice Versions')
        .replaceAll('Run tournament', 'Start Practice Versions')
        .replaceAll('run tournament', 'start Practice Versions')
        .replaceAll('clone battle', 'practice versions run')
        .replaceAll('Clone battle', 'Practice versions run')
        .replaceAll('battle', 'practice run')
        .replaceAll('Battle', 'Practice run')
        .replaceAll('clones', 'practice paths')
        .replaceAll('Clones', 'Practice paths')
        .replaceAll('clone', 'practice path')
        .replaceAll('Clone', 'Practice path');
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
              color: EchoColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EchoColors.border),
            ),
            child: Text('I need to think about this', style: GoogleFonts.plusJakartaSans(color: EchoColors.textPrimary, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _state = _TodayState.silence);
          },
          child: Text('Dismiss', style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildStreakPill(int days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: EchoColors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EchoColors.amber.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded, size: 13, color: EchoColors.amber),
              const SizedBox(width: 5),
              Text(
                '$days day streak',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: EchoColors.amber, letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStuckButton() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        _showStuckSheet();
      },
      child: Text(
        "I'm stuck",
        style: GoogleFonts.plusJakartaSans(
          color: EchoColors.textGhost,
          fontSize: 12,
          decoration: TextDecoration.underline,
          decorationColor: EchoColors.textGhost.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _showStuckSheet() async {
    Map<String, dynamic>? intervention;
    if (!EchoRuntimeService().isDevice) {
      intervention = await EchoApiClient().getNextIntervention();
    }

    if (!mounted) return;

    final message =
        intervention?['message'] as String? ??
        intervention?['body'] as String? ??
        "You've been here before and kept going. One small thing counts today.";
    final id = intervention?['id'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EchoColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: EchoColors.amber),
                const SizedBox(width: 8),
                Text(
                  'Echo sees this',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: EchoColors.amber, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: GoogleFonts.lora(fontSize: 17, color: EchoColors.textPrimary, height: 1.6, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      if (id != null && !EchoRuntimeService().isDevice) {
                        await EchoApiClient().ackIntervention(id, status: 'acted');
                      }
                      if (mounted) {
                        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyCheckinScreen()));
                        if (mounted) _checkState();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: EchoColors.amber.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.28)),
                      ),
                      child: Text(
                        'Do today\'s check-in',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: EchoColors.amber, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      if (id != null && !EchoRuntimeService().isDevice) {
                        await EchoApiClient().ackIntervention(id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: EchoColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EchoColors.border),
                      ),
                      child: Text(
                        'Just needed to see this',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: EchoColors.border),
        ),
        child: Text('Decide with Echo', style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 13, letterSpacing: 0.3)),
      ),
    );
  }
}
