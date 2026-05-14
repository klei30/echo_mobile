import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:chatmcp/utils/storage_manager.dart';

class FileLogger {
  static File? _logFile;
  static IOSink? _logSink;

  static Future<void> initLogFile() async {
    try {
      final String appDirPath = await StorageManager.getAppDataDirectory();
      final logDir = Directory(path.join(appDirPath, 'logs'));

      // Ensure log directory exists
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Clean up old log files (3 days ago)
      await cleanupOldLogs();

      // Use date as log filename
      final now = DateTime.now();
      final fileName = 'app_${now.year}-${now.month}-${now.day}.log';
      _logFile = File(path.join(logDir.path, fileName));

      // Open file in append mode
      _logSink = _logFile?.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to initialize log file: $e');
    }
  }

  /// Clean up old log files (3 days ago)
  static Future<void> cleanupOldLogs({int days = 3}) async {
    try {
      final String appDirPath = await StorageManager.getAppDataDirectory();
      final logDir = Directory(path.join(appDirPath, 'logs'));

      if (!await logDir.exists()) {
        return;
      }

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(Duration(days: days));

      await for (final FileSystemEntity entity in logDir.list()) {
        if (entity is File && entity.path.endsWith('.log')) {
          final fileName = path.basename(entity.path);

          // 解析文件名中的日期 (app_YYYY-M-D.log)
          final dateMatch = RegExp(r'app_(\d{4})-(\d{1,2})-(\d{1,2})\.log$').firstMatch(fileName);

          if (dateMatch != null) {
            try {
              final year = int.parse(dateMatch.group(1)!);
              final month = int.parse(dateMatch.group(2)!);
              final day = int.parse(dateMatch.group(3)!);
              final logDate = DateTime(year, month, day);

              // 如果日志文件日期早于3天前，则删除
              if (logDate.isBefore(threeDaysAgo)) {
                await entity.delete();
                debugPrint('Deleted old log file: ${entity.path}');
              }
            } catch (e) {
              debugPrint('Failed to parse date from log file $fileName: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old logs: $e');
    }
  }

  static void closeLogFile() {
    _logSink?.flush();
    _logSink?.close();
  }

  static void writeToFile(String message) {
    _logSink?.writeln('${DateTime.now()} $message');
  }
}
