import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/page/echo_tabs/memories_screen.dart';
import 'package:chatmcp/page/echo_tabs/operating_system_screen.dart';
import 'package:chatmcp/page/echo_tabs/permanent_record_screen.dart';

class WhatEchoUsesScreen extends StatelessWidget {
  const WhatEchoUsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: EchoColors.bg,
        appBar: AppBar(
          backgroundColor: EchoColors.bg,
          elevation: 0,
          iconTheme: IconThemeData(color: EchoColors.textPrimary),
          title: Text(
            'What Echo uses',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Text(
                  'Echo should never feel mysterious. These are the sources that shape your read, your daily practice, and how Echo improves.',
                  style: GoogleFonts.newsreader(fontSize: 20, height: 1.32, fontWeight: FontWeight.w600, color: EchoColors.textPrimary),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: EchoColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EchoColors.borderSubtle),
                ),
                child: TabBar(
                  isScrollable: true,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: EchoColors.primaryAi.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                  labelColor: EchoColors.primaryAi,
                  unselectedLabelColor: EchoColors.textGhost,
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800),
                  tabs: const [
                    Tab(text: 'Memories'),
                    Tab(text: 'Rules'),
                    Tab(text: 'Evidence'),
                    Tab(text: 'Corrections'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _SourceTab(
                      rows: [
                        _SourceRowSpec(
                          icon: Icons.psychology_alt_outlined,
                          color: EchoColors.memory,
                          title: 'Long-term memory',
                          body: 'Goals, people, patterns, and context Echo is allowed to reuse.',
                          source: 'Saved by you or approved from Talk',
                          confidence: 'User-controlled',
                          lastUsed: 'Used in Talk, Today, and You',
                          action: 'Open memories',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoriesScreen())),
                        ),
                      ],
                      correction: 'Delete or edit anything that feels wrong before it shapes future reads.',
                    ),
                    _SourceTab(
                      rows: [
                        _SourceRowSpec(
                          icon: Icons.rule_folder_outlined,
                          color: EchoColors.practice,
                          title: 'Operating rules',
                          body: 'Preferences and boundaries Echo should follow when it helps you.',
                          source: 'Set by you',
                          confidence: 'Highest priority',
                          lastUsed: 'Applied before model replies',
                          action: 'Open rules',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OperatingSystemScreen())),
                        ),
                      ],
                      correction: 'Rules should override confident guesses. Add a rule when Echo keeps helping in the wrong way.',
                    ),
                    _SourceTab(
                      rows: [
                        _SourceRowSpec(
                          icon: Icons.receipt_long_outlined,
                          color: EchoColors.proof,
                          title: 'Evidence record',
                          body: 'Outcomes, decisions, practice results, proof items, and feedback that explain the current read.',
                          source: 'Captured from actions',
                          confidence: 'Stronger than memory',
                          lastUsed: 'Feeds Path, Proof, and Place',
                          action: 'Open record',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen())),
                        ),
                      ],
                      correction: 'Evidence should make Echo less vague. If a claim has no evidence, treat it as early.',
                    ),
                    _SourceTab(
                      rows: [
                        _SourceRowSpec(
                          icon: Icons.edit_note_rounded,
                          color: EchoColors.risk,
                          title: 'Corrections',
                          body: 'When you mark a read as partly true or not true, Echo should store the correction and reduce confidence.',
                          source: 'Inline feedback in You',
                          confidence: 'Calibration signal',
                          lastUsed: 'Updates future reads',
                          action: 'Open record',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermanentRecordScreen())),
                        ),
                      ],
                      correction: 'The goal is not for Echo to sound certain. The goal is for Echo to become easier to correct.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTab extends StatelessWidget {
  final List<_SourceRowSpec> rows;
  final String correction;

  const _SourceTab({required this.rows, required this.correction});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      children: [
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SourceCard(row: row),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Color.alphaBlend(EchoColors.risk.withValues(alpha: 0.06), EchoColors.bgSurface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: EchoColors.risk.withValues(alpha: 0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tune_rounded, color: EchoColors.risk, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(correction, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.45, color: EchoColors.textSecondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourceRowSpec {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String source;
  final String confidence;
  final String lastUsed;
  final String action;
  final VoidCallback onTap;

  const _SourceRowSpec({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.source,
    required this.confidence,
    required this.lastUsed,
    required this.action,
    required this.onTap,
  });
}

class _SourceCard extends StatelessWidget {
  final _SourceRowSpec row;

  const _SourceCard({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color.alphaBlend(row.color.withValues(alpha: 0.18), EchoColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: row.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: row.color.withValues(alpha: 0.20)),
                ),
                child: Icon(row.icon, color: row.color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(row.body, style: GoogleFonts.plusJakartaSans(fontSize: 11.8, height: 1.38, color: EchoColors.textGhost)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: row.source, color: row.color),
              _MetaChip(label: row.confidence, color: EchoColors.primaryAi),
              _MetaChip(label: row.lastUsed, color: EchoColors.textGhost),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: row.onTap,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text(row.action),
              style: TextButton.styleFrom(
                foregroundColor: row.color,
                textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
