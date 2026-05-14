import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:chatmcp/echo/echo_theme.dart';

class EchoSpacing {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
}

class EchoRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double pill = 999;
}

// ── Typography ────────────────────────────────────────────────────────────────

class EchoText {
  // Monospace label — eyebrow / section header (Fix #2)
  static TextStyle label({Color? color}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: 9.5,
      letterSpacing: 0.08 * 9.5,
      fontWeight: FontWeight.w700,
      color: color ?? EchoColors.textGhost,
      height: 1.2,
    );
  }

  static TextStyle title({double size = 18, Color? color}) {
    return GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: FontWeight.w900, color: color ?? EchoColors.textPrimary, height: 1.22);
  }

  static TextStyle body({double size = 13, Color? color}) {
    return GoogleFonts.plusJakartaSans(fontSize: size, color: color ?? EchoColors.textSecondary, height: 1.5);
  }

  // Italic serif — for Echo "insight" quotes
  static TextStyle insight({double size = 17, Color? color}) {
    return GoogleFonts.newsreader(fontSize: size, fontStyle: FontStyle.italic, color: color ?? EchoColors.textPrimary, height: 1.38);
  }

  // Non-italic serif — Proof Passport current read title (Fix #10)
  static TextStyle serifTitle({double size = 15, Color? color}) {
    return GoogleFonts.newsreader(fontSize: size, fontWeight: FontWeight.w600, color: color ?? EchoColors.textPrimary, height: 1.28);
  }
}

// ── Page shell ────────────────────────────────────────────────────────────────

class EchoPageShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  const EchoPageShell({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 36), this.maxWidth = 980});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// ── Card variants (Fix #4) ────────────────────────────────────────────────────

enum EchoCardStyle { plain, ai, practice, proof, memory, gold }

// ── Panel ─────────────────────────────────────────────────────────────────────

class EchoPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final EchoCardStyle style;

  const EchoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.borderColor,
    this.radius = EchoRadii.md,
    this.onTap,
    this.style = EchoCardStyle.plain,
  });

  ({Color accent, Color defaultBorder}) _styleTokens() {
    switch (style) {
      case EchoCardStyle.ai:
        return (accent: EchoColors.amber, defaultBorder: Color.alphaBlend(EchoColors.amber.withValues(alpha: 0.24), EchoColors.border));
      case EchoCardStyle.practice:
        return (accent: EchoColors.practice, defaultBorder: Color.alphaBlend(EchoColors.practice.withValues(alpha: 0.24), EchoColors.border));
      case EchoCardStyle.proof:
        return (accent: EchoColors.proof, defaultBorder: Color.alphaBlend(EchoColors.proof.withValues(alpha: 0.24), EchoColors.border));
      case EchoCardStyle.memory:
        return (accent: EchoColors.memory, defaultBorder: Color.alphaBlend(EchoColors.memory.withValues(alpha: 0.24), EchoColors.border));
      case EchoCardStyle.gold:
        return (accent: EchoColors.opportunity, defaultBorder: Color.alphaBlend(EchoColors.opportunity.withValues(alpha: 0.30), EchoColors.border));
      case EchoCardStyle.plain:
        return (accent: EchoColors.surface, defaultBorder: borderColor ?? EchoColors.borderSubtle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _styleTokens();
    final effectiveBorder = borderColor ?? tokens.defaultBorder;

    final Decoration decoration;
    if (style != EchoCardStyle.plain) {
      final tinted = Color.alphaBlend(tokens.accent.withValues(alpha: 0.09), EchoColors.surface);
      decoration = BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tinted, EchoColors.surface]),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: effectiveBorder),
      );
    } else {
      decoration = BoxDecoration(
        color: background ?? EchoColors.bgSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: effectiveBorder),
      );
    }

    final panel = Container(width: double.infinity, padding: padding, decoration: decoration, child: child);

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: panel),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class EchoSectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final String? body;
  final Widget? trailing;

  const EchoSectionHeader({super.key, required this.label, required this.title, this.body, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: EchoText.label(color: EchoColors.amber)),
              const SizedBox(height: 6),
              Text(title, style: EchoText.title(size: 22)),
              if (body != null) ...[const SizedBox(height: 8), Text(body!, style: EchoText.body(size: 13.2))],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

// ── Tag / chip ────────────────────────────────────────────────────────────────

class EchoTag extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;
  final bool filled;

  const EchoTag({super.key, this.icon, required this.label, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EchoColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: filled ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(EchoRadii.pill),
        border: Border.all(color: c.withValues(alpha: filled ? 0.32 : 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: c), const SizedBox(width: 5)],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w700, color: c, height: 1.15),
          ),
        ],
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class EchoPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const EchoPrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EchoColors.amber;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: c,
        foregroundColor: EchoColors.bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoRadii.md)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class EchoSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const EchoSecondaryButton({super.key, required this.label, this.icon, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EchoColors.textPrimary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        side: BorderSide(color: EchoColors.borderSubtle),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(EchoRadii.md)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

// ── Metric tile (Fix #8 — value glow) ────────────────────────────────────────

class EchoMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  final double? barValue; // 0.0–1.0; renders 3 px bar when set

  const EchoMetric({super.key, required this.value, required this.label, this.color, this.barValue});

  @override
  Widget build(BuildContext context) {
    final c = color ?? EchoColors.amber;
    return Expanded(
      child: EchoPanel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.spaceMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c,
                shadows: [Shadow(color: c.withValues(alpha: 0.55), blurRadius: 16)],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EchoText.label(color: EchoColors.textGhost),
            ),
            if (barValue != null) ...[
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  height: 3,
                  color: EchoColors.borderSubtle,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: barValue!.clamp(0.0, 1.0),
                    child: Container(color: c),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Progress bar with shimmer (Fix #7) ───────────────────────────────────────

class EchoProgressBar extends StatefulWidget {
  final double value; // 0.0–1.0
  const EchoProgressBar({super.key, required this.value});

  @override
  State<EchoProgressBar> createState() => _EchoProgressBarState();
}

class _EchoProgressBarState extends State<EchoProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(EchoRadii.pill),
      child: SizedBox(
        height: 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Track
            Container(color: EchoColors.deepSurface),
            // Fill + shimmer overlay
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clamped,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context2, child2) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [EchoColors.practice, EchoColors.amber])),
                        ),
                        // Shimmer sweep
                        LayoutBuilder(
                          builder: (_, c) => Transform.translate(
                            offset: Offset(c.maxWidth * (_anim.value * 2 - 0.3), 0),
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withValues(alpha: 0.22), Colors.transparent]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subtle grid background (Fix #13) ─────────────────────────────────────────

class EchoGridBackground extends StatelessWidget {
  final Widget child;
  const EchoGridBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(), child: child);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EchoColors.textPrimary.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 32; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Action strip ──────────────────────────────────────────────────────────────

class EchoActionStrip extends StatelessWidget {
  final List<EchoActionStripItem> items;
  const EchoActionStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items
          .map(
            (item) => InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(EchoRadii.pill),
              child: EchoTag(icon: item.icon, label: item.label, color: item.color, filled: item.filled),
            ),
          )
          .toList(),
    );
  }
}

class EchoActionStripItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool filled;

  const EchoActionStripItem({required this.icon, required this.label, required this.onTap, this.color, this.filled = false});
}
