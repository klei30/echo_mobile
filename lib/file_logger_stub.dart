class FileLogger {
  static Future<void> initLogFile() async {
    // Do nothing on the web.
  }

  static void closeLogFile() {
    // Do nothing on the web.
  }

  static void writeToFile(String message) {
    // Do nothing on the web.
  }

  static Future<void> cleanupOldLogs({int days = 3}) async {
    // Do nothing on the web.
  }
}
