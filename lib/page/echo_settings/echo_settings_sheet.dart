import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/auth_service.dart';

/// Stripped-down mobile settings sheet — hides all technical LLM/MCP
/// complexity and shows only what Echo users care about.
class EchoSettingsSheet extends StatefulWidget {
  const EchoSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EchoSettingsSheet(),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: EchoColors.bgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: EchoColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Settings',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: EchoColors.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 24),

              // ── Account ────────────────────────────────────────────────
              _sectionLabel('ACCOUNT'),
              _settingTile(
                label: AuthService().username ?? 'Your account',
                sub: AuthService().isLoggedIn ? AuthService().userId ?? '' : 'Not signed in',
                trailing: GestureDetector(
                  onTap: () async {
                    await AuthService().logout();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text('Sign out',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: const Color(0xFF8A5050))),
                ),
              ),

              const SizedBox(height: 20),

              // ── Echo Behaviour ─────────────────────────────────────────
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

              const SizedBox(height: 20),

              // ── Privacy ─────────────────────────────────────────────────
              _sectionLabel('PRIVACY'),
              _settingTile(
                label: 'Your data',
                sub: 'Runs on your private Echo instance.\nMessages encrypted in transit.',
                trailing: const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF3A3530)),
              ),
              _settingTile(
                label: 'Reset memory',
                sub: 'Clear all Echo\'s observations about you',
                trailing: GestureDetector(
                  onTap: () => _confirmReset(context),
                  child: Text('Reset',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: const Color(0xFF7A5A38))),
                ),
              ),

              const SizedBox(height: 20),

              // ── About ───────────────────────────────────────────────────
              _sectionLabel('ABOUT'),
              _settingTile(
                label: 'Echo',
                sub: 'Your shadow clone · version 1.0',
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: const Color(0xFF3A3530))),
    );
  }

  Widget _settingTile({required String label, required String sub, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: EchoColors.borderSubtle))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w500, color: EchoColors.textSecondary)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5, color: const Color(0xFF4A4540), height: 1.5)),
            ],
          ]),
        ),
        trailing,
      ]),
    );
  }

  Widget _toggleTile({
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _settingTile(
      label: label, sub: sub,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EchoColors.bgCard,
        title: Text('Reset Echo memory?',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: EchoColors.textPrimary)),
        content: Text('This will clear all of Echo\'s observations. Your conversations are kept.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // TODO: call echo backend reset endpoint
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memory reset requested')),
              );
            },
            child: Text('Reset',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8A5050))),
          ),
        ],
      ),
    );
  }
}
