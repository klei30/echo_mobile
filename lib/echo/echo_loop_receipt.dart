import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatmcp/echo/echo_theme.dart';

class EchoLoopReceipt extends StatelessWidget {
  final bool proofCreated;
  final bool opportunityUnlocked;
  final bool trainingSignalSaved;
  final String title;
  final String detail;
  final String nextAction;
  final bool queuedOffline;

  const EchoLoopReceipt({
    super.key,
    this.proofCreated = false,
    this.opportunityUnlocked = false,
    this.trainingSignalSaved = false,
    this.title = 'Echo updated',
    this.detail = 'This moment was saved to your loop.',
    this.nextAction = 'Add evidence when you have it.',
    this.queuedOffline = false,
  });

  static void show(
    BuildContext context, {
    bool proofCreated = false,
    bool opportunityUnlocked = false,
    bool trainingSignalSaved = false,
    String title = 'Echo updated',
    String detail = 'This moment was saved to your loop.',
    String nextAction = 'Add evidence when you have it.',
    bool queuedOffline = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          content: EchoLoopReceipt(
            proofCreated: proofCreated,
            opportunityUnlocked: opportunityUnlocked,
            trainingSignalSaved: trainingSignalSaved,
            title: title,
            detail: detail,
            nextAction: nextAction,
            queuedOffline: queuedOffline,
          ),
        ),
      );
  }

  static void showFromDelta(BuildContext context, Map<String, dynamic>? delta, {bool fallbackProofCreated = false}) {
    show(
      context,
      proofCreated: (delta?['proof_created'] as bool?) ?? fallbackProofCreated,
      opportunityUnlocked: delta?['opportunity_unlocked'] as bool? ?? false,
      trainingSignalSaved: delta?['training_signal_saved'] as bool? ?? false,
      title: delta?['receipt_title'] as String? ?? 'Echo updated',
      detail: delta?['receipt_detail'] as String? ?? 'This moment was saved to your loop.',
      nextAction: delta?['next_action'] as String? ?? 'Add evidence when you have it.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EchoColors.practice.withValues(alpha: 0.24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(queuedOffline ? Icons.cloud_off_outlined : Icons.check_circle_outline_rounded, color: EchoColors.practice, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  queuedOffline ? 'Saved on this device' : title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: EchoColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReceiptChip(icon: Icons.flag_outlined, label: 'Outcome saved', color: EchoColors.practice),
              if (trainingSignalSaved) _ReceiptChip(icon: Icons.psychology_alt_outlined, label: 'Echo learned', color: EchoColors.memory),
              _ReceiptChip(
                icon: proofCreated ? Icons.inventory_2_outlined : Icons.psychology_alt_outlined,
                label: proofCreated ? 'Proof saved' : 'Signal saved',
                color: proofCreated ? EchoColors.proof : EchoColors.memory,
              ),
              if (opportunityUnlocked) _ReceiptChip(icon: Icons.place_outlined, label: 'Place updated', color: EchoColors.opportunity),
              if (queuedOffline) _ReceiptChip(icon: Icons.sync_rounded, label: 'Sync later', color: EchoColors.primaryAi),
            ],
          ),
          const SizedBox(height: 10),
          Text(detail, style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: EchoColors.textMuted)),
          const SizedBox(height: 5),
          Text('Next: $nextAction', style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.35, color: EchoColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReceiptChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ReceiptChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
