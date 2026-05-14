import 'dart:convert';

import 'package:chatmcp/echo/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EchoOfflineQueue {
  EchoOfflineQueue._();
  static final EchoOfflineQueue _instance = EchoOfflineQueue._();
  factory EchoOfflineQueue() => _instance;

  static final _log = Logger('echo.offline_queue');
  static const _keyPairs = 'echo_offline_pairs';

  Future<int> get pendingPairCount async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyPairs) ?? const [];
    return raw.length;
  }

  Future<void> addPair({
    required String userMessage,
    required String assistantMessage,
    required String modelUsed,
    String engagementSignal = 'continue',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyPairs) ?? <String>[];
    raw.add(
      jsonEncode({
        'type': 'chat_pair',
        'created_at': DateTime.now().toIso8601String(),
        'user_message': userMessage,
        'assistant_message': assistantMessage,
        'model_used': modelUsed,
        'engagement_signal': engagementSignal,
      }),
    );
    await prefs.setStringList(_keyPairs, raw);
  }

  /// Upload all queued offline pairs to the Echo backend /save endpoint.
  /// Pairs that succeed are removed; pairs that fail are kept for the next attempt.
  /// Returns the number of pairs successfully uploaded.
  Future<int> flush() async {
    if (!AuthService().isLoggedIn) return 0;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyPairs) ?? const [];
    if (raw.isEmpty) return 0;

    final userId = AuthService().userId;
    if (userId == null || userId.isEmpty) return 0;

    final baseUrl = AuthService().baseUrl;
    final headers = {...AuthService().authHeaders, 'Content-Type': 'application/json'};

    final remaining = <String>[];
    int uploaded = 0;

    for (final item in raw) {
      try {
        final pair = jsonDecode(item) as Map<String, dynamic>;
        final userMsg = pair['user_message'] as String? ?? '';
        final assistantMsg = pair['assistant_message'] as String? ?? '';
        if (userMsg.isEmpty || assistantMsg.isEmpty) continue; // drop malformed

        final body = jsonEncode({
          'user_id': userId,
          'user_message': userMsg,
          'assistant_message': assistantMsg,
          'model_used': pair['model_used'] as String? ?? 'device_gemma',
          'engagement_signal': pair['engagement_signal'] as String? ?? 'continue',
        });

        final resp = await http.post(Uri.parse('$baseUrl/save'), headers: headers, body: body).timeout(const Duration(seconds: 12));

        if (resp.statusCode == 200) {
          uploaded++;
        } else {
          _log.warning('flush: /save returned ${resp.statusCode}, keeping pair');
          remaining.add(item);
        }
      } catch (e) {
        _log.warning('flush: failed to upload pair: $e');
        remaining.add(item);
      }
    }

    await prefs.setStringList(_keyPairs, remaining);

    if (uploaded > 0) {
      _log.info('Offline queue flushed: $uploaded pairs uploaded, ${remaining.length} remaining');
    }
    return uploaded;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPairs);
  }
}
