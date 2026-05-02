import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:logging/logging.dart';

class EchoContext {
  final String systemInjection;
  final String recommendedModel; // "local" or "openai"
  final String? loraId;
  final double confidence;
  final Map<String, dynamic> loopState;

  const EchoContext({
    required this.systemInjection,
    required this.recommendedModel,
    this.loraId,
    required this.confidence,
    this.loopState = const {},
  });

  factory EchoContext.fromJson(Map<String, dynamic> json) => EchoContext(
        systemInjection: json['system_injection'] as String? ?? '',
        recommendedModel: json['recommended_model'] as String? ?? 'openai',
        loraId: json['lora_id'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        loopState: Map<String, dynamic>.from(json['loop_state'] as Map? ?? {}),
      );
}

class EchoClient {
  static final EchoClient _instance = EchoClient._internal();
  factory EchoClient() => _instance;
  EchoClient._internal();

  static final _log = Logger('echo.client');

  String get _baseUrl {
    // Android emulator uses 10.0.2.2 to reach host's localhost
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:8002' : 'http://localhost:8002';
  }

  // Public getter for code that references .baseUrl
  String get baseUrl => _baseUrl;

  String? _lastUserMessage;
  String _lastModelUsed = '';

  // Cached from last successful /context — used as fallback when the call times out
  EchoContext? _cachedContext;

  /// user_id comes from the verified JWT — not generated locally anymore.
  Future<String?> get userId async => AuthService().userId;

  Map<String, String> get _headers => AuthService().authHeaders;
  String? get lastUserMessage => _lastUserMessage;

  /// Call before every LLM request. Returns enriched context or null (silent fail).
  /// Falls back to the last cached context if the server doesn't respond in time.
  Future<EchoContext?> fetchContext(String message) async {
    _lastUserMessage = message;
    if (!AuthService().isLoggedIn) return _cachedContext;
    _log.info('Echo /context msg="${message.substring(0, message.length.clamp(0, 60))}"');
    try {
      final uid = AuthService().userId!;
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/context'),
            headers: _headers,
            body: jsonEncode({'user_id': uid, 'message': message}),
          )
          .timeout(const Duration(milliseconds: 5000));

      if (resp.statusCode == 200) {
        final ctx = EchoContext.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        _cachedContext = ctx;
        final priority = ctx.loopState['today_priority'];
        final thesis = ctx.loopState['thesis'];
        EchoLoopState().apply(
          todayPriority: priority is Map ? Map<String, dynamic>.from(priority) : null,
          thesis: thesis is Map ? Map<String, dynamic>.from(thesis) : null,
        );
        _log.info('Echo /context OK model=${ctx.recommendedModel} confidence=${ctx.confidence.toStringAsFixed(2)}');
        return ctx;
      }
      _log.warning('Echo /context HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('Echo /context failed (using cache): $e');
      return _cachedContext;
    }
    return _cachedContext;
  }

  /// Call after every LLM response. Fire-and-forget.
  Future<Map<String, dynamic>?> savePair({
    required String userMessage,
    required String assistantMessage,
    required String modelUsed,
    String engagementSignal = 'continue',
  }) {
    _lastModelUsed = modelUsed;
    if (!AuthService().isLoggedIn) return Future.value(null);
    return _savePairAsync(
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      modelUsed: modelUsed,
      engagementSignal: engagementSignal,
    );
  }

  /// Thumbs up/down — uses stored last user message.
  void sendFeedback({required String assistantMessage, required String signal}) {
    if (_lastUserMessage == null || _lastUserMessage!.isEmpty) return;
    _sendOutcomeAsync(assistantMessage: assistantMessage, signal: signal);
  }

  Future<Map<String, dynamic>?> _savePairAsync({
    required String userMessage,
    required String assistantMessage,
    required String modelUsed,
    required String engagementSignal,
  }) async {
    try {
      final uid = AuthService().userId!;
      final resp = await http
          .post(
            Uri.parse('$_baseUrl/save'),
            headers: _headers,
            body: jsonEncode({
              'user_id': uid,
              'user_message': userMessage,
              'assistant_message': assistantMessage,
              'model_used': modelUsed,
              'engagement_signal': engagementSignal,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final delta = data['loop_delta'];
        if (delta is Map) {
          final priority = delta['today_priority'];
          final thesis = delta['thesis'];
          final snapshot = delta['snapshot'];
          EchoLoopState().apply(
            todayPriority: priority is Map ? Map<String, dynamic>.from(priority) : null,
            thesis: thesis is Map ? Map<String, dynamic>.from(thesis) : null,
            snapshot: snapshot is Map ? Map<String, dynamic>.from(snapshot) : null,
          );
        }
        return data;
      }
    } catch (e) {
      _log.warning('Echo /save failed: $e');
    }
    return null;
  }

  Future<void> _sendOutcomeAsync({
    required String assistantMessage,
    required String signal,
  }) async {
    final scores = <String, double>{
      'thumbs_up': 1.0,
      'helped': 1.0,
      'saved_signal': 1.2,
      'thumbs_down': -1.0,
      'not_true': -0.7,
    };
    final userMsg = _lastUserMessage ?? '';
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/v1/outcome'),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'subject_type': 'chat_response',
              'outcome': signal,
              'score': scores[signal] ?? 0.5,
              'user_message': userMsg,
              'assistant_message': assistantMessage,
              'model_used': _lastModelUsed.isEmpty ? 'unknown' : _lastModelUsed,
              'note': jsonEncode({
                'user_preview': userMsg.substring(0, userMsg.length.clamp(0, 240)),
                'assistant_preview': assistantMessage.substring(0, assistantMessage.length.clamp(0, 240)),
                'model_used': _lastModelUsed.isEmpty ? 'unknown' : _lastModelUsed,
              }),
            }),
          )
          .timeout(const Duration(seconds: 5));
      await EchoLoopState().refresh();
    } catch (e) {
      _log.warning('Echo /outcome failed: $e');
    }
  }
}
