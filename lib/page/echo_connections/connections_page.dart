import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/provider/composio_provider.dart';

/// Composio-style integration marketplace for Echo.
/// Each connection gives Echo more context about the user's life.
class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  static const _meta = {
    'Gmail': (Icons.mail_outline_rounded, Color(0xFFE85A5A), Color(0xFF1C0808),
        'Who reaches out to you and how often'),
    'Google Calendar': (Icons.calendar_today_outlined, Color(0xFF4A7AE8), Color(0xFF0A0F1C),
        'How you spend time vs. how you say you want to'),
    'Kindle / Reading': (Icons.menu_book_outlined, Color(0xFF7AAA5A), Color(0xFF0A1408),
        'What captures your attention when you choose'),
    'Spotify': (Icons.headphones_outlined, Color(0xFF1DB954), Color(0xFF081408),
        'Your emotional weather, without you having to explain it'),
    'Notion': (Icons.article_outlined, Color(0xFFEAE6E0), Color(0xFF141210),
        'What you\'re working on and thinking through'),
    'GitHub': (Icons.code_outlined, Color(0xFF9A90E8), Color(0xFF0C0A18),
        'What you\'re building and how your focus shifts'),
    'Slack': (Icons.chat_bubble_outline_rounded, Color(0xFF4A5AE8), Color(0xFF0A0C1C),
        'How you communicate at work and who matters'),
    'Twitter / X': (Icons.alternate_email_rounded, Color(0xFF5A9AE8), Color(0xFF080E1C),
        'What ideas you react to and amplify publicly'),
  };

  @override
  Widget build(BuildContext context) {
    final composio = context.watch<ComposioProvider>();

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _buildIntro(),
                  const SizedBox(height: 20),
                  ..._meta.keys.map((name) => _buildItem(name, composio)),
                  const SizedBox(height: 16),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EchoColors.bgSurface,
              border: Border.all(color: EchoColors.border),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 16, color: EchoColors.textMuted),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Connections',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: EchoColors.textPrimary, letterSpacing: -0.3)),
          Text('Give Echo more context',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost)),
        ]),
      ]),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        border: Border.all(color: EchoColors.borderSubtle),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF131009)),
          child: const Icon(Icons.visibility_outlined, size: 15, color: EchoColors.amber),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            "Echo reads these quietly — to understand context, not to report back. You control what it can see.",
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: EchoColors.textMuted, height: 1.55),
          ),
        ),
      ]),
    );
  }

  Widget _buildItem(String name, ComposioProvider composio) {
    final (icon, iconColor, iconBg, desc) = _meta[name]!;
    final isOn = composio.isConnected(name);

    return Column(children: [
      Padding(
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
                      fontSize: 13.5, fontWeight: FontWeight.w500,
                      color: const Color(0xFFC8C4BE))),
              Text(desc,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: const Color(0xFF4A4540), height: 1.4)),
            ]),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => composio.connectToolkit(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: isOn
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                      )
                    : null,
                color: isOn ? null : const Color(0xFF1E1B17),
              ),
              child: Align(
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16, height: 16,
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFEAE6E0)),
                ),
              ),
            ),
          ),
        ]),
      ),
      const Divider(color: Color(0xFF0F0E0C), height: 1),
    ]);
  }

  Widget _buildFooter() {
    return Text(
      'Integrations powered by Composio Managed MCP.',
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2A2520)),
    );
  }
}
