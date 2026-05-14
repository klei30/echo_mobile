import 'dart:io';

import 'package:chatmcp/provider/provider_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logging/logging.dart';

import 'platform.dart';

Future<void> initNonWeb() async {
  if (kIsWeb) {
    return;
  }

  // Get an available port
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();

  if (!kIsDesktop) {
    final InAppLocalhostServer localhostServer = InAppLocalhostServer(documentRoot: 'assets/sandbox', port: port);

    ProviderManager.settingsProvider.updateSandboxServerPort(port: port);

    // start the localhost server
    await localhostServer.start();

    Logger.root.info('Sandbox server started @ http://localhost:$port');
  }
}
