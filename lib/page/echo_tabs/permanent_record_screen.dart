import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/auth_service.dart';

class PermanentRecordScreen extends StatefulWidget {
  const PermanentRecordScreen({super.key});

  @override
  State<PermanentRecordScreen> createState() => _PermanentRecordScreenState();
}

class _PermanentRecordScreenState extends State<PermanentRecordScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;

  static const _topicLabels = {
    'general': 'General',
    'ml': 'ML / AI',
    'coding': 'Coding',
    'research': 'Research',
    'writing': 'Writing',
    'math': 'Math',
    'personal': 'Personal',
    'work': 'Work',
    'language': 'Language',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      EchoApiClient().getUserStats(),
      EchoApiClient().getConfidence(),
    ]);
    if (!mounted) return;
    final conf = results[1];
    setState(() {
      _stats = results[0];
      if (conf != null && conf['topics'] is List) {
        _topics = (conf['topics'] as List)
            .map((t) => Map<String, dynamic>.from(t as Map))
            .toList();
      }
      _loading = false;
    });
  }

  String _topicDesc(double score) {
    if (score >= 0.90) return 'speaks with full authority';
    if (score >= 0.70) return 'pattern clearly your own';
    if (score >= 0.50) return 'voice is forming';
    if (score >= 0.30) return 'still becoming';
    return 'watching and learning';
  }

  String _pct(double score) => '${(score * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final username = AuthService().username ?? 'You';
    final weeksActive = _stats?['weeks_active'] as int? ?? 0;
    final totalPairs = _stats?['total_pairs'] as int? ?? 0;

    final strong = _topics.where((t) => ((t['score'] as num?)?.toDouble() ?? 0) >= 0.40).toList();
    final becoming = _topics.where((t) => ((t['score'] as num?)?.toDouble() ?? 0) < 0.40).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF030201),
      body: SafeArea(
        child: RefreshIndicator(
          color: EchoColors.amber,
          backgroundColor: EchoColors.bgSurface,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: EchoColors.textMuted),
                    ),
                    const SizedBox(width: 10),
                    Text('Permanent Record',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.textPrimary)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'PERMANENT RECORD · ECHO OBSERVED',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2, color: const Color(0xFF4A3A28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: _loading
                    ? Text('...', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textGhost))
                    : RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textMuted, height: 1.6),
                          children: [
                            TextSpan(
                              text: username,
                              style: const TextStyle(color: EchoColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text: ', observed for $weeksActive week${weeksActive == 1 ? '' : 's'}'
                                  ' · $totalPairs conversation${totalPairs == 1 ? '' : 's'}.',
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.lora(fontSize: 18, color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3),
                    children: const [
                      TextSpan(text: 'This is the report\n'),
                      TextSpan(
                        text: 'school never gave you.',
                        style: TextStyle(fontStyle: FontStyle.italic, color: EchoColors.amber),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: EchoColors.amber, strokeWidth: 1.5),
                  ),
                )
              else ...[
                // Strongest in your own work
                if (strong.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'STRONGEST IN YOUR OWN WORK',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: const Color(0xFF4A3A28)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: strong.map((t) {
                        final key = t['topic'] as String? ?? '';
                        final score = (t['score'] as num?)?.toDouble() ?? 0.0;
                        final label = _topicLabels[key] ?? key;
                        return _RecordRow(
                          label: label,
                          score: _pct(score),
                          desc: _topicDesc(score),
                          isStrong: true,
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Where you're still becoming
                if (becoming.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'WHERE YOU\'RE STILL BECOMING',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5, fontWeight: FontWeight.w700,
                          letterSpacing: 1.2, color: const Color(0xFF4A3A28)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      children: becoming.map((t) {
                        final key = t['topic'] as String? ?? '';
                        final score = (t['score'] as num?)?.toDouble() ?? 0.0;
                        final label = _topicLabels[key] ?? key;
                        return _RecordRow(
                          label: label,
                          score: _pct(score),
                          desc: _topicDesc(score),
                          isStrong: false,
                        );
                      }).toList(),
                    ),
                  ),
                ],

                if (_topics.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Text(
                      'Keep talking — Echo is still building your record.',
                      style: GoogleFonts.lora(
                          fontSize: 14, fontStyle: FontStyle.italic,
                          color: EchoColors.textGhost, height: 1.65),
                    ),
                  ),

                // Verdict card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: EchoColors.amber.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(13),
                      border: Border(
                        left: BorderSide(color: EchoColors.amber.withValues(alpha: 0.5), width: 2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ECHO\'S VERDICT · FOR YOU ALONE',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              letterSpacing: 1.1, color: EchoColors.amber.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You didn\'t get a grade. You got a pattern. '
                          'The pattern is more honest than any score. '
                          'This is what you actually are — not what you said you\'d be.',
                          style: GoogleFonts.lora(
                              fontSize: 13, fontStyle: FontStyle.italic,
                              color: EchoColors.textMuted, height: 1.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String label;
  final String score;
  final String desc;
  final bool isStrong;

  const _RecordRow({
    required this.label,
    required this.score,
    required this.desc,
    required this.isStrong,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isStrong
                      ? EchoColors.amber.withValues(alpha: 0.7)
                      : const Color(0xFF5A6AB4).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, fontWeight: FontWeight.w500,
                          color: EchoColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      score,
                      style: GoogleFonts.lora(
                          fontSize: 13, fontStyle: FontStyle.italic,
                          color: isStrong ? EchoColors.amber : EchoColors.textGhost),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: EchoColors.textGhost, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
