import 'dart:convert';

import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_offline_queue.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EchoOfflineMemoryService {
  EchoOfflineMemoryService._();
  static final EchoOfflineMemoryService _instance = EchoOfflineMemoryService._();
  factory EchoOfflineMemoryService() => _instance;

  static final _log = Logger('echo.offline_memory');
  static const _packKey = 'echo_offline_memory_pack';

  Map<String, dynamic>? _pack;

  Map<String, dynamic>? get pack => _pack;
  bool get hasPack => _pack != null;

  String get exportedAt => _pack?['exported_at'] as String? ?? '';

  int count(String key) {
    final counts = _pack?['counts'];
    if (counts is! Map) return 0;
    final value = counts[key];
    return value is num ? value.toInt() : 0;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_packKey);
    if (raw == null || raw.isEmpty) return;
    try {
      _pack = jsonDecode(raw) as Map<String, dynamic>;
      _applyLoopState(_pack!);
    } catch (e) {
      _log.warning('Could not load offline memory pack: $e');
    }
  }

  Future<bool> syncFromEcho() async {
    if (!AuthService().isLoggedIn) return false;
    try {
      final resp = await http
          .get(
            Uri.parse('${AuthService().baseUrl}/v1/offline/export'),
            headers: AuthService().authHeaders,
          )
          .timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) {
        _log.warning('offline export HTTP ${resp.statusCode}');
        return false;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_packKey, jsonEncode(data));
      _pack = data;
      _applyLoopState(data);

      // Upload any conversations captured while offline so they enter training.
      final uploaded = await EchoOfflineQueue().flush();
      if (uploaded > 0) {
        _log.info('syncFromEcho: flushed $uploaded offline pairs into training');
      }
      return true;
    } catch (e) {
      _log.warning('offline export failed: $e');
      return false;
    }
  }

  Future<void> clear() async {
    _pack = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_packKey);
  }

  String buildDevicePrompt() {
    final pack = _pack;
    if (pack == null) {
      return 'No offline Echo memory pack has been synced yet. Be honest that you only have the current chat and any cached screen state.';
    }

    final buffer = StringBuffer();
    final user = _asMap(pack['user']);
    final username = user['username']?.toString();
    if (username != null && username.trim().isNotEmpty) {
      buffer.writeln('User: $username');
    }
    buffer.writeln('Offline pack exported at: ${pack['exported_at'] ?? 'unknown'}');

    final memories = _asList(pack['memories']);
    if (memories.isNotEmpty) {
      buffer.writeln('\nKnown Memories');
      for (final item in memories.take(12)) {
        final map = _asMap(item);
        final memory = _clip(map['memory']?.toString().trim(), 120);
        if (memory != null && memory.isNotEmpty) buffer.writeln('- $memory');
      }
    }

    final rules = _asList(pack['rules']);
    if (rules.isNotEmpty) {
      buffer.writeln('\nUser Rules');
      for (final item in rules.take(6)) {
        final map = _asMap(item);
        final text = _clip(map['rule_text']?.toString().trim(), 120);
        if (text != null && text.isNotEmpty) buffer.writeln('- $text');
      }
    }

    final loop = _asMap(pack['loop_state']);
    _writeSection(buffer, 'Current Read', _flattenMap(_asMap(loop['thesis']), const ['title', 'statement']));
    _writeSection(buffer, 'Today Priority', _flattenMap(_asMap(loop['today_priority']), const ['title', 'body']));
    _writeSection(buffer, 'Practice Rep', _flattenMap(_asMap(loop['practice']), const ['rep_title', 'rep_instruction']));

    final recent = _asMap(pack['recent']);
    final threads = _asList(recent['threads']);
    if (threads.isNotEmpty) {
      buffer.writeln('\nActive Patterns');
      for (final item in threads.take(5)) {
        final map = _asMap(item);
        final name = _clip(map['name']?.toString(), 80);
        final topic = map['topic']?.toString();
        if (name != null && name.isNotEmpty) buffer.writeln('- $name${topic == null || topic.isEmpty ? '' : ' ($topic)'}');
      }
    }

    final events = _asList(recent['life_events']);
    if (events.isNotEmpty) {
      buffer.writeln('\nRecent Signals');
      for (final item in events.take(5)) {
        final map = _asMap(item);
        final title = map['title']?.toString().trim();
        final summary = map['summary']?.toString().trim();
        final text = _clip((summary?.isNotEmpty == true) ? summary! : title, 120);
        if (text != null && text.isNotEmpty) buffer.writeln('- $text');
      }
    }

    return _clip(buffer.toString().trim(), 2800) ?? '';
  }

  void _applyLoopState(Map<String, dynamic> pack) {
    final loop = _asMap(pack['loop_state']);
    EchoLoopState().apply(
      snapshot: _nullableMap(loop['snapshot']),
      todayPriority: _nullableMap(loop['today_priority']),
      thesis: _nullableMap(loop['thesis']),
      mission: _nullableMap(loop['mission']),
      practice: _nullableMap(loop['practice']),
      trainingSummary: _nullableMap(loop['training_summary']),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static Map<String, dynamic>? _nullableMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static List<Object?> _asList(Object? value) {
    if (value is List) return value;
    return const [];
  }

  static String _flattenMap(Map<String, dynamic> map, List<String> keys) {
    final parts = <String>[];
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) parts.add(value.trim());
      if (value is num || value is bool) parts.add('$key: $value');
    }
    return parts.join('\n');
  }

  static String? _clip(String? value, int maxChars) {
    if (value == null) return null;
    final text = value.trim();
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}...';
  }

  static void _writeSection(StringBuffer buffer, String title, String body) {
    if (body.trim().isEmpty) return;
    buffer.writeln('\n$title');
    buffer.writeln(body.trim());
  }
}
