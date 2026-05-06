import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_api_client.dart';
import 'package:chatmcp/echo/echo_loop_state.dart';
import 'package:chatmcp/echo/echo_theme.dart';

class ProofBuilderScreen extends StatefulWidget {
  const ProofBuilderScreen({super.key});

  @override
  State<ProofBuilderScreen> createState() => _ProofBuilderScreenState();
}

class _ProofBuilderScreenState extends State<ProofBuilderScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await EchoApiClient().getProofItems();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _addProof() async {
    final result = await showModalBottomSheet<_ProofDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProofDraftSheet(),
    );
    if (result == null) return;
    setState(() => _saving = true);
    final saved = await EchoApiClient().createProofItem(
      title: result.title,
      description: result.description,
      category: result.category,
      evidence: result.evidence,
      skillTags: result.skillTags,
      opportunityType: result.opportunityType,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save proof. Check your Echo connection.')));
      return;
    }
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  Future<void> _deleteProof(Map<String, dynamic> item) async {
    final id = item['id'] as String?;
    if (id == null || id.isEmpty) return;
    final ok = await EchoApiClient().deleteProofItem(id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete proof.')));
      return;
    }
    await Future.wait([_load(), EchoLoopState().refresh()]);
  }

  @override
  Widget build(BuildContext context) {
    final items = (_data?['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    final summary = Map<String, dynamic>.from(_data?['summary'] as Map? ?? {});
    final count = (summary['count'] as num?)?.toInt() ?? items.length;
    final byCategory = (summary['by_category'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: EchoColors.amber,
          backgroundColor: EchoColors.bgSurface,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
              _header(context),
              const SizedBox(height: 20),
              Text(
                'Turn today\'s work into proof someone else can understand.',
                style: GoogleFonts.lora(fontSize: 24, height: 1.28, fontStyle: FontStyle.italic, color: EchoColors.textPrimary),
              ),
              const SizedBox(height: 14),
              Text(
                'Save artifacts, outcomes, practice wins, decisions, and feedback. Echo uses this to build a stronger Passport for jobs, school, scholarships, projects, or personal goals.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.55, color: EchoColors.textMuted),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.inventory_2_outlined, '$count proof items'),
                  ...byCategory.take(3).map((cat) => _pill(Icons.label_outline_rounded, '${cat['category']} ${cat['cnt']}')),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _addProof,
                  icon: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_rounded, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Add proof'),
                  style: FilledButton.styleFrom(
                    backgroundColor: EchoColors.amber,
                    foregroundColor: EchoColors.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 44),
                  child: Center(child: CircularProgressIndicator(color: EchoColors.amber)),
                )
              else if (items.isEmpty)
                _empty()
              else
                ...items.map((item) => _proofCard(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Proof Builder',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: EchoColors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, color: EchoColors.textGhost),
        ),
      ],
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Text(
        'Start with one small item: a shipped file, a practice result, a decision you made better, or feedback from someone you helped.',
        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.5, color: EchoColors.textMuted),
      ),
    );
  }

  Widget _proofCard(Map<String, dynamic> item) {
    final title = item['title'] as String? ?? 'Proof item';
    final description = item['description'] as String? ?? '';
    final evidence = item['evidence'] as String? ?? '';
    final category = item['category'] as String? ?? 'practice';
    final tags = (item['skill_tags'] as List? ?? []).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: EchoColors.amber.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: EchoColors.amber.withValues(alpha: 0.20)),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 17, color: EchoColors.amber),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      category.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.w800, color: EchoColors.amber),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteProof(item),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: EchoColors.textGhost,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(description, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: EchoColors.textMuted)),
          ],
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(evidence, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.45, color: EchoColors.textGhost)),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(spacing: 6, runSpacing: 6, children: tags.take(5).map((tag) => _smallTag(tag)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: EchoColors.amber.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: EchoColors.textMuted)),
        ],
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: EchoColors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EchoColors.borderSubtle),
      ),
      child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: EchoColors.textGhost)),
    );
  }
}

class _ProofDraft {
  final String title;
  final String description;
  final String evidence;
  final String category;
  final List<String> skillTags;
  final String opportunityType;

  const _ProofDraft({
    required this.title,
    required this.description,
    required this.evidence,
    required this.category,
    required this.skillTags,
    required this.opportunityType,
  });
}

class _ProofDraftSheet extends StatefulWidget {
  const _ProofDraftSheet();

  @override
  State<_ProofDraftSheet> createState() => _ProofDraftSheetState();
}

class _ProofDraftSheetState extends State<_ProofDraftSheet> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _evidenceCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _category = 'practice';
  String _opportunityType = 'personal_goal';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _evidenceCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final evidence = _evidenceCtrl.text.trim();
    if (title.isEmpty && description.isEmpty && evidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title, description, or evidence.')));
      return;
    }
    Navigator.of(context).pop(
      _ProofDraft(
        title: title.isEmpty ? (description.isEmpty ? evidence : description) : title,
        description: description,
        evidence: evidence,
        category: _category,
        skillTags: _tagsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        opportunityType: _opportunityType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: EchoColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: EchoColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: EchoColors.amber, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Add proof',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: EchoColors.textGhost,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _field(_titleCtrl, 'Title', 'Built a portfolio draft'),
                const SizedBox(height: 10),
                _field(_descriptionCtrl, 'What happened?', 'Describe the action, artifact, or result.', minLines: 2, maxLines: 4),
                const SizedBox(height: 10),
                _field(_evidenceCtrl, 'Evidence', 'Link, file name, metric, feedback, or short proof note.', minLines: 2, maxLines: 4),
                const SizedBox(height: 14),
                Text('Category', style: _labelStyle()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _choice('practice', 'Practice'),
                    _choice('artifact', 'Artifact'),
                    _choice('feedback', 'Feedback'),
                    _choice('outcome', 'Outcome'),
                  ],
                ),
                const SizedBox(height: 14),
                _field(_tagsCtrl, 'Skills', 'writing, coding, sales', minLines: 1, maxLines: 1),
                const SizedBox(height: 14),
                Text('Opportunity', style: _labelStyle()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _opportunityChoice('personal_goal', 'Goal'),
                    _opportunityChoice('job', 'Job'),
                    _opportunityChoice('school', 'School'),
                    _opportunityChoice('scholarship', 'Scholarship'),
                    _opportunityChoice('project', 'Project'),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save proof'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EchoColors.amber,
                      foregroundColor: EchoColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint, {int minLines = 1, int maxLines = 1}) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: EchoColors.textPrimary, height: 1.45),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: EchoColors.textGhost),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: EchoColors.textVeryGhost),
        filled: true,
        fillColor: EchoColors.bgInput,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EchoColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EchoColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EchoColors.amber)),
      ),
    );
  }

  Widget _choice(String value, String label) {
    final selected = _category == value;
    return GestureDetector(
      onTap: () => setState(() => _category = value),
      child: _chip(label, selected),
    );
  }

  Widget _opportunityChoice(String value, String label) {
    final selected = _opportunityType == value;
    return GestureDetector(
      onTap: () => setState(() => _opportunityType = value),
      child: _chip(label, selected),
    );
  }

  Widget _chip(String label, bool selected) {
    return Container(
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
    );
  }

  TextStyle _labelStyle() => GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: EchoColors.textGhost);
}
