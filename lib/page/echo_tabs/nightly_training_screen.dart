import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/provider/provider_manager.dart';

// ─── Gyroscope Orb ───────────────────────────────────────────────────────────

class _GyroOrb extends StatefulWidget {
  final bool active;
  final double size;
  const _GyroOrb({required this.active, this.size = 120});

  @override
  State<_GyroOrb> createState() => _GyroOrbState();
}

class _GyroOrbState extends State<_GyroOrb> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _ringYCtrl;
  late AnimationController _ringXCtrl;
  late AnimationController _ring2YCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.active ? 900 : 3000),
    )..repeat();
    _ringYCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.active ? 1800 : 7000),
    )..repeat();
    _ringXCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.active ? 2600 : 10000),
    )..repeat();
    _ring2YCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.active ? 3400 : 13000),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_GyroOrb old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      _pulseCtrl.duration = Duration(milliseconds: widget.active ? 900 : 3000);
      _ringYCtrl.duration = Duration(milliseconds: widget.active ? 1800 : 7000);
      _ringXCtrl.duration = Duration(milliseconds: widget.active ? 2600 : 10000);
      _ring2YCtrl.duration = Duration(milliseconds: widget.active ? 3400 : 13000);
      for (final c in [_pulseCtrl, _ringYCtrl, _ringXCtrl]) {
        c
          ..reset()
          ..repeat();
      }
      _ring2YCtrl
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringYCtrl.dispose();
    _ringXCtrl.dispose();
    _ring2YCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final coreSize = s * 0.38;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _ringYCtrl, _ringXCtrl, _ring2YCtrl]),
      builder: (ctx, _) {
        final pulse = math.sin(_pulseCtrl.value * 2 * math.pi).abs();
        final glowAlpha = widget.active ? 0.55 + 0.30 * pulse : 0.22 + 0.12 * pulse;
        final glowRadius = widget.active ? s * 0.55 + s * 0.15 * pulse : s * 0.28;
        final angleY = _ringYCtrl.value * 2 * math.pi;
        final angleX = _ringXCtrl.value * 2 * math.pi;
        final angle2Y = _ring2YCtrl.value * math.pi;
        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EchoColors.amber.withValues(alpha: glowAlpha * 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(angleY),
                alignment: Alignment.center,
                child: Container(
                  width: s * 0.92,
                  height: s * 0.92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EchoColors.amber.withValues(alpha: widget.active ? 0.40 : 0.14),
                      width: widget.active ? 1.4 : 1.0,
                    ),
                  ),
                ),
              ),
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateX(angleX),
                alignment: Alignment.center,
                child: Container(
                  width: s * 0.72,
                  height: s * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EchoColors.amber.withValues(alpha: widget.active ? 0.30 : 0.10), width: 1.0),
                  ),
                ),
              ),
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(angle2Y)
                  ..rotateX(math.pi / 4),
                alignment: Alignment.center,
                child: Container(
                  width: s * 0.54,
                  height: s * 0.54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EchoColors.amber.withValues(alpha: widget.active ? 0.22 : 0.07), width: 0.8),
                  ),
                ),
              ),
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [EchoColors.amberGlow, EchoColors.amber, EchoColors.amberDark],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.amber.withValues(alpha: glowAlpha),
                      blurRadius: glowRadius,
                      spreadRadius: widget.active ? 3 : 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Radar Chart ─────────────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final Map<String, double> scores;
  final double animValue;

  const _RadarPainter({required this.scores, required this.animValue});

  static const _topicColors = {
    'general': Color(0xFFF5A623),
    'ml': Color(0xFF8A92D8),
    'research': Color(0xFF6A9A7A),
    'coding': Color(0xFF9A6AB4),
    'personal': Color(0xFF7A8A9A),
    'writing': Color(0xFFA07850),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxR = math.min(cx, cy) - 32;
    final topics = scores.keys.toList();
    final n = topics.length;
    if (n < 3) return;
    final angles = List.generate(n, (i) => -math.pi / 2 + 2 * math.pi * i / n);

    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final x = cx + r * math.cos(angles[i]);
        final y = cy + r * math.sin(angles[i]);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = EchoColors.amber.withValues(alpha: ring == 4 ? 0.08 : 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
    }

    for (int i = 0; i < n; i++) {
      final x = cx + maxR * math.cos(angles[i]);
      final y = cy + maxR * math.sin(angles[i]);
      canvas.drawLine(
        center,
        Offset(x, y),
        Paint()
          ..color = EchoColors.amber.withValues(alpha: 0.08)
          ..strokeWidth = 0.7,
      );
    }

    final fillPath = Path();
    final strokePath = Path();
    for (int i = 0; i < n; i++) {
      final rawScore = (scores[topics[i]] ?? 0.0).clamp(0.0, 1.0);
      final score = (rawScore * animValue).clamp(0.03, 1.0) * animValue;
      final r = maxR * score;
      final x = cx + r * math.cos(angles[i]);
      final y = cy + r * math.sin(angles[i]);
      if (i == 0) {
        fillPath.moveTo(x, y);
        strokePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        strokePath.lineTo(x, y);
      }
    }
    fillPath.close();
    strokePath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = RadialGradient(
          colors: [EchoColors.amber.withValues(alpha: 0.12), EchoColors.amber.withValues(alpha: 0.04)],
        ).createShader(Rect.fromCircle(center: center, radius: maxR))
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      strokePath,
      Paint()
        ..color = EchoColors.amber.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    for (int i = 0; i < n; i++) {
      final rawScore = (scores[topics[i]] ?? 0.0).clamp(0.0, 1.0);
      final score = (rawScore * animValue).clamp(0.03, 1.0) * animValue;
      final r = maxR * score;
      final x = cx + r * math.cos(angles[i]);
      final y = cy + r * math.sin(angles[i]);
      final dotColor = _topicColors[topics[i]] ?? EchoColors.amber;
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = dotColor.withValues(alpha: 0.9 * animValue));
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final labelR = maxR + 22;
      final x = cx + labelR * math.cos(angles[i]);
      final y = cy + labelR * math.sin(angles[i]);
      final score = scores[topics[i]] ?? 0.0;
      final pct = (score * 100).round();
      final dotColor = _topicColors[topics[i]] ?? EchoColors.amber;
      tp.text = TextSpan(
        children: [
          TextSpan(
            text: '${topics[i]}\n',
            style: TextStyle(
              fontSize: 9.0,
              color: EchoColors.textGhost.withValues(alpha: 0.8 * animValue),
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          TextSpan(
            text: '$pct%',
            style: TextStyle(
              fontSize: 8.5,
              color: dotColor.withValues(alpha: 0.75 * animValue),
              fontFamily: 'PlusJakartaSans',
            ),
          ),
        ],
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.animValue != animValue || old.scores != scores;
}

// ─── Step Arc ────────────────────────────────────────────────────────────────

class _StepArc extends StatelessWidget {
  final int step;
  final int total;
  final bool complete;

  const _StepArc({required this.step, required this.total, this.complete = false});

  @override
  Widget build(BuildContext context) {
    final progress = complete ? 1.0 : (step / total).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (_, value, __) => SizedBox(
        width: 52,
        height: 52,
        child: CustomPaint(
          painter: _StepArcPainter(progress: value, step: step, total: total),
        ),
      ),
    );
  }
}

class _StepArcPainter extends CustomPainter {
  final double progress;
  final int step;
  final int total;
  const _StepArcPainter({required this.progress, required this.step, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = EchoColors.amber.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = EchoColors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '$step/$total',
        style: const TextStyle(fontSize: 9.5, color: EchoColors.amberText, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_StepArcPainter old) => old.progress != progress;
}

// ─── Log Line ─────────────────────────────────────────────────────────────────

class _LogLine extends StatefulWidget {
  final String text;
  final int delayMs;
  final bool done;
  const _LogLine({required this.text, required this.delayMs, this.done = false});

  @override
  State<_LogLine> createState() => _LogLineState();
}

class _LogLineState extends State<_LogLine> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: widget.done
                  ? const Icon(Icons.check_rounded, size: 11, color: EchoColors.amber)
                  : Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: EchoColors.amber.withValues(alpha: 0.45)),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                widget.text,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: widget.done ? EchoColors.textMuted : EchoColors.textGhost, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot Loader ───────────────────────────────────────────────────────────────

class _DotLoader extends StatefulWidget {
  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        children: List.generate(3, (i) {
          final t = (_ctrl.value - i / 3).clamp(0.0, 1.0);
          final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.amber.withValues(alpha: 0.2 + 0.65 * alpha),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class NightlyTrainingScreen extends StatefulWidget {
  const NightlyTrainingScreen({super.key});

  @override
  State<NightlyTrainingScreen> createState() => _NightlyTrainingScreenState();
}

class _NightlyTrainingScreenState extends State<NightlyTrainingScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _insights;
  Map<String, dynamic>? _confidence;
  Map<String, dynamic>? _trainingSummary;
  Map<String, dynamic>? _rank;
  List<Map<String, dynamic>> _runs = [];
  bool _loading = true;
  bool _pressing = false;

  String _trainingStatus = 'idle';
  Timer? _pollTimer;
  int _logStep = 0;
  Timer? _logTimer;

  String _trainingLane() => 'gemma4_e2b';

  static const _logLines = [
    'Reading your conversations...',
    'Extracting behavioral patterns...',
    'Preparing training dataset...',
    'Fine-tuning personal model weights...',
    'Merging LoRA adapter...',
    'Restarting your personal model...',
    'Loading updated model...',
    'Verifying personality alignment...',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _logTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool keepCompleteState = false}) async {
    setState(() => _loading = true);
    final results = await Future.wait([
      EchoApiClient().getUserStats(),
      EchoApiClient().getUserInsights(),
      EchoApiClient().getConfidence(),
      EchoApiClient().getTrainingSummary(lane: _trainingLane()),
      EchoApiClient().getTrainingRuns(lane: _trainingLane()),
      EchoApiClient().getUserRank(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as Map<String, dynamic>?;
      _insights = results[1] as Map<String, dynamic>?;
      _confidence = results[2] as Map<String, dynamic>?;
      _trainingSummary = results[3] as Map<String, dynamic>?;
      _runs = results[4] as List<Map<String, dynamic>>;
      _rank = results[5] as Map<String, dynamic>?;
      final status = _trainingSummary?['status'] as String?;
      if (status == 'running' || status == 'loading_adapter') {
        _trainingStatus = 'running';
        if (status == 'loading_adapter') {
          _logStep = _logLines.indexOf('Restarting your personal model...');
        } else {
          _startLogAnimation();
        }
        _startPolling();
      } else if (status != null && status.startsWith('complete')) {
        _pollTimer?.cancel();
        _logTimer?.cancel();
        if (keepCompleteState) {
          _trainingStatus = status;
          _logStep = _logLines.length - 1;
        } else {
          _trainingStatus = 'idle';
        }
      } else if (!keepCompleteState && !_trainingStatus.startsWith('complete')) {
        _trainingStatus = 'idle';
      }
      _loading = false;
    });
  }

  Future<void> _startTraining() async {
    HapticFeedback.mediumImpact();
    final lane = _trainingLane();
    final result = await EchoApiClient().triggerTraining(lane: lane);
    if (result == null) return;

    final status = result['status'] as String? ?? '';
    if (status == 'not_enough_data') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: EchoColors.bgCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Need ${result['required']} conversations. You have ${result['pairs']} new ones.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
            ),
          ),
        );
      }
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _trainingStatus = 'running';
      _logStep = 0;
    });
    _startLogAnimation();
    _startPolling();
  }

  void _startLogAnimation() {
    _logTimer?.cancel();
    _logStep = 0;
    // Once the animation reaches the last two steps, oscillate between them
    // so the UI never freezes while the backend is still evaluating.
    const loopFrom = 6; // 'Loading updated model...'
    _logTimer = Timer.periodic(const Duration(seconds: 11), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_logStep < _logLines.length - 1) {
          _logStep++;
        } else {
          _logStep = loopFrom;
        }
      });
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      final status = await EchoApiClient().getTrainingStatus(lane: _trainingLane());
      if (!mounted) {
        t.cancel();
        return;
      }
      if (status.startsWith('complete')) {
        t.cancel();
        _logTimer?.cancel();
        HapticFeedback.lightImpact();
        setState(() {
          _trainingStatus = status;
          _logStep = _logLines.length - 1;
        });
        await _load(keepCompleteState: true);
        await EchoLoopState().refresh();
      } else if (status == 'loading_adapter') {
        _logTimer?.cancel();
        setState(() {
          _trainingStatus = 'running';
          _logStep = _logLines.indexOf('Restarting your personal model...');
        });
      } else if (status == 'failed' || status == 'idle') {
        t.cancel();
        _logTimer?.cancel();
        if (mounted) {
          setState(() => _trainingStatus = status == 'failed' ? 'failed' : 'idle');
          await _load();
        }
      }
    });
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${m[dt.month - 1]} ${dt.day} · $h:$min';
    } catch (_) {
      return '—';
    }
  }

  String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${m[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '—';
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isRunning = _trainingStatus == 'running';
    final isComplete = _trainingStatus.startsWith('complete');

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isRunning, isComplete),
            Expanded(
              child: _loading
                  ? const Center(child: _GyroOrb(active: false, size: 80))
                  : isRunning || isComplete
                  ? _buildActiveTraining(isRunning, isComplete)
                  : _buildIdleState(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isRunning, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: EchoColors.textMuted),
          ),
          const SizedBox(width: 12),
          Text(
            isRunning
                ? 'IMPROVING ECHO'
                : isComplete
                ? 'ECHO IMPROVED'
                : 'IMPROVE ECHO',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: isRunning ? EchoColors.amber.withValues(alpha: 0.75) : EchoColors.textVeryGhost,
            ),
          ),
          if (isRunning) ...[const SizedBox(width: 10), _DotLoader()],
        ],
      ),
    );
  }

  // ─── IDLE STATE ──────────────────────────────────────────────────────────────

  Widget _buildIdleState() {
    final totalPairs = _stats?['total_pairs'] as int? ?? 0;
    final lastTrained = _stats?['last_trained'] as String?;
    final topics = (_confidence?['topics'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final pattern = _insights?['latest_pattern'] as String? ?? '';
    final rankName = _rank?['rank'] as String? ?? '';
    final xp = _rank?['xp'] as int? ?? 0;
    final xpToNext = _rank?['xp_to_next'] as int? ?? 0;
    final progress = (_rank?['progress'] as num?)?.toDouble() ?? 0.0;

    final completedRuns = _runs.where((r) {
      final s = r['status'] as String? ?? '';
      return s.startsWith('complete') || s == 'failed';
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero Section ──
          _buildHeroSection(totalPairs, lastTrained, rankName, xp, xpToNext, progress, completedRuns),

          const SizedBox(height: 32),

          // ── Train Now CTA ──
          _buildTrainButton(),

          const SizedBox(height: 32),

          // ── Dashboard Grid ──
          if (pattern.isNotEmpty) ...[
            _buildCard(
              title: 'LATEST PATTERN',
              icon: Icons.psychology_rounded,
              borderColor: EchoColors.amber.withValues(alpha: 0.3),
              child: Text(
                pattern,
                style: GoogleFonts.lora(fontSize: 14, fontStyle: FontStyle.italic, height: 1.6, color: EchoColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (topics.isNotEmpty) ...[
            _buildCard(
              title: 'COGNITIVE FINGERPRINT',
              icon: Icons.radar_rounded,
              child: Column(
                children: [
                  Text(
                    'Topics Echo has learned most about you',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _buildRadarChart(topics),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_trainingSummary != null) ...[_buildBattleSummaryCard(), const SizedBox(height: 16)],

          if (completedRuns.isNotEmpty) ...[_buildEvolutionRoadmap(completedRuns), const SizedBox(height: 32)],
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    int totalPairs,
    String? lastTrained,
    String rankName,
    int xp,
    int xpToNext,
    double progress,
    List<Map<String, dynamic>> completedRuns,
  ) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          const _GyroOrb(active: false, size: 120),
          const SizedBox(height: 24),
          if (rankName.isNotEmpty) ...[
            Text(
              rankName.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: EchoColors.amber),
            ),
            const SizedBox(height: 12),
            // XP progress bar
            SizedBox(
              width: 220,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: EchoColors.amber.withValues(alpha: 0.10),
                        valueColor: const AlwaysStoppedAnimation(EchoColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$xp XP',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.amberText, fontWeight: FontWeight.w600),
                      ),
                      Text('$xpToNext to next rank', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textVeryGhost)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (totalPairs > 0) _pill('$totalPairs pairs', icon: Icons.chat_bubble_outline_rounded),
              if (completedRuns.isNotEmpty) _pill('${completedRuns.length} runs', icon: Icons.memory_rounded),
              if (lastTrained != null)
                _pill(_formatDate(lastTrained), icon: Icons.access_time_rounded, color: EchoColors.amber.withValues(alpha: 0.8)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Dashboard Components ────────────────────────────────────────────────────

  Widget _buildCard({required String title, required IconData icon, required Widget child, Color? borderColor, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? EchoColors.borderSubtle),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: EchoColors.amber),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: EchoColors.amber),
              ),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildBattleSummaryCard() {
    final s = _trainingSummary ?? {};
    final battles = s['tournament_battles'] as int? ?? 0;
    final prefs = s['preference_signals'] as int? ?? 0;
    final dpoReady = (s['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (s['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    final untrained = s['untrained_pairs'] as int? ?? 0;
    final required = (s['required_pairs'] as num?)?.toInt() ?? 20;
    final leading = s['leading_style'] as String?;
    final adapter = Map<String, dynamic>.from(s['adapter'] as Map? ?? {});
    final adapterLoaded = adapter['loaded'] as bool? ?? false;
    final styleWins = Map<String, dynamic>.from(s['style_wins'] as Map? ?? {});

    return _buildCard(
      title: 'PREFERENCE SIGNAL',
      icon: Icons.psychology_alt_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: adapterLoaded ? const Color(0xFF4CAF50) : EchoColors.textGhost),
          ),
          const SizedBox(width: 6),
          Text(
            adapterLoaded ? 'live' : 'offline',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: adapterLoaded ? const Color(0xFF4CAF50) : EchoColors.textGhost,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leading == null ? 'Run a comparison to see which guidance style fits you best.' : '$leading is the guidance style helping most often.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.5, color: EchoColors.textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          Text(
            'Home Brain trains the personal Gemma adapter. This Device does not train locally yet; offline chats sync back as future training signal.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.45, color: EchoColors.textGhost),
          ),
          if (styleWins.isNotEmpty) ...[const SizedBox(height: 16), _buildStyleBars(styleWins)],
          const SizedBox(height: 20),
          _buildProgressRow('Pairs ready', untrained, required, EchoColors.amber),
          const SizedBox(height: 12),
          _buildProgressRow('Preference pairs', dpoReady, dpoRequired, const Color(0xFF8A92D8)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill('$battles comparisons', icon: Icons.compare_arrows_rounded),
              _pill('$prefs preference signals', icon: Icons.thumbs_up_down_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionRoadmap(List<Map<String, dynamic>> completedRuns) {
    if (completedRuns.isEmpty) return const SizedBox.shrink();

    final runs = completedRuns.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route_rounded, size: 16, color: EchoColors.amber),
            const SizedBox(width: 8),
            Text(
              'EVOLUTION ROADMAP',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: EchoColors.amber),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: List.generate(runs.length, (index) {
              return _buildRoadmapNode(run: runs[index], isFirst: index == 0, isLast: index == runs.length - 1, isLatest: index == 0);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapNode({required Map<String, dynamic> run, required bool isFirst, required bool isLast, required bool isLatest}) {
    final status = run['status'] as String? ?? '';
    final score = run['eval_score'] as num?;
    final date = (run['finished_at'] as String? ?? '');
    final pairs = run['pairs'] as num? ?? 0;
    final isFailed = status == 'failed';

    final String scoreLabel = isFailed
        ? 'Failed'
        : score != null
        ? '${(score * 100).round()}% alignment'
        : 'Unrated';

    final String dateLabel = date.length >= 16 ? _formatDate(date) : (date.length >= 10 ? _shortDate(date) : '—');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Stem
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vertical Line
                Positioned(
                  top: isFirst ? 24 : 0,
                  bottom: isLast ? null : 0,
                  height: isLast ? 24 : null,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          if (isFirst) EchoColors.amber.withValues(alpha: 0.5) else EchoColors.borderSubtle.withValues(alpha: 0.3),
                          if (isLast) Colors.transparent else EchoColors.borderSubtle.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),
                // Glowing Node or Simple Dot
                Positioned(
                  top: 20,
                  child: Container(
                    width: isLatest ? 12 : 8,
                    height: isLatest ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLatest ? EchoColors.amber : EchoColors.bg,
                      border: Border.all(color: isLatest ? EchoColors.amber : EchoColors.borderSubtle, width: isLatest ? 0 : 2),
                      boxShadow: isLatest ? [BoxShadow(color: EchoColors.amber.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2)] : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isLatest ? 'Latest Evolution' : 'Previous State',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isLatest ? EchoColors.amberText : EchoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textVeryGhost, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$pairs memories integrated • $scoreLabel',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleBars(Map<String, dynamic> wins) {
    final entries = wins.entries.toList()..sort((a, b) => (b.value as int).compareTo(a.value as int));
    final total = entries.fold<int>(0, (s, e) => s + (e.value as int));
    if (total == 0) return const SizedBox.shrink();

    const styleColors = {
      'Challenger': Color(0xFFF5A623),
      'Mirror': Color(0xFF8A92D8),
      'Builder': Color(0xFF6A9A7A),
      'Strategist': Color(0xFF9A6AB4),
      'Creative': Color(0xFF7A8A9A),
    };

    return Column(
      children: entries.take(5).map((e) {
        final count = e.value as int;
        final frac = (count / total).clamp(0.0, 1.0);
        final color = styleColors[e.key] ?? EchoColors.amber;
        final pct = (frac * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  e.key,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: frac),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor: color.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.65)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 34,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressRow(String label, int current, int required, Color color) {
    final frac = (current / required).clamp(0.0, 1.0);
    final ready = current >= required;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: frac),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(color.withValues(alpha: ready ? 0.9 : 0.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$current/$required',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: ready ? color : EchoColors.textGhost,
            fontWeight: ready ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRadarChart(List<Map<String, dynamic>> topics) {
    final scores = <String, double>{};
    for (final t in topics) {
      final topic = t['topic'] as String? ?? '';
      final score = (t['score'] as num?)?.toDouble() ?? 0.0;
      if (topic.isNotEmpty) scores[topic] = score;
    }
    if (scores.length < 3) return const SizedBox.shrink();

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOut,
        builder: (_, value, __) => SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _RadarPainter(scores: scores, animValue: value),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainButton() {
    final summary = _trainingSummary ?? {};
    final untrained = (summary['untrained_pairs'] as num?)?.toInt() ?? 0;
    final required = (summary['required_pairs'] as num?)?.toInt() ?? 20;
    final ready = summary['ready_for_training'] as bool? ?? false;
    final dpoReady = (summary['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final dpoRequired = (summary['dpo_required_pairs'] as num?)?.toInt() ?? 4;
    final label = ready ? 'Improve Echo' : '$untrained/$required new signals';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTapDown: ready ? (_) => setState(() => _pressing = true) : null,
          onTapUp: (_) {
            setState(() => _pressing = false);
            if (ready) _startTraining();
          },
          onTapCancel: () => setState(() => _pressing = false),
          child: AnimatedScale(
            scale: _pressing ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ready ? (_pressing ? EchoColors.amber.withValues(alpha: 0.80) : EchoColors.amber.withValues(alpha: 0.95)) : EchoColors.bgSurface,
                    ready ? (_pressing ? EchoColors.amberDark.withValues(alpha: 0.85) : EchoColors.amberDark) : EchoColors.bgSurface,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: ready ? null : Border.all(color: EchoColors.borderSubtle),
                boxShadow: [
                  if (ready)
                    BoxShadow(
                      color: EchoColors.amber.withValues(alpha: _pressing ? 0.15 : 0.30),
                      blurRadius: _pressing ? 10 : 24,
                      offset: const Offset(0, 6),
                      spreadRadius: _pressing ? 0 : 2,
                    ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ready ? Icons.bolt_rounded : Icons.hourglass_bottom_rounded,
                    size: 20,
                    color: ready ? const Color(0xFF0A0800) : EchoColors.textGhost,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: ready ? const Color(0xFF0A0800) : EchoColors.textGhost,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          ready ? '$untrained new moments + $dpoReady/$dpoRequired preference pairs' : 'Keep chatting - each useful turn becomes training signal',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textVeryGhost),
        ),
      ],
    );
  }

  // ─── ACTIVE TRAINING STATE ───────────────────────────────────────────────────

  Widget _buildActiveTraining(bool isRunning, bool isComplete) {
    final adapterLoaded = _trainingStatus != 'complete_adapter_not_loaded';
    final summary = _trainingSummary ?? {};
    final leading = summary['leading_style'] as String?;
    final dpoReady = (summary['dpo_ready_pairs'] as num?)?.toInt() ?? 0;
    final prefSignals = (summary['preference_signals'] as num?)?.toInt() ?? 0;
    final completeSummary = leading != null
        ? 'Echo learned from $prefSignals preference signals. $leading is the style helping most often.'
        : dpoReady > 0
        ? 'Echo learned from $prefSignals preference signals and $dpoReady preference pairs.'
        : 'Echo learned your latest style. Run a comparison to add stronger preference signal.';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      child: Column(
        children: [
          Center(child: _GyroOrb(active: isRunning, size: 150)),
          const SizedBox(height: 32),

          if (isRunning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, __) => Opacity(
                opacity: v,
                child: Text(
                  'updating your personal model...',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: EchoColors.amber.withValues(alpha: 0.85),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: 0.15),
                    border: Border.all(color: EchoColors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: EchoColors.amber),
                ),
                const SizedBox(width: 12),
                Text(
                  'Model updated',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: EchoColors.amber),
                ),
              ],
            ),

          const SizedBox(height: 36),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepArc(step: _logStep + 1, total: _logLines.length, complete: isComplete),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'Complete' : 'Step ${_logStep + 1} of ${_logLines.length}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.amberText, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(_logLines[_logStep], style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textGhost, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          Container(height: 1, color: EchoColors.borderSubtle),
          const SizedBox(height: 24),

          ...(_logLines
              .sublist(0, _logStep + 1)
              .asMap()
              .entries
              .map((e) => _LogLine(text: e.value, delayMs: 0, done: isComplete || e.key < _logStep))),

          if (isRunning) ...[const SizedBox(height: 12), _DotLoader()],

          if (isComplete) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: EchoColors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.amber.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  Icon(adapterLoaded ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, size: 20, color: EchoColors.amber),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      adapterLoaded ? 'Echo is updated and live. $completeSummary' : 'Training finished. Echo is improved but waiting to go live.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: EchoColors.amberText, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            // Show latest run score after completion
            if (_runs.isNotEmpty) ...[const SizedBox(height: 20), _buildRoadmapNode(run: _runs.first, isFirst: true, isLast: true, isLatest: true)],
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => setState(() => _trainingStatus = 'idle'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.35)),
                  color: EchoColors.amber.withValues(alpha: 0.07),
                ),
                child: Text(
                  'Train Again',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: EchoColors.amber.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _pill(String text, {IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: color ?? EchoColors.textGhost), const SizedBox(width: 6)],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color ?? EchoColors.textGhost),
          ),
        ],
      ),
    );
  }
}

// ─── Sparkline Painter ────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> scores;
  final double minScore;
  final double range;

  const _SparklinePainter({required this.scores, required this.minScore, required this.range});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.length < 2) return;

    final n = scores.length;
    final xStep = size.width / (n - 1);

    // Gradient fill
    final fillPath = Path();
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = i * xStep;
      final y = size.height - ((scores[i] - minScore) / range) * (size.height - 8) - 4;
      points.add(Offset(x, y));
    }

    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [EchoColors.amber.withValues(alpha: 0.18), EchoColors.amber.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = EchoColors.amber.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (int i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      canvas.drawCircle(points[i], isLast ? 4.0 : 2.5, Paint()..color = EchoColors.amber.withValues(alpha: isLast ? 0.95 : 0.50));
    }

    // Score labels at first and last
    void drawLabel(String text, Offset point, bool right) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: 9.0, color: EchoColors.amberText, fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = right ? point.dx - tp.width - 4 : point.dx + 4;
      tp.paint(canvas, Offset(dx, point.dy - tp.height - 2));
    }

    final firstScore = '${(scores.first * 100).round()}%';
    final lastScore = '${(scores.last * 100).round()}%';
    drawLabel(firstScore, points.first, false);
    drawLabel(lastScore, points.last, true);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.scores != scores;
}
