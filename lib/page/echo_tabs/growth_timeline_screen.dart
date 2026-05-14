import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_theme.dart';

class GrowthTimelineScreen extends StatefulWidget {
  const GrowthTimelineScreen({super.key});

  @override
  State<GrowthTimelineScreen> createState() => _GrowthTimelineScreenState();
}

class _GrowthTimelineScreenState extends State<GrowthTimelineScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await EchoApiClient().getGrowthTimeline();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final milestones = (_data?['milestones'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final stats = Map<String, dynamic>.from(_data?['stats'] as Map? ?? {});
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: EchoColors.amber))
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
                children: [
                  _header(context),
                  const SizedBox(height: 22),
                  Text(
                    _data?['headline'] as String? ?? 'Proof is still forming.',
                    style: GoogleFonts.lora(fontSize: 22, height: 1.35, fontStyle: FontStyle.italic, color: EchoColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(Icons.flag_outlined, '${stats['milestones'] ?? 0} milestones'),
                      _pill(Icons.bolt_outlined, '${stats['practice_done'] ?? 0} reps'),
                      _pill(Icons.psychology_alt_outlined, '${stats['clone_battles'] ?? 0} practice runs'),
                      _pill(Icons.memory_outlined, '${stats['model_updates'] ?? 0} updates'),
                    ],
                  ),
                  const SizedBox(height: 26),
                  if (milestones.isEmpty) _empty() else ...milestones.reversed.map(_timelineItem),
                ],
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Progress Evidence',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, color: EchoColors.textGhost),
        ),
      ],
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: EchoColors.amber.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Text(
        'The timeline fills when you talk, compare perspectives, complete reps, correct Echo, and update the personal model.',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: EchoColors.textMuted),
      ),
    );
  }

  Widget _timelineItem(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Signal captured';
    final summary = item['summary'] as String? ?? '';
    final date = item['date'] as String? ?? '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(shape: BoxShape.circle, color: EchoColors.amber.withValues(alpha: 0.8)),
              ),
              Expanded(
                child: Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 6), color: EchoColors.borderSubtle),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(summary, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: EchoColors.textMuted)),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textVeryGhost)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
