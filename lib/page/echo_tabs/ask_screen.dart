import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/council_screen.dart';
import 'package:chatmcp/page/echo_tabs/twin_screen.dart';
import 'package:chatmcp/page/echo_tabs/parallel_self_screen.dart';

enum _AskMode { voices, twin, paths }

class AskScreen extends StatefulWidget {
  final String? initialQuestion;
  final String? threadId;
  final String? threadContext;

  const AskScreen({
    super.key,
    this.initialQuestion,
    this.threadId,
    this.threadContext,
  });

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> with SingleTickerProviderStateMixin {
  _AskMode _mode = _AskMode.voices;
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _switchMode(_AskMode mode) {
    HapticFeedback.selectionClick();
    setState(() => _mode = mode);
    _pageCtrl.animateToPage(
      mode.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      appBar: AppBar(
        backgroundColor: EchoColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          color: EchoColors.textMuted,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ask',
          style: GoogleFonts.inter(
            color: EchoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildModeSelector(),
        ),
      ),
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          CouncilScreen(
            initialQuestion: widget.initialQuestion,
            threadId: widget.threadId,
            threadContext: widget.threadContext,
          ),
          const TwinScreen(),
          const ParallelSelfScreen(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _modeTab('Voices', _AskMode.voices),
          const SizedBox(width: 8),
          _modeTab('Twin', _AskMode.twin),
          const SizedBox(width: 8),
          _modeTab('Paths', _AskMode.paths),
        ],
      ),
    );
  }

  Widget _modeTab(String label, _AskMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => _switchMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? EchoColors.amber.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? EchoColors.amber.withValues(alpha: 0.40)
                : EchoColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? EchoColors.amber : EchoColors.textMuted,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
