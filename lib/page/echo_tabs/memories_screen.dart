import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/auth_service.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  List<Map<String, dynamic>> _memories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final base = AuthService().baseUrl;
      final h = AuthService().authHeaders;
      final resp = await http.get(Uri.parse('$base/v1/user/memories'), headers: h).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = (data['memories'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted)
          setState(() {
            _memories = list;
            _loading = false;
          });
      } else {
        if (mounted)
          setState(() {
            _error = 'HTTP ${resp.statusCode}';
            _loading = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _delete(String id) async {
    try {
      final base = AuthService().baseUrl;
      final h = AuthService().authHeaders;
      await http.delete(Uri.parse('$base/v1/user/memories/$id'), headers: h).timeout(const Duration(seconds: 10));
      await _load();
    } catch (_) {}
  }

  Future<void> _deleteAll() async {
    try {
      final base = AuthService().baseUrl;
      final h = AuthService().authHeaders;
      await http.delete(Uri.parse('$base/v1/user/memories'), headers: h).timeout(const Duration(seconds: 15));
      await _load();
    } catch (_) {}
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EchoColors.bgCard,
        title: Text(
          'Forget everything?',
          style: GoogleFonts.lora(color: EchoColors.textPrimary, fontSize: 16, fontStyle: FontStyle.italic),
        ),
        content: Text(
          'This will delete all ${_memories.length} memories. Echo will start fresh.',
          style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 13, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAll();
            },
            child: Text('Forget all', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8A3030))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EchoColors.bgCard,
        title: Text(
          'Forget this?',
          style: GoogleFonts.lora(color: EchoColors.textPrimary, fontSize: 16, fontStyle: FontStyle.italic),
        ),
        content: Text(
          text.length > 80 ? '${text.substring(0, 80)}…' : text,
          style: GoogleFonts.plusJakartaSans(color: EchoColors.textMuted, fontSize: 13, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep', style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(id);
            },
            child: Text('Forget', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8A3030))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
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
                    child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: EchoColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Memories',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: EchoColors.textPrimary),
                    ),
                  ),
                  Text('${_memories.length} things remembered', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: EchoColors.textGhost)),
                  if (_memories.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _confirmDeleteAll,
                      child: const Icon(Icons.delete_sweep_rounded, size: 18, color: Color(0xFF5A3030)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: Text(
                'What I keep about you',
                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: const Color(0xFF4A3A28)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'Not everything. Only what proves something.',
                style: GoogleFonts.lora(fontSize: 15, fontStyle: FontStyle.italic, color: EchoColors.textGhost, height: 1.5),
              ),
            ),
            // Memory list
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: EchoColors.amber, strokeWidth: 1.5))
                  : _error != null
                  ? Center(
                      child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: EchoColors.textGhost, fontSize: 12)),
                    )
                  : _memories.isEmpty
                  ? Center(
                      child: Text(
                        'No memories yet — keep talking.',
                        style: GoogleFonts.lora(fontSize: 14, fontStyle: FontStyle.italic, color: EchoColors.textGhost),
                      ),
                    )
                  : RefreshIndicator(
                      color: EchoColors.amber,
                      backgroundColor: EchoColors.bgSurface,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _memories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _MemoryCard(
                          memory: _memories[i],
                          onForget: () => _confirmDelete(_memories[i]['id'] as String, _memories[i]['memory'] as String),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final Map<String, dynamic> memory;
  final VoidCallback onForget;

  const _MemoryCard({required this.memory, required this.onForget});

  Color get _accentColor => EchoColors.amber;

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = memory['memory'] as String? ?? '';
    final createdAt = memory['created_at'] as String?;
    final dateStr = _formatDate(createdAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border(left: BorderSide(color: _accentColor, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$text"',
            style: GoogleFonts.lora(fontSize: 13.5, fontStyle: FontStyle.italic, color: EchoColors.textSecondary, height: 1.6),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (dateStr.isNotEmpty) Text('↑ $dateStr', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
              const Spacer(),
              GestureDetector(
                onTap: onForget,
                child: Text('forget', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF5A3030))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
