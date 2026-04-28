import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/auth_service.dart';
import 'package:logging/logging.dart';

class EchoContext {
  final String systemInjection;
  final String recommendedModel; // "local" or "openai"
  final String? loraId;
  final double confidence;

  const EchoContext({
    required this.systemInjection,
    required this.recommendedModel,
    this.loraId,
    required this.confidence,
  });

  factory EchoContext.fromJson(Map<String, dynamic> json) => EchoContext(
        systemInjection: json['system_injection'] as String? ?? '',
        recommendedModel: json['recommended_model'] as String? ?? 'openai',
        loraId: json['lora_id'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      );
}

class EchoClient {
  static final EchoClient _instance = EchoClient._internal();
  factory EchoClient() => _instance;
  EchoClient._internal();

  static final _log = Logger('echo.client');

  String get baseUrl => 'http://localhost:8002';

  String? _lastUserMessage;
  String _lastModelUsed = '';

  // Cached from last successful /context — used as fallback when the call times out
  EchoContext? _cachedContext;

  /// user_id comes from the verified JWT — not generated locally anymore.
  Future<String?> get userId async => AuthService().userId;

  Map<String, String> get _headers => AuthService().authHeaders;

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
            Uri.parse('$baseUrl/context'),
            headers: _headers,
            body: jsonEncode({'user_id': uid, 'message': message}),
          )
          .timeout(const Duration(milliseconds: 5000));

      if (resp.statusCode == 200) {
        final ctx = EchoContext.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
        _cachedContext = ctx;
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
  void savePair({
    required String userMessage,
    required String assistantMessage,
    required String modelUsed,
    String engagementSignal = 'continue',
  }) {
    _lastModelUsed = modelUsed;
    if (!AuthService().isLoggedIn) return;
    _savePairAsync(
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      modelUsed: modelUsed,
      engagementSignal: engagementSignal,
    );
  }

  /// Thumbs up/down — uses stored last user message.
  void sendFeedback({required String assistantMessage, required String signal}) {
    if (_lastUserMessage == null || _lastUserMessage!.isEmpty) return;
    _savePairAsync(
      userMessage: _lastUserMessage!,
      assistantMessage: assistantMessage,
      modelUsed: _lastModelUsed.isEmpty ? 'unknown' : _lastModelUsed,
      engagementSignal: signal,
    );
  }

  Future<void> _savePairAsync({
    required String userMessage,
    required String assistantMessage,
    required String modelUsed,
    required String engagementSignal,
  }) async {
    try {
      final uid = AuthService().userId!;
      await http
          .post(
            Uri.parse('$baseUrl/save'),
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
    } catch (e) {
      _log.warning('Echo /save failed: $e');
    }
  }
}
