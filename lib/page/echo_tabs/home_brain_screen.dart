import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import 'package:chatmcp/echo/auth_service.dart';
import 'package:chatmcp/echo/echo_host_service.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/utils/platform.dart';

class HomeBrainScreen extends StatefulWidget {
  const HomeBrainScreen({super.key});

  @override
  State<HomeBrainScreen> createState() => _HomeBrainScreenState();
}

class _HomeBrainScreenState extends State<HomeBrainScreen> {
  bool? _echoRunning;
  bool? _vllmRunning;
  bool? _adapterLoaded;
  String? _tunnelUrl;
  Process? _tunnelProcess;
  Timer? _pollTimer;
  bool _startingEcho = false;
  bool _startingVllm = false;
  bool _startingTunnel = false;
  bool _tunnelDnsWarming = false;
  final List<String> _tunnelLog = [];

  @override
  void initState() {
    super.initState();
    // Quick tunnels die when the process stops — don't show a stale saved URL.
    // Clear it on open so the user always starts a fresh tunnel session.
    EchoHostService().clearTunnel();
    _pollHealth();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _pollHealth());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tunnelProcess?.kill();
    super.dispose();
  }

  // HomeBrainScreen always polls localhost directly — never via tunnel.
  // The desktop IS the server; routing through EchoHostService would try
  // the remote tunnel URL and fail with DNS errors.
  static const _localBase = 'http://localhost:8002';

  Future<void> _pollHealth() async {
    // Public ping — no auth needed
    bool echoUp = false;
    try {
      final resp = await http
          .get(Uri.parse('$_localBase/health'))
          .timeout(const Duration(seconds: 3));
      echoUp = resp.statusCode == 200;
    } catch (_) {}

    if (!mounted) return;
    if (!echoUp) {
      setState(() {
        _echoRunning = false;
        _vllmRunning = false;
        _adapterLoaded = false;
      });
      return;
    }

    // Full system health — requires auth, always hit localhost
    setState(() => _echoRunning = true);
    try {
      final resp = await http
          .get(
            Uri.parse('$_localBase/v1/system/health'),
            headers: AuthService().authHeaders,
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          final vllmVal = body['vllm']?.toString() ?? '';
          _vllmRunning = vllmVal == 'ok' || vllmVal == 'running';
          _adapterLoaded = body['adapter_loaded'] == true;
        });
      } else {
        setState(() { _vllmRunning = false; _adapterLoaded = false; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _vllmRunning = false; _adapterLoaded = false; });
    }
  }

  Future<void> _startEchoApi() async {
    if (!kIsWindows) return;
    setState(() => _startingEcho = true);
    // Use detached mode — cmd /k keeps the window open forever, so Process.run
    // would never return. ProcessStartMode.detached fires and forgets.
    await Process.start(
      'cmd',
      ['/c', 'start', '/min', 'cmd', '/k',
       'wsl -d Ubuntu-24.04 bash -c "cd /mnt/c/Users/ASUS/Desktop/echo && python main.py"'],
      mode: ProcessStartMode.detached,
    );
    setState(() => _startingEcho = false);
  }

  Future<void> _startVllm() async {
    if (!kIsWindows) return;
    setState(() => _startingVllm = true);
    await Process.start(
      'cmd',
      ['/c', 'start', '/min', 'cmd', '/k',
       'wsl -d Ubuntu-24.04 bash /mnt/c/Users/ASUS/Desktop/echo/start_gemma4_e2b_vllm.sh'],
      mode: ProcessStartMode.detached,
    );
    setState(() => _startingVllm = false);
  }

  void _stopTunnel() {
    _tunnelProcess?.kill();
    _tunnelProcess = null;
    EchoHostService().clearTunnel();
    // Kill any orphaned cloudflared processes from previous sessions
    if (kIsWindows) {
      Process.run('taskkill', ['/F', '/IM', 'cloudflared.exe']);
    }
    if (!mounted) return;
    setState(() {
      _tunnelUrl = null;
      _tunnelDnsWarming = false;
      _startingTunnel = false;
      _tunnelLog.clear();
    });
  }

  Future<void> _startTunnel() async {
    if (!kIsWindows) return;

    // Stop if active in any state (process running, DNS warming, or URL set)
    if (_tunnelProcess != null || _tunnelUrl != null || _tunnelDnsWarming) {
      _stopTunnel();
      return;
    }

    // Kill any orphaned cloudflared from previous app sessions before starting fresh
    await Process.run('taskkill', ['/F', '/IM', 'cloudflared.exe']);

    setState(() {
      _startingTunnel = true;
      _tunnelLog.clear();
    });

    // Resolve cloudflared path — winget installs it to the Links folder
    final candidates = [
      'cloudflared',
      r'C:\Windows\System32\cloudflared.exe',
      r'C:\Program Files (x86)\cloudflared\cloudflared.exe',
      '${Platform.environment['ProgramFiles']}\\cloudflared\\cloudflared.exe',
      '${Platform.environment['LOCALAPPDATA']}\\Microsoft\\WinGet\\Links\\cloudflared.exe',
    ];

    String? cloudflaredExe;
    for (final candidate in candidates) {
      try {
        final result = await Process.run(candidate, ['--version']);
        if (result.exitCode == 0 || result.stdout.toString().contains('cloudflared')) {
          cloudflaredExe = candidate;
          break;
        }
      } catch (_) {}
    }

    if (cloudflaredExe == null) {
      if (!mounted) return;
      setState(() {
        _startingTunnel = false;
        _tunnelLog.add('cloudflared not found.');
        _tunnelLog.add('Install it: winget install Cloudflare.cloudflared');
        _tunnelLog.add('Then reopen this screen.');
      });
      return;
    }

    try {
      final process = await Process.start(
        cloudflaredExe,
        ['tunnel', '--url', 'http://localhost:8002'],
      );
      _tunnelProcess = process;
      process.stderr.transform(const SystemEncoding().decoder).listen(_onTunnelOutput);
      process.stdout.transform(const SystemEncoding().decoder).listen(_onTunnelOutput);
      process.exitCode.then((_) {
        if (!mounted) return;
        setState(() {
          _tunnelProcess = null;
          _startingTunnel = false;
          _tunnelDnsWarming = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _startingTunnel = false;
        _tunnelLog.add('Failed to start tunnel: $e');
      });
    }
  }

  void _onTunnelOutput(String chunk) {
    for (final line in chunk.split('\n')) {
      if (line.trim().isEmpty) continue;
      final match = RegExp(r'https://[a-z0-9-]+\.trycloudflare\.com').firstMatch(line);
      if (match != null && _tunnelUrl == null && !_tunnelDnsWarming) {
        final url = match.group(0)!;
        EchoHostService().setTunnel(url);
        if (!mounted) return;
        setState(() {
          _startingTunnel = false;
          _tunnelDnsWarming = true;
          _tunnelLog.add('Tunnel URL ready - waiting for DNS to propagate...');
        });
        // Cloudflare DNS takes ~15s to propagate after the URL appears.
        // Show QR only once the record is resolvable.
        _waitForDns(url);
      }
      if (mounted) {
        setState(() {
          _tunnelLog.add(line.trim());
          if (_tunnelLog.length > 20) _tunnelLog.removeAt(0);
        });
      }
    }
  }

  Future<void> _waitForDns(String url) async {
    // Poll the actual tunnel /health endpoint — more reliable than DNS lookup alone
    // since DNS lookup on Windows may resolve before the Android emulator's DNS does.
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !_tunnelDnsWarming) return;
      try {
        final resp = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          if (!mounted || !_tunnelDnsWarming) return;
          setState(() {
            _tunnelUrl = url;
            _tunnelDnsWarming = false;
            _tunnelLog.add('Tunnel ready - scan QR to pair your phone with Home Brain');
          });
          return;
        }
      } catch (_) {}
    }
    // 60s timeout — show QR anyway and let mobile retry handle it
    if (mounted && _tunnelDnsWarming) {
      setState(() { _tunnelUrl = url; _tunnelDnsWarming = false; });
    }
  }

  String _qrPayload(String url) => jsonEncode({
        'type': 'echo_local_brain',
        'baseUrl': url,
        'version': 1,
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text('Home Brain',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: EchoColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              'Run Echo privately on this computer, load your personal model, and pair your phone by Wi-Fi or tunnel.',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, color: EchoColors.textGhost, height: 1.5),
            ),
            const SizedBox(height: 20),

            _serviceRow(
              label: 'Echo API',
              running: _echoRunning,
              icon: Icons.api_rounded,
              starting: _startingEcho,
              onStart: _startEchoApi,
            ),
            const SizedBox(height: 8),
            _serviceRow(
              label: 'Gemma 4 Model (vLLM)',
              running: _vllmRunning,
              icon: Icons.memory_rounded,
              starting: _startingVllm,
              onStart: _startVllm,
              extra: _adapterLoaded == true ? 'adapter loaded' : null,
            ),
            const SizedBox(height: 8),
            _tunnelRow(),
            const SizedBox(height: 20),

            if (_tunnelUrl != null) ...[
              _qrCard(_tunnelUrl!),
              const SizedBox(height: 20),
            ],

            if (_tunnelLog.isNotEmpty) ...[
              Text('TUNNEL LOG',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: EchoColors.textGhost)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EchoColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _tunnelLog
                      .map((l) => Text(l,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: EchoColors.textGhost,
                              height: 1.5)))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serviceRow({
    required String label,
    required bool? running,
    required IconData icon,
    required bool starting,
    required VoidCallback onStart,
    String? extra,
  }) {
    final isRunning = running == true;
    final statusColor = isRunning ? const Color(0xFF4CAF50) : EchoColors.textGhost;
    final statusText = running == null
        ? 'checking...'
        : isRunning
            ? extra != null
                ? 'running · $extra'
                : 'running'
            : 'not running';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isRunning
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : EchoColors.borderSubtle,
        ),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: statusColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: EchoColors.textMuted)),
            Text(statusText,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: statusColor)),
          ]),
        ),
        if (!isRunning)
          GestureDetector(
            onTap: starting ? null : onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: EchoColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: starting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: EchoColors.amber))
                  : Text('Start',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: EchoColors.amberText)),
            ),
          ),
      ]),
    );
  }

  Widget _tunnelRow() {
    final active = _tunnelProcess != null || _tunnelUrl != null;
    final statusColor = active ? const Color(0xFF4CAF50) : EchoColors.textGhost;
    final statusText = _startingTunnel
        ? 'starting...'
        : _tunnelDnsWarming
            ? 'waiting for DNS...'
            : _tunnelUrl != null
                ? _tunnelUrl!.replaceFirst('https://', '')
                : 'not running';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: active
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
              : EchoColors.borderSubtle,
        ),
      ),
      child: Row(children: [
        Icon(Icons.wifi_tethering_rounded, size: 16, color: statusColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Secure Tunnel',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: EchoColors.textMuted)),
            Text(statusText,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: statusColor)),
          ]),
        ),
        GestureDetector(
          onTap: _startingTunnel ? null : _startTunnel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? Colors.redAccent.withValues(alpha: 0.08)
                  : EchoColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _startingTunnel
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: EchoColors.amber))
                : Text(
                    active ? 'Stop' : 'Start',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.redAccent
                            : EchoColors.amberText),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _qrCard(String url) {
    final payload = _qrPayload(url);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.phone_iphone_rounded,
              size: 16, color: EchoColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Pair your phone',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: EchoColors.textPrimary)),
          ),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: url)),
            child: const Icon(Icons.copy_outlined,
                size: 15, color: EchoColors.textGhost),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          'Open Echo on your phone -> Home Brain -> Scan QR',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5, color: EchoColors.textGhost, height: 1.5),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: payload,
            version: QrVersions.auto,
            size: 180,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0D0B08)),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0D0B08)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'URL changes each restart · use a named tunnel for a stable address',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5, color: EchoColors.textGhost, height: 1.5),
        ),
      ]),
    );
  }
}
