import 'package:logging/logging.dart';
import '../utils/toast.dart';
import './models/server.dart';
import './client/mcp_client_interface.dart';
import './stdio/stdio_client.dart';
import './sse/sse_client.dart';
import './streamable/streamable_client.dart';
import 'inmemory/client.dart';
import 'inmemory_server/factory.dart';

Future<McpClient?> initializeMcpServer(Map<String, dynamic> mcpServerConfig) async {
  // Get server configuration
  final serverConfig = ServerConfig.fromJson(mcpServerConfig);

  // Create appropriate client based on configuration
  McpClient mcpClient;

  // 首先检查类型字段
  if (serverConfig.type.isNotEmpty) {
    switch (serverConfig.type) {
      case 'sse':
        mcpClient = SSEClient(serverConfig: serverConfig);
        break;
      case 'streamable':
        mcpClient = StreamableClient(serverConfig: serverConfig);
        break;
      case 'stdio':
        try {
          mcpClient = StdioClient(serverConfig: serverConfig);
        } catch (e) {
          Logger.root.severe('Failed to create StdioClient: $e');
          ToastUtils.error('StdioClient creation failed: ${e.toString()}');
          return null;
        }
        break;
      case 'inmemory':
        final memoryServer = MemoryServerFactory.createMemoryServer(serverConfig.command);
        if (memoryServer == null) {
          Logger.root.severe('Failed to create memory server');

          ToastUtils.error('Memory server creation failed');

          return null;
        }
        mcpClient = InMemoryClient(server: memoryServer);
        break;
      default:
        // 降级为基于命令的逻辑
        if (serverConfig.command.startsWith('http')) {
          mcpClient = SSEClient(serverConfig: serverConfig);
        } else {
          try {
            mcpClient = StdioClient(serverConfig: serverConfig);
          } catch (e) {
            Logger.root.severe('Failed to create StdioClient in fallback: $e');
            ToastUtils.error('StdioClient creation failed: ${e.toString()}');
            return null;
          }
        }
    }
  } else {
    // 降级为原来的逻辑
    if (serverConfig.command.startsWith('http')) {
      mcpClient = SSEClient(serverConfig: serverConfig);
    } else {
      try {
        mcpClient = StdioClient(serverConfig: serverConfig);
      } catch (e) {
        Logger.root.severe('Failed to create StdioClient in legacy fallback: $e');
        ToastUtils.error('StdioClient creation failed: ${e.toString()}');
        return null;
      }
    }
  }

  try {
    await mcpClient.initialize();
    final initResponse = await mcpClient.sendInitialize();
    Logger.root.info('Initialization response: $initResponse');

    final toolListResponse = await mcpClient.sendToolList();
    Logger.root.info('Tool list response: $toolListResponse');

    return mcpClient;
  } catch (e) {
    Logger.root.severe('Failed to initialize MCP server: $e');

    // Only show toast after widget tree is ready (navigatorKey has state).
    // During app startup the tree isn't mounted yet, so skip the toast to
    // avoid the BotToast "currentState != null" assertion crash.
    try {
      ToastUtils.error('MCP Error: ${e.toString()}');
    } catch (_) {}

    return null;
  }
}

Future<bool> verifyMcpServer(Map<String, dynamic> mcpServerConfig) async {
  final serverConfig = ServerConfig.fromJson(mcpServerConfig);

  McpClient mcpClient;

  if (serverConfig.type.isNotEmpty) {
    switch (serverConfig.type) {
      case 'sse':
        mcpClient = SSEClient(serverConfig: serverConfig);
        break;
      case 'streamable':
        mcpClient = StreamableClient(serverConfig: serverConfig);
        break;
      case 'stdio':
        try {
          mcpClient = StdioClient(serverConfig: serverConfig);
        } catch (e) {
          Logger.root.severe('Failed to create StdioClient for verification: $e');
          ToastUtils.error('StdioClient creation failed: ${e.toString()}');
          return false;
        }
        break;
      default:
        // 降级为基于命令的逻辑
        if (serverConfig.command.startsWith('http')) {
          mcpClient = SSEClient(serverConfig: serverConfig);
        } else {
          try {
            mcpClient = StdioClient(serverConfig: serverConfig);
          } catch (e) {
            Logger.root.severe('Failed to create StdioClient in verify fallback: $e');
            ToastUtils.error('StdioClient creation failed: ${e.toString()}');
            return false;
          }
        }
    }
  } else {
    // 降级为原来的逻辑
    if (serverConfig.command.startsWith('http')) {
      mcpClient = SSEClient(serverConfig: serverConfig);
    } else {
      try {
        mcpClient = StdioClient(serverConfig: serverConfig);
      } catch (e) {
        Logger.root.severe('Failed to create StdioClient in verify legacy fallback: $e');
        ToastUtils.error('StdioClient creation failed: ${e.toString()}');
        return false;
      }
    }
  }

  try {
    await mcpClient.sendInitialize();
    return true;
  } catch (e) {
    Logger.root.warning('Failed to verify MCP server: $e');

    ToastUtils.warn('MCP server verification failed: ${e.toString()}');

    return false;
  }
}
