import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/auth_service.dart';
import 'package:logging/logging.dart';

class EchoApiClient {
  static final EchoApiClient _i = EchoApiClient._();
  factory EchoApiClient() => _i;
  EchoApiClient._();

  static final _log = Logger('echo.api');

  String get _base => AuthService().baseUrl;
  Map<String, String> get _h => AuthService().authHeaders;

  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/v1/user/stats'), headers: _h)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserStats HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserStats error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getConfidence() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/v1/user/confidence'), headers: _h)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getConfidence HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getConfidence error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserInsights() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/v1/user/insights'), headers: _h)
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getUserInsights HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getUserInsights error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getEmergence() async {
    try {
      final resp = await http
          .post(Uri.parse('$_base/v1/emergence'), headers: _h)
          .timeout(const Duration(seconds: 35));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getEmergence HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getEmergence error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeeklyMirror() async {
    try {
      final resp = await http
          .post(Uri.parse('$_base/v1/mirror/weekly'), headers: _h)
          .timeout(const Duration(seconds: 35));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getWeeklyMirror HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getWeeklyMirror error: $e');
    }
    return null;
  }
}
