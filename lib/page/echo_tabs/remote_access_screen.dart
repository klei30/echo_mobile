import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_host_service.dart';

class RemoteAccessScreen extends StatefulWidget {
  const RemoteAccessScreen({super.key});

  @override
  State<RemoteAccessScreen> createState() => _RemoteAccessScreenState();
}

class _RemoteAccessScreenState extends State<RemoteAccessScreen> {
  final _urlCtrl = TextEditingController();
  bool _saving = false;
  bool _testing = false;
  String? _testResult; // 'ok' | 'fail' | null
  String? _testError;
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = EchoHostService().tunnelUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
    if (url.isEmpty) return;
    setState(() { _testing = true; _testResult = null; _testError = null; });
    try {
      final resp = await http
          .get(Uri.parse('$url/health'))
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        _testResult = resp.statusCode == 200 ? 'ok' : 'fail';
        _testError = resp.statusCode != 200 ? 'Server returned ${resp.statusCode}' : null;
        _testing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testResult = 'fail';
        _testError = e.toString().replaceFirst('Exception: ', '');
        _testing = false;
      });
    }
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
    setState(() => _saving = true);
    await EchoHostService().setTunnel(url);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: EchoColors.bgCard,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(
        url.isEmpty ? 'Switched back to local connection.' : 'Remote URL saved. Echo will use this connection.',
        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
      ),
    ));
  }

  Future<void> _clear() async {
    _urlCtrl.clear();
    await EchoHostService().clearTunnel();
    if (!mounted) return;
    setState(() { _testResult = null; _testError = null; });
  }

  @override
  Widget build(BuildContext context) {
    final current = EchoHostService().resolvedUrl;
    final hasTunnel = EchoHostService().hasTunnel;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            // Header
            Row(children: [
              Expanded(
                child: Text('Advanced Remote Access',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w900,
                        color: EchoColors.textPrimary)),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: EchoColors.textGhost),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              'Developer setup for entering a remote Echo URL manually. Most people should pair Home Brain instead.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textGhost, height: 1.5),
            ),
            const SizedBox(height: 22),

            // Current status
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: EchoColors.bgSurface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: EchoColors.borderSubtle),
              ),
              child: Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasTunnel ? const Color(0xFF4CAF50) : EchoColors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      hasTunnel ? 'Remote URL active' : 'Using local Echo',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: EchoColors.textMuted),
                    ),
                    Text(
                      current,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textGhost),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                GestureDetector(
                  onTap: () => Clipboard.setData(ClipboardData(text: current)),
                  child: const Icon(Icons.copy_outlined, size: 15, color: EchoColors.textGhost),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // Tunnel URL input
            Text('Remote Echo URL',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w800,
                    color: EchoColors.textGhost)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: EchoColors.bgInput,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EchoColors.border),
              ),
              child: TextField(
                controller: _urlCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: EchoColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'https://your-tunnel.trycloudflare.com',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textGhost),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  suffixIcon: _urlCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: EchoColors.textGhost),
                          onPressed: _clear,
                        )
                      : null,
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() { _testResult = null; _testError = null; }),
              ),
            ),
            // Android emulator shortcut — 10.0.2.2 routes to host machine
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  _urlCtrl.text = 'http://10.0.2.2:8002';
                  setState(() { _testResult = null; _testError = null; });
                },
                child: Row(children: [
                  const Icon(Icons.computer_rounded, size: 13, color: EchoColors.amber),
                  const SizedBox(width: 5),
                  Text(
                    'Use emulator local address  (http://10.0.2.2:8002)',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: EchoColors.amberText, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 10),

            // Test + Save buttons
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _testing ? null : _test,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: EchoColors.bgSurface,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: _testResult == 'ok'
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                          : _testResult == 'fail'
                              ? Colors.redAccent.withValues(alpha: 0.4)
                              : EchoColors.borderSubtle),
                    ),
                    child: _testing
                        ? const Center(child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: EchoColors.amber)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(
                              _testResult == 'ok' ? Icons.check_circle_rounded
                                  : _testResult == 'fail' ? Icons.cancel_rounded
                                  : Icons.wifi_tethering_rounded,
                              size: 15,
                              color: _testResult == 'ok' ? const Color(0xFF4CAF50)
                                  : _testResult == 'fail' ? Colors.redAccent
                                  : EchoColors.textGhost,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _testResult == 'ok' ? 'Connected'
                                  : _testResult == 'fail' ? 'Failed'
                                  : 'Test',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5, fontWeight: FontWeight.w600,
                                  color: _testResult == 'ok' ? const Color(0xFF4CAF50)
                                      : _testResult == 'fail' ? Colors.redAccent
                                      : EchoColors.textMuted),
                            ),
                          ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: _saving
                        ? const Center(child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: EchoColors.bg)))
                        : Text('Save',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: EchoColors.bg)),
                  ),
                ),
              ),
            ]),

            if (_testError != null) ...[
              const SizedBox(height: 8),
              Text(_testError!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.redAccent.withValues(alpha: 0.8))),
            ],

            const SizedBox(height: 28),

            // Setup guide
            GestureDetector(
              onTap: () => setState(() => _showGuide = !_showGuide),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: EchoColors.borderSubtle),
                ),
                child: Row(children: [
                  const Icon(Icons.help_outline_rounded, size: 16, color: EchoColors.textGhost),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Manual setup notes',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, fontWeight: FontWeight.w600, color: EchoColors.textMuted)),
                  ),
                  Icon(_showGuide ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 18, color: EchoColors.textGhost),
                ]),
              ),
            ),

            if (_showGuide) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                  border: Border.all(color: EchoColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _guideStep('1', 'Install cloudflared on your PC',
                        'Download from one.dash.cloudflare.com/cloudflared\nor run: winget install Cloudflare.cloudflared'),
                    _guideStep('2', 'Start the tunnel',
                        'Open a terminal on your PC and run:\ncloudflared tunnel --url http://localhost:8002'),
                    _guideStep('3', 'Copy the URL',
                        'cloudflared prints a URL like:\nhttps://abc-def-ghi.trycloudflare.com\n\nCopy that URL.'),
                    _guideStep('4', 'Paste it above',
                        'Paste the URL in the field above, tap Test, then Save. Your phone can now reach your home PC from anywhere.'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: EchoColors.amber.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: EchoColors.amber.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        'Quick tunnels are free and need no account.\nThe URL changes each restart — for a stable URL, use a named tunnel (cloudflared tunnel create echo).',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5, color: EchoColors.amberText, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _guideStep(String num, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EchoColors.amber.withValues(alpha: 0.12),
              border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, fontWeight: FontWeight.w800, color: EchoColors.amberText)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: EchoColors.textMuted)),
                const SizedBox(height: 3),
                Text(body,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: EchoColors.textGhost, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
