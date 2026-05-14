import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class ParallelSelfScreen extends StatefulWidget {
  final bool showChrome;
  const ParallelSelfScreen({super.key, this.showChrome = true});

  @override
  State<ParallelSelfScreen> createState() => _ParallelSelfScreenState();
}

class _ParallelSelfScreenState extends State<ParallelSelfScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;

  late final AnimationController _currentCtrl;
  late final AnimationController _avoidedCtrl;
  late final AnimationController _dividerCtrl;

  @override
  void initState() {
    super.initState();
    _currentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _avoidedCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _dividerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _load();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _avoidedCtrl.dispose();
    _dividerCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await EchoApiClient().getSimulation();
    if (!mounted) return;
    setState(() {
      _data = result;
      _loading = false;
    });
    if (result != null) {
      await Future.delayed(const Duration(milliseconds: 150));
      _currentCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _dividerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 100));
      _avoidedCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: widget.showChrome
          ? AppBar(
              backgroundColor: EchoColors.bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                color: EchoColors.textMuted,
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Scenarios',
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: _loading ? _buildLoading() : _buildContent(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: EchoColors.amber.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reading your patterns…',
            style: GoogleFonts.plusJakartaSans(
              color: EchoColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Not enough data yet.\nKeep talking to Echo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: EchoColors.textMuted,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    final current = Map<String, dynamic>.from(_data!['current_path'] as Map? ?? {});
    final avoided = Map<String, dynamic>.from(_data!['avoided_path'] as Map? ?? {});
    final ready = _data!['ready'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20, left: 2),
            child: Text(
              'Not prediction. Pattern-based projection.',
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textMuted.withValues(alpha: 0.55),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Current Path
          FadeTransition(
            opacity: _currentCtrl,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(-0.06, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _currentCtrl, curve: Curves.easeOut)),
              child: _buildPathCard(
                label: current['label'] as String? ?? 'Current Path',
                projection: current['projection'] as String? ?? '',
                detail: current['detail'] as String? ?? '',
                isCurrent: true,
                ready: ready,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider with "vs"
          FadeTransition(
            opacity: _dividerCtrl,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: EchoColors.borderSubtle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      color: EchoColors.textMuted.withValues(alpha: 0.35),
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: EchoColors.borderSubtle,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Avoided Path
          FadeTransition(
            opacity: _avoidedCtrl,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _avoidedCtrl, curve: Curves.easeOut)),
              child: _buildPathCard(
                label: avoided['label'] as String? ?? 'Avoided Path',
                projection: avoided['projection'] as String? ?? '',
                detail: avoided['detail'] as String? ?? '',
                isCurrent: false,
                ready: ready,
              ),
            ),
          ),

          if (!ready) ...[
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Keep talking. The patterns become clearer over time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: EchoColors.textMuted.withValues(alpha: 0.4),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPathCard({
    required String label,
    required String projection,
    required String detail,
    required bool isCurrent,
    required bool ready,
  }) {
    final borderColor = isCurrent
        ? EchoColors.textDim.withValues(alpha: 0.5)
        : EchoColors.amber.withValues(alpha: 0.35);
    final labelColor = isCurrent ? EchoColors.textMuted : EchoColors.amber;
    final bgColor = isCurrent
        ? EchoColors.bgSurface
        : EchoColors.amber.withValues(alpha: 0.04);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCurrent ? Icons.trending_flat : Icons.trending_up,
                size: 14,
                color: labelColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                isCurrent ? 'CURRENT PATH' : 'AVAILABLE PATH',
                style: GoogleFonts.plusJakartaSans(
                  color: labelColor.withValues(alpha: 0.7),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: EchoColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            projection,
            style: GoogleFonts.lora(
              color: EchoColors.textSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.55,
            ),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail,
              style: GoogleFonts.plusJakartaSans(
                color: EchoColors.textMuted,
                fontSize: 12.5,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
