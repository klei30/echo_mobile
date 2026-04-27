import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class EmergenceScreen extends StatefulWidget {
  const EmergenceScreen({super.key});

  @override
  State<EmergenceScreen> createState() => _EmergenceScreenState();
}

class _EmergenceScreenState extends State<EmergenceScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    final data = await EchoApiClient().getEmergence();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _error = data == null;
    });
  }

  static const _gradeColors = [
    Color(0xFF1C1914),
    Color(0xFF2E2A24),
    Color(0xFF4A4438),
    Color(0xFF6A6258),
    Color(0xFF8A8278),
    Color(0xFFB8B2AA),
    Color(0xFFD8D4CE),
  ];

  static const _gradeSizes = [18.0, 17.0, 16.0, 15.0, 16.0, 17.0, 18.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040302),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EchoOrb(size: 40, rings: 3),
          const SizedBox(height: 20),
          Text(
            'Echo is surfacing something...',
            style: GoogleFonts.lora(
              fontSize: 15, fontStyle: FontStyle.italic,
              color: const Color(0xFF3A3530),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Couldn\'t reach Echo.',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: const Color(0xFF3A3530)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _load,
            child: Text('Tap to retry',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: EchoColors.amber)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final phaseLabel = _data?['phase_label'] as String? ?? 'EMERGENCE';
    final rawLines = _data?['lines'] as List? ?? [];
    final climax = _data?['climax'] as String? ?? '';
    final climaxHighlight = _data?['climax_highlight'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: EchoColors.textMuted),
              ),
              const SizedBox(width: 12),
              Text(
                phaseLabel.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: const Color(0xFF2A2520),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 32, 30, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildLines(rawLines),
                const SizedBox(height: 24),
                _buildClimax(climax, climaxHighlight),
                const SizedBox(height: 28),
                _buildCta(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLines(List rawLines) {
    final widgets = <Widget>[];
    for (final entry in rawLines) {
      final text = (entry as List).isNotEmpty ? entry[0] as String : '';
      final grade = entry.length > 1 ? entry[1] as int : 0;

      if (grade == -1 || text.isEmpty) {
        widgets.add(const SizedBox(height: 22));
        continue;
      }
      final color = _gradeColors[grade.clamp(0, 6)];
      final size = _gradeSizes[grade.clamp(0, 6)];
      widgets.add(Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: FontWeight.w300,
          height: 1.9, letterSpacing: -0.2, color: color,
        ),
      ));
    }
    return widgets;
  }

  Widget _buildClimax(String climax, String highlight) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.lora(
          fontSize: 23, fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic, color: const Color(0xFFEAE6E0),
          height: 1.5, letterSpacing: -0.3,
        ),
        children: [
          if (climax.isNotEmpty) TextSpan(text: '$climax\n'),
          TextSpan(
            text: highlight.isNotEmpty ? highlight : '...',
            style: const TextStyle(color: EchoColors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: EchoColors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tell me more',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: EchoColors.amber,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, size: 13, color: EchoColors.amber),
          ],
        ),
      ),
    );
  }
}
