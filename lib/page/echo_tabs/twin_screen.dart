import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

enum _Phase { intro, input, loading, comparing, done }

class TwinScreen extends StatefulWidget {
  const TwinScreen({super.key});

  @override
  State<TwinScreen> createState() => _TwinScreenState();
}

class _TwinScreenState extends State<TwinScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.intro;
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Map<String, dynamic>? _session;
  bool _choseClone = false;
  String? _resultMessage;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _transition(VoidCallback change) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(change);
    _fadeCtrl.forward();
  }

  Future<void> _ask() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _focusNode.unfocus();
    await _transition(() => _phase = _Phase.loading);
    final result = await EchoApiClient().askTwin(q);
    if (!mounted) return;
    if (result == null || result['error'] != null) {
      await _transition(() => _phase = _Phase.input);
      return;
    }
    await _transition(() {
      _session = result;
      _phase = _Phase.comparing;
    });
  }

  Future<void> _choose(String choice) async {
    if (_session == null) return;
    HapticFeedback.lightImpact();
    final result = await EchoApiClient().chooseTwin(
      _session!['session_id'] as String,
      choice,
    );
    if (!mounted) return;
    await _transition(() {
      _choseClone = result?['chose_clone'] as bool? ?? false;
      _resultMessage = result?['message'] as String?;
      _phase = _Phase.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030201),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: switch (_phase) {
            _Phase.intro => _buildIntro(),
            _Phase.input => _buildInput(),
            _Phase.loading => _buildLoading(),
            _Phase.comparing => _buildComparing(),
            _Phase.done => _buildDone(),
          },
        ),
      ),
    );
  }

  Widget _buildCloseButton() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, size: 18, color: EchoColors.textVeryGhost),
        ),
      );

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCloseButton(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EchoOrb(size: 52, rings: 3),
                const SizedBox(height: 32),
                Text(
                  'Ask Your Twin',
                  style: GoogleFonts.lora(
                    fontSize: 26, fontStyle: FontStyle.italic,
                    color: EchoColors.textPrimary, letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your shadow clone has been trained on your conversations. '
                  'Ask both — see which one sounds more like you.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, height: 1.7, color: EchoColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You pick the answer that feels more you.\nYour twin learns from every choice.',
                  style: GoogleFonts.lora(
                    fontSize: 13, fontStyle: FontStyle.italic,
                    height: 1.6, color: EchoColors.textGhost,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () => _transition(() => _phase = _Phase.input),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: EchoColors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'Ask something',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w500,
                        color: EchoColors.amber,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Column(
      children: [
        _buildCloseButton(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What do you want to ask?',
                  style: GoogleFonts.lora(
                    fontSize: 18, fontStyle: FontStyle.italic,
                    color: EchoColors.textPrimary, height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ask anything you would ask Echo — the same question goes to both.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: EchoColors.textGhost, height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _ctrl,
                  focusNode: _focusNode,
                  autofocus: true,
                  maxLines: 6,
                  minLines: 3,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, color: EchoColors.textPrimary, height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. What should I focus on this week?',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 14, color: EchoColors.textGhost),
                    filled: true,
                    fillColor: const Color(0xFF0F0D0B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: EchoColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: EchoColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: EchoColors.amber.withValues(alpha: 0.4)),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24,
              MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 28),
          child: GestureDetector(
            onTap: _ask,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: EchoColors.amber,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  'Ask both',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: const Color(0xFF060504),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildCloseButton(),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              EchoOrb(size: 56, rings: 3),
              const SizedBox(height: 24),
              Text(
                'Asking both...',
                style: GoogleFonts.lora(
                  fontSize: 16, fontStyle: FontStyle.italic,
                  color: EchoColors.textGhost,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparing() {
    final q = _session?['question'] as String? ?? '';
    final respA = _session?['response_a'] as String? ?? '';
    final respB = _session?['response_b'] as String? ?? '';

    return Column(
      children: [
        _buildCloseButton(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              Text(
                'ECHO  ·  TWIN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.4, color: EchoColors.amber,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Which one sounds more like you?',
                style: GoogleFonts.lora(
                  fontSize: 18, fontStyle: FontStyle.italic,
                  color: EchoColors.textPrimary, height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"$q"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: EchoColors.textGhost, height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 28),
              _buildResponseCard('A', respA),
              const SizedBox(height: 14),
              _buildResponseCard('B', respB),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseCard(String label, String text) {
    return GestureDetector(
      onTap: () => _choose(label),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0806),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EchoColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EchoColors.textGhost),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: EchoColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Tap if this sounds more like you',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: EchoColors.textGhost,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5, color: EchoColors.textSecondary, height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        _buildCloseButton(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
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
                const SizedBox(height: 20),
                Text(
                  _resultMessage ?? 'Your twin just learned something.',
                  style: GoogleFonts.lora(
                    fontSize: 22, fontStyle: FontStyle.italic,
                    color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _choseClone
                      ? 'You picked the clone. It\'s working — your shadow is becoming more you.'
                      : 'You picked the teacher. The clone still has room to grow on this.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, height: 1.6, color: EchoColors.textMuted,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () => _transition(() {
                    _ctrl.clear();
                    _session = null;
                    _phase = _Phase.input;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: EchoColors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Ask something else',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: EchoColors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: EchoColors.textGhost,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
