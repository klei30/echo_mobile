import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EchoHostService {
  static final EchoHostService _instance = EchoHostService._internal();
  factory EchoHostService() => _instance;
  EchoHostService._internal();

  static const _keyMode = 'echo_host_mode';      // 'auto' | 'tunnel'
  static const _keyTunnelUrl = 'echo_tunnel_url';
  static const _keyConfigured = 'echo_brain_configured';

  String _mode = 'auto';
  String _tunnelUrl = '';
  bool _configured = false;

  bool get isConfigured => _configured;
  bool get hasTunnel => _mode == 'tunnel' && _tunnelUrl.isNotEmpty;
  String get tunnelUrl => _tunnelUrl;

  /// The URL all API calls use. Falls back to platform localhost if no tunnel set.
  String get resolvedUrl {
    if (_mode == 'tunnel' && _tunnelUrl.isNotEmpty) return _tunnelUrl;
    // Android emulator routes host localhost via 10.0.2.2
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:8002' : 'http://localhost:8002';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString(_keyMode) ?? 'auto';
    _tunnelUrl = prefs.getString(_keyTunnelUrl) ?? '';
    _configured = prefs.getBool(_keyConfigured) ?? false;
  }

  Future<void> setTunnel(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/$'), '');
    _tunnelUrl = clean;
    _mode = clean.isNotEmpty ? 'tunnel' : 'auto';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTunnelUrl, _tunnelUrl);
    await prefs.setString(_keyMode, _mode);
  }

  Future<void> clearTunnel() async {
    _tunnelUrl = '';
    _mode = 'auto';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTunnelUrl);
    await prefs.setString(_keyMode, 'auto');
  }

  Future<void> markConfigured() async {
    _configured = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConfigured, true);
  }
}
