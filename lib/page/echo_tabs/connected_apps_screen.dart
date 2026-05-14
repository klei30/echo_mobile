import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/setting/mcp_server.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ConnectedAppsScreen extends StatelessWidget {
  const ConnectedAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _sectionLabel('READY TO USE'),
            _workflowCard(
              icon: Icons.today_outlined,
              title: 'Daily Brief',
              subtitle: 'Let Talk read your priority, check-in status, and next practice rep.',
              accent: EchoColors.practice,
            ),
            _workflowCard(
              icon: Icons.psychology_alt_outlined,
              title: 'Decision Room',
              subtitle: 'Compare options, surface tradeoffs, and save the lesson afterward.',
              accent: EchoColors.primaryAi,
            ),
            _workflowCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Proof Capture',
              subtitle: 'Turn outcomes, feedback, and project evidence into shareable proof.',
              accent: EchoColors.proof,
            ),
            _workflowCard(
              icon: Icons.hub_outlined,
              title: 'Home Brain',
              subtitle: 'Use your private desktop runtime when your phone is connected.',
              accent: EchoColors.memory,
            ),
            const SizedBox(height: 24),
            _sectionLabel('CONNECTED'),
            _ConnectedList(),
            const SizedBox(height: 20),
            _advancedButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop) ...[_iconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.of(context).pop()), const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected Actions',
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: EchoColors.textPrimary, height: 1.05),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose what Echo can use when it helps you. Keep the technical manager tucked away until you need it.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45, color: EchoColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: EchoColors.textVeryGhost),
      ),
    );
  }

  Widget _workflowCard({required IconData icon, required String title, required String subtitle, required Color accent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EchoColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: EchoColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _advancedButton(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: EchoColors.textSecondary,
        side: BorderSide(color: EchoColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.settings_outlined, size: 17, color: EchoColors.textMuted),
      label: Text('Advanced app manager', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
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
                'Advanced Connections',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
              ),
            ),
            body: const McpServer(),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: EchoColors.bgSurface,
          border: Border.all(color: EchoColors.border),
        ),
        child: Icon(icon, size: 16, color: EchoColors.textMuted),
      ),
    );
  }
}

class _ConnectedList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<McpServerProvider>(
      builder: (context, provider, _) {
        return FutureBuilder<List<String>>(
          future: provider.mcpServers,
          builder: (context, snapshot) {
            final names = snapshot.data ?? const <String>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _emptyState('Checking connections...');
            }
            if (names.isEmpty) {
              return _emptyState('No external apps are connected yet.');
            }
            return Column(
              children: names.map((name) {
                final running = provider.mcpServerIsRunning(name);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: EchoColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EchoColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: running ? EchoColors.practice : EchoColors.textVeryGhost),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: EchoColors.textSecondary),
                        ),
                      ),
                      Text(
                        running ? 'On' : 'Off',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: running ? EchoColors.practice : EchoColors.textGhost),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted)),
    );
  }
}
