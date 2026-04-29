import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/auth_service.dart';

// ─── 3D Gyroscope Orb ────────────────────────────────────────────────────────

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
        c..reset()..repeat();
      }
      _ring2YCtrl..reset()..repeat(reverse: true);
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
      builder: (context2, child2) {
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
              // Ambient glow behind everything
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

              // Outer ring — Y axis rotation (gyroscope ring 1)
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
                      color: EchoColors.amber.withValues(
                          alpha: widget.active ? 0.40 : 0.14),
                      width: widget.active ? 1.4 : 1.0,
                    ),
                  ),
                ),
              ),

              // Middle ring — X axis rotation (gyroscope ring 2)
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
                    border: Border.all(
                      color: EchoColors.amber.withValues(
                          alpha: widget.active ? 0.30 : 0.10),
                      width: 1.0,
                    ),
                  ),
                ),
              ),

              // Inner ring — diagonal Y rotation (gyroscope ring 3)
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
                    border: Border.all(
                      color: EchoColors.amber.withValues(
                          alpha: widget.active ? 0.22 : 0.07),
                      width: 0.8,
                    ),
                  ),
                ),
              ),

              // Core orb
              Container(
                width: coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [
                      EchoColors.amberGlow,
                      EchoColors.amber,
                      EchoColors.amberDark,
                    ],
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

// ─── Radar Spider Chart ───────────────────────────────────────────────────────

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

    // Faint grid rings
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final x = cx + r * math.cos(angles[i]);
        final y = cy + r * math.sin(angles[i]);
        if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
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

    // Spokes
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

    // Filled radar polygon
    final fillPath = Path();
    final strokePath = Path();
    for (int i = 0; i < n; i++) {
      final rawScore = (scores[topics[i]] ?? 0.0).clamp(0.0, 1.0);
      // Ensure at least a tiny dot even at 0 so shape is visible
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
          colors: [
            EchoColors.amber.withValues(alpha: 0.12),
            EchoColors.amber.withValues(alpha: 0.04),
          ],
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

    // Dots on each vertex
    for (int i = 0; i < n; i++) {
      final rawScore = (scores[topics[i]] ?? 0.0).clamp(0.0, 1.0);
      final score = (rawScore * animValue).clamp(0.03, 1.0) * animValue;
      final r = maxR * score;
      final x = cx + r * math.cos(angles[i]);
      final y = cy + r * math.sin(angles[i]);
      final dotColor = _topicColors[topics[i]] ?? EchoColors.amber;
      canvas.drawCircle(
        Offset(x, y),
        3.5,
        Paint()..color = dotColor.withValues(alpha: 0.9 * animValue),
      );
    }

    // Topic labels
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final labelR = maxR + 22;
      final x = cx + labelR * math.cos(angles[i]);
      final y = cy + labelR * math.sin(angles[i]);
      final score = (scores[topics[i]] ?? 0.0);
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
  bool shouldRepaint(_RadarPainter old) =>
      old.animValue != animValue || old.scores != scores;
}

// ─── Step Arc Progress ───────────────────────────────────────────────────────

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
      builder: (context2, value, child2) => SizedBox(
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
      center, radius,
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
        style: const TextStyle(
          fontSize: 9.5,
          color: EchoColors.amberText,
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(
      center.dx - tp.width / 2,
      center.dy - tp.height / 2,
    ));
  }

  @override
  bool shouldRepaint(_StepArcPainter old) => old.progress != progress || old.step != old.step;
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
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EchoColors.amber.withValues(alpha: 0.45),
                      ),
                    ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                widget.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: widget.done ? EchoColors.textMuted : EchoColors.textGhost,
                  height: 1.45,
                ),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
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
      builder: (context2, child2) => Row(
        children: List.generate(3, (i) {
          final t = (_ctrl.value - i / 3).clamp(0.0, 1.0);
          final alpha = math.sin(t * math.pi).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              width: 5, height: 5,
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
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  bool _pressing = false;

  String _trainingStatus = 'idle';
  Timer? _pollTimer;
  int _logStep = 0;
  Timer? _logTimer;

  static const _logLines = [
    'Reading your conversations...',
    'Extracting behavioral patterns...',
    'Preparing training dataset...',
    'Fine-tuning shadow clone weights...',
    'Merging LoRA adapter...',
    'Loading updated clone...',
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

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      EchoApiClient().getUserStats(),
      EchoApiClient().getUserInsights(),
      EchoApiClient().getConfidence(),
      EchoApiClient().getTrainingHistory(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0] as Map<String, dynamic>?;
      _insights = results[1] as Map<String, dynamic>?;
      _confidence = results[2] as Map<String, dynamic>?;
      _history = results[3] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  Future<void> _startTraining() async {
    final uid = AuthService().userId;
    if (uid == null) return;

    HapticFeedback.mediumImpact();
    final result = await EchoApiClient().triggerTraining(uid);
    if (result == null) return;

    final status = result['status'] as String? ?? '';
    if (status == 'not_enough_data') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: EchoColors.bgCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Need ${result['required']} conversations. You have ${result['pairs']} new ones.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
          ),
        ));
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
    _logTimer = Timer.periodic(const Duration(seconds: 11), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_logStep < _logLines.length - 1) _logStep++;
      });
      if (_logStep >= _logLines.length - 1) t.cancel();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      final status = await EchoApiClient().getTrainingStatus();
      if (!mounted) { t.cancel(); return; }
      if (status == 'complete') {
        t.cancel();
        _logTimer?.cancel();
        HapticFeedback.lightImpact();
        setState(() {
          _trainingStatus = 'complete';
          _logStep = _logLines.length - 1;
        });
        await _load();
      }
    });
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${m[dt.month - 1]} ${dt.day} · $h:$min';
    } catch (_) {
      return '—';
    }
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isRunning = _trainingStatus == 'running';
    final isComplete = _trainingStatus == 'complete';

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isRunning, isComplete),
            Expanded(
              child: _loading
                  ? _buildLoadingState()
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
            child: const Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: EchoColors.textMuted),
          ),
          const SizedBox(width: 12),
          Text(
            isRunning
                ? 'TRAINING IN PROGRESS'
                : isComplete
                    ? 'TRAINING COMPLETE'
                    : 'SHADOW CLONE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: isRunning
                  ? EchoColors.amber.withValues(alpha: 0.75)
                  : EchoColors.textVeryGhost,
            ),
          ),
          if (isRunning) ...[
            const SizedBox(width: 10),
            _DotLoader(),
          ],
        ],
      ),
    );
  }

  // ─── Loading state ───────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: _GyroOrb(active: false, size: 80),
    );
  }

  // ─── IDLE STATE ──────────────────────────────────────────────────────────────

  Widget _buildIdleState() {
    final totalPairs = _stats?['total_pairs'] as int? ?? 0;
    final lastTrained = _stats?['last_trained'] as String?;
    final checkpointCount = _history.length;
    final topics = (_confidence?['topics'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final pattern = _insights?['latest_pattern'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Orb + stats ────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const _GyroOrb(active: false, size: 120),
                  const SizedBox(height: 18),
                  Text(
                    'your shadow clone',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, letterSpacing: 0.9,
                      color: EchoColors.textGhost,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8, runSpacing: 6,
                    children: [
                      if (totalPairs > 0)
                        _pill('$totalPairs conversations'),
                      if (checkpointCount > 0)
                        _pill('$checkpointCount training runs'),
                      if (lastTrained != null)
                        _pill(_formatDate(lastTrained),
                            color: EchoColors.amber.withValues(alpha: 0.75)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Cognitive fingerprint (radar chart) ────────────────────────
          if (topics.isNotEmpty) ...[
            _sectionLabel('COGNITIVE FINGERPRINT'),
            const SizedBox(height: 4),
            Text(
              'The shape of what your clone knows about you',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, color: EchoColors.textGhost, height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildRadarChart(topics),
            const SizedBox(height: 24),
          ],

          // ── Latest pattern ─────────────────────────────────────────────
          if (pattern.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: EchoColors.amber, width: 2),
                  right: BorderSide(color: EchoColors.borderSubtle),
                  top: BorderSide(color: EchoColors.borderSubtle),
                  bottom: BorderSide(color: EchoColors.borderSubtle),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LATEST PATTERN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.0, color: EchoColors.amberText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pattern,
                    style: GoogleFonts.lora(
                      fontSize: 13.5, fontStyle: FontStyle.italic,
                      height: 1.65, color: EchoColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Training history strip ─────────────────────────────────────
          if (_history.isNotEmpty)
            _buildHistoryStrip(),

          const SizedBox(height: 8),

          // ── Train Now button ───────────────────────────────────────────
          _buildTrainButton(totalPairs),
        ],
      ),
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
        builder: (context2, value, child2) => SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _RadarPainter(scores: scores, animValue: value),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryStrip() {
    final Map<String, int> byDay = {};
    for (final c in _history) {
      final iso = c['created_at'] as String? ?? '';
      try {
        final day = iso.substring(0, 10);
        byDay[day] = (byDay[day] ?? 0) + 1;
      } catch (_) {}
    }
    if (byDay.isEmpty) return const SizedBox.shrink();

    final days = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxCount = byDay.values.reduce(math.max);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('TRAINING HISTORY'),
          const SizedBox(height: 12),
          SizedBox(
            height: 28,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((entry) {
                final count = entry.value;
                final frac = count / maxCount;
                final isLast = entry == days.last;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      height: 4 + (24 * frac),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isLast
                            ? EchoColors.amber.withValues(alpha: 0.80)
                            : EchoColors.amber.withValues(alpha: 0.18 + 0.28 * frac),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _shortDate(days.first.key),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, color: EchoColors.textVeryGhost,
                ),
              ),
              Text(
                _shortDate(days.last.key),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, color: EchoColors.amberText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainButton(int totalPairs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressing = true),
          onTapUp: (_) {
            setState(() => _pressing = false);
            _startTraining();
          },
          onTapCancel: () => setState(() => _pressing = false),
          child: AnimatedScale(
            scale: _pressing ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _pressing
                        ? EchoColors.amber.withValues(alpha: 0.80)
                        : EchoColors.amber.withValues(alpha: 0.92),
                    _pressing
                        ? EchoColors.amberDark.withValues(alpha: 0.85)
                        : EchoColors.amberDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: EchoColors.amber.withValues(
                        alpha: _pressing ? 0.15 : 0.28),
                    blurRadius: _pressing ? 10 : 22,
                    offset: const Offset(0, 4),
                    spreadRadius: _pressing ? 0 : 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 19, color: Color(0xFF0A0800)),
                  const SizedBox(width: 8),
                  Text(
                    'Train Your Clone Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A0800),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          totalPairs > 0
              ? '$totalPairs conversations ready for training'
              : 'Keep chatting — more conversations improve training',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11, color: EchoColors.textVeryGhost,
          ),
        ),
      ],
    );
  }

  // ─── ACTIVE TRAINING STATE ───────────────────────────────────────────────────

  Widget _buildActiveTraining(bool isRunning, bool isComplete) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      child: Column(
        children: [
          // Big pulsing orb
          Center(
            child: _GyroOrb(active: isRunning, size: 150),
          ),
          const SizedBox(height: 22),

          // Status label
          if (isRunning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 900),
              builder: (context2, v, child2) => Opacity(
                opacity: v,
                child: Text(
                  'training your shadow clone...',
                  style: GoogleFonts.lora(
                    fontSize: 15,
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
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: 0.15),
                    border: Border.all(
                        color: EchoColors.amber.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 11, color: EchoColors.amber),
                ),
                const SizedBox(width: 9),
                Text(
                  'Clone updated',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: EchoColors.amber,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 28),

          // Step arc + label row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepArc(
                step: _logStep + 1,
                total: _logLines.length,
                complete: isComplete,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isComplete ? 'Complete' : 'Step ${_logStep + 1} of ${_logLines.length}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: EchoColors.amberText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _logLines[_logStep],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: EchoColors.textGhost,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Divider
          Container(height: 1, color: EchoColors.borderSubtle),
          const SizedBox(height: 20),

          // Log lines
          ...(_logLines.sublist(0, _logStep + 1).asMap().entries.map((e) =>
              _LogLine(
                text: e.value,
                delayMs: 0,
                done: isComplete || e.key < _logStep,
              ))),

          if (isRunning) ...[
            const SizedBox(height: 8),
            _DotLoader(),
          ],

          if (isComplete) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: EchoColors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: EchoColors.amber.withValues(alpha: 0.20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: EchoColors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New adapter loaded. Your shadow clone is updated.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: EchoColors.amberText,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: EchoColors.textGhost,
      ),
    );
  }

  Widget _pill(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: color ?? EchoColors.textGhost,
        ),
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${m[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return iso;
    }
  }
}
