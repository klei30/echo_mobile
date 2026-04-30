import 'dart:async';
import 'dart:convert';

import 'package:chatmcp/provider/composio_provider.dart';
import 'package:chatmcp/provider/provider_manager.dart';
import 'package:chatmcp/utils/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class ComposioAuthButton extends StatefulWidget {
  final String url;
  final String label;
  final String? toolkit;
  /// Called when the connection is confirmed active (optional).
  final VoidCallback? onConnected;

  const ComposioAuthButton({
    super.key,
    required this.url,
    required this.label,
    this.toolkit,
    this.onConnected,
  });

  @override
  State<ComposioAuthButton> createState() => _ComposioAuthButtonState();
}

class _ComposioAuthButtonState extends State<ComposioAuthButton>
    with WidgetsBindingObserver {
  bool _opened = false;
  bool _polling = false;
  bool _connected = false;
  bool _authBrowserOpen = false;
  String? _message;
  Timer? _pollTimer;

  String get _toolkit {
    if (widget.toolkit != null && widget.toolkit!.trim().isNotEmpty) {
      return widget.toolkit!.trim().toLowerCase();
    }
    final label = widget.label.toLowerCase();
    final match = RegExp(r'connect\s+([a-z0-9_-]+)').firstMatch(label);
    if (match != null) return match.group(1)!;
    if (label.contains('gmail')) return 'gmail';
    return 'gmail';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _opened && !_connected) {
      _authBrowserOpen = false;
      _schedulePoll();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _authBrowserOpen = true;
      _pollTimer?.cancel();
    }
  }

  Future<void> _openAuth() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      setState(() => _message = 'Invalid auth link.');
      return;
    }

    setState(() {
      _opened = true;
      _authBrowserOpen = true;
      _message =
          'Sign in, press Allow, then return here. Echo will detect the connection automatically.';
    });

    try {
      // External browser handles OAuth redirect chains better than in-app WebView.
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!launched) {
        setState(() => _message = 'Could not open browser. Link copied.');
        await Clipboard.setData(ClipboardData(text: widget.url));
      }
    } catch (e, st) {
      Logger.root.warning('Composio auth launch failed: $e', e, st);
      setState(() => _message = 'Could not open browser. Link copied.');
      await Clipboard.setData(ClipboardData(text: widget.url));
    }
  }

  void _schedulePoll() {
    if (_authBrowserOpen || _connected) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_authBrowserOpen && !_connected) {
        unawaited(_pollConnection());
      }
    });
    unawaited(_pollConnection());
  }

  Future<void> _pollConnection() async {
    if (_authBrowserOpen || _polling || _connected) return;
    final client =
        ProviderManager.mcpServerProvider.getClient(ComposioProvider.serverName) ??
        ProviderManager.mcpServerProvider.getClient(ComposioProvider.legacyServerName);
    if (client == null) {
      setState(() => _message = 'Echo Tools is not running yet.');
      return;
    }

    setState(() {
      _polling = true;
      _message = 'Checking $_toolkit connection...';
    });

    try {
      final response = await client
          .sendToolCall(
            name: 'COMPOSIO_MANAGE_CONNECTIONS',
            arguments: {'action': 'list', 'toolkit': _toolkit},
          )
          .timeout(const Duration(seconds: 20));

      final responseText = jsonEncode(response.toJson()).toUpperCase();
      final isActive = responseText.contains('ACTIVE');
      final failed = responseText.contains('FAILED') ||
          responseText.contains('ERROR');

      if (isActive && !failed) {
        _pollTimer?.cancel();
        setState(() {
          _connected = true;
          _message = '${_toolkit.toUpperCase()} connected. ✓';
        });

        // Update provider state.
        ProviderManager.composioProvider.markConnected(_toolkit);

        // If opened from the Connections page via onConnected callback, call it.
        widget.onConnected?.call();

        // If opened from chat, resume the pending prompt.
        if (widget.onConnected == null) {
          await emit(SubmitPromptEvent(
            'Continue the previous $_toolkit request now that $_toolkit is connected.',
          ));
        }
      } else {
        setState(() {
          _message = failed
              ? 'Connection failed. Try tapping the button again.'
              : 'Waiting for you to finish signing in...';
        });
      }
    } catch (e, st) {
      Logger.root.warning('Composio poll failed: $e', e, st);
      setState(() =>
          _message = 'Waiting for sign-in to complete. Return here after pressing Allow.');
    } finally {
      if (mounted) setState(() => _polling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = _connected ? '${_toolkit.toUpperCase()} connected' : widget.label;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: _connected ? null : _openAuth,
            icon: _polling
                ? SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colorScheme.onPrimary),
                  )
                : Icon(_connected
                    ? Icons.check_circle_outline
                    : Icons.lock_open_outlined),
            label: Text(label),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _message!,
                style: TextStyle(
                    fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}
