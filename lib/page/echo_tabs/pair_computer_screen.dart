import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:chatmcp/echo/echo_host_service.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/remote_access_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

class PairComputerScreen extends StatefulWidget {
  final String? initialUrl;
  const PairComputerScreen({super.key, this.initialUrl});

  @override
  State<PairComputerScreen> createState() => _PairComputerScreenState();
}

class _PairComputerScreenState extends State<PairComputerScreen> {
  final _pasteCtrl = TextEditingController();
  bool _scanning = false;
  bool _testing = false;
  bool _handledScan = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      // Auto-connect when launched via deep link from the camera QR scan
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _connect(widget.initialUrl!);
      });
    }
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _handledScan = false;
      _error = null;
    });
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_handledScan) return;
    String? raw;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        raw = value;
        break;
      }
    }
    if (raw == null || raw.trim().isEmpty) return;
    _handledScan = true;
    await _connect(raw);
  }

  Future<void> _connect(String raw) async {
    final url = _extractUrl(raw);
    if (url == null) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _testing = false;
        _error = 'That QR code does not look like an Echo Home Brain pairing code.';
      });
      return;
    }

    setState(() {
      _testing = true;
      _error = null;
    });

    // Android emulator: try the host machine directly first (10.0.2.2 routes to
    // Windows localhost). This completely bypasses Cloudflare DNS propagation
    // delays â€” DNS on the emulator uses Google's resolvers which lag behind
    // Windows DNS by up to 60s. On a real phone 10.0.2.2 isn't routable, so
    // we silently fall through to the tunnel retry loop.
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final localResp = await http
            .get(Uri.parse('http://10.0.2.2:8002/health'))
            .timeout(const Duration(seconds: 4));
        if (localResp.statusCode == 200) {
          // Emulator can reach the Windows host directly.
          // Save 10.0.2.2:8002 as the "tunnel URL" so hasTunnel = true
          // and all status cards show "connected". verifyTunnel() at next
          // startup will re-confirm it or clear it if Echo isn't running.
          await EchoHostService().setTunnel('http://10.0.2.2:8002');
          if (!mounted) return;
          Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {
        // Not an emulator or Echo not running on host â€” fall through to tunnel.
      }
    }

    // Retry up to 15 times (60s) â€” Cloudflare DNS can take up to ~60s on some resolvers
    Exception? lastErr;
    for (int attempt = 0; attempt < 15; attempt++) {
      if (attempt > 0) {
        if (mounted) {
          setState(() => _error = 'Connecting... (${attempt * 4}s)');
        }
        await Future.delayed(const Duration(seconds: 4));
      }
      if (!mounted) return;
      try {
        final resp = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) {
          throw Exception('Home Brain returned ${resp.statusCode}.');
        }
        await EchoHostService().setTunnel(url);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      } catch (e) {
        lastErr = e is Exception ? e : Exception(e.toString());
        final msg = e.toString();
        // Only retry on DNS / socket errors â€” not on HTTP errors
        final isDnsError = msg.contains('host lookup') ||
            msg.contains('errno = 7') ||
            msg.contains('errno = 11001') ||
            msg.contains('SocketException') ||
            msg.contains('SocketFailed');
        if (!isDnsError) break;
      }
    }

    if (!mounted) return;
    setState(() {
      _scanning = false;
      _testing = false;
      _handledScan = false;
      _error = lastErr.toString().replaceFirst('Exception: ', '');
    });
  }

  String? _extractUrl(String raw) {
    final text = raw.trim();
    final direct = Uri.tryParse(text);
    // Handle echo://pair?baseUrl=... custom scheme from desktop QR code
    if (direct != null && direct.scheme == 'echo') {
      final pairedUrl = direct.queryParameters['baseUrl'] ??
          direct.queryParameters['url'] ??
          direct.queryParameters['tunnelUrl'];
      if (pairedUrl != null) {
        final uri = Uri.tryParse(pairedUrl.trim());
        if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
          return pairedUrl.trim().replaceAll(RegExp(r'/$'), '');
        }
      }
    }
    final pairedUrl = direct?.queryParameters['baseUrl'] ??
        direct?.queryParameters['url'] ??
        direct?.queryParameters['tunnelUrl'];
    if (pairedUrl != null) {
      final uri = Uri.tryParse(pairedUrl.trim());
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        return pairedUrl.trim().replaceAll(RegExp(r'/$'), '');
      }
    }
    if (direct != null &&
        (direct.scheme == 'http' || direct.scheme == 'https') &&
        direct.host.isNotEmpty) {
      return text.replaceAll(RegExp(r'/$'), '');
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) {
        final value = decoded['baseUrl'] ??
            decoded['url'] ??
            decoded['tunnelUrl'] ??
            decoded['echoUrl'];
        if (value is String) {
          final uri = Uri.tryParse(value.trim());
          if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
            return value.trim().replaceAll(RegExp(r'/$'), '');
          }
        }
      }
    } catch (_) {
      // Not JSON; handled by the invalid-code message.
    }
    return null;
  }

  Future<void> _openAdvanced() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RemoteAccessScreen()),
    );
    if (!mounted) return;
    if (EchoHostService().hasTunnel) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = EchoHostService().hasTunnel;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pair Home Brain',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: EchoColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(Icons.close_rounded, color: EchoColors.textGhost),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Open Home Brain on your computer, choose Pair phone, then scan the QR code here.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: EchoColors.textGhost,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            _statusCard(connected),
            const SizedBox(height: 18),
            if (_scanning) _scannerCard() else _stepsCard(),
            const SizedBox(height: 14),
            _primaryButton(
              icon: _scanning ? Icons.close_rounded : Icons.qr_code_scanner_rounded,
              label: _scanning ? 'Cancel scan' : 'Scan pairing QR',
              onTap: _testing
                  ? null
                  : () {
                      if (_scanning) {
                        setState(() {
                          _scanning = false;
                          _handledScan = false;
                        });
                      } else {
                        _scan();
                      }
                    },
            ),
            const SizedBox(height: 10),
            _pasteCard(),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _openAdvanced,
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text('Advanced: enter remote URL manually'),
              style: TextButton.styleFrom(
                foregroundColor: EchoColors.textGhost,
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: Colors.redAccent.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusCard(bool connected) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: connected
            ? const Color(0xFF4CAF50).withValues(alpha: 0.07)
            : EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: connected
              ? const Color(0xFF4CAF50).withValues(alpha: 0.24)
              : EchoColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.check_circle_rounded : Icons.computer_rounded,
            size: 18,
            color: connected ? const Color(0xFF4CAF50) : EchoColors.textGhost,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'Home Brain connected' : 'Home Brain not connected',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: EchoColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'Secure private connection active'
                      : 'Pair Home Brain to use your own computer.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: EchoColors.textGhost,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        children: [
          _step('1', 'Install or open Echo Home Brain'),
          _step('2', 'Click Pair phone'),
          _step('3', 'Scan the QR code'),
          _step('4', 'Echo saves the connection automatically'),
        ],
      ),
    );
  }

  Widget _scannerCard() {
    return Container(
      height: 310,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Stack(
        children: [
          MobileScanner(onDetect: _handleBarcode),
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: EchoColors.amber, width: 2),
              ),
            ),
          ),
          if (_testing)
            Container(
              color: EchoColors.bg.withValues(alpha: 0.72),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EchoColors.amber,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pasteCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have a pairing link?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: EchoColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pasteCtrl,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: EchoColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste link or pairing code',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: EchoColors.textGhost,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: EchoColors.bgInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                  onSubmitted: (_) => _connect(_pasteCtrl.text),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _testing ? null : () => _connect(_pasteCtrl.text),
                icon: _testing
                    ? SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.7,
                          color: EchoColors.amber,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                color: EchoColors.amber,
                style: IconButton.styleFrom(
                  backgroundColor: EchoColors.amber.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: EchoColors.bg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: EchoColors.bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EchoColors.amber.withValues(alpha: 0.12),
              border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: EchoColors.amberText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: EchoColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
