import 'package:flutter/material.dart';

import 'glass.dart';
import 'surfaces.dart';

/// Round frosted-glass button, used for back, menu, bell and the bottom
/// navigation. [selected] gives it the accent tint; otherwise it is neutral.
class CircleIconButton extends StatefulWidget {
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

  /// Accent tint override; when null a selected button uses the theme primary.
  final Color? background;
  final Color? foreground;
  final bool elevated;

  /// Marks the button as the current tab for screen readers, and tints it.
  final bool selected;

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final tint = widget.background ?? (widget.selected ? scheme.primary : null);
    // Selected/accent buttons carry white icons; neutral ones use the ink.
    final iconColor = enabled
        ? widget.foreground ?? (tint != null ? Colors.white : palette.ink)
        : palette.muted.withValues(alpha: 0.5);

    return Semantics(
      selected: widget.selected,
      button: true,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: GlassSurface(
            shape: BoxShape.circle,
            tint: tint,
            glow: widget.elevated,
            pressed: _pressed,
            disabled: !enabled,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onPressed,
                child: SizedBox.square(
                  dimension: widget.size,
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize ?? widget.size * 0.46,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
