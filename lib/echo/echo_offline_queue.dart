import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EchoOfflineQueue {
  EchoOfflineQueue._();
  static final EchoOfflineQueue _instance = EchoOfflineQueue._();
  factory EchoOfflineQueue() => _instance;

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
    raw.add(jsonEncode({
      'type': 'chat_pair',
      'created_at': DateTime.now().toIso8601String(),
      'user_message': userMessage,
      'assistant_message': assistantMessage,
      'model_used': modelUsed,
      'engagement_signal': engagementSignal,
    }));
    await prefs.setStringList(_keyPairs, raw);
  }
}
