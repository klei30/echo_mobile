import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/main.dart';
import 'package:chatmcp/page/echo_tabs/connected_apps_screen.dart';
import 'package:chatmcp/page/echo_tabs/home_brain_screen.dart';
import 'package:chatmcp/page/echo_tabs/local_model_setup_screen.dart';
import 'package:chatmcp/page/setting/setting.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EchoSettingsSheet extends StatefulWidget {
  const EchoSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EchoSettingsSheet(), fullscreenDialog: true));
  }

  @override
  State<EchoSettingsSheet> createState() => _EchoSettingsSheetState();
}

class _EchoSettingsSheetState extends State<EchoSettingsSheet> {
  static const _kMemory = 'echo_setting_memory';
  static const _kProactive = 'echo_setting_proactive';
  static const _kVoice = 'echo_setting_voice';

  bool _memoryEnabled = true;
  bool _proactiveEnabled = true;
  bool _voiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _memoryEnabled = prefs.getBool(_kMemory) ?? true;
      _proactiveEnabled = prefs.getBool(_kProactive) ?? true;
      _voiceEnabled = prefs.getBool(_kVoice) ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: EchoColors.bg,
          appBar: AppBar(
            backgroundColor: EchoColors.bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: EchoColors.textMuted),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: EchoColors.borderNav),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              _accountCard(),
              const SizedBox(height: 20),
              _sectionLabel('APPEARANCE'),
              _appearanceCard(settings),
              const SizedBox(height: 20),
              _sectionLabel('ECHO'),
              _switchRow(
                icon: Icons.memory_rounded,
                title: 'Memory',
                subtitle: 'Use your past outcomes and notes when Talk answers.',
                value: _memoryEnabled,
                onChanged: (value) {
                  setState(() => _memoryEnabled = value);
                  _saveBool(_kMemory, value);
                },
              ),
              _switchRow(
                icon: Icons.notifications_active_outlined,
                title: 'Proactive help',
                subtitle: 'Allow reminders when a practice rep, outcome, or opportunity needs attention.',
                value: _proactiveEnabled,
                onChanged: (value) {
                  setState(() => _proactiveEnabled = value);
                  _saveBool(_kProactive, value);
                },
              ),
              _switchRow(
                icon: Icons.graphic_eq_rounded,
                title: 'Voice session',
                subtitle: 'Show the mic button for tap-to-start listening. Background listening stays off.',
                value: _voiceEnabled,
                onChanged: (value) {
                  setState(() => _voiceEnabled = value);
                  _saveBool(_kVoice, value);
                },
              ),
              const SizedBox(height: 20),
              _sectionLabel('CONNECTIONS'),
              _navRow(
                icon: Icons.offline_bolt_outlined,
                title: 'Where Echo Thinks',
                subtitle: 'Offline Gemma, local memory, and connection status.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LocalModelSetupScreen())),
              ),
              _navRow(
                icon: Icons.hub_outlined,
                title: 'Home Brain',
                subtitle: 'Connect this phone to your private desktop brain.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeBrainScreen())),
              ),
              _navRow(
                icon: Icons.extension_outlined,
                title: 'Connected Actions',
                subtitle: 'Control useful actions Echo can use from Talk.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectedAppsScreen())),
              ),
              const SizedBox(height: 20),
              _sectionLabel('PRIVACY'),
              _navRow(
                icon: Icons.lock_outline_rounded,
                title: 'Private by default',
                subtitle: 'Cloud, Home Brain, and on-device modes are shown before sensitive work runs.',
                onTap: () {},
                showArrow: false,
              ),
              _actionRow(
                icon: Icons.delete_outline_rounded,
                title: 'Reset Echo memory',
                subtitle: 'Clear Echo observations while keeping your conversations.',
                label: 'Reset',
                onTap: () => _confirmReset(context),
              ),
              const SizedBox(height: 20),
              _sectionLabel('ADVANCED'),
              _navRow(
                icon: Icons.tune_rounded,
                title: 'Advanced settings',
                subtitle: 'Model keys, sync, network, and connection manager.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingPage())),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text('Echo mobile app', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textVeryGhost)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _accountCard() {
    final signedIn = AuthService().isLoggedIn;
    final username = AuthService().username;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: EchoColors.primaryAi.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.person_outline_rounded, color: EchoColors.primaryAi, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username?.isNotEmpty == true ? username! : 'Your Echo',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(signedIn ? 'Signed in' : 'Not signed in', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textMuted)),
              ],
            ),
          ),
          if (signedIn)
            TextButton(
              onPressed: () => _confirmSignOut(context),
              child: Text('Sign out', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _appearanceCard(SettingsProvider settings) {
    final current = settings.generalSetting.theme;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: EchoColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          _themeOption(settings, current, 'system', Icons.brightness_auto_outlined, 'Auto'),
          _themeOption(settings, current, 'light', Icons.wb_sunny_outlined, 'Light'),
          _themeOption(settings, current, 'dark', Icons.nightlight_outlined, 'Dark'),
        ],
      ),
    );
  }

  Widget _themeOption(SettingsProvider settings, String current, String value, IconData icon, String label) {
    final selected = current == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => settings.updateGeneralSettingsPartially(theme: value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? EchoColors.primaryAi.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? EchoColors.primaryAi.withValues(alpha: 0.35) : Colors.transparent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? EchoColors.primaryAi : EchoColors.textMuted),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? EchoColors.primaryAi : EchoColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: EchoColors.textVeryGhost),
      ),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _baseRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }

  Widget _navRow({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool showArrow = true}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: _baseRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: showArrow ? Icon(Icons.chevron_right_rounded, color: EchoColors.textGhost) : const SizedBox.shrink(),
      ),
    );
  }

  Widget _actionRow({required IconData icon, required String title, required String subtitle, required String label, required VoidCallback onTap}) {
    return _baseRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: TextButton(
        onPressed: onTap,
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _baseRow({required IconData icon, required String title, required String subtitle, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      decoration: BoxDecoration(
        color: EchoColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: EchoColors.primaryAi.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 18, color: EchoColors.primaryAi),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.35, color: EchoColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EchoColors.bgCard,
        title: Text(
          'Sign out?',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
        ),
        content: Text('You will need to sign in again to use Echo.', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              ChatProvider().clearOnLogout();
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => AuthGate()), (_) => false);
              }
            },
            child: Text('Sign out', style: GoogleFonts.plusJakartaSans(color: EchoColors.risk)),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EchoColors.bgCard,
        title: Text(
          'Reset Echo memory?',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
        ),
        content: Text(
          "This clears Echo's observations about you. Conversations stay available.",
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory reset requested')));
            },
            child: Text('Reset', style: GoogleFonts.plusJakartaSans(color: EchoColors.risk)),
          ),
        ],
      ),
    );
  }
}
