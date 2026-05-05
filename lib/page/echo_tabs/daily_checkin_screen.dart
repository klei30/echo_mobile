import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
enum _Phase { intro, loading, asking, typing, echoing, done }

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen>
    with TickerProviderStateMixin {

  static const _fallbackQuestions = [
    'What\'s one moment from today you keep replaying in your head?',
    'Did you say what you actually meant, or hold something back?',
    'What does today tell you about yourself that yesterday didn\'t?',
  ];

  static const _staticEchoes = [
    'Got it. I\'m tracking that.',
    'Honest. That matters.',
    'That\'s the one I was looking for.',
  ];

  _Phase _phase = _Phase.intro;
  int _qIndex = 0;
  List<String> _questions = _fallbackQuestions;
  final List<String> _answers = [];
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  String get _currentQuestion => _questions[_qIndex];
  String get _currentEcho => _qIndex < _staticEchoes.length
      ? _staticEchoes[_qIndex]
      : 'Got it.';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _transition(VoidCallback stateChange) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(stateChange);
    _slideCtrl.reset();
    _fadeCtrl.reset();
    _slideCtrl.forward();
    _fadeCtrl.forward();
  }

  void _beginCheckin() {
    _transition(() => _phase = _Phase.loading).then((_) async {
      final fetched = await EchoApiClient().getDailyQuestions();
      if (!mounted) return;
      if (fetched != null && fetched.length >= 3) {
        setState(() => _questions = fetched);
      }
      _transition(() => _phase = _Phase.asking);
    });
  }

  void _openKeyboard() {
    _transition(() => _phase = _Phase.typing).then((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  void _submitAnswer() {
    final answer = _textCtrl.text.trim();
    if (answer.isEmpty) return;
    HapticFeedback.lightImpact();
    _textCtrl.clear();
    _focusNode.unfocus();
    _answers.add(answer);

    _transition(() => _phase = _Phase.echoing).then((_) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        if (_qIndex < _questions.length - 1) {
          _transition(() {
            _qIndex++;
            _phase = _Phase.asking;
          });
        } else {
          _finishCheckin();
        }
      });
    });
  }

  Future<void> _finishCheckin() async {
    final qas = List.generate(_questions.length, (i) => {
      'q': _questions[i],
      'a': i < _answers.length ? _answers[i] : '',
    });
    await EchoApiClient().submitDailyCheckin(qas);
    if (!mounted) return;
    setState(() => _phase = _Phase.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030201),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _phase == _Phase.intro
                ? _buildIntro()
                : _phase == _Phase.loading
                    ? _buildLoading()
                    : _phase == _Phase.done
                        ? _buildDone()
                        : _buildFlow(),
          ),
        ),
      ),
    );
  }

  Widget _buildDone() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EchoOrb(size: 56, rings: 2),
            const SizedBox(height: 28),
            Text(
              'Echo heard you.',
              style: GoogleFonts.lora(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 20,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textGhost,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildCloseRow(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EchoOrb(size: 48, rings: 3),
              const SizedBox(height: 20),
              Text(
                'Echo is thinking of what to ask...',
                style: GoogleFonts.lora(
                  fontSize: 15, fontStyle: FontStyle.italic,
                  color: EchoColors.textGhost,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Intro ────────────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return Column(
      children: [
        _buildCloseRow(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EchoOrb(size: 60, rings: 2),
              const SizedBox(height: 32),
              Text(
                'Evening Signal',
                style: GoogleFonts.lora(
                  fontSize: 24, fontStyle: FontStyle.italic,
                  color: EchoColors.textPrimary, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3 questions · 5 minutes',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: EchoColors.textGhost),
              ),
              const SizedBox(height: 14),
              Text(
                'Echo has something to ask.',
                style: GoogleFonts.lora(
                  fontSize: 13, fontStyle: FontStyle.italic,
                  color: EchoColors.textGhost,
                ),
              ),
              const SizedBox(height: 52),
              _buildReadyButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyButton() {
    return GestureDetector(
      onTap: _beginCheckin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Ready',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w500, color: EchoColors.amber,
          ),
        ),
      ),
    );
  }

  // ─── Main flow ────────────────────────────────────────────────────────────

  Widget _buildFlow() {
    final isTyping = _phase == _Phase.typing;
    return Column(
      children: [
        _buildHeader(),
        _buildOrb(),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: _phase == _Phase.echoing
              ? _buildEchoSynthesis()
              : _buildQuestion(),
        ),
        const Spacer(),
        if (_phase == _Phase.asking) _buildTapPrompt(),
        if (isTyping) _buildTextInput(),
        SizedBox(height: isTyping ? 8 : 28),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 18, color: EchoColors.textVeryGhost),
          ),
          const Spacer(),
          // Progress dots
          Row(
            children: List.generate(3, (i) {
              final done = i < _answers.length;
              final active = i == _qIndex && _phase != _Phase.echoing;
              final echoing = i == _qIndex && _phase == _Phase.echoing;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: (done || echoing) ? 8 : active ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: (done || echoing)
                      ? EchoColors.amber
                      : active
                          ? EchoColors.amber.withValues(alpha: 0.35)
                          : const Color(0xFF1A1815),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 8),
      child: Center(
        child: EchoOrb(
          size: _phase == _Phase.echoing ? 64 : 52,
          rings: _phase == _Phase.echoing ? 3 : 2,
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Text(
      _currentQuestion,
      textAlign: TextAlign.center,
      style: GoogleFonts.lora(
        fontSize: 20, fontStyle: FontStyle.italic,
        height: 1.58, color: EchoColors.textPrimary, letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildEchoSynthesis() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: EchoColors.amber),
            ),
            const SizedBox(width: 8),
            Text(
              'ECHO',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: EchoColors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _currentEcho,
          textAlign: TextAlign.center,
          style: GoogleFonts.lora(
            fontSize: 20, fontStyle: FontStyle.italic,
            height: 1.55, color: EchoColors.textMuted, letterSpacing: -0.2,
          ),
        ),
        if (_answers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0806),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A1815)),
            ),
            child: Text(
              '"${_answers.last}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5, height: 1.6, color: EchoColors.textGhost,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTapPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GestureDetector(
        onTap: _openKeyboard,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: EchoColors.amber.withValues(alpha: 0.2)),
            color: const Color(0xFF0A0806),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_rounded, size: 14, color: EchoColors.textGhost),
                const SizedBox(width: 8),
                Text(
                  'tap to answer',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: EchoColors.textGhost),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 0, 20, MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: EchoColors.textPrimary, height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Say what\'s true...',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: EchoColors.textGhost),
                filled: true,
                fillColor: const Color(0xFF0F0D0B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: EchoColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: EchoColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: EchoColors.amber.withValues(alpha: 0.4)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _submitAnswer,
            child: Container(
              width: 46, height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.amber,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF060504), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 18, color: EchoColors.textVeryGhost),
          ),
        ],
      ),
    );
  }
}
