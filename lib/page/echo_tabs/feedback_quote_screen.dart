import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class FeedbackQuoteScreen extends StatefulWidget {
  final String? context;
  const FeedbackQuoteScreen({super.key, this.context});

  @override
  State<FeedbackQuoteScreen> createState() => _FeedbackQuoteScreenState();
}

class _FeedbackQuoteScreenState extends State<FeedbackQuoteScreen> {
  final _quoteCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  bool _showTemplate = false;

  static const _template = 'Hi — I\'ve been working on [what you did]. Can you give one sentence on what improved or what you noticed?\nThanks.';

  @override
  void dispose() {
    _quoteCtrl.dispose();
    _fromCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_quoteCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await EchoApiClient().createProofItem(
      title: 'Feedback: ${_fromCtrl.text.trim().isNotEmpty ? _fromCtrl.text.trim() : 'external source'}',
      description: _quoteCtrl.text.trim(),
      category: 'feedback',
      opportunityType: 'scholarship_story',
      skillTags: ['external proof', 'feedback'],
      sourceType: 'feedback_quote',
    );
    if (!mounted) return;
    setState(() { _saving = false; _saved = true; });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EchoColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Feedback quote saved to Proof.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted),
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ask for proof', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost, letterSpacing: 0.5)),
                      Text('Feedback', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: EchoColors.textPrimary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: EchoColors.textGhost),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message template card
            GestureDetector(
              onTap: () => setState(() => _showTemplate = !_showTemplate),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      EchoColors.primaryAi.withValues(alpha: 0.08),
                      EchoColors.bgSurface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EchoColors.primaryAi.withValues(alpha: 0.20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'MESSAGE TEMPLATE',
                          style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.primaryAi.withValues(alpha: 0.70)),
                        ),
                        const Spacer(),
                        Icon(_showTemplate ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16, color: EchoColors.textGhost),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Can you give one sentence on what improved?',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EchoColors.textPrimary, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The opportunity engine helps collect external evidence, not only organize internal notes.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                    ),
                    if (_showTemplate) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: EchoColors.bgInput,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EchoColors.border),
                        ),
                        child: Text(
                          _template,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textMuted, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: _template));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: EchoColors.bgCard,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: Text('Template copied.', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted)),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.copy_outlined, size: 14, color: EchoColors.primaryAi),
                            const SizedBox(width: 6),
                            Text('Copy template', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: EchoColors.primaryAi)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Steps
            _stepRow(Icons.send_rounded, EchoColors.practice, 'ready', 'Send request', 'one specific ask to one person'),
            const SizedBox(height: 8),
            _stepRow(Icons.format_quote_rounded, EchoColors.proof, 'next', 'Save quote', 'redact private details before saving'),
            const SizedBox(height: 20),

            Text('WHO GAVE FEEDBACK (optional)', style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.textGhost)),
            const SizedBox(height: 8),
            _buildField(_fromCtrl, 'e.g. colleague, mentor, manager...', maxLines: 1),
            const SizedBox(height: 16),

            Text('FEEDBACK QUOTE', style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.textGhost)),
            const SizedBox(height: 8),
            _buildField(_quoteCtrl, 'Paste or type the feedback here...', maxLines: 5),
            const SizedBox(height: 6),
            Text(
              'Remove names or private details before saving.',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _saving || _saved ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _saved ? EchoColors.practice : EchoColors.primaryAi,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: _saving
                    ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)))
                    : Text(
                        _saved ? 'Saved to Proof' : 'Create request',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepRow(IconData icon, Color color, String tag, String title, String sub) {
    final tagBg = tag == 'ready' ? EchoColors.practice.withValues(alpha: 0.12) : EchoColors.bgSurface;
    final tagFg = tag == 'ready' ? EchoColors.practice : EchoColors.textGhost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: EchoColors.textPrimary)),
                Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: tagFg.withValues(alpha: 0.28))),
            child: Text(tag, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: tagFg)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: EchoColors.bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EchoColors.border),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 2 : 1,
        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: EchoColors.textPrimary, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textGhost),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
