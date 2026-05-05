import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

// Perspective identity definitions
const _cloneOrder = ['Builder', 'Creative', 'Strategist', 'Examiner', 'Connector'];

const _cloneColors = {
  'Builder': Color(0xFFFFA726),    // amber
  'Creative': Color(0xFFCE93D8),   // purple
  'Strategist': Color(0xFF42A5F5), // blue
  'Examiner': Color(0xFFE0E0E0),   // white/gray
  'Connector': Color(0xFF66BB6A),  // green
};

const _cloneIcons = {
  'Builder': Icons.architecture_outlined,
  'Creative': Icons.auto_awesome_outlined,
  'Strategist': Icons.timeline_outlined,
  'Examiner': Icons.search_outlined,
  'Connector': Icons.people_outline,
};

const _cloneSubtitle = {
  'Builder': 'What does this enable?',
  'Creative': 'What does this feel like?',
  'Strategist': 'Where does this lead in 5 years?',
  'Examiner': 'What are you avoiding?',
  'Connector': 'Who does this affect?',
};

enum _Phase { input, loading, result }

class CouncilScreen extends StatefulWidget {
  final String? initialQuestion;
  final String? threadId;
  final String? threadContext;
  final bool showChrome;
  const CouncilScreen({
    super.key,
    this.initialQuestion,
    this.threadId,
    this.threadContext,
    this.showChrome = true,
  });

  @override
  State<CouncilScreen> createState() => _CouncilScreenState();
}

class _CouncilScreenState extends State<CouncilScreen> with TickerProviderStateMixin {
  _Phase _phase = _Phase.input;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  Map<String, dynamic>? _result;

  late final AnimationController _orbPulse;
  late final List<AnimationController> _cardControllers;

  @override
  void initState() {
    super.initState();
    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _cardControllers = List.generate(
      6, // 5 voices + 1 verdict
      (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 380)),
    );

    if (widget.initialQuestion != null) {
      _ctrl.text = widget.initialQuestion!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask());
    }
  }

  @override
  void dispose() {
    _orbPulse.dispose();
    for (final c in _cardControllers) { c.dispose(); }
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
    HapticFeedback.mediumImpact();

    setState(() => _phase = _Phase.loading);

    final result = await EchoApiClient().askCouncil(
      q,
      threadId: widget.threadId,
      threadContext: widget.threadContext,
    );
    if (!mounted) return;

    if (result == null) {
      setState(() => _phase = _Phase.input);
      return;
    }

    // Reset card animations
    for (final c in _cardControllers) { c.value = 0; }

    setState(() {
      _result = result;
      _phase = _Phase.result;
    });

    // Stagger card reveal
    for (int i = 0; i < _cardControllers.length; i++) {
      await Future.delayed(Duration(milliseconds: 120 * i));
      if (mounted) _cardControllers[i].forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: widget.showChrome
          ? AppBar(
              backgroundColor: EchoColors.bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                color: EchoColors.textMuted,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Perspective Panel',
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _phase == _Phase.input
            ? _buildInput()
            : _phase == _Phase.loading
                ? _buildLoading()
                : _buildResult(),
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Thread context banner — shown when Echo called council proactively
            if (widget.threadContext != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E C H O  C A L L E D  T H I S',
                      style: GoogleFonts.plusJakartaSans(
                        color: EchoColors.amber.withValues(alpha: 0.55),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.threadContext!,
                      style: GoogleFonts.plusJakartaSans(
                        color: EchoColors.textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              'Bring a decision to the council.',
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Five distinct perspectives. They will disagree. That\'s the point.',
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                maxLines: 4,
                minLines: 2,
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textPrimary,
                  fontSize: 15,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Should I accept this offer?\nWhat do I do about this situation?',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: EchoColors.textMuted.withValues(alpha: 0.5),
                    fontSize: 14,
                    height: 1.6,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _ask(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _ask,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [EchoColors.amber, EchoColors.amber.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: 0.28),
                        blurRadius: 18,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Convene the council',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Perspective preview
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cloneOrder.map((name) {
                final color = _cloneColors[name]!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_cloneIcons[name], size: 12, color: color.withValues(alpha: 0.8)),
                      const SizedBox(width: 5),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _orbPulse,
            builder: (context, child) {
              final t = _orbPulse.value;
              return Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EchoColors.amber.withValues(alpha: 0.08 + t * 0.06),
                  border: Border.all(
                    color: EchoColors.amber.withValues(alpha: 0.25 + t * 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EchoColors.amber.withValues(alpha: 0.12 + t * 0.10),
                      blurRadius: 24 + t * 12,
                      spreadRadius: t * 4,
                    ),
                  ],
                ),
                child: Icon(Icons.groups_outlined, color: EchoColors.amber.withValues(alpha: 0.6 + t * 0.3), size: 30),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'The council is deliberating…',
            style: GoogleFonts.plusJakartaSans(
              color: EchoColors.textMuted,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Five perspectives. One question.',
            style: GoogleFonts.plusJakartaSans(
              color: EchoColors.textMuted.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();
    final voices = Map<String, dynamic>.from(_result!['voices'] as Map? ?? {});
    final verdict = _result!['verdict'] as String? ?? '';
    final question = _result!['question'] as String? ?? _ctrl.text;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Question recap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: EchoColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '"$question"',
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),

          // Perspective cards
          for (int i = 0; i < _cloneOrder.length; i++) ...[
            _buildVoiceCard(i, _cloneOrder[i], voices[_cloneOrder[i]] as String? ?? ''),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 8),

          // Verdict
          FadeTransition(
            opacity: _cardControllers[5],
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: _cardControllers[5], curve: Curves.easeOut)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel_outlined, size: 14, color: EchoColors.amber.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Text(
                          'VERDICT',
                          style: GoogleFonts.plusJakartaSans(
                            color: EchoColors.amber.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verdict,
                      style: GoogleFonts.plusJakartaSans(
                        color: EchoColors.textPrimary,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Thread resolve — only shown when triggered from a thread
          if (widget.threadId != null) ...[
            GestureDetector(
              onTap: () async {
                HapticFeedback.lightImpact();
                await EchoApiClient().resolveThread(
                  widget.threadId!,
                  note: 'council heard',
                );
                if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    'I\'ve heard this',
                    style: GoogleFonts.plusJakartaSans(
                      color: EchoColors.amber.withValues(alpha: 0.80),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Ask again
          GestureDetector(
            onTap: () => setState(() {
              _phase = _Phase.input;
              _ctrl.clear();
            }),
            child: Center(
              child: Text(
                'Ask a different question',
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: EchoColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard(int index, String name, String text) {
    final color = _cloneColors[name]!;
    final icon = _cloneIcons[name]!;
    final subtitle = _cloneSubtitle[name]!;
    final ctrl = _cardControllers[index];

    return FadeTransition(
      opacity: ctrl,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(icon, size: 17, color: color.withValues(alpha: 0.85)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.plusJakartaSans(
                            color: color.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· $subtitle',
                          style: GoogleFonts.plusJakartaSans(
                            color: EchoColors.textMuted.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      text.isNotEmpty ? text : '—',
                      style: GoogleFonts.plusJakartaSans(
                        color: EchoColors.textPrimary.withValues(alpha: 0.88),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
