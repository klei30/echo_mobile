import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/provider/chat_provider.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';
import 'package:chatmcp/page/setting/mcp_server.dart';
import 'package:chatmcp/main.dart';

class EchoSettingsSheet extends StatefulWidget {
  const EchoSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EchoSettingsSheet(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<EchoSettingsSheet> createState() => _EchoSettingsSheetState();
}

class _EchoSettingsSheetState extends State<EchoSettingsSheet> {
  bool _memoryEnabled = true;
  bool _proactiveEnabled = true;
  bool _voiceEnabled = true;

  static const _kMemory = 'echo_setting_memory';
  static const _kProactive = 'echo_setting_proactive';
  static const _kVoice = 'echo_setting_voice';

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

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: AppBar(
        backgroundColor: EchoColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: EchoColors.textMuted),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: EchoColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: EchoColors.borderNav),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        children: [

          // ── Account ──────────────────────────────────────────────────────
          _sectionLabel('ACCOUNT'),
          _settingTile(
            label: AuthService().username ?? 'Your account',
            sub: AuthService().isLoggedIn
                ? AuthService().userId ?? 'Signed in'
                : 'Not signed in',
            trailing: GestureDetector(
              onTap: () => _confirmSignOut(context),
              child: Text(
                'Sign out',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF8A5050)),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Echo Behaviour ────────────────────────────────────────────────
          _sectionLabel('ECHO BEHAVIOUR'),
          _toggleTile(
            label: 'Memory',
            sub: 'Echo references past conversations',
            value: _memoryEnabled,
            onChanged: (v) {
              setState(() => _memoryEnabled = v);
              _saveSetting(_kMemory, v);
            },
          ),
          _toggleTile(
            label: 'Proactive messages',
            sub: 'Echo can reach out without being asked',
            value: _proactiveEnabled,
            onChanged: (v) {
              setState(() => _proactiveEnabled = v);
              _saveSetting(_kProactive, v);
            },
          ),
          _toggleTile(
            label: 'Voice mode',
            sub: 'Real-time voice conversation',
            value: _voiceEnabled,
            onChanged: (v) {
              setState(() => _voiceEnabled = v);
              _saveSetting(_kVoice, v);
            },
          ),
          const SizedBox(height: 28),

          // ── Notifications ─────────────────────────────────────────────────
          _sectionLabel('NOTIFICATIONS'),
          _settingTile(
            label: 'Evening Signal',
            sub: 'Daily check-in at 7:00 PM · 3 questions, 5 minutes',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: EchoColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: EchoColors.amber.withValues(alpha: 0.3)),
              ),
              child: Text(
                'On',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: EchoColors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Connected Tools ───────────────────────────────────────────────
          _sectionLabel('CONNECTED TOOLS'),
          _buildMcpConnections(context),
          const SizedBox(height: 8),
          _settingTile(
            label: 'Add connection',
            sub: 'Connect custom MCP tools',
            trailing: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: EchoColors.bg,
                    appBar: AppBar(
                      backgroundColor: EchoColors.bg,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: EchoColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text('Connected Tools',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: EchoColors.textPrimary)),
                    ),
                    body: const McpServer(),
                  ),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 18, color: EchoColors.amber),
            ),
          ),
          const SizedBox(height: 28),

          // ── Privacy ───────────────────────────────────────────────────────
          _sectionLabel('PRIVACY'),
          _settingTile(
            label: 'Your data',
            sub: 'Runs on your private Echo instance.\nMessages encrypted in transit.',
            trailing: const Icon(Icons.lock_outline_rounded,
                size: 16, color: Color(0xFF3A3530)),
          ),
          _settingTile(
            label: 'Reset memory',
            sub: "Clear all Echo's observations about you",
            trailing: GestureDetector(
              onTap: () => _confirmReset(context),
              child: Text(
                'Reset',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF7A5A38)),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── About ─────────────────────────────────────────────────────────
          _sectionLabel('ABOUT'),
          _settingTile(
            label: 'Echo',
            sub: 'Your shadow clone · version 1.0',
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMcpConnections(BuildContext context) {
    return Consumer<McpServerProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<String>>(
          future: provider.mcpServers,
          builder: (context, snap) {
            final servers = snap.data ?? [];
            if (servers.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'No tools connected yet.',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: EchoColors.textVeryGhost),
                ),
              );
            }
            return Column(
              children: servers.map((name) {
                final running = provider.mcpServerIsRunning(name);
                return _settingTile(
                  label: name,
                  sub: running ? 'Connected' : 'Disconnected',
                  trailing: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: running
                          ? const Color(0xFF4CAF50)
                          : EchoColors.textVeryGhost,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: EchoColors.textVeryGhost,
        ),
      ),
    );
  }

  Widget _settingTile({
    required String label,
    required String sub,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EchoColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: EchoColors.textSecondary,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: EchoColors.textVeryGhost,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _settingTile(
      label: label,
      sub: sub,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EchoColors.bgCard,
        title: Text(
          'Sign out?',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EchoColors.textPrimary),
        ),
        content: Text(
          'You will need to sign in again to use Echo.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: EchoColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: EchoColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              ChatProvider().clearOnLogout();
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => AuthGate()),
                  (_) => false,
                );
              }
            },
            child: Text('Sign out',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8A5050))),
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
          style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: EchoColors.textPrimary),
        ),
        content: Text(
          "This will clear all of Echo's observations. Your conversations are kept.",
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: EchoColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(
                    color: EchoColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Memory reset requested')),
                );
              }
            },
            child: Text('Reset',
                style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF8A5050))),
          ),
        ],
      ),
    );
  }
}
