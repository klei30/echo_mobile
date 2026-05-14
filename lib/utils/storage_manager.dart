import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:chatmcp/utils/platform.dart';
import 'package:path_provider/path_provider.dart';

class StorageManager {
  static const String _appName = 'ChatMcp';
  static String? _appDataDirectory;

  /// 获取应用数据目录
  static Future<String> getAppDataDirectory() async {
    if (_appDataDirectory != null) return _appDataDirectory!;

    if (kIsMobile) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _appDataDirectory = path.join(appDir.path, _appName);
      } catch (e) {
        // 如果获取应用目录失败，使用临时目录作为备选
        final tempDir = await getTemporaryDirectory();
        _appDataDirectory = path.join(tempDir.path, _appName);
      }
    } else if (kIsLinux) {
      // Linux: 遵循 XDG Base Directory Specification
      final homeDir = Platform.environment['HOME'] ?? '';
      final xdgDataHome = Platform.environment['XDG_DATA_HOME'] ?? path.join(homeDir, '.local', 'share');
      _appDataDirectory = path.join(xdgDataHome, _appName);
    } else if (kIsWindows) {
      final appDataDir = Platform.environment['APPDATA'] ?? '';
      _appDataDirectory = path.join(appDataDir, _appName);
    } else if (kIsMacOS) {
      final homeDir = Platform.environment['HOME'] ?? '';
      _appDataDirectory = path.join(homeDir, 'Library', 'Application Support', _appName);
    } else {
      // 其他平台：使用 path_provider 作为回退方案
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _appDataDirectory = path.join(appDir.path, _appName);
      } catch (e) {
        // 如果获取应用目录失败，使用临时目录作为备选
        final tempDir = await getTemporaryDirectory();
        _appDataDirectory = path.join(tempDir.path, _appName);
      }
    }

    // 确保目录存在
    final dir = Directory(_appDataDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return _appDataDirectory!;
  }

  /// Get database file path
  static Future<String> getDatabasePath() async {
    final appDir = await getAppDataDirectory();
    return path.join(appDir, 'chatmcp.db');
  }
}
