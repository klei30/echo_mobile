import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/page/echo_tabs/pair_computer_screen.dart';

const _kOnboardedKeyPrefix = 'echo_onboarded';

String _onboardingKey() {
  final uid = AuthService().userId;
  return uid != null && uid.isNotEmpty ? '${_kOnboardedKeyPrefix}_$uid' : _kOnboardedKeyPrefix;
}

/// Returns true if the current user has completed onboarding.
Future<bool> hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_onboardingKey()) ?? false;
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_onboardingKey(), true);
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  bool _submitting = false;
  Map<String, dynamic>? _firstRead;

  // Step 2 toggles
  final Map<String, bool> _connections = {'Email': true, 'Calendar': true, 'Reading': true, 'Listening': false};

  // Step 3 answer
  final TextEditingController _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
    } else if (_step == 3) {
      final answer = _answerCtrl.text.trim();
      if (answer.length < 8) return;
      setState(() => _submitting = true);
      final result = await EchoApiClient().submitOnboardingFirstRead(answer);
      if (!mounted) return;
      if (result != null) {
        final delta = result['loop_delta'];
        if (delta is Map) {
          EchoLoopState().apply(
            snapshot: delta['snapshot'] is Map ? Map<String, dynamic>.from(delta['snapshot'] as Map) : null,
            todayPriority: delta['today_priority'] is Map ? Map<String, dynamic>.from(delta['today_priority'] as Map) : null,
            thesis: delta['thesis'] is Map ? Map<String, dynamic>.from(delta['thesis'] as Map) : null,
          );
        } else {
          await EchoLoopState().refresh();
        }
        setState(() {
          _firstRead = result;
          _submitting = false;
          _step = 4;
        });
      } else {
        setState(() => _submitting = false);
        await markOnboardingComplete();
        widget.onComplete();
      }
    } else {
      await markOnboardingComplete();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final step = AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _buildStep(_step),
            );

            if (!isDesktop) return step;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Expanded(child: _buildDesktopIntro()),
                      const SizedBox(width: 36),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 560, minHeight: 620),
                          decoration: BoxDecoration(
                            color: EchoColors.bgSurface.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: EchoColors.borderSubtle),
                          ),
                          child: step,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    return switch (step) {
      0 => _buildPromise(key: const ValueKey(0)),
      1 => _buildConnect(key: const ValueKey(1)),
      2 => _buildBrainPicker(key: const ValueKey(2)),
      3 => _buildFirstQuestion(key: const ValueKey(3)),
      _ => _buildFirstRead(key: const ValueKey(4)),
    };
  }

  Widget _buildDesktopIntro() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Image.asset('assets/echo_logo.png', width: 52, height: 52),
              const SizedBox(width: 12),
              Text(
                'Echo',
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'A private operating layer for how you think, decide, and change.',
            style: GoogleFonts.lora(fontSize: 38, height: 1.22, fontStyle: FontStyle.italic, color: EchoColors.textPrimary),
          ),
          const SizedBox(height: 18),
          Text(
            'Start with a few real signals. Echo builds the rest from use, not from a long setup form.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.7, color: EchoColors.textGhost),
          ),
          const SizedBox(height: 28),
          _buildStepBar(_step.clamp(0, 3), 4),
        ],
      ),
    );
  }

  // ─── S1: The Promise ─────────────────────────────────────────────────────

  Widget _buildPromise({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(36, 0, 36, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Row(
            children: [
              Image.asset('assets/echo_logo.png', width: 42, height: 42),
              const SizedBox(width: 10),
              Text(
                'echo',
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, color: EchoColors.textPrimary, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 52),
          RichText(
            text: TextSpan(
              style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w400, color: EchoColors.textPrimary, height: 1.65, letterSpacing: -0.3),
              children: const [
                TextSpan(text: "I'm going to watch\nhow you think.\n"),
                TextSpan(
                  text: "How you decide.\nWhat you avoid.\n",
                  style: TextStyle(color: Color(0xFF3A3530)),
                ),
                TextSpan(
                  text: "What makes you\ncome alive.",
                  style: TextStyle(color: Color(0xFF1E1B17)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "No quiz. No setup. No \"tell us about yourself.\"\n"
            "Just talk. I'll figure out the rest.",
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4A4540), height: 1.7),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _next(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB86A28), Color(0xFFE0A850)]),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Begin',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: EchoColors.bg, letterSpacing: -0.2),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: EchoColors.bg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── S2: Connect Your World ───────────────────────────────────────────────

  static const _connIcons = {
    'Email': (Icons.mail_outline_rounded, Color(0xFFE85A5A), Color(0xFF1C0808)),
    'Calendar': (Icons.calendar_today_outlined, Color(0xFF4A7AE8), Color(0xFF0A0F1C)),
    'Reading': (Icons.menu_book_outlined, Color(0xFF7AAA5A), Color(0xFF0A1408)),
    'Listening': (Icons.headphones_outlined, Color(0xFF4AAAA0), Color(0xFF081412)),
  };

  static const _connDesc = {
    'Email': 'Who reaches out to you, and how often',
    'Calendar': 'How you spend time vs. how you say you want to',
    'Reading': 'What captures your attention when you choose',
    'Listening': 'Your emotional weather, without you having to explain it',
  };

  Widget _buildConnect({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2 of 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3A3530))),
          const SizedBox(height: 16),
          _buildStepBar(1, 4),
          const SizedBox(height: 28),
          Text(
            "To know you, I need\nto see your world.",
            style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w400, color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Text(
            "I'll read these quietly. Not to report back — to understand context.\nYou control what I can see.",
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4A4540), height: 1.6),
          ),
          const SizedBox(height: 24),
          ..._connections.keys.map((name) {
            final (icon, iconColor, bg) = _connIcons[name]!;
            return Column(
              children: [
                _ConnItem(
                  icon: icon,
                  iconColor: iconColor,
                  iconBg: bg,
                  name: name,
                  desc: _connDesc[name]!,
                  on: _connections[name]!,
                  onChanged: (v) => setState(() => _connections[name] = v),
                ),
                const Divider(color: Color(0xFF0F0E0C), height: 1),
              ],
            );
          }),
          const Spacer(),
          GestureDetector(
            onTap: () => _next(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB46A28), Color(0xFFE0A850)]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                'Continue',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.bg),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this anytime in settings',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2A2520)),
          ),
        ],
      ),
    );
  }

  // ─── S3: First Question ───────────────────────────────────────────────────

  Widget _buildFirstQuestion({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4 of 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3A3530))),
          const SizedBox(height: 16),
          _buildStepBar(3, 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/echo_logo.png', width: 48, height: 48),
                const SizedBox(height: 32),
                Text(
                  "What's something you've been putting off thinking about?",
                  style: GoogleFonts.lora(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    color: EchoColors.textPrimary,
                    height: 1.55,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "There's no wrong answer.\nThis is just the beginning.",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF3A3530), height: 1.6),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0D0B),
              border: Border.all(color: const Color(0xFF1E1B17)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _answerCtrl,
              maxLines: 4,
              minLines: 3,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tap to type...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF3A3530)),
                border: InputBorder.none,
                isDense: true,
              ),
              cursorColor: EchoColors.amber,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _submitting ? null : () => _next(),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: _submitting
                        ? const SizedBox(height: 19, width: 19, child: CircularProgressIndicator(strokeWidth: 2, color: EchoColors.bg))
                        : Text(
                            'Send',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.bg),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirstRead({Key? key}) {
    final title = _firstRead?['title'] as String? ?? 'A first signal is visible.';
    final read = _firstRead?['read'] as String? ?? 'Echo has enough of a first signal to begin watching a real pattern.';
    final nextMove = _firstRead?['next_move'] as String? ?? 'Keep talking until Echo can test this with clones.';

    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(32, 18, 32, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(child: EchoOrb(size: 62, rings: 3)),
          const SizedBox(height: 34),
          Text(
            title,
            style: GoogleFonts.lora(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: EchoColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Text(read, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textMuted, height: 1.65)),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EchoColors.amber.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EchoColors.amber.withValues(alpha: 0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 17, color: EchoColors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(nextMove, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.amberText, height: 1.45)),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _next(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB46A28), Color(0xFFE0A850)]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                'Start talking',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.bg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── S3: Brain Picker ────────────────────────────────────────────────────

  Widget _buildBrainPicker({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3 of 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3A3530))),
          const SizedBox(height: 16),
          _buildStepBar(2, 4),
          const SizedBox(height: 32),
          Text(
            "Where should\nEcho think?",
            style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w400, color: EchoColors.textPrimary, height: 1.4, letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Text("You can change this anytime in Lab.", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF4A4540), height: 1.6)),
          const SizedBox(height: 28),
          // Echo Cloud card
          GestureDetector(
            onTap: () => _next(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: EchoColors.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.amber.withValues(alpha: 0.35), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: EchoColors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.cloud_outlined, size: 19, color: EchoColors.amber),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Echo Cloud',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(color: EchoColors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                'Recommended',
                                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: EchoColors.amberText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fastest setup. Works everywhere.\nBest for most people.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF4A4540), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: EchoColors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // My Computer card
          GestureDetector(
            onTap: () async {
              final paired = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const PairComputerScreen()),
              );
              if (!mounted) return;
              if (paired == true) _next();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E1B17)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: const Color(0xFF0F0D0B), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.computer_outlined, size: 19, color: Color(0xFF4A4540)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Computer',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EchoColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Runs on your own device.\nPair Echo Desktop with a QR code.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: const Color(0xFF3A3530), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF3A3530)),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStepBar(int active, int total) {
    return Row(
      children: List.generate(
        total,
        (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(color: i <= active ? EchoColors.amber : const Color(0xFF1E1B17), borderRadius: BorderRadius.circular(2)),
          ),
        ),
      ),
    );
  }
}

class _ConnItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String name;
  final String desc;
  final bool on;
  final ValueChanged<bool> onChanged;

  const _ConnItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.name,
    required this.desc,
    required this.on,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFFC8C4BE)),
                ),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF4A4540), height: 1.4)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!on),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: on
                    ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFB46A28), Color(0xFFE0A850)])
                    : null,
                color: on ? null : const Color(0xFF1E1B17),
              ),
              child: Align(
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAE6E0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
