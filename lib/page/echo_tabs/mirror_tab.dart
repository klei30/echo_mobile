import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class MirrorTab extends StatefulWidget {
  const MirrorTab({super.key});

  @override
  State<MirrorTab> createState() => _MirrorTabState();
}

class _MirrorTabState extends State<MirrorTab> {
  Map<String, dynamic>? _mirror;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    final data = await EchoApiClient().getWeeklyMirror();
    if (!mounted) return;
    setState(() {
      _mirror = data;
      _loading = false;
      _error = data == null;
    });
  }

  String _headerDate() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    final dayName = days[now.weekday - 1];
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$dayName · ${months[now.month - 1]} ${now.day} · $h:${m}pm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: EchoColors.amber,
          backgroundColor: EchoColors.bgSurface,
          onRefresh: _load,
          child: _loading
              ? _buildLoading()
              : _error
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(children: [
      SizedBox(
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EchoOrb(size: 36, rings: 2),
            const SizedBox(height: 18),
            Text(
              'Echo is reflecting...',
              style: GoogleFonts.lora(
                fontSize: 15, fontStyle: FontStyle.italic,
                color: EchoColors.textGhost,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildError() {
    return ListView(children: [
      SizedBox(
        height: 400,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Couldn\'t reach Echo.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _load,
              child: Text(
                'Tap to retry',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: EchoColors.amber),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildContent() {
    final headline = _mirror?['headline'] as String? ?? '';
    final observations = (_mirror?['observations'] as List?)
            ?.map((o) => o.toString())
            .toList() ??
        [];
    final sitWithThis = _mirror?['sit_with_this'] as String? ?? '';
    final experiment = _mirror?['experiment'] as String? ?? '';
    final weekNumber = _mirror?['week_number'] as int? ?? 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(weekNumber),
          const SizedBox(height: 20),
          _buildKicker(),
          const SizedBox(height: 14),
          _buildHeadline(headline),
          const SizedBox(height: 24),
          _buildSectionLabel('WHAT I NOTICED'),
          const SizedBox(height: 12),
          ...observations.asMap().entries.map((e) => _mirrorItem(
                highlighted: e.key < 2,
                text: e.value,
              )),
          const SizedBox(height: 16),
          if (sitWithThis.isNotEmpty) _buildSitWithThis(sitWithThis),
          if (sitWithThis.isNotEmpty) const SizedBox(height: 10),
          if (experiment.isNotEmpty) _buildExperiment(experiment),
        ],
      ),
    );
  }

  Widget _buildHeader(int weekNumber) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Mirror',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: EchoColors.textPrimary, letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _headerDate(),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5, color: EchoColors.textGhost),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: EchoColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EchoColors.border),
          ),
          child: Text(
            'Wk $weekNumber',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: EchoColors.amberText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKicker() {
    return Row(
      children: [
        Text(
          'THIS WEEK\'S REFLECTION',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5, fontWeight: FontWeight.w700,
            letterSpacing: 1.2, color: const Color(0xFF5A4A38),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: EchoColors.borderSubtle)),
      ],
    );
  }

  Widget _buildHeadline(String text) {
    return Text(
      text.isEmpty ? 'Echo is watching.' : text,
      style: GoogleFonts.lora(
        fontSize: 21, fontStyle: FontStyle.italic,
        height: 1.5, letterSpacing: -0.2,
        color: EchoColors.textPrimary,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 9.5, fontWeight: FontWeight.w700,
        letterSpacing: 1.0, color: EchoColors.textGhost,
      ),
    );
  }

  Widget _mirrorItem({required bool highlighted, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: highlighted
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [EchoColors.amber, Colors.transparent],
                      )
                    : null,
                color: highlighted ? null : EchoColors.borderSubtle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, height: 1.68,
                  color: EchoColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSitWithThis(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIT WITH THIS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: EchoColors.amber,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 13, fontStyle: FontStyle.italic,
              height: 1.72, color: const Color(0xFFA8A4A0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperiment(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS WEEK\'S EXPERIMENT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: EchoColors.textGhost,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5, height: 1.55,
              color: EchoColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
