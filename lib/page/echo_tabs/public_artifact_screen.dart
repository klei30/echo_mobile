import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_api_client.dart';

class PublicArtifactScreen extends StatefulWidget {
  final String? proofId;
  final String? seedTitle;
  final String? seedBody;

  const PublicArtifactScreen({super.key, this.proofId, this.seedTitle, this.seedBody});

  @override
  State<PublicArtifactScreen> createState() => _PublicArtifactScreenState();
}

class _PublicArtifactScreenState extends State<PublicArtifactScreen> {
  final _titleCtrl = TextEditingController();
  final _whatChangedCtrl = TextEditingController();
  final _whatLearnedCtrl = TextEditingController();
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    if (widget.seedTitle != null) _titleCtrl.text = widget.seedTitle!;
    if (widget.seedBody != null) _whatChangedCtrl.text = widget.seedBody!;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _whatChangedCtrl.dispose();
    _whatLearnedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await EchoApiClient().createProofItem(
      title: _titleCtrl.text.trim(),
      description: '${_whatChangedCtrl.text.trim()}\n\n${_whatLearnedCtrl.text.trim()}'.trim(),
      category: 'artifact',
      opportunityType: 'starter_portfolio',
      skillTags: ['public artifact'],
      sourceType: 'public_artifact',
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = true;
    });
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EchoColors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Public artifact saved to Proof.', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted)),
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
                      Text('Make it visible', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost, letterSpacing: 0.5)),
                      Text(
                        'Artifact',
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
                      ),
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

            // Draft card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [EchoColors.proof.withValues(alpha: 0.09), EchoColors.bgSurface],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EchoColors.proof.withValues(alpha: 0.24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DRAFT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: EchoColors.proof.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Turn your work into a short public note.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: EchoColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Echo helps write a safe, useful artifact without exposing private memory.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textMuted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'ARTIFACT TITLE',
              style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: EchoColors.textGhost),
            ),
            const SizedBox(height: 8),
            _buildField(_titleCtrl, 'e.g. Reduced API latency by 42%', maxLines: 2),
            const SizedBox(height: 16),

            // Steps
            _stepRow(Icons.change_circle_outlined, EchoColors.proof, '1', 'What changed', 'latency, reliability, speed, outcome'),
            const SizedBox(height: 8),
            _buildField(_whatChangedCtrl, 'Describe what changed or improved (public-safe)...', maxLines: 3),
            const SizedBox(height: 16),

            _stepRow(Icons.lightbulb_outline_rounded, EchoColors.practice, '2', 'What you learned', 'tradeoff in plain words'),
            const SizedBox(height: 8),
            _buildField(_whatLearnedCtrl, 'Explain the tradeoff or insight in plain words...', maxLines: 3),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _saving || _saved ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: _saved ? EchoColors.practice : EchoColors.proof, borderRadius: BorderRadius.circular(13)),
                child: _saving
                    ? Center(
                        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)),
                      )
                    : Text(
                        _saved ? 'Saved to Proof' : 'Draft artifact',
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

  Widget _stepRow(IconData icon, Color color, String num, String title, String sub) {
    return Row(
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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: EchoColors.textPrimary),
              ),
              Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: EchoColors.textGhost)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            num,
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
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
