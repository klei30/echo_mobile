import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/page/layout/sidebar.dart';
import 'package:chatmcp/page/layout/chat_page/chat_page.dart';
import 'package:chatmcp/page/echo_tabs/mirror_tab.dart';
import 'package:chatmcp/page/echo_tabs/you_tab.dart';
import 'package:chatmcp/page/onboarding/onboarding_page.dart';
import 'package:chatmcp/page/echo_settings/echo_settings_sheet.dart';
import 'package:chatmcp/provider/chat_model_provider.dart';
import 'package:chatmcp/provider/provider_manager.dart';

class EchoMobilePage extends StatefulWidget {
  const EchoMobilePage({super.key});

  @override
  State<EchoMobilePage> createState() => _EchoMobilePageState();
}

class _EchoMobilePageState extends State<EchoMobilePage> {
  int _selectedTab = 0;
  bool _onboardingChecked = false;
  bool _showOnboarding = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ProviderManager.settingsProvider.loadSettings();
      final done = await hasCompletedOnboarding();
      if (mounted) {
        setState(() {
          _showOnboarding = !done;
          _onboardingChecked = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatModelProvider>(
      builder: (context, chatModel, child) {
        final theme = _buildEchoTheme();

        // Show onboarding before the main app
        if (_onboardingChecked && _showOnboarding) {
          return Theme(
            data: theme,
            child: OnboardingPage(
              onComplete: () => setState(() => _showOnboarding = false),
            ),
          );
        }

        // Loading state while checking onboarding
        if (!_onboardingChecked) {
          return Theme(
            data: theme,
            child: Scaffold(
              backgroundColor: EchoColors.bg,
              body: Center(child: Image.asset('assets/echo_logo.png', width: 56, height: 56)),
            ),
          );
        }

        return KeyboardDismisser(
          gestures: const [
            GestureType.onTap,
            GestureType.onPanUpdateDownDirection,
          ],
          child: Theme(
            data: theme,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: EchoColors.bg,
              drawer: _buildDrawer(),
              body: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildEchoTab(),
                  const MirrorTab(),
                  const YouTab(),
                ],
              ),
              bottomNavigationBar: _buildBottomNav(),
            ),
          ),
        );
      },
    );
  }

  // ─── Theme ────────────────────────────────────────────────────────────────

  ThemeData _buildEchoTheme() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: EchoColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: EchoColors.amber,
        secondary: EchoColors.indigo,
        surface: EchoColors.bgSurface,
        onSurface: EchoColors.textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: EchoColors.textSecondary,
        displayColor: EchoColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EchoColors.bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: EchoColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: EchoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: EchoColors.amber, width: 1),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: EchoColors.textGhost,
        ),
      ),
      dividerColor: EchoColors.borderSubtle,
      cardColor: EchoColors.bgCard,
      iconTheme: const IconThemeData(color: EchoColors.textMuted),
      popupMenuTheme: const PopupMenuThemeData(
        color: EchoColors.bgCard,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: EchoColors.bgCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: EchoColors.bgSurface,
        surfaceTintColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? EchoColors.amber : EchoColors.textGhost,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? EchoColors.amber.withValues(alpha: 0.4)
              : EchoColors.border,
        ),
      ),
    );
  }

  // ─── Drawer (conversation list) ───────────────────────────────────────────

  Widget _buildDrawer() {
    return Container(
      width: 280,
      color: const Color(0xFF080604),
      child: SafeArea(
        child: SidebarPanel(
          onToggle: () => _scaffoldKey.currentState?.closeDrawer(),
        ),
      ),
    );
  }

  // ─── Echo (chat) tab ─────────────────────────────────────────────────────

  Widget _buildEchoTab() {
    return Column(
      children: [
        SafeArea(bottom: false, child: _buildEchoNavHeader()),
        const Expanded(child: ChatPage()),
      ],
    );
  }

  Widget _buildEchoNavHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      decoration: const BoxDecoration(
        color: EchoColors.bg,
        border: Border(bottom: BorderSide(color: EchoColors.borderNav, width: 1)),
      ),
      child: Row(
        children: [
          Image.asset('assets/echo_logo.png', width: 36, height: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Echo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EchoColors.textPrimary,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                Text(
                  'your shadow clone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: EchoColors.textGhost,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // Settings button
          GestureDetector(
            onTap: () => EchoSettingsSheet.show(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.bgSurface,
                border: Border.all(color: EchoColors.border),
              ),
              child: const Icon(Icons.tune_rounded, size: 16, color: EchoColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          // Conversation history button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.bgSurface,
                border: Border.all(color: EchoColors.border),
              ),
              child: const Icon(Icons.menu_rounded, size: 16, color: EchoColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom navigation ────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: EchoColors.bg,
        border: Border(top: BorderSide(color: EchoColors.borderNav, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, 'Echo', _EchoTabIcon.echo),
              _navItem(1, 'Mirror', _EchoTabIcon.mirror),
              _navItem(2, 'You', _EchoTabIcon.you),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, String label, _EchoTabIcon icon) {
    final active = _selectedTab == index;
    final color = active ? EchoColors.amber : EchoColors.textVeryGhost;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(icon, color),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(_EchoTabIcon icon, Color color) {
    switch (icon) {
      case _EchoTabIcon.echo:
        return Icon(Icons.chat_bubble_outline_rounded, size: 21, color: color);
      case _EchoTabIcon.mirror:
        return _MirrorCircleIcon(color: color);
      case _EchoTabIcon.you:
        return Icon(Icons.person_outline_rounded, size: 21, color: color);
    }
  }
}

enum _EchoTabIcon { echo, mirror, you }

/// Mirror icon: circle with 4 cardinal tick marks — matches the design's circle+crosses icon.
class _MirrorCircleIcon extends StatelessWidget {
  final Color color;
  const _MirrorCircleIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21,
      height: 21,
      child: CustomPaint(painter: _MirrorPainter(color: color)),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  final Color color;
  const _MirrorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;
    final tick = size.width * 0.12;

    // Circle
    canvas.drawCircle(Offset(cx, cy), r, paint);
    // Cardinal ticks
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy - r - tick), paint); // top
    canvas.drawLine(Offset(cx, cy + r), Offset(cx, cy + r + tick), paint); // bottom
    canvas.drawLine(Offset(cx - r, cy), Offset(cx - r - tick, cy), paint); // left
    canvas.drawLine(Offset(cx + r, cy), Offset(cx + r + tick, cy), paint); // right
  }

  @override
  bool shouldRepaint(covariant _MirrorPainter old) => old.color != color;
}
