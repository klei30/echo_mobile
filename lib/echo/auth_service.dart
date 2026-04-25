import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final _log = Logger('echo.auth');

  static const _tokenKey = 'echo_jwt_token';
  static const _userIdKey = 'echo_user_id';
  static const _usernameKey = 'echo_username';

  String? _token;
  String? _userId;
  String? _username;

  String get baseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8002' : 'http://localhost:8002';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _userId = prefs.getString(_userIdKey);
    _username = prefs.getString(_usernameKey);
  }

  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  String? get userId => _userId;
  String? get username => _username;

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<String?> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        await _saveSession(jsonDecode(resp.body) as Map<String, dynamic>);
        return null; // success
      }
      final err = jsonDecode(resp.body);
      return err['detail'] ?? 'Registration failed';
    } catch (e) {
      _log.warning('Register error: $e');
      return 'Cannot connect to Echo server';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        await _saveSession(jsonDecode(resp.body) as Map<String, dynamic>);
        return null; // success
      }
      final err = jsonDecode(resp.body);
      return err['detail'] ?? 'Login failed';
    } catch (e) {
      _log.warning('Login error: $e');
      return 'Cannot connect to Echo server';
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['token'] as String;
    _userId = data['user_id'] as String;
    _username = data['username'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token!);
    await prefs.setString(_userIdKey, _userId!);
    await prefs.setString(_usernameKey, _username!);
    _log.info('Session saved for user=${_userId} username=${_username}');
  }
}
