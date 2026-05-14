import 'package:chatmcp/components/widgets/base.dart';
import 'package:chatmcp/widgets/ink_icon.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart' as wm;
import 'package:chatmcp/generated/app_localizations.dart';

class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove,
          onPressed: () async {
            await wm.windowManager.minimize();
          },
          tooltip: l10n.minimize,
        ),
        const Gap(size: 8),
        _WindowButton(
          icon: Icons.crop_square,
          onPressed: () async {
            bool isMaximized = await wm.windowManager.isMaximized();
            if (isMaximized) {
              await wm.windowManager.unmaximize();
            } else {
              await wm.windowManager.maximize();
            }
          },
          tooltip: l10n.maximize,
        ),
        const Gap(size: 8),
        _WindowButton(
          icon: Icons.close,
          onPressed: () async {
            await wm.windowManager.close();
          },
          tooltip: l10n.close,
          isCloseButton: true,
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isCloseButton;

  const _WindowButton({required this.icon, required this.onPressed, required this.tooltip, this.isCloseButton = false});

  @override
  _WindowButtonState createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor = Colors.transparent;

    backgroundColor = widget.isCloseButton ? Colors.red : (isDark ? Colors.white24 : Colors.black12);

    return InkIcon(icon: widget.icon, onTap: widget.onPressed, hoverColor: backgroundColor, tooltip: widget.tooltip);
  }
}
