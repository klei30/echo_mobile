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
  Map<String, dynamic>? _report;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    final data = await EchoApiClient().getUserReport();
    if (!mounted) return;
    setState(() {
      _report = data;
      _loading = false;
      _error = data == null;
    });
  }

  String _weekLabel() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}';
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
        height: 420,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EchoOrb(size: 40, rings: 2),
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
        height: 420,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Couldn\'t reach Echo.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: EchoColors.textGhost)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _load,
              child: Text('Tap to retry',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, color: EchoColors.amber)),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildContent() {
    final weeks = _report?['weeks'] as int? ?? 0;
    final totalPairs = _report?['total_pairs'] as int? ?? 0;
    final headline = _report?['headline'] as String? ?? '';
    final observations = (_report?['observations'] as List?)
            ?.map((o) => o.toString()).toList() ?? [];
    final sitWithThis = _report?['sit_with_this'] as String? ?? '';
    final rules = (_report?['rules'] as List?)
            ?.map((r) => r.toString()).toList() ?? [];
    final recentMsgs = (_report?['recent_messages'] as List?)
            ?.map((m) => Map<String, dynamic>.from(m as Map)).toList() ?? [];
    final weekCompletions = _report?['week_completions'] as int? ?? 0;
    final avgConf = (_report?['avg_confidence'] as num?)?.toDouble() ?? 0.0;
    final lastTrained = _report?['last_trained'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────────────
          _buildHeader(weeks, totalPairs),
          const SizedBox(height: 24),

          // ─── Headline ─────────────────────────────────────────────
          if (headline.isNotEmpty) ...[
            Text(
              '"$headline"',
              style: GoogleFonts.lora(
                fontSize: 20, fontStyle: FontStyle.italic,
                color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EchoColors.amber.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
          ],

          // ─── This week I noticed ───────────────────────────────────
          if (observations.isNotEmpty) ...[
            _sectionLabel('THIS WEEK I NOTICED'),
            const SizedBox(height: 14),
            ...observations.asMap().entries.map((e) =>
              _observationItem(index: e.key + 1, text: e.value)),
            const SizedBox(height: 20),
          ],

          // ─── Sit with this ────────────────────────────────────────
          if (sitWithThis.isNotEmpty) ...[
            _buildSitWithThis(sitWithThis),
            const SizedBox(height: 20),
          ],

          Container(height: 1, color: EchoColors.borderSubtle),
          const SizedBox(height: 20),

          // ─── Shadow clone status ──────────────────────────────────
          _buildCloneStatus(totalPairs, weeks, avgConf, weekCompletions, lastTrained),
          const SizedBox(height: 20),

          // ─── Behavioral rules ─────────────────────────────────────
          if (rules.isNotEmpty) ...[
            _sectionLabel('YOUR OPERATING SYSTEM'),
            const SizedBox(height: 12),
            ...rules.map((r) => _ruleItem(r)),
            const SizedBox(height: 20),
          ],

          // ─── Recent things you said ───────────────────────────────
          if (recentMsgs.isNotEmpty) ...[
            _sectionLabel('RECENTLY'),
            const SizedBox(height: 12),
            ...recentMsgs.map((m) => _messageItem(m['text'] as String? ?? '')),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(int weeks, int totalPairs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WHAT ECHO SEES',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.2, color: EchoColors.amber,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                weeks > 0 ? 'Week $weeks · ${_weekLabel()}' : _weekLabel(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: EchoColors.textGhost,
                ),
              ),
            ],
          ),
        ),
        if (totalPairs > 0)
          Text(
            '$totalPairs conversations',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5, color: EchoColors.textGhost,
            ),
          ),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 9.5, fontWeight: FontWeight.w700,
        letterSpacing: 1.0, color: EchoColors.textGhost,
      ),
    );
  }

  Widget _observationItem({required int index, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            index.toString().padLeft(2, '0'),
            style: GoogleFonts.lora(
              fontSize: 11, fontStyle: FontStyle.italic,
              color: EchoColors.amber, letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, height: 1.7, color: EchoColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSitWithThis(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.lora(
              fontSize: 14, fontStyle: FontStyle.italic,
              height: 1.65, color: EchoColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloneStatus(int totalPairs, int weeks, double avgConf,
      int weekCompletions, String? lastTrained) {
    final clonePct = (avgConf * 100).round();
    final trained = lastTrained != null
        ? _formatDate(lastTrained)
        : 'Not yet';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: EchoColors.amber),
              ),
              const SizedBox(width: 7),
              Text(
                'SHADOW CLONE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.0, color: const Color(0xFF7A5A30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$totalPairs conversations · $weeks week${weeks == 1 ? '' : 's'} · still learning.',
            style: GoogleFonts.lora(
              fontSize: 13, fontStyle: FontStyle.italic,
              color: EchoColors.textMuted, height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week\'s practice',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10, color: EchoColors.textGhost)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(7, (i) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < weekCompletions
                                ? EchoColors.amber
                                : const Color(0xFF1A1815),
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Avg confidence',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, color: EchoColors.textGhost)),
                  const SizedBox(height: 2),
                  Text(
                    clonePct > 0 ? '$clonePct%' : '—',
                    style: GoogleFonts.lora(
                      fontSize: 16, fontStyle: FontStyle.italic,
                      color: EchoColors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last trained · $trained',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10, color: EchoColors.textVeryGhost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [EchoColors.amber, Colors.transparent],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rule,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, height: 1.65, color: EchoColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '"${text.trim()}"',
        style: GoogleFonts.lora(
          fontSize: 12.5, fontStyle: FontStyle.italic,
          height: 1.6, color: EchoColors.textGhost,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return 'Unknown';
    }
  }
}
