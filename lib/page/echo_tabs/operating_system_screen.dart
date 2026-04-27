import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/auth_service.dart';

class OperatingSystemScreen extends StatefulWidget {
  const OperatingSystemScreen({super.key});

  @override
  State<OperatingSystemScreen> createState() => _OperatingSystemScreenState();
}

class _OperatingSystemScreenState extends State<OperatingSystemScreen> {
  List<Map<String, dynamic>> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await http
          .get(Uri.parse('${AuthService().baseUrl}/v1/user/rules'),
              headers: AuthService().authHeaders)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['rules'] as List? ?? [])
            .where((r) => (r as Map)['active'] == 1 || (r as Map)['active'] == true)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        if (mounted) setState(() { _rules = list; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030201),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text('Your Operating System',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'YOUR RULES · LEARNED BY WATCHING',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.2, color: const Color(0xFF4A3A28)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.lora(fontSize: 18, color: EchoColors.textPrimary,
                      height: 1.5, letterSpacing: -0.3),
                  children: const [
                    TextSpan(text: 'You don\'t follow rules.\n'),
                    TextSpan(
                      text: 'You have rules.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: EchoColors.amber),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'I observed these. You never told me. You probably can\'t articulate them. But you live them.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5, color: EchoColors.textGhost, height: 1.6),
              ),
            ),
            // Rules list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: EchoColors.amber, strokeWidth: 1.5))
                  : _rules.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No rules distilled yet.\nEcho is still watching.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                  fontSize: 14, fontStyle: FontStyle.italic,
                                  color: EchoColors.textGhost, height: 1.65),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: EchoColors.amber,
                          backgroundColor: EchoColors.bgSurface,
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            children: [
                              ..._rules.asMap().entries.map((e) =>
                                  _RuleItem(index: e.key, rule: e.value)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: EchoColors.amber.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border(
                                    left: BorderSide(
                                        color: EchoColors.amber.withValues(alpha: 0.4), width: 2)),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5, color: EchoColors.textMuted, height: 1.6),
                                    children: const [
                                      TextSpan(text: 'Echo learned these by watching how you '),
                                      TextSpan(
                                        text: 'actually live',
                                        style: TextStyle(
                                            color: EchoColors.amber, fontWeight: FontWeight.w500),
                                      ),
                                      TextSpan(text: ' — not what you say you believe.'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final int index;
  final Map<String, dynamic> rule;

  const _RuleItem({required this.index, required this.rule});

  static const _lineColors = [EchoColors.amber, Color(0xFF9A6AB4)];

  @override
  Widget build(BuildContext context) {
    final text = rule['rule_text'] as String? ?? '';
    final confidence = rule['confidence'] as String? ?? '';
    final isHighConf = confidence == '0.99' || confidence == '0.95' || confidence == 'high';
    final number = (index + 1).toString().padLeft(2, '0');
    final lineColor = _lineColors[index % _lineColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number in Lora italic
          SizedBox(
            width: 26,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                number,
                style: GoogleFonts.lora(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF7A5A30), letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient separator line
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lineColor.withValues(alpha: 0.4), Colors.transparent],
                    ),
                  ),
                ),
                Text(
                  text,
                  style: isHighConf
                      ? GoogleFonts.lora(
                          fontSize: 14, fontStyle: FontStyle.italic,
                          color: EchoColors.textSecondary, height: 1.6, letterSpacing: -0.2)
                      : GoogleFonts.plusJakartaSans(
                          fontSize: 13.5, color: EchoColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 4),
                Text(
                  confidence == '0.99' ? '· Manually confirmed'
                      : confidence == '0.95' ? '· Auto-observed'
                      : confidence == 'high' ? '· High confidence'
                      : '· Observed',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: EchoColors.textGhost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
