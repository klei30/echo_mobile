import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

final bool kIsDebug = (() {
  bool isDebug = false;
  assert(() {
    isDebug = true;
    return true;
  }());
  return isDebug;
}());

final bool kIsLinux = !kIsWeb && Platform.isLinux;
final bool kIsWindows = !kIsWeb && Platform.isWindows;
final bool kIsMacOS = !kIsWeb && Platform.isMacOS;
final bool kIsDesktop = !kIsWeb && (kIsLinux || kIsWindows || kIsMacOS);
final bool kIsMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
final bool kIsAndroid = !kIsWeb && Platform.isAndroid;
final bool kIsIOS = !kIsWeb && Platform.isIOS;
final bool kIsBrowser = kIsWeb;

String? getPlatformPath() {
  if (kIsWeb) {
    return null;
  }
  return Platform.environment['PATH'];
}
