import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/layout/sidebar.dart';
import 'package:chatmcp/page/layout/chat_page/chat_page.dart';
import 'package:chatmcp/page/echo_tabs/you_tab.dart';
import 'package:chatmcp/page/echo_tabs/today_screen.dart';
import 'package:chatmcp/page/echo_tabs/echo_lab_screen.dart';
import 'package:chatmcp/page/setting/mcp_server.dart';
import 'package:chatmcp/page/setting/network_sync_setting.dart';
import 'package:chatmcp/page/onboarding/onboarding_page.dart';
import 'package:chatmcp/page/echo_settings/echo_settings_sheet.dart';
import 'package:chatmcp/provider/chat_model_provider.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/notification_service.dart';
import 'package:chatmcp/page/echo_tabs/home_brain_screen.dart';

class EchoMobilePage extends StatefulWidget {
  const EchoMobilePage({super.key});

  @override
  State<EchoMobilePage> createState() => _EchoMobilePageState();
}

class _EchoMobilePageState extends State<EchoMobilePage> with WidgetsBindingObserver {
  int _selectedTab = 1;
  bool _onboardingChecked = false;
  bool _showOnboarding = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onLoopStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    EchoLoopState().addListener(_onLoopStateChanged);
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    EchoLoopState().removeListener(_onLoopStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncEchoInterventionNotification();
      syncTrainingReadyNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatModelProvider>(
      builder: (context, chatModel, child) {
        final theme = _buildEchoTheme();
        final wideWeb = _isWideWeb(context);

        // Show onboarding before the main app
        if (_onboardingChecked && _showOnboarding) {
          return Theme(
            data: theme,
            child: OnboardingPage(onComplete: () => setState(() => _showOnboarding = false)),
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
          gestures: const [GestureType.onTap, GestureType.onPanUpdateDownDirection],
          child: Theme(
            data: theme,
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: EchoColors.bg,
              drawer: wideWeb ? null : _buildDrawer(),
              body: wideWeb ? _buildDesktopShell() : _buildMobileShell(),
              bottomNavigationBar: wideWeb ? null : _buildBottomNav(),
            ),
          ),
        );
      },
    );
  }

  bool _isWideWeb(BuildContext context) {
    // True responsive behavior: switch based on width, regardless of platform
    return MediaQuery.sizeOf(context).width >= 800;
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
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: EchoColors.textSecondary, displayColor: EchoColors.textPrimary),
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
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: EchoColors.textGhost),
      ),
      dividerColor: EchoColors.borderSubtle,
      cardColor: EchoColors.bgCard,
      iconTheme: const IconThemeData(color: EchoColors.textMuted),
      popupMenuTheme: const PopupMenuThemeData(color: EchoColors.bgCard, surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(backgroundColor: EchoColors.bgCard, surfaceTintColor: Colors.transparent),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: EchoColors.bgSurface, surfaceTintColor: Colors.transparent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? EchoColors.amber : EchoColors.textGhost),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? EchoColors.amber.withValues(alpha: 0.4) : EchoColors.border,
        ),
      ),
    );
  }

  // ─── Drawer (conversation list) ───────────────────────────────────────────

  Widget _buildDrawer() {
    return Container(
      width: 280,
      color: const Color(0xFF080604),
      child: SafeArea(child: SidebarPanel(onToggle: () => _scaffoldKey.currentState?.closeDrawer())),
    );
  }

  Widget _buildMobileShell() {
    final mobileIndex = _selectedTab > 2 ? 1 : _selectedTab;
    return IndexedStack(index: mobileIndex, children: [_buildEchoTab(), const TodayScreen(), const YouTab()]);
  }

  Widget _buildDesktopShell() {
    return SafeArea(
      child: Row(
        children: [
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Color(0xFF080604),
              border: Border(right: BorderSide(color: EchoColors.borderNav, width: 1)),
            ),
            child: Column(
              children: [
                _buildDesktopBrand(),
                const Divider(color: EchoColors.borderNav, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  child: Column(
                    children: [
                      _desktopNavItem(0, 'Talk', Icons.chat_bubble_outline_rounded),
                      _desktopNavItem(1, 'Today', Icons.circle_outlined),
                      _desktopNavItem(2, 'You', Icons.person_outline_rounded),
                      const SizedBox(height: 4),
                      const Divider(color: EchoColors.borderNav, height: 12),
                      _desktopNavItem(3, 'Studio', Icons.model_training_rounded),
                      _desktopNavItem(4, 'Local Brain', Icons.computer_rounded),
                      _desktopNavItem(5, 'Sync', Icons.sync_rounded),
                      _desktopNavItem(6, 'Tools', Icons.extension_rounded),
                    ],
                  ),
                ),
                const Divider(color: EchoColors.borderNav, height: 1),
                Expanded(child: SidebarPanel(onToggle: () {})),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                _DesktopChatPane(),
                TodayScreen(),
                YouTab(),
                EchoLabScreen(),
                HomeBrainScreen(),
                NetworkSyncSetting(),
                McpServer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBrand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        children: [
          Image.asset('assets/echo_logo.png', width: 38, height: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Echo',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
            ),
          ),
          _circleIconButton(Icons.tune_rounded, () => EchoSettingsSheet.show(context)),
        ],
      ),
    );
  }

  Widget _desktopNavItem(int index, String label, IconData icon) {
    final active = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? EchoColors.amber.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? EchoColors.amber.withValues(alpha: 0.24) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: active ? EchoColors.amber : EchoColors.textGhost),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? EchoColors.textPrimary : EchoColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Echo (chat) tab ─────────────────────────────────────────────────────

  Widget _buildEchoTab({bool showHeader = true}) {
    return Column(
      children: [
        if (showHeader) SafeArea(bottom: false, child: _buildEchoNavHeader()),
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
                Builder(
                  builder: (context) {
                    final username = AuthService().username;
                    final firstName = username != null && username.isNotEmpty ? username.split(' ').first : null;
                    final loop = EchoLoopState();
                    final rankName = loop.rank?['rank'] as String?;
                    final subtitle = rankName != null && rankName.isNotEmpty
                        ? '${_displayRank(rankName)} - ${firstName != null ? 'hi, $firstName' : 'personal model'}'
                        : firstName != null
                        ? 'hi, $firstName'
                        : 'personal model';
                    return Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost, height: 1.3));
                  },
                ),
              ],
            ),
          ),
          _circleIconButton(Icons.edit_outlined, () {
            final chatProvider = Provider.of<ChatProvider>(context, listen: false);
            chatProvider.startNewChat();
          }),
          const SizedBox(width: 8),
          _circleIconButton(Icons.tune_rounded, () => EchoSettingsSheet.show(context)),
          const SizedBox(width: 8),
          _circleIconButton(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer()),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EchoColors.bgSurface,
          border: Border.all(color: EchoColors.border),
        ),
        child: Icon(icon, size: 16, color: EchoColors.textMuted),
      ),
    );
  }

  // ─── Bottom navigation ────────────────────────────────────────────────────

  String _displayRank(String rank) {
    switch (rank) {
      case 'Genin':
        return 'level 1';
      case 'Chunin':
        return 'level 2';
      case 'Jonin':
        return 'level 3';
      case 'Kage':
        return 'mastery';
      default:
        return rank.toLowerCase();
    }
  }

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
            children: [_navItem(0, 'TALK', _EchoTabIcon.echo), _navItem(1, 'TODAY', _EchoTabIcon.today), _navItem(2, 'YOU', _EchoTabIcon.you)],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, String label, _EchoTabIcon icon) {
    final mobileIndex = _selectedTab > 2 ? 1 : _selectedTab;
    final active = mobileIndex == index;
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
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _icon(_EchoTabIcon icon, Color color) {
    switch (icon) {
      case _EchoTabIcon.echo:
        return _SonarRingsIcon(color: color);
      case _EchoTabIcon.today:
        return Icon(Icons.circle_outlined, size: 21, color: color);
      case _EchoTabIcon.you:
        return Icon(Icons.person_outline_rounded, size: 21, color: color);
    }
  }
}

enum _EchoTabIcon { echo, today, you }

class _DesktopChatPane extends StatelessWidget {
  const _DesktopChatPane();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: ChatPage()),
      ],
    );
  }
}

/// Sonar rings icon — Echo brand mark: center dot + two concentric arcs emanating outward.
class _SonarRingsIcon extends StatelessWidget {
  final Color color;
  const _SonarRingsIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21,
      height: 21,
      child: CustomPaint(painter: _SonarRingsPainter(color: color)),
    );
  }
}

class _SonarRingsPainter extends CustomPainter {
  final Color color;
  const _SonarRingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Center dot
    canvas.drawCircle(Offset(cx, cy), size.width * 0.09, Paint()..color = color);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    // Inner ring
    canvas.drawCircle(Offset(cx, cy), size.width * 0.28, stroke..color = color.withValues(alpha: 0.75));
    // Outer ring
    canvas.drawCircle(Offset(cx, cy), size.width * 0.46, stroke..color = color.withValues(alpha: 0.40));
  }

  @override
  bool shouldRepaint(covariant _SonarRingsPainter old) => old.color != color;
}
