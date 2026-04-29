import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/page/echo_tabs/council_screen.dart';
import 'package:chatmcp/page/echo_tabs/revelation_screen.dart';
import 'package:chatmcp/page/echo_tabs/parallel_self_screen.dart';
import 'package:chatmcp/page/echo_tabs/you_tab.dart';

/// The 4-state single screen that IS Echo.
/// State machine: silence → interruption → council → revelation
/// No tabs. Navigation is emergent — when something happens, it appears.
class PresenceScreen extends StatefulWidget {
  const PresenceScreen({super.key});

  @override
  State<PresenceScreen> createState() => _PresenceScreenState();
}

enum _PresenceState { silence, checking, interruption, council, revelation }

class _PresenceScreenState extends State<PresenceScreen>
    with TickerProviderStateMixin {
  _PresenceState _state = _PresenceState.checking;

  String? _statement;
  String? _letter;

  // Orb animation
  late final AnimationController _orbPulse;
  late final AnimationController _contentFade;

  @override
  void initState() {
    super.initState();
    _orbPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);

    _contentFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkState();
  }

  @override
  void dispose() {
    _orbPulse.dispose();
    _contentFade.dispose();
    super.dispose();
  }

  Future<void> _checkState() async {
    setState(() => _state = _PresenceState.checking);
    final decision = await EchoApiClient().decideState();
    if (!mounted) return;

    final echoState = decision?['state'] as String? ?? 'silence';
    final speakNow = decision?['speak_now'] as bool? ?? false;

    if (!speakNow || echoState == 'silence') {
      setState(() => _state = _PresenceState.silence);
      _contentFade.forward();
      return;
    }

    switch (echoState) {
      case 'interruption':
        setState(() {
          _statement = decision?['statement'] as String?;
          _state = _PresenceState.interruption;
        });
        break;
      case 'revelation':
        setState(() {
          _letter = decision?['letter'] as String?;
          _state = _PresenceState.revelation;
        });
        break;
      case 'council':
        setState(() => _state = _PresenceState.council);
        break;
      default:
        setState(() => _state = _PresenceState.silence);
    }
    _contentFade.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background orb — always present
            Positioned.fill(
              child: _buildOrbBackground(),
            ),

            // State content
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _buildStateContent(),
              ),
            ),

            // Bottom nav — always visible
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomNav(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbBackground() {
    return AnimatedBuilder(
      animation: _orbPulse,
      builder: (context, child) {
        final t = _orbPulse.value;
        final isActive = _state == _PresenceState.interruption ||
            _state == _PresenceState.revelation;
        final baseGlow = isActive ? 0.22 : 0.06;
        final pulseGlow = isActive ? 0.18 : 0.08;

        return Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: baseGlow + t * pulseGlow),
                        blurRadius: 60 + t * 30,
                        spreadRadius: t * 10,
                      ),
                    ],
                  ),
                ),
                // Mid ring
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: 0.03 + t * 0.03),
                    border: Border.all(
                      color: EchoColors.amber.withValues(alpha: 0.12 + t * 0.10),
                      width: 1.0,
                    ),
                  ),
                ),
                // Core
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: EchoColors.amber.withValues(alpha: 0.08 + t * 0.08),
                    boxShadow: [
                      BoxShadow(
                        color: EchoColors.amber.withValues(alpha: 0.15 + t * 0.15),
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

  Widget _buildStateContent() {
    switch (_state) {
      case _PresenceState.checking:
        return const SizedBox.shrink();

      case _PresenceState.silence:
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('silence'),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 220), // push below orb
                Text(
                  'Nothing yet.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.18),
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        );

      case _PresenceState.interruption:
        final statement = _statement ?? '';
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('interruption'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 200),
                Text(
                  statement,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
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
        );

      case _PresenceState.revelation:
        final letter = _letter ?? '';
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('revelation'),
          child: GestureDetector(
            onTap: () {
              if (letter.isNotEmpty) {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        RevelationScreen(letter: letter),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 700),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 200, 32, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'R E V E L A T I O N',
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to read',
                    style: GoogleFonts.inter(
                      color: EchoColors.amber.withValues(alpha: 0.45),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case _PresenceState.council:
        return FadeTransition(
          opacity: _contentFade,
          key: const ValueKey('council'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 200, 32, 100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'The council is ready.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CouncilScreen()),
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
                      'Bring your question',
                      style: GoogleFonts.inter(
                        color: EchoColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildInterruptionActions() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _state = _PresenceState.silence);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              'I need to think about this',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _state = _PresenceState.silence);
          },
          child: Text(
            'Dismiss',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            icon: Icons.refresh_outlined,
            label: 'Refresh',
            onTap: () {
              _contentFade.value = 0;
              _checkState();
            },
          ),
          _navItem(
            icon: Icons.groups_outlined,
            label: 'Council',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CouncilScreen()),
            ),
          ),
          _navItem(
            icon: Icons.fork_right_outlined,
            label: 'Two Paths',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParallelSelfScreen()),
            ),
          ),
          _navItem(
            icon: Icons.grid_view_outlined,
            label: 'Explore',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const YouTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.white.withValues(alpha: 0.35)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
