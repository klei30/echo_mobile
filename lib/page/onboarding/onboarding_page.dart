import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/auth_service.dart';

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

  // Step 2 toggles
  final Map<String, bool> _connections = {
    'Email': true,
    'Calendar': true,
    'Reading': true,
    'Listening': false,
  };

  // Step 3 answer
  final TextEditingController _answerCtrl = TextEditingController();

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  void _next() async {
    if (_step < 2) {
      setState(() => _step++);
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: _buildStep(_step),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    return switch (step) {
      0 => _buildPromise(key: const ValueKey(0)),
      1 => _buildConnect(key: const ValueKey(1)),
      _ => _buildFirstQuestion(key: const ValueKey(2)),
    };
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
          Row(children: [
            Image.asset('assets/echo_logo.png', width: 42, height: 42),
            const SizedBox(width: 10),
            Text('echo',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w600,
                    color: EchoColors.textPrimary, letterSpacing: -0.5)),
          ]),
          const SizedBox(height: 52),
          RichText(
            text: TextSpan(
              style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.w400,
                  color: EchoColors.textPrimary, height: 1.65, letterSpacing: -0.3),
              children: const [
                TextSpan(text: "I'm going to watch\nhow you think.\n"),
                TextSpan(text: "How you decide.\nWhat you avoid.\n",
                    style: TextStyle(color: Color(0xFF3A3530))),
                TextSpan(text: "What makes you\ncome alive.",
                    style: TextStyle(color: Color(0xFF1E1B17))),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "No quiz. No setup. No \"tell us about yourself.\"\n"
            "Just talk. I'll figure out the rest.",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13, color: const Color(0xFF4A4540), height: 1.7),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _next,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB86A28), Color(0xFFE0A850)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Begin',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: EchoColors.bg, letterSpacing: -0.2)),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_rounded, size: 15, color: EchoColors.bg),
              ]),
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
          Text('Step 2 of 3',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3A3530))),
          const SizedBox(height: 16),
          _buildStepBar(1),
          const SizedBox(height: 28),
          Text("To know you, I need\nto see your world.",
              style: GoogleFonts.lora(
                  fontSize: 22, fontWeight: FontWeight.w400,
                  color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text("I'll read these quietly. Not to report back — to understand context.\nYou control what I can see.",
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: const Color(0xFF4A4540), height: 1.6)),
          const SizedBox(height: 24),
          ..._connections.keys.map((name) {
            final (icon, iconColor, bg) = _connIcons[name]!;
            return Column(children: [
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
            ]);
          }),
          const Spacer(),
          GestureDetector(
            onTap: _next,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text('Continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.bg)),
            ),
          ),
          const SizedBox(height: 8),
          Text('You can change this anytime in settings',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2A2520))),
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
          Text('Step 3 of 3',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF3A3530))),
          const SizedBox(height: 16),
          _buildStepBar(2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/echo_logo.png', width: 48, height: 48),
                const SizedBox(height: 32),
                Text("What's something you've been putting off thinking about?",
                    style: GoogleFonts.lora(
                        fontSize: 24, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic,
                        color: EchoColors.textPrimary, height: 1.55, letterSpacing: -0.3)),
                const SizedBox(height: 14),
                Text("There's no wrong answer.\nThis is just the beginning.",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: const Color(0xFF3A3530), height: 1.6)),
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
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _next,
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
                  child: Text('Send',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.bg)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStepBar(int active) {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
          height: 3,
          decoration: BoxDecoration(
            color: i <= active ? EchoColors.amber : const Color(0xFF1E1B17),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
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
    required this.icon, required this.iconColor, required this.iconBg,
    required this.name, required this.desc, required this.on, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFFC8C4BE))),
            Text(desc,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: const Color(0xFF4A4540), height: 1.4)),
          ]),
        ),
        GestureDetector(
          onTap: () => onChanged(!on),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38, height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: on
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                    )
                  : null,
              color: on ? null : const Color(0xFF1E1B17),
            ),
            child: Align(
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16, height: 16,
                margin: const EdgeInsets.all(3),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAE6E0)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
