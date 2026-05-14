import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_design_system.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';

class MemoryConsentSheet extends StatefulWidget {
  final String proposedMemory;
  final String sourceType;

  const MemoryConsentSheet({
    super.key,
    required this.proposedMemory,
    this.sourceType = 'talk',
  });

  static Future<bool?> show(
    BuildContext context, {
    required String proposedMemory,
    String sourceType = 'talk',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemoryConsentSheet(proposedMemory: proposedMemory, sourceType: sourceType),
    );
  }

  @override
  State<MemoryConsentSheet> createState() => _MemoryConsentSheetState();
}

class _MemoryConsentSheetState extends State<MemoryConsentSheet> {
  late final TextEditingController _controller;
  String _privacy = 'private';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _compact(widget.proposedMemory));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _compact(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 420) return normalized;
    return normalized.substring(0, 420);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await EchoApiClient().proposeMemory(text: _controller.text, sourceType: widget.sourceType, privacy: _privacy);
    if (!mounted) return;
    if (ok) {
      await EchoLoopState().refresh();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this lesson. Check your Echo connection.')));
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
                  Icon(Icons.lock_outline_rounded, color: EchoColors.memory, size: 18),
                  const SizedBox(width: 9),
                  Expanded(child: Text('Should Echo remember this?', style: EchoText.title(size: 15))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: EchoColors.textGhost,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Memory should be explicit. Edit the lesson before Echo uses it in Today, You, or future practice.',
                style: EchoText.body(size: 12.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textPrimary, height: 1.45),
                decoration: InputDecoration(
                  hintText: 'Write the lesson Echo should remember.',
                  filled: true,
                  fillColor: EchoColors.bgInput,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EchoColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EchoColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EchoColors.memory)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _privacyChip('private', 'Private only'),
                  _privacyChip('training', 'Use to improve Echo'),
                  _privacyChip('never_share', 'Never share'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: EchoSecondaryButton(
                      label: 'Not now',
                      icon: Icons.close_rounded,
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EchoPrimaryButton(
                      label: _saving ? 'Saving...' : 'Remember',
                      icon: Icons.check_rounded,
                      color: EchoColors.memory,
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyChip(String value, String label) {
    final selected = _privacy == value;
    return GestureDetector(
      onTap: () => setState(() => _privacy = value),
      child: EchoTag(
        icon: selected ? Icons.check_rounded : Icons.circle_outlined,
        label: label,
        color: selected ? EchoColors.memory : EchoColors.textGhost,
        filled: selected,
      ),
    );
  }
}
