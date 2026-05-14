import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/page/echo_tabs/local_model_setup_screen.dart';
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
  final Map<String, bool> _connections = {'Direction': true, 'Work': true, 'Learning': true, 'Relationships': false};

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
            'Start with a few real outcomes. Echo builds the rest from use, not from a long setup form.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.7, color: EchoColors.textGhost),
          ),
          const SizedBox(height: 28),
          _buildStepBar(_step.clamp(0, 3), 4),
        ],
      ),
    );
  }

  // â”€â”€â”€ S1: The Promise â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
              children: [
                const TextSpan(text: "Echo starts with\nsmall signals.\n"),
                TextSpan(
                  text: "It looks for evidence.\nIt asks you to correct it.\n",
                  style: TextStyle(color: EchoColors.textMuted),
                ),
                TextSpan(
                  text: "Then it gives you\none useful practice.",
                  style: TextStyle(color: EchoColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "No personality test. No fake certainty.\n"
            "Start with one real situation; Echo builds a weak read and improves from outcomes.",
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.7),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _next(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [EchoColors.primaryAi, EchoColors.practice]),
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
                  Icon(Icons.arrow_forward_rounded, size: 15, color: EchoColors.bg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ S2: Connect Your World â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const _connIcons = {
    'Direction': (Icons.explore_outlined, Color(0xFF83BDF2), Color(0xFF122A44)),
    'Work': (Icons.work_outline_rounded, Color(0xFF68D99D), Color(0xFF10271D)),
    'Learning': (Icons.menu_book_outlined, Color(0xFFB8ABFF), Color(0xFF1A1733)),
    'Relationships': (Icons.people_outline_rounded, Color(0xFFE3BD61), Color(0xFF2C2410)),
  };

  static const _connDesc = {
    'Direction': 'What you want to understand about yourself',
    'Work': 'Where effort, stress, and proof show up',
    'Learning': 'Skills you want to practice and improve',
    'Relationships': 'Patterns in collaboration, care, and conflict',
  };

  Widget _buildConnect({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2 of 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
          const SizedBox(height: 16),
          _buildStepBar(1, 4),
          const SizedBox(height: 28),
          Text(
            "Choose what Echo\nshould notice first.",
            style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w400, color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Text(
            "This is only a starting direction. Echo should earn confidence from evidence and outcomes.",
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.6),
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
                Divider(color: EchoColors.borderSubtle, height: 1),
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
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [EchoColors.primaryAi, EchoColors.practice]),
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
            'You can change this anytime in Settings',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ S3: First Question â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildFirstQuestion({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4 of 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.6),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EchoColors.bgInput,
              border: Border.all(color: EchoColors.borderSubtle),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _answerCtrl,
              maxLines: 4,
              minLines: 3,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tap to type...',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textGhost),
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [EchoColors.primaryAi, EchoColors.practice],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: _submitting
                        ? SizedBox(height: 19, width: 19, child: CircularProgressIndicator(strokeWidth: 2, color: EchoColors.bg))
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
    final title = _firstRead?['title'] as String? ?? 'A first pattern is visible.';
    final read = _firstRead?['read'] as String? ?? 'Echo has enough to begin building a first picture.';
    final nextMove = _firstRead?['next_move'] as String? ?? 'Keep talking until Echo can test this with real feedback.';

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
                Icon(Icons.bolt_rounded, size: 17, color: EchoColors.amber),
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

  // â”€â”€â”€ S3: Brain Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildBrainPicker({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3 of 4', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
          const SizedBox(height: 16),
          _buildStepBar(2, 4),
          const SizedBox(height: 32),
          Text(
            "Where should\nEcho think?",
            style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.w400, color: EchoColors.textPrimary, height: 1.4, letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Text(
            "You can change this anytime in Where Echo Thinks.",
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 28),
          // Echo Cloud card
          GestureDetector(
            onTap: () async {
              await EchoRuntimeService().setMode(EchoRuntimeMode.cloud);
              _next();
            },
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
                    child: Icon(Icons.cloud_outlined, size: 19, color: EchoColors.amber),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: EchoColors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Home Brain card
          GestureDetector(
            onTap: () async {
              final paired = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const PairComputerScreen()));
              if (!mounted) return;
              if (paired == true) {
                await EchoRuntimeService().setMode(EchoRuntimeMode.desktop);
                _next();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: EchoColors.bgInput, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.computer_outlined, size: 19, color: EchoColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Brain',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EchoColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Runs on your own computer.\nPair by Wi-Fi or secure QR tunnel.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: EchoColors.textGhost),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // This Device card
          GestureDetector(
            onTap: () async {
              final ready = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const LocalModelSetupScreen(onboarding: true)));
              if (!mounted) return;
              if (ready == true) _next();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: EchoColors.bgInput, borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.phone_android_rounded, size: 19, color: EchoColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Device',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: EchoColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use Gemma offline.\nPrivate, portable, syncs later.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: EchoColors.textGhost),
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
            decoration: BoxDecoration(color: i <= active ? EchoColors.primaryAi : EchoColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: EchoColors.textPrimary),
                ),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textMuted, height: 1.4)),
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAE6E0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
