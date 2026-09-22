import 'package:flutter/material.dart';

import 'surfaces.dart';

/// Round white button with a soft shadow, used for back, menu, bell and the
/// bottom navigation.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize,
    this.background,
    this.foreground,
    this.elevated = true,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double? iconSize;
  final Color? background;
  final Color? foreground;
  final bool elevated;

  /// Marks the button as the current tab for screen readers.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final enabled = onPressed != null;
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: palette.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: background ?? palette.card,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(
                dimension: size,
                child: Icon(
                  icon,
                  size: iconSize ?? size * 0.46,
                  color: enabled
                      ? foreground ?? palette.ink
                      : palette.muted.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
