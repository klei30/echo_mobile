import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';
import 'package:chatmcp/provider/serve_state_provider.dart';
import 'package:chatmcp/mcp/client/mcp_client_interface.dart';

class ComposioProvider extends ChangeNotifier {
  static const serverName = 'Echo Tools';
  static const legacyServerName = 'Composio';

  // Map from Composio display name → toolkit slug used in API calls.
  static const Map<String, String> toolkitSlugs = {
    'Gmail': 'gmail',
    'Google Calendar': 'googlecalendar',
    'Kindle / Reading': 'kindle',
    'Spotify': 'spotify',
    'Notion': 'notion',
    'GitHub': 'github',
    'Slack': 'slack',
    'Twitter / X': 'twitter',
  };

  final _logger = Logger('ComposioProvider');

  bool _isLoading = false;
  String? _lastError;
  // Toolkit slug → connected state (authoritative from Composio REST or MCP).
  final Map<String, bool> _connected = {};

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  bool get isInstalled => McpServerProvider().clients.containsKey(serverName);
  bool get isRunning => McpServerProvider().mcpServerIsRunning(serverName);

  bool isConnected(String displayName) {
    final slug = toolkitSlugs[displayName] ?? _slugify(displayName);
    return _connected[slug] ?? false;
  }

  String _slugify(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  // ── Setup ──────────────────────────────────────────────────────────────────

  Future<void> installEchoTools() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final data = await EchoApiClient().getComposioMcpConfig();
      final config = data?['server_config'];
      if (config is! Map<String, dynamic>) {
        throw Exception('Echo did not return a Composio MCP config.');
      }

      await _removeLegacyServer();
      await McpServerProvider().addMcpServer(Map<String, dynamic>.from(config));
      final client = await McpServerProvider().startMcpServer(serverName);
      if (client == null) throw Exception('Could not start Echo Tools.');

      McpServerProvider().toggleToolCategory(serverName, true);
      ServerStateProvider().setEnabled(serverName, true);
      ServerStateProvider().setRunning(serverName, true);

      // Refresh connection status after MCP starts.
      await _loadStatusViaMcp();
    } catch (e, st) {
      _lastError = e.toString();
      _logger.severe('Failed to install Echo Tools', e, st);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startEchoTools() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await _removeLegacyServer();
      final client = await McpServerProvider().startMcpServer(serverName);
      if (client == null) throw Exception('Could not start Echo Tools.');
      McpServerProvider().toggleToolCategory(serverName, true);
      ServerStateProvider().setEnabled(serverName, true);
      ServerStateProvider().setRunning(serverName, true);
      await _loadStatusViaMcp();
    } catch (e, st) {
      _lastError = e.toString();
      _logger.severe('Failed to start Echo Tools', e, st);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Connection status ──────────────────────────────────────────────────────

  /// Load which toolkits are connected.  Tries REST API first, falls back to MCP.
  Future<void> loadStatus() async {
    try {
      final active = await EchoApiClient().getComposioStatus();
      if (active.isNotEmpty) {
        _connected.clear();
        for (final slug in active) {
          _connected[slug] = true;
        }
        notifyListeners();
        return;
      }
    } catch (_) {}
    // REST not available (no project API key) → try MCP.
    if (isRunning) await _loadStatusViaMcp();
  }

  Future<void> _loadStatusViaMcp() async {
    final client = _mcpClient;
    if (client == null) return;
    for (final slug in toolkitSlugs.values) {
      try {
        final resp = await client
            .sendToolCall(
              name: 'COMPOSIO_MANAGE_CONNECTIONS',
              arguments: {'action': 'list', 'toolkit': slug},
            )
            .timeout(const Duration(seconds: 8));
        final text = jsonEncode(resp.toJson()).toUpperCase();
        if (text.contains('ACTIVE')) {
          _connected[slug] = true;
        }
      } catch (_) {
        // Tool not found or timeout — ignore; status stays unknown.
      }
    }
    notifyListeners();
  }

  // ── Initiating a connection ────────────────────────────────────────────────

  /// Returns an OAuth redirect URL the user should open in their browser.
  /// Tries the backend REST endpoint first (requires COMPOSIO_PROJECT_API_KEY),
  /// then falls back to calling the Composio MCP helper action directly.
  Future<String?> getConnectionUrl(String displayName) async {
    final slug = toolkitSlugs[displayName] ?? _slugify(displayName);

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // ── Path 1: backend REST endpoint ──
      final data = await EchoApiClient().createComposioConnection(slug);
      final url = data?['redirect_url'] as String?;
      if (url != null && url.isNotEmpty) {
        _logger.info('Got connection URL from backend REST: $url');
        return url;
      }
      final useMcp = data?['use_mcp_fallback'] == true;
      if (!useMcp && data != null) {
        _lastError = data['error'] as String? ?? 'Failed to get connection URL';
        notifyListeners();
        return null;
      }

      // ── Path 2: MCP helper action ──
      if (!isRunning) await installEchoTools();
      return await _getUrlViaMcp(slug);
    } catch (e, st) {
      _lastError = e.toString();
      _logger.warning('getConnectionUrl failed', e, st);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _getUrlViaMcp(String slug) async {
    final client = _mcpClient;
    if (client == null) {
      _lastError = 'Echo Tools is not running. Tap "Set up Echo Tools" first.';
      notifyListeners();
      return null;
    }

    try {
      final resp = await client
          .sendToolCall(
            name: 'COMPOSIO_MANAGE_CONNECTIONS',
            arguments: {'action': 'add', 'toolkit': slug},
          )
          .timeout(const Duration(seconds: 30));

      final text = jsonEncode(resp.toJson());
      _logger.info('COMPOSIO_MANAGE_CONNECTIONS add response: $text');

      // Composio returns a redirect URL — match any https link that looks like an auth URL.
      final match = RegExp(
        r'https://[^\s"<>\\]+(?:oauth|auth|connect|accounts\.google)[^\s"<>\\]*',
        caseSensitive: false,
      ).firstMatch(text);
      if (match != null) {
        _logger.info('Got connection URL via MCP: ${match.group(0)}');
        return match.group(0);
      }

      // Fallback: grab any https URL from the response.
      final anyUrl = RegExp(r'https://[^\s"<>\\]+').firstMatch(text);
      if (anyUrl != null) {
        _logger.info('Got connection URL (fallback) via MCP: ${anyUrl.group(0)}');
        return anyUrl.group(0);
      }
    } catch (e) {
      _logger.warning('COMPOSIO_MANAGE_CONNECTIONS add failed: $e');
    }

    _lastError = 'Could not get a connection URL for $slug. '
        'Make sure Echo Tools is running and your Composio API key is valid.';
    notifyListeners();
    return null;
  }

  /// Mark a toolkit as connected (called after successful OAuth polling).
  void markConnected(String toolkit) {
    _connected[toolkit.toLowerCase()] = true;
    notifyListeners();
  }

  // ── Legacy entry point (kept for backward compat) ─────────────────────────

  Future<void> connectToolkit(String displayNameOrSlug) => installEchoTools();

  // ── Helpers ────────────────────────────────────────────────────────────────

  McpClient? get _mcpClient =>
      McpServerProvider().getClient(serverName) ??
      McpServerProvider().getClient(legacyServerName);

  Future<void> _removeLegacyServer() async {
    await McpServerProvider().stopMcpServer(legacyServerName);
    await McpServerProvider().removeMcpServer(legacyServerName);
    McpServerProvider().toggleToolCategory(legacyServerName, false);
    ServerStateProvider().setEnabled(legacyServerName, false);
    ServerStateProvider().setRunning(legacyServerName, false);
  }
}
