import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EchoRuntimeMode {
  cloud,
  desktop,
  device;

  static EchoRuntimeMode fromString(String value) {
    return EchoRuntimeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => EchoRuntimeMode.cloud,
    );
  }
}

enum DeviceModelStatus {
  missing,
  ready,
  error;

  static DeviceModelStatus fromString(String value) {
    return DeviceModelStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DeviceModelStatus.missing,
    );
  }
}

class EchoRuntimeService extends ChangeNotifier {
  EchoRuntimeService._();
  static final EchoRuntimeService _instance = EchoRuntimeService._();
  factory EchoRuntimeService() => _instance;

  static const _keyMode = 'echo_runtime_mode';
  static const _keyDeviceModelPath = 'echo_device_model_path';
  static const _keyDeviceModelStatus = 'echo_device_model_status';
  static const _keyDeviceModelVersion = 'echo_device_model_version';

  EchoRuntimeMode _mode = EchoRuntimeMode.cloud;
  DeviceModelStatus _deviceModelStatus = DeviceModelStatus.missing;
  String _deviceModelPath = '';
  String _deviceModelVersion = '';

  EchoRuntimeMode get mode => _mode;
  DeviceModelStatus get deviceModelStatus => _deviceModelStatus;
  String get deviceModelPath => _deviceModelPath;
  String get deviceModelVersion => _deviceModelVersion;

  bool get isCloud => _mode == EchoRuntimeMode.cloud;
  bool get isDesktop => _mode == EchoRuntimeMode.desktop;
  bool get isDevice => _mode == EchoRuntimeMode.device;
  bool get isDeviceReady => isDevice && _deviceModelStatus == DeviceModelStatus.ready && _deviceModelPath.isNotEmpty;

  String get modeLabel {
    return switch (_mode) {
      EchoRuntimeMode.cloud => 'Echo Cloud',
      EchoRuntimeMode.desktop => 'My Computer',
      EchoRuntimeMode.device => 'This Device',
    };
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = EchoRuntimeMode.fromString(prefs.getString(_keyMode) ?? EchoRuntimeMode.cloud.name);
    _deviceModelPath = prefs.getString(_keyDeviceModelPath) ?? '';
    _deviceModelStatus = DeviceModelStatus.fromString(prefs.getString(_keyDeviceModelStatus) ?? DeviceModelStatus.missing.name);
    _deviceModelVersion = prefs.getString(_keyDeviceModelVersion) ?? '';
  }

  Future<void> setMode(EchoRuntimeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, mode.name);
    notifyListeners();
  }

  Future<void> setDeviceModel({
    required String path,
    String version = 'Gemma on device',
  }) async {
    _deviceModelPath = path.trim();
    _deviceModelVersion = version.trim().isEmpty ? 'Gemma on device' : version.trim();
    _deviceModelStatus = _deviceModelPath.isEmpty ? DeviceModelStatus.missing : DeviceModelStatus.ready;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceModelPath, _deviceModelPath);
    await prefs.setString(_keyDeviceModelVersion, _deviceModelVersion);
    await prefs.setString(_keyDeviceModelStatus, _deviceModelStatus.name);
    notifyListeners();
  }

  Future<void> markDeviceModelError() async {
    _deviceModelStatus = DeviceModelStatus.error;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceModelStatus, _deviceModelStatus.name);
    notifyListeners();
  }

  Future<void> clearDeviceModel() async {
    _deviceModelPath = '';
    _deviceModelVersion = '';
    _deviceModelStatus = DeviceModelStatus.missing;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceModelPath);
    await prefs.remove(_keyDeviceModelVersion);
    await prefs.setString(_keyDeviceModelStatus, DeviceModelStatus.missing.name);
    notifyListeners();
  }
}
