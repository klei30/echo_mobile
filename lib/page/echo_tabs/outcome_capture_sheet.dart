import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_loop_receipt.dart';
import 'package:chatmcp/echo/echo_theme.dart';

class OutcomeCaptureSheet extends StatefulWidget {
  final String title;
  final String subjectType;
  final String? subjectId;
  final String contextNote;
  final String doneLabel;
  final String skippedLabel;
  final bool createProof;
  final String proofCategory;
  final String opportunityType;
  final String? proofTitle;
  final VoidCallback? onSaved;

  static Map<String, dynamic>? _lastLoopDelta;

  const OutcomeCaptureSheet({
    super.key,
    required this.title,
    required this.subjectType,
    this.subjectId,
    this.contextNote = '',
    this.doneLabel = 'Done',
    this.skippedLabel = 'Skipped',
    this.createProof = false,
    this.proofCategory = 'outcome',
    this.opportunityType = 'personal_goal',
    this.proofTitle,
    this.onSaved,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String subjectType,
    String? subjectId,
    String contextNote = '',
    String doneLabel = 'Done',
    String skippedLabel = 'Skipped',
    bool createProof = false,
    String proofCategory = 'outcome',
    String opportunityType = 'personal_goal',
    String? proofTitle,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OutcomeCaptureSheet(
        title: title,
        subjectType: subjectType,
        subjectId: subjectId,
        contextNote: contextNote,
        doneLabel: doneLabel,
        skippedLabel: skippedLabel,
        createProof: createProof,
        proofCategory: proofCategory,
        opportunityType: opportunityType,
        proofTitle: proofTitle,
        onSaved: onSaved,
      ),
    ).then((saved) {
      if (saved == true && context.mounted) {
        final delta = OutcomeCaptureSheet._lastLoopDelta;
        OutcomeCaptureSheet._lastLoopDelta = null;
        EchoLoopReceipt.showFromDelta(context, delta, fallbackProofCreated: createProof);
      }
      return saved;
    });
  }

  @override
  State<OutcomeCaptureSheet> createState() => _OutcomeCaptureSheetState();
}

class _OutcomeCaptureSheetState extends State<OutcomeCaptureSheet> {
  final _noteCtrl = TextEditingController();
  bool _done = true;
  String _energy = 'gained';
  String _privacy = 'private';
  double _confidence = 3;
  bool _saving = false;

  String _compactTitle(String value, String fallback) {
    final text = value.trim().split(RegExp(r'\s+')).join(' ');
    if (text.isEmpty) return fallback;
    if (text.length <= 90) return text;
    return '${text.substring(0, 87)}...';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final energyScore = switch (_energy) {
      'gained' => 0.25,
      'drained' => -0.25,
      _ => 0.0,
    };
    final score = (_done ? 0.55 : -0.15) + ((_confidence - 3) * 0.10) + energyScore;
    final outcome = _done ? 'completed_with_outcome' : 'skipped_or_blocked';
    final userNote = _noteCtrl.text.trim();
    final note = jsonEncode({
      'context': widget.contextNote,
      'energy': _energy,
      'confidence': _confidence.round(),
      'privacy': _privacy,
      'note': userNote,
    });
    final outcomeResult = await EchoApiClient().recordOutcomeJson(
      subjectType: widget.subjectType,
      subjectId: widget.subjectId,
      outcome: outcome,
      score: score.clamp(-1.0, 1.0).toDouble(),
      note: note,
    );
    final ok = outcomeResult != null;
    var loopDelta = Map<String, dynamic>.from(outcomeResult?['loop_delta'] as Map? ?? {});
    if (!mounted) return;

    var proofOk = true;
    if (ok && widget.createProof && _done) {
      final source = widget.contextNote.trim();
      final proofTitle = _compactTitle(widget.proofTitle ?? userNote, widget.title);
      final proof = await EchoApiClient().createProofItem(
        title: proofTitle,
        description: userNote,
        category: widget.proofCategory,
        sourceType: widget.subjectType,
        sourceId: widget.subjectId,
        evidence: source,
        opportunityType: widget.opportunityType,
      );
      proofOk = proof != null;
      final proofDelta = Map<String, dynamic>.from(proof?['loop_delta'] as Map? ?? {});
      if (proofDelta.isNotEmpty) {
        loopDelta = proofDelta;
      } else if (proofOk) {
        loopDelta['proof_created'] = true;
        loopDelta['next_action'] = 'Open Place to see what this proof can unlock.';
      }
      if (!mounted) return;
    }

    if (ok && proofOk) {
      OutcomeCaptureSheet._lastLoopDelta = loopDelta;
      await EchoLoopState().refresh();
      if (!mounted) return;
      widget.onSaved?.call();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok && widget.createProof ? 'Outcome saved, but proof could not be added.' : 'Could not save outcome. Check your Echo connection.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: EchoColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: EchoColors.amber, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.createProof ? 'Add proof' : 'Log outcome',
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: EchoColors.textGhost,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: GoogleFonts.lora(fontSize: 18, fontStyle: FontStyle.italic, height: 1.35, color: EchoColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _choice(widget.doneLabel, _done, () => setState(() => _done = true))),
                  const SizedBox(width: 10),
                  Expanded(child: _choice(widget.skippedLabel, !_done, () => setState(() => _done = false))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Energy', style: _labelStyle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [_energyChip('gained', 'Gained energy'), _energyChip('neutral', 'Neutral'), _energyChip('drained', 'Drained')],
              ),
              const SizedBox(height: 16),
              Text('Privacy', style: _labelStyle()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _privacyChip('private', 'Private memory'),
                  _privacyChip('proof', 'Proof candidate'),
                  _privacyChip('shareable', 'Safe to share'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Confidence', style: _labelStyle()),
                  const Spacer(),
                  Text('${_confidence.round()}/5', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: EchoColors.textGhost)),
                ],
              ),
              Slider(
                value: _confidence,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: EchoColors.amber,
                inactiveColor: EchoColors.border,
                onChanged: (v) => setState(() => _confidence = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: 4,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textPrimary, height: 1.45),
                decoration: InputDecoration(
                  hintText: 'What happened? What proof did you create?',
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textGhost),
                  filled: true,
                  fillColor: EchoColors.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: EchoColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: EchoColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: EchoColors.amber),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_saving ? 'Saving...' : (widget.createProof ? 'Save proof' : 'Save outcome')),
                  style: FilledButton.styleFrom(
                    backgroundColor: EchoColors.amber,
                    foregroundColor: const Color(0xFF070604),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _labelStyle() => GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: EchoColors.textGhost);

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? EchoColors.amber.withValues(alpha: 0.13) : EchoColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? EchoColors.amber.withValues(alpha: 0.4) : EchoColors.borderSubtle),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? EchoColors.amber : EchoColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _energyChip(String value, String label) {
    final selected = _energy == value;
    return GestureDetector(
      onTap: () => setState(() => _energy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? EchoColors.amber.withValues(alpha: 0.10) : EchoColors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? EchoColors.amber.withValues(alpha: 0.35) : EchoColors.borderSubtle),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? EchoColors.amber : EchoColors.textGhost),
        ),
      ),
    );
  }

  Widget _privacyChip(String value, String label) {
    final selected = _privacy == value;
    final color = value == 'shareable'
        ? EchoColors.proof
        : value == 'proof'
        ? EchoColors.opportunity
        : EchoColors.memory;
    return GestureDetector(
      onTap: () => setState(() => _privacy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : EchoColors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? color.withValues(alpha: 0.35) : EchoColors.borderSubtle),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? color : EchoColors.textGhost),
        ),
      ),
    );
  }
}
