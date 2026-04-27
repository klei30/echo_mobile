import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chatmcp/echo/echo_theme.dart';
import 'package:chatmcp/echo/echo_orb.dart';

/// Data model for an experiment
class EchoExperiment {
  final int number;
  final String trigger;
  final String hypothesis;
  final String title;
  final String body;
  final String followup;
  final int durationDays;
  final int? currentDay;

  const EchoExperiment({
    required this.number,
    required this.trigger,
    required this.hypothesis,
    required this.title,
    required this.body,
    required this.followup,
    this.durationDays = 7,
    this.currentDay,
  });
}

/// S18 — Experiment Proposal Screen
class ExperimentProposalScreen extends StatelessWidget {
  final EchoExperiment experiment;
  final VoidCallback? onAccept;
  final VoidCallback? onSkip;

  const ExperimentProposalScreen({
    super.key,
    required this.experiment,
    this.onAccept,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrigger(),
                    _buildNumberRow(),
                    _buildHypothesis(),
                    _buildExperimentCard(),
                    const SizedBox(height: 20),
                    _buildButtons(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EchoColors.bgSurface,
                border: Border.all(color: EchoColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 16, color: EchoColors.textMuted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Experiment', style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: EchoColors.textPrimary)),
                Text('From what Echo observed', style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5, color: EchoColors.textGhost)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrigger() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0806),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF161210)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [EchoColors.amber, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.lora(
                  fontSize: 12, height: 1.6,
                  fontStyle: FontStyle.italic, color: const Color(0xFF5A5550),
                ),
                children: _parseTrigger(experiment.trigger),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseTrigger(String text) {
    final parts = text.split('**');
    return List.generate(parts.length, (i) => TextSpan(
      text: parts[i],
      style: i.isOdd
          ? GoogleFonts.lora(
              fontSize: 12, fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w500, color: const Color(0xFF8A8480))
          : null,
    ));
  }

  Widget _buildNumberRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF131009),
              border: Border.all(color: EchoColors.amber.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(
                '${experiment.number}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: EchoColors.amber,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'EXPERIMENT · FROM OBSERVATION',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10, fontWeight: FontWeight.w700,
              letterSpacing: 1.0, color: const Color(0xFF4A4038),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHypothesis() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 2),
      child: Text(
        '"${experiment.hypothesis}"',
        style: GoogleFonts.lora(
          fontSize: 13, fontStyle: FontStyle.italic,
          color: const Color(0xFF5A5048), height: 1.6,
        ),
      ),
    );
  }

  Widget _buildExperimentCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0806),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF161210)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF141009),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E1815)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF6A6058)),
                const SizedBox(width: 6),
                Text(
                  '${experiment.durationDays} days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: const Color(0xFF6A6058),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            experiment.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17, fontWeight: FontWeight.w500,
              color: EchoColors.textPrimary, height: 1.5, letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, height: 1.7, color: const Color(0xFF6A6560),
              ),
              children: _parseBody(experiment.body),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF0F0E0C))),
            ),
            child: Text(
              experiment.followup,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5, fontStyle: FontStyle.italic,
                color: const Color(0xFF3A3530),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseBody(String text) {
    final parts = text.split('**');
    return List.generate(parts.length, (i) => TextSpan(
      text: parts[i],
      style: i.isOdd
          ? const TextStyle(
              color: Color(0xFFA8A4A0), fontWeight: FontWeight.w500)
          : null,
    ));
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onAccept ?? () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [Color(0xFFB46A28), Color(0xFFE0A850)],
                ),
              ),
              child: Text(
                'I\'ll try it',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: const Color(0xFF060504), letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSkip ?? () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0D0B),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFF161210)),
            ),
            child: Text(
              'Not now',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: const Color(0xFF3A3530),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// S19 — Experiment Check-in Screen
class ExperimentCheckinScreen extends StatefulWidget {
  final EchoExperiment experiment;
  final String? echoObservation;
  final String? dataPoint;
  final List<String> quickReplies;

  const ExperimentCheckinScreen({
    super.key,
    required this.experiment,
    this.echoObservation,
    this.dataPoint,
    this.quickReplies = const ['It\'s working', 'It feels strange', 'Haven\'t tried yet'],
  });

  @override
  State<ExperimentCheckinScreen> createState() => _ExperimentCheckinScreenState();
}

class _ExperimentCheckinScreenState extends State<ExperimentCheckinScreen> {
  int? _selectedReply;

  @override
  Widget build(BuildContext context) {
    final exp = widget.experiment;
    final currentDay = exp.currentDay ?? 3;
    final progress = currentDay / exp.durationDays;

    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _buildProgressBar(progress, currentDay, exp.durationDays, exp.number),
                  const SizedBox(height: 12),
                  _buildCheckinBubble(),
                  const SizedBox(height: 10),
                  _buildInsightBubble(),
                  const SizedBox(height: 8),
                  _buildQuickReplies(),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      decoration: const BoxDecoration(
        color: EchoColors.bg,
        border: Border(bottom: BorderSide(color: EchoColors.borderNav)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: EchoColors.textMuted),
          ),
          const SizedBox(width: 10),
          EchoOrb(size: 32, rings: 2),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Echo', style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: EchoColors.textPrimary, letterSpacing: -0.3)),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: EchoColors.textGhost),
                    children: [
                      TextSpan(
                        text: 'week ${(widget.experiment.currentDay ?? 3) ~/ 7 + 1}',
                        style: const TextStyle(color: Color(0xFF9A7048), fontWeight: FontWeight.w500),
                      ),
                      const TextSpan(text: ' · experiment active'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, int currentDay, int total, int expNum) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: const Color(0xFF161210),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE0A850)),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Experiment #$expNum · ${widget.experiment.title}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: const Color(0xFF6A5A40),
              ),
            ),
            Text(
              'Day $currentDay of $total',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: const Color(0xFF3A3530),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckinBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        EchoOrb(size: 28, rings: 1),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 278),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF121009),
              border: Border.all(color: const Color(0xFF1C1915)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomLeft: Radius.circular(3), bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'Day ${widget.experiment.currentDay ?? 3}. How\'s the experiment going?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, height: 1.65, color: const Color(0xFFC8C4BE),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBubble() {
    final observation = widget.echoObservation ??
        'Echo is watching how the experiment lands. Keep going — patterns take a few days to surface.';
    final dataPoint = widget.dataPoint ?? 'Come back tomorrow and Echo will have more to show you.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        EchoOrb(size: 28, rings: 1),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 278),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF120E08), Color(0xFF181208)],
              ),
              border: Border.all(color: EchoColors.amber.withValues(alpha: 0.2)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16),
                bottomLeft: Radius.circular(3), bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: EchoColors.amber,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'I NOTICED SOMETHING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        letterSpacing: 0.8, color: EchoColors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5, height: 1.65,
                      color: const Color(0xFFC8C4BE),
                    ),
                    children: _parseObservation(observation),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dataPoint,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF7A7570), height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _parseObservation(String text) {
    final parts = text.split('**');
    return List.generate(parts.length, (i) => TextSpan(
      text: parts[i],
      style: i.isOdd
          ? const TextStyle(
              color: Color(0xFFEAE6E0), fontWeight: FontWeight.w600)
          : null,
    ));
  }

  Widget _buildQuickReplies() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: List.generate(widget.quickReplies.length, (i) {
          final selected = _selectedReply == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedReply = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0D0B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? EchoColors.amber.withValues(alpha: 0.3)
                      : const Color(0xFF1E1B17),
                ),
              ),
              child: Text(
                widget.quickReplies[i],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: selected ? EchoColors.amber : const Color(0xFF5A5550),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: const BoxDecoration(
        color: EchoColors.bg,
        border: Border(top: BorderSide(color: EchoColors.borderNav)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: EchoColors.bgInput,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: EchoColors.border),
              ),
              child: Text(
                'Tell Echo what happened...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, color: EchoColors.textGhost,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
