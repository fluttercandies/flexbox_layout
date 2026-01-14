import 'package:flutter/material.dart';

import '../theme/neo_brutalism.dart';

/// A card widget with Neo-Brutalism style.
///
/// Features:
/// - Thick black border
/// - Hard drop shadow with offset
/// - Optional accent color
/// - Press/tap animation
class NeoCard extends StatefulWidget {
  const NeoCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.hasShadow = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool hasShadow;

  @override
  State<NeoCard> createState() => _NeoCardState();
}

class _NeoCardState extends State<NeoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;

    return GestureDetector(
      onTapDown: isInteractive
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: isInteractive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isInteractive
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: widget.margin,
        transform: Matrix4.translationValues(
          _isPressed ? NeoBrutalism.shadowOffset.dx : 0,
          _isPressed ? NeoBrutalism.shadowOffset.dy : 0,
          0,
        ),
        decoration: NeoBrutalism.shapeDecoration(
          color: widget.color ?? NeoBrutalism.white,
          radius: widget.borderRadius,
          hasShadow: widget.hasShadow && !_isPressed,
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A button with Neo-Brutalism style.
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  /// Creates a Neo-Brutalism button with text.
  factory NeoButton.text({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    Color? color,
    EdgeInsetsGeometry? padding,
  }) {
    return NeoButton(
      key: key,
      onPressed: onPressed,
      color: color,
      padding: padding,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  /// Creates a Neo-Brutalism button with an icon.
  factory NeoButton.icon({
    Key? key,
    required VoidCallback? onPressed,
    required IconData icon,
    Color? color,
    double size = 24,
  }) {
    return NeoButton(
      key: key,
      onPressed: onPressed,
      color: color,
      padding: const EdgeInsets.all(12),
      child: Icon(icon, size: size),
    );
  }

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onPressed != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? NeoBrutalism.shadowOffset.dx : 0,
          _isPressed ? NeoBrutalism.shadowOffset.dy : 0,
          0,
        ),
        decoration: NeoBrutalism.shapeDecoration(
          color: widget.color ?? NeoBrutalism.yellow,
          radius: widget.borderRadius ?? NeoBrutalism.borderRadiusSmall,
          hasShadow: !_isPressed,
        ),
        child: Padding(
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A badge/chip with Neo-Brutalism style.
class NeoBadge extends StatelessWidget {
  const NeoBadge({super.key, required this.label, this.color, this.textColor});

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: NeoBrutalism.shapeDecoration(
        color: color ?? NeoBrutalism.pink,
        radius: 20,
        hasShadow: false,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? NeoBrutalism.black,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// An icon button with Neo-Brutalism style (circular).
class NeoIconButton extends StatefulWidget {
  const NeoIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.iconColor,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double size;

  @override
  State<NeoIconButton> createState() => _NeoIconButtonState();
}

class _NeoIconButtonState extends State<NeoIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onPressed != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        decoration: NeoBrutalism.circleDecoration(
          color: widget.color ?? NeoBrutalism.yellow,
          hasShadow: !_isPressed,
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: widget.iconColor ?? NeoBrutalism.black,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// AppBar with Neo-Brutalism style.
class NeoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NeoAppBar({
    super.key,
    required this.title,
    this.color,
    this.actions,
    this.leading,
    this.bottom,
  });

  final String title;
  final Color? color;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight +
        (bottom?.preferredSize.height ?? 0) +
        NeoBrutalism.borderWidth,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? NeoBrutalism.yellow,
        border: Border(
          bottom: BorderSide(
            color: NeoBrutalism.black,
            width: NeoBrutalism.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kToolbarHeight,
              child: NavigationToolbar(
                leading:
                    leading ??
                    (Navigator.canPop(context)
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.pop(context),
                          )
                        : null),
                middle: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: actions != null
                    ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    : null,
                centerMiddle: false,
                middleSpacing: 8,
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// A tile/list item with Neo-Brutalism style.
class NeoListTile extends StatefulWidget {
  const NeoListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.color,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<NeoListTile> createState() => _NeoListTileState();
}

class _NeoListTileState extends State<NeoListTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? NeoBrutalism.shadowOffset.dx : 0,
          _isPressed ? NeoBrutalism.shadowOffset.dy : 0,
          0,
        ),
        padding: const EdgeInsets.all(16),
        decoration: NeoBrutalism.shapeDecoration(
          color: widget.color ?? NeoBrutalism.white,
          hasShadow: !_isPressed,
        ),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: NeoBrutalism.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 16),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A slider with Neo-Brutalism style label.
class NeoSlider extends StatelessWidget {
  const NeoSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.valueLabel,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final double min;
  final double max;
  final int? divisions;
  final String? valueLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: NeoBrutalism.shapeDecoration(
                color: NeoBrutalism.yellow,
                radius: 6,
                hasShadow: false,
              ),
              child: Text(
                valueLabel ??
                    value.toStringAsFixed(
                      value.truncateToDouble() == value ? 0 : 1,
                    ),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: _NeoSliderTrackShape(),
            thumbShape: _NeoSliderThumbShape(),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NeoSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const trackHeight = 12.0;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    // Background track
    final bgPaint = Paint()
      ..color = NeoBrutalism.grey
      ..style = PaintingStyle.fill;
    final bgRRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    context.canvas.drawRRect(bgRRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = NeoBrutalism.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    context.canvas.drawRRect(bgRRect, borderPaint);

    // Active track
    final activeRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      thumbCenter.dx,
      rect.bottom,
    );
    final activePaint = Paint()
      ..color = NeoBrutalism.pink
      ..style = PaintingStyle.fill;
    final activeRRect = RRect.fromRectAndRadius(
      activeRect,
      const Radius.circular(6),
    );
    context.canvas.drawRRect(activeRRect, activePaint);
  }
}

class _NeoSliderThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(24, 24);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Shadow
    final shadowPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: center + const Offset(2, 2),
          width: 24,
          height: 24,
        ),
      );
    canvas.drawPath(shadowPath, Paint()..color = NeoBrutalism.black);

    // Thumb circle
    canvas.drawCircle(center, 12, Paint()..color = NeoBrutalism.yellow);
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = NeoBrutalism.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// A container with Neo-Brutalism style for sections.
class NeoSection extends StatelessWidget {
  const NeoSection({
    super.key,
    required this.title,
    required this.child,
    this.color,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: NeoBrutalism.shapeDecoration(
            color: color ?? NeoBrutalism.white,
          ),
          child: child,
        ),
      ],
    );
  }
}
