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

  Future<List<Map<String, dynamic>>> getMemories() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/v1/user/memories'), headers: _h)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['memories'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      _log.warning('getMemories HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getMemories error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getSkills() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/v1/user/skills'), headers: _h)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['skills'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      _log.warning('getSkills HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getSkills error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getTalent() async {
    try {
      final resp = await http
          .post(Uri.parse('$_base/v1/user/talent'), headers: _h)
          .timeout(const Duration(seconds: 45));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getTalent HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getTalent error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getNotableQuote() async {
    try {
      final resp = await http
          .get(Uri.parse('$_base/v1/user/notable-quote'), headers: _h)
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getNotableQuote HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getNotableQuote error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getExperiment() async {
    try {
      final resp = await http
          .post(Uri.parse('$_base/v1/user/experiment'), headers: _h)
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) return jsonDecode(resp.body) as Map<String, dynamic>;
      _log.warning('getExperiment HTTP ${resp.statusCode}');
    } catch (e) {
      _log.warning('getExperiment error: $e');
    }
    return null;
  }
}
