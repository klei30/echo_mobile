import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_orb.dart';
import 'package:chatmcp/page/echo_connections/connections_page.dart';
import 'package:chatmcp/page/echo_tabs/emergence_screen.dart';
import 'package:chatmcp/page/echo_tabs/nightly_training_screen.dart';
import 'package:chatmcp/page/echo_tabs/experiment_screen.dart';
import 'package:chatmcp/page/echo_tabs/after_meeting_screen.dart';
import 'package:chatmcp/page/echo_tabs/anniversary_screen.dart';

class YouTab extends StatefulWidget {
  const YouTab({super.key});

  @override
  State<YouTab> createState() => _YouTabState();
}

class _YouTabState extends State<YouTab> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _topics = [];
  bool _loading = true;

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
    setState(() {
      _stats = results[0];
      final conf = results[1];
      if (conf != null && conf['topics'] is List) {
        _topics = (conf['topics'] as List)
            .map((t) => Map<String, dynamic>.from(t as Map))
            .toList();
      }
      _loading = false;
    });
  }

  static const _topicLabels = {
    'general': 'General',
    'ml': 'ML / AI',
    'coding': 'Coding',
    'research': 'Research',
    'writing': 'Writing',
    'math': 'Math',
  };

  static const _topicColors = {
    'general': Color(0xFFC4783A),
    'ml': Color(0xFF5A6AB4),
    'coding': Color(0xFF4A82D4),
    'research': Color(0xFF4A5AA4),
    'writing': Color(0xFF5A9A6A),
    'math': Color(0xFF8A5AB4),
  };

  String _formatLastTrained(String? iso) {
    if (iso == null) return 'Never';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day} · $h:$m';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _monthYear() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _shortDate() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final username = AuthService().username ?? 'You';
    final totalPairs = _stats?['total_pairs'] as int? ?? 0;
    final weeksActive = _stats?['weeks_active'] as int? ?? 0;
    final patternsFound = _stats?['patterns_found'] as int? ?? 0;
    final lastTrained = _formatLastTrained(_stats?['last_trained'] as String?);

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: EchoColors.amber,
          backgroundColor: EchoColors.bgSurface,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ─── Portrait header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Portrait',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: EchoColors.textPrimary, letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Cognitive fingerprint · ${_monthYear()}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5, color: EchoColors.textGhost),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      username,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: EchoColors.textPrimary, letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      _loading
                          ? '...'
                          : '$weeksActive week${weeksActive == 1 ? '' : 's'} · '
                            '$totalPairs conversation${totalPairs == 1 ? '' : 's'} · '
                            '$patternsFound pattern${patternsFound == 1 ? '' : 's'} found',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: EchoColors.textGhost),
                    ),
                  ],
                ),
              ),
              // ─── Constellation ────────────────────────────────────────
              SizedBox(
                height: 260,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: CustomPaint(
                    painter: _ConstellationPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // ─── Quote ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: _buildQuote(),
              ),
              // ─── Shadow Clone status ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _buildShadowClone(lastTrained, totalPairs),
              ),
              // ─── Connections ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _buildConnections(context),
              ),
              // ─── Moments & Milestones ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
                child: Text(
                  'MOMENTS & MILESTONES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.0, color: EchoColors.textGhost,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: _buildMomentCard(
                  context,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: EchoColors.amber,
                  label: 'Emergence',
                  sub: patternsFound > 0
                      ? '$patternsFound pattern${patternsFound == 1 ? '' : 's'} found · tap to see'
                      : 'Keep chatting — patterns are forming',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergenceScreen()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _buildMomentCard(
                  context,
                  icon: Icons.nights_stay_rounded,
                  iconColor: EchoColors.indigo,
                  label: 'Nightly Training',
                  sub: lastTrained != 'Never'
                      ? 'Last trained $lastTrained'
                      : 'No training yet — keep chatting',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NightlyTrainingScreen()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _buildMomentCard(
                  context,
                  icon: Icons.science_outlined,
                  iconColor: const Color(0xFF6A9A7A),
                  label: 'Active Experiment',
                  sub: 'Speak without hedging · Day 3 of 7',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExperimentCheckinScreen(
                        experiment: const EchoExperiment(
                          number: 5,
                          trigger: 'You had the right answer **three times** today and started each with "I think" or "maybe."',
                          hypothesis: 'You\'re not missing confidence. You\'re performing uncertainty you don\'t have.',
                          title: 'Speak without hedging. Just once a day.',
                          body: 'Once a day — in a meeting, a message, or a conversation — say your point **without "I think," "maybe," or "I could be wrong."**\n\nNot every time. Just once. See what happens to the room. See what happens to you.\n\n**I predict:** people will respond to you differently.',
                          followup: 'I\'ll check in every 2 days.',
                          durationDays: 7,
                          currentDay: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _buildMomentCard(
                  context,
                  icon: Icons.groups_outlined,
                  iconColor: const Color(0xFF7A5A30),
                  label: 'After Meeting',
                  sub: 'Echo was listening · product call',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AfterMeetingScreen()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: _buildMomentCard(
                  context,
                  icon: Icons.celebration_outlined,
                  iconColor: EchoColors.amber,
                  label: 'Your Journey',
                  sub: '$totalPairs conversation${totalPairs == 1 ? '' : 's'} · $patternsFound pattern${patternsFound == 1 ? '' : 's'} found',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AnniversaryScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          border: Border.all(color: EchoColors.borderSubtle),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, fontWeight: FontWeight.w500,
                      color: EchoColors.textSecondary)),
                  Text(sub, style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: EchoColors.textGhost)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: EchoColors.textGhost),
          ],
        ),
      ),
    );
  }

  Widget _buildShadowClone(String lastTrained, int totalPairs) {
    final displayTopics = _topics.take(5).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        border: Border.all(color: EchoColors.borderSubtle),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
                  letterSpacing: 1.0, color: const Color(0xFF7A5A30)),
            ),
            const Spacer(),
            Text(
              '$totalPairs training pairs',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, color: EchoColors.textGhost),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'Your personal model — trained on you.',
            style: GoogleFonts.lora(
                fontSize: 13, fontStyle: FontStyle.italic,
                color: EchoColors.textMuted, height: 1.6),
          ),
          const SizedBox(height: 12),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: EchoOrb(size: 20, rings: 1),
              ),
            )
          else if (displayTopics.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No confidence data yet — keep chatting.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: EchoColors.textGhost),
              ),
            )
          else
            ...displayTopics.map((t) {
              final key = t['topic'] as String? ?? '';
              final score = (t['score'] as num?)?.toDouble() ?? 0.0;
              final label = _topicLabels[key] ?? key;
              final color = _topicColors[key] ?? EchoColors.amber;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(label,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: EchoColors.textMuted)),
                    const Spacer(),
                    Text('${(score * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: EchoColors.textGhost)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: score.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: EchoColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ]),
              );
            }),
          const SizedBox(height: 4),
          Text(
            'Last trained · $lastTrained',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: EchoColors.textVeryGhost),
          ),
        ],
      ),
    );
  }

  Widget _buildConnections(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConnectionsPage())),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          border: Border.all(color: EchoColors.borderSubtle),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(children: [
          const Icon(Icons.link_rounded, size: 15, color: EchoColors.amber),
          const SizedBox(width: 10),
          Text('Connections',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w500,
                  color: EchoColors.textSecondary)),
          const Spacer(),
          Text('Gmail · Calendar · Reading',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: EchoColors.textGhost)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 16,
              color: EchoColors.textGhost),
        ]),
      ),
    );
  }

  Widget _buildQuote() {
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
          RichText(
            text: TextSpan(
              style: GoogleFonts.lora(
                fontSize: 13, fontStyle: FontStyle.italic,
                height: 1.65, color: EchoColors.textMuted,
              ),
              children: const [
                TextSpan(text: '"', style: TextStyle(color: EchoColors.amber)),
                TextSpan(text: 'You solve for elegance before you solve for speed.'),
                TextSpan(text: '"', style: TextStyle(color: EchoColors.amber)),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '— from your conversation, ${_shortDate()}',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: EchoColors.textVeryGhost),
          ),
        ],
      ),
    );
  }
}

// ─── Constellation nodes & edges ─────────────────────────────────────────────

class _NodeData {
  final double x, y, r;
  final String label;
  final bool isCx;
  final Color color;
  const _NodeData({required this.x, required this.y, required this.r,
      required this.label, required this.isCx, required this.color});
}

const _nodes = [
  _NodeData(x: 148, y: 108, r: 13, label: 'Systems Thinking',    isCx: true,  color: Color(0xFFC4783A)),
  _NodeData(x: 236, y: 88,  r: 11, label: 'Pattern Recognition', isCx: true,  color: Color(0xFFC4783A)),
  _NodeData(x: 284, y: 162, r: 10, label: 'Teaching Instinct',   isCx: false, color: Color(0xFFD48A50)),
  _NodeData(x: 188, y: 202, r: 9,  label: 'Builder Mindset',     isCx: false, color: Color(0xFFC4783A)),
  _NodeData(x: 80,  y: 172, r: 9,  label: 'Emotional Intel.',    isCx: false, color: Color(0xFF5A6AB4)),
  _NodeData(x: 52,  y: 262, r: 6,  label: 'Creative Expression', isCx: false, color: Color(0xFF4A5AA4)),
  _NodeData(x: 302, y: 248, r: 5,  label: 'Strategic Patience',  isCx: false, color: Color(0xFF3A4A94)),
];

const _edges = [
  [0, 1, 0.30], [1, 2, 0.25], [2, 3, 0.20], [0, 3, 0.20],
  [1, 4, 0.15], [3, 4, 0.12], [4, 5, 0.08], [2, 6, 0.07],
];

const _stars = [
  [30.0, 40.0], [310.0, 60.0], [20.0, 200.0],
  [340.0, 230.0], [170.0, 270.0], [60.0, 140.0], [290.0, 130.0],
];

class _ConstellationPainter extends CustomPainter {
  static const double _vw = 350, _vh = 290;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _vw;
    final sy = size.height / _vh;
    final scale = (sx + sy) / 2;

    Offset nodeOffset(_NodeData n) => Offset(n.x * sx, n.y * sy);

    final starPaint = Paint()..color = const Color(0xFF1E1B17);
    for (final s in _stars) {
      canvas.drawCircle(Offset(s[0] * sx, s[1] * sy), 1, starPaint);
    }

    for (final e in _edges) {
      final a = _nodes[e[0] as int];
      final b = _nodes[e[1] as int];
      canvas.drawLine(nodeOffset(a), nodeOffset(b),
          Paint()
            ..color = Color.fromRGBO(90, 106, 170, e[2] as double)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke);
    }

    for (final n in _nodes) {
      canvas.drawCircle(nodeOffset(n), (n.r + 6) * scale,
          Paint()
            ..color = n.color.withValues(alpha: 0.06)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    for (final n in _nodes) {
      canvas.drawCircle(nodeOffset(n), n.r * scale,
          Paint()..color = n.color.withValues(alpha: n.isCx ? 1.0 : 0.7));
    }

    for (final n in _nodes) {
      final tp = TextPainter(
        text: TextSpan(
          text: n.label,
          style: TextStyle(
            color: n.isCx
                ? const Color(0xFFC8C4BE).withValues(alpha: 0.75)
                : const Color(0xFF8C8884).withValues(alpha: 0.50),
            fontSize: 10 * scale,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 90 * sx);

      final nodeRight = nodeOffset(n).dx + n.r * scale + 4;
      final nodeLeft  = nodeOffset(n).dx - n.r * scale - 4 - tp.width;
      final ly        = nodeOffset(n).dy - tp.height / 2;

      tp.paint(canvas, nodeRight + tp.width <= size.width
          ? Offset(nodeRight, ly)
          : Offset(nodeLeft, ly));
    }

    _legend(canvas, 16 * sx,  size.height - 14 * sy, const Color(0xFFC4783A), 5 * scale, 'Core strengths', scale);
    _legend(canvas, 115 * sx, size.height - 14 * sy, const Color(0xFF5A6AB4), 4 * scale, 'Growing',        scale);
    _legend(canvas, 185 * sx, size.height - 14 * sy, const Color(0xFF3A4A94), 3 * scale, 'Emerging',       scale);
  }

  void _legend(Canvas canvas, double x, double y, Color color, double r,
      String label, double scale) {
    canvas.drawCircle(Offset(x, y), r, Paint()..color = color.withValues(alpha: 0.9));
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
            color: const Color(0xFF787470).withValues(alpha: 0.5),
            fontSize: 9 * scale),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + r + 4, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
