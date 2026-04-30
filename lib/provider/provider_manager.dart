import 'dart:async';
import 'package:provider/provider.dart';
import 'settings_provider.dart';
import 'mcp_server_provider.dart';
import 'chat_provider.dart';
import 'chat_model_provider.dart';
import 'serve_state_provider.dart';
import 'package:logging/logging.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/repository/local_chat_repository.dart';

import 'composio_provider.dart';

class ProviderManager {
  static List<ChangeNotifierProvider> providers = [
    ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
    ChangeNotifierProvider<McpServerProvider>(create: (_) => McpServerProvider()),
    ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
    ChangeNotifierProvider<ChatModelProvider>(create: (_) => ChatModelProvider()),
    ChangeNotifierProvider<ServerStateProvider>(create: (_) => ServerStateProvider()),
    ChangeNotifierProvider<ComposioProvider>(create: (_) => ComposioProvider()),
  ];

  static SettingsProvider? _settingsProvider;

  static SettingsProvider get settingsProvider {
    _settingsProvider ??= SettingsProvider();
    return _settingsProvider!;
  }

  static McpServerProvider? _mcpServerProvider;

  static McpServerProvider get mcpServerProvider {
    _mcpServerProvider ??= McpServerProvider();
    return _mcpServerProvider!;
  }

  static ChatProvider? _chatProvider;

  static ChatProvider get chatProvider {
    _chatProvider ??= ChatProvider();
    return _chatProvider!;
  }

  static ChatModelProvider? _chatModelProvider;

  static ChatModelProvider get chatModelProvider {
    _chatModelProvider ??= ChatModelProvider();
    return _chatModelProvider!;
  }

  static ServerStateProvider? _serverStateProvider;

  static ServerStateProvider get serverStateProvider {
    _serverStateProvider ??= ServerStateProvider();
    return _serverStateProvider!;
  }

  static ComposioProvider? _composioProvider;

  static ComposioProvider get composioProvider {
    _composioProvider ??= ComposioProvider();
    return _composioProvider!;
  }

  static Future<void> init() async {
    await SettingsProvider().loadSettings();

    // FIX: Adopt orphan chats (legacy userId=NULL) to current user before loading
    final repo = LocalChatRepository();
    await repo.adoptOrphanChats();

    await ChatProvider().loadChats();
    await McpServerProvider().init();
    await McpServerProvider().loadInMemoryServers();
    await _autoStartEchoTools();
  }

  static Future<void> _autoStartEchoTools() async {
    try {
      final mcp = McpServerProvider();
      final servers = await mcp.mcpServers;

      if (servers.contains(ComposioProvider.legacyServerName)) {
        await mcp.stopMcpServer(ComposioProvider.legacyServerName);
        await mcp.removeMcpServer(ComposioProvider.legacyServerName);
        mcp.toggleToolCategory(ComposioProvider.legacyServerName, false);
        ServerStateProvider().setEnabled(ComposioProvider.legacyServerName, false);
        ServerStateProvider().setRunning(ComposioProvider.legacyServerName, false);
      }

      final updatedServers = await mcp.mcpServers;
      if (!updatedServers.contains(ComposioProvider.serverName)) return;

      final data = await EchoApiClient().getComposioMcpConfig();
      final config = data?['server_config'];
      if (config is Map<String, dynamic>) {
        await mcp.addMcpServer(Map<String, dynamic>.from(config));
      }

      final client = await mcp.startMcpServer(ComposioProvider.serverName);
      if (client == null) return;

      mcp.toggleToolCategory(ComposioProvider.serverName, true);
      ServerStateProvider().setEnabled(ComposioProvider.serverName, true);
      ServerStateProvider().setRunning(ComposioProvider.serverName, true);
    } catch (e, stackTrace) {
      Logger('ProviderManager').warning('Echo Tools auto-start failed', e, stackTrace);
    }
  }
}
