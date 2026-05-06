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
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_offline_memory_service.dart';
import 'package:chatmcp/echo/echo_offline_queue.dart';
import 'package:chatmcp/echo/echo_runtime_service.dart';
import 'package:chatmcp/echo/notification_service.dart';
import 'package:chatmcp/page/echo_tabs/home_brain_screen.dart';
import 'package:chatmcp/page/echo_tabs/ask_screen.dart';
import 'package:chatmcp/page/echo_tabs/local_model_setup_screen.dart';
import 'package:chatmcp/page/echo_tabs/opportunities_screen.dart';
import 'package:chatmcp/page/echo_tabs/proof_builder_screen.dart';

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
      // After onboarding check, seed skills and proof if the backend is reachable.
      if (AuthService().isLoggedIn && !EchoRuntimeService().isDevice) {
        _autoSeedIfNeeded();
      }
    });
  }

  Future<void> _autoSeedIfNeeded() async {
    try {
      // These endpoints are idempotent — safe to call every startup.
      await Future.wait([
        EchoApiClient().triggerSkillExtraction(),
        EchoApiClient().triggerProofSeed(),
      ]);
    } catch (_) {}
  }

  Future<void> _openRuntimePanel() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalModelSetupScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _openEchoContextSheet() async {
    await EchoLoopState().refresh();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EchoContextSheet(
        onOpenRuntime: () {
          Navigator.of(context).pop();
          _openRuntimePanel();
        },
        onOpenToday: () {
          Navigator.of(context).pop();
          setState(() => _selectedTab = 1);
        },
        onOpenDecision: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AskScreen()));
        },
        onOpenProof: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProofBuilderScreen()));
        },
      ),
    );
    if (mounted) setState(() {});
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
      // Upload any offline conversations when the app comes back to foreground
      // and the user is connected to their backend (not in offline device mode).
      if (AuthService().isLoggedIn && !EchoRuntimeService().isDevice) {
        EchoOfflineQueue().flush();
      }
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
                      _desktopNavItem(0, 'Coach', Icons.chat_bubble_outline_rounded),
                      _desktopNavItem(1, 'Today', Icons.circle_outlined),
                      _desktopNavItem(2, 'Passport', Icons.assignment_ind_outlined),
                      _desktopNavItem(3, 'Proof', Icons.workspace_premium_outlined),
                      const SizedBox(height: 4),
                      const Divider(color: EchoColors.borderNav, height: 12),
                      _desktopNavItem(4, 'Improve Echo', Icons.model_training_rounded),
                      _desktopNavItem(5, 'Home Brain', Icons.hub_rounded),
                      _desktopNavItem(6, 'Sync', Icons.sync_rounded),
                      _desktopNavItem(7, 'Tools', Icons.extension_rounded),
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
                _ProofDesktopPane(),
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
                        : 'private mentor';
                    return Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost, height: 1.3));
                  },
                ),
                const SizedBox(height: 5),
                _RuntimeStatusPill(onTap: _openEchoContextSheet),
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
            children: [_navItem(0, 'COACH', _EchoTabIcon.echo), _navItem(1, 'TODAY', _EchoTabIcon.today), _navItem(2, 'PASSPORT', _EchoTabIcon.you)],
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
        return Icon(Icons.assignment_ind_outlined, size: 21, color: color);
    }
  }
}

class _RuntimeStatusPill extends StatelessWidget {
  final VoidCallback onTap;

  const _RuntimeStatusPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final runtime = EchoRuntimeService();
    final memory = EchoOfflineMemoryService();
    return ListenableBuilder(
      listenable: runtime,
      builder: (context, _) {
        return FutureBuilder<int>(
          future: EchoOfflineQueue().pendingPairCount,
          builder: (context, snapshot) {
            final pendingPairs = snapshot.data ?? 0;
            return GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: EchoColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(runtime.mode), size: 12, color: EchoColors.amber),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${runtime.modeLabel} - ${_detail(runtime, memory, pendingPairs)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost, height: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static IconData _iconFor(EchoRuntimeMode mode) {
    return switch (mode) {
      EchoRuntimeMode.desktop => Icons.hub_rounded,
      EchoRuntimeMode.cloud => Icons.cloud_rounded,
      EchoRuntimeMode.device => Icons.phone_android_rounded,
    };
  }

  static String _detail(EchoRuntimeService runtime, EchoOfflineMemoryService memory, int pendingPairs) {
    if (runtime.isDevice) {
      final memoryState = memory.hasPack ? 'memory synced' : 'sync memory';
      final queued = pendingPairs > 0 ? ', $pendingPairs queued' : '';
      return '$memoryState$queued';
    }
    if (runtime.isDesktop) {
      return pendingPairs > 0 ? '$pendingPairs queued to upload' : 'Wi-Fi or tunnel';
    }
    return pendingPairs > 0 ? '$pendingPairs queued to upload' : 'online fallback';
  }
}

class _EchoContextSheet extends StatelessWidget {
  final VoidCallback onOpenRuntime;
  final VoidCallback onOpenToday;
  final VoidCallback onOpenDecision;
  final VoidCallback onOpenProof;

  const _EchoContextSheet({
    required this.onOpenRuntime,
    required this.onOpenToday,
    required this.onOpenDecision,
    required this.onOpenProof,
  });

  @override
  Widget build(BuildContext context) {
    final runtime = EchoRuntimeService();
    final memory = EchoOfflineMemoryService();
    final loop = EchoLoopState();
    final thesis = loop.thesis;
    final priority = loop.todayPriority;
    final practice = loop.practice;
    final thesisTitle = thesis?['title'] as String? ?? 'Current Read is still forming';
    final thesisBody = thesis?['statement'] as String? ?? 'Echo will use what you share in Talk, Today, and Passport.';
    final priorityTitle = priority?['title'] as String? ?? 'No priority loaded yet';
    final priorityBody = priority?['body'] as String? ?? 'Open Today to refresh your next useful step.';
    final practiceTitle = practice?['rep_title'] as String? ?? 'No practice rep loaded yet';
    final practiceBody = practice?['rep_instruction'] as String? ?? 'Echo will suggest a small rep when enough context exists.';

    return Container(
      decoration: const BoxDecoration(
        color: EchoColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: FutureBuilder<int>(
            future: EchoOfflineQueue().pendingPairCount,
            builder: (context, snapshot) {
              final pendingPairs = snapshot.data ?? 0;
              final memoryLabel = runtime.isDevice
                  ? memory.hasPack
                      ? 'Synced memory pack${memory.exportedAt.isEmpty ? '' : ' - ${memory.exportedAt}'}'
                      : 'No synced memory pack yet'
                  : 'Full Echo memory through ${runtime.modeLabel}';
              final scopeLabel = runtime.isDevice
                  ? 'Offline scope: no MCP tools, no training, no live backend. New chat pairs sync later.'
                  : pendingPairs > 0
                      ? '$pendingPairs offline pairs ready to upload into Echo training.'
                      : 'Connected scope: memory, Today, Passport, tools, and training can stay in sync.';

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: EchoColors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.radar_rounded, color: EchoColors.amber, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Echo is using', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: EchoColors.textPrimary)),
                            const SizedBox(height: 3),
                            Text('${runtime.modeLabel} - ${_RuntimeStatusPill._detail(runtime, memory, pendingPairs)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: EchoColors.textGhost),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ContextInfoRow(icon: Icons.psychology_alt_outlined, label: 'Current Read', title: thesisTitle, body: thesisBody),
                  _ContextInfoRow(icon: Icons.flag_outlined, label: 'Today', title: priorityTitle, body: priorityBody),
                  _ContextInfoRow(icon: Icons.fitness_center_rounded, label: 'Practice', title: practiceTitle, body: practiceBody),
                  _ContextInfoRow(icon: Icons.storage_rounded, label: 'Memory', title: memoryLabel, body: scopeLabel),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ContextAction(icon: Icons.play_arrow_rounded, label: 'Work on priority', onTap: onOpenToday),
                      _ContextAction(icon: Icons.repeat_rounded, label: 'Practice rep', onTap: onOpenToday),
                      _ContextAction(icon: Icons.psychology_rounded, label: 'Decision Room', onTap: onOpenDecision),
                      _ContextAction(icon: Icons.inventory_2_outlined, label: 'Build proof', onTap: onOpenProof),
                      _ContextAction(icon: Icons.tune_rounded, label: 'Runtime', onTap: onOpenRuntime),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ContextInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String body;

  const _ContextInfoRow({required this.icon, required this.label, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: EchoColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: EchoColors.amber)),
                const SizedBox(height: 5),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: EchoColors.textPrimary, height: 1.3)),
                const SizedBox(height: 4),
                Text(body, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContextAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: EchoColors.textPrimary,
        side: const BorderSide(color: EchoColors.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

enum _EchoTabIcon { echo, today, you }

class _DesktopChatPane extends StatelessWidget {
  const _DesktopChatPane();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Expanded(child: ChatPage())]);
  }
}

class _ProofDesktopPane extends StatelessWidget {
  const _ProofDesktopPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EchoColors.bg,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          children: [
            Text(
              'Proof',
              style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'Turn practice, decisions, shipped work, and feedback into evidence that can unlock jobs, school, scholarships, projects, or personal goals.',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.55, color: EchoColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _ProofActionCard(
                  icon: Icons.add_task_rounded,
                  title: 'Build proof',
                  body: 'Save outcomes, artifacts, practice wins, decisions, and feedback into a useful evidence trail.',
                  action: 'Open Proof Builder',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProofBuilderScreen())),
                ),
                _ProofActionCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Find opportunities',
                  body: 'Map your current evidence to practical next steps and see what proof is still missing.',
                  action: 'Open Opportunities',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OpportunitiesScreen())),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 920),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EchoColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sync_alt_rounded, color: EchoColors.amber, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'The loop',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Today gives a small practice rep. Echo captures the outcome. Proof Builder saves the evidence. Opportunities show where that evidence can be used next.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.55, color: EchoColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;

  const _ProofActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Material(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EchoColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: EchoColors.amber),
                const SizedBox(height: 16),
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: EchoColors.textPrimary)),
                const SizedBox(height: 8),
                Text(body, style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: EchoColors.textMuted)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      action,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: EchoColors.amber),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: EchoColors.amber),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
