import 'dart:math' as math;

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

import '../theme/neo_brutalism.dart';

/// Neo-Brutalism style header for EasyRefresh
///
/// Features bold borders, vibrant colors, and hard shadows
/// consistent with the Neo-Brutalism design system.
class NeoBrutalismHeader extends Header {
  /// Creates a Neo-Brutalism style header
  const NeoBrutalismHeader({
    this.textStyle,
    this.backgroundColor = NeoBrutalism.white,
    this.borderColor = NeoBrutalism.black,
    this.iconColor = NeoBrutalism.pink,
  }) : super(
         triggerOffset: 70,
         clamping: false,
         position: IndicatorPosition.above,
         processedDuration: const Duration(seconds: 1),
       );

  /// Text style for the status message
  final TextStyle? textStyle;

  /// Background color of the header
  final Color backgroundColor;

  /// Border color
  final Color borderColor;

  /// Icon color for the loading indicator
  final Color iconColor;

  @override
  Widget build(BuildContext context, IndicatorState state) {
    // Determine status text and icon
    final String text;
    final double rotation;
    final Color displayColor;

    switch (state.mode) {
      case IndicatorMode.inactive:
        text = '';
        rotation = 0;
        displayColor = backgroundColor;
        break;
      case IndicatorMode.drag:
        text = 'Pull to refresh';
        // Smooth rotation from 0 to π (180 degrees)
        rotation = (state.offset / triggerOffset) * math.pi;
        displayColor = NeoBrutalism.blue;
        break;
      case IndicatorMode.armed:
        text = 'Release to refresh';
        rotation = math.pi;
        displayColor = NeoBrutalism.yellow;
        break;
      case IndicatorMode.ready:
        text = 'Refreshing...';
        rotation = math.pi;
        displayColor = NeoBrutalism.orange;
        break;
      case IndicatorMode.processing:
        text = 'Refreshing...';
        rotation = math.pi;
        displayColor = iconColor;
        break;
      case IndicatorMode.processed:
        text = 'Refresh complete!';
        rotation = math.pi;
        displayColor = NeoBrutalism.green;
        break;
      case IndicatorMode.done:
        text = '';
        rotation = 0;
        displayColor = backgroundColor;
        break;
      default:
        text = '';
        rotation = 0;
        displayColor = backgroundColor;
    }

    // Only show when there's content
    if (text.isEmpty && state.mode == IndicatorMode.inactive) {
      return const SizedBox.shrink();
    }

    return _NeoBrutalismIndicator(
      text: text,
      rotation: rotation,
      backgroundColor: displayColor,
      borderColor: borderColor,
      textStyle: textStyle,
      isFooter: false,
      isProcessing: state.mode == IndicatorMode.processing,
      progress: state.offset / triggerOffset,
    );
  }
}

/// Neo-Brutalism style footer for EasyRefresh
///
/// Features bold borders, vibrant colors, and hard shadows
/// consistent with the Neo-Brutalism design system.
class NeoBrutalismFooter extends Footer {
  /// Creates a Neo-Brutalism style footer
  const NeoBrutalismFooter({
    this.textStyle,
    this.backgroundColor = NeoBrutalism.white,
    this.borderColor = NeoBrutalism.black,
    this.iconColor = NeoBrutalism.cyan,
  }) : super(
         triggerOffset: 70,
         clamping: false,
         infiniteOffset: 70,
         processedDuration: const Duration(seconds: 1),
       );

  /// Text style for the status message
  final TextStyle? textStyle;

  /// Background color of the footer
  final Color backgroundColor;

  /// Border color
  final Color borderColor;

  /// Icon color for the loading indicator
  final Color iconColor;

  @override
  Widget build(BuildContext context, IndicatorState state) {
    // Determine status text and icon
    final String text;
    final double rotation;
    final Color displayColor;

    switch (state.mode) {
      case IndicatorMode.inactive:
        text = '';
        rotation = 0;
        displayColor = backgroundColor;
        break;
      case IndicatorMode.drag:
        text = 'Pull to load more';
        // Smooth rotation from 0 to π (180 degrees)
        rotation = (state.offset / triggerOffset) * math.pi;
        displayColor = NeoBrutalism.purple;
        break;
      case IndicatorMode.armed:
        text = 'Release to load';
        rotation = math.pi;
        displayColor = NeoBrutalism.pink;
        break;
      case IndicatorMode.ready:
        text = 'Loading...';
        rotation = math.pi;
        displayColor = NeoBrutalism.orange;
        break;
      case IndicatorMode.processing:
        text = 'Loading...';
        rotation = math.pi;
        displayColor = iconColor;
        break;
      case IndicatorMode.processed:
        text = 'Load complete!';
        rotation = math.pi;
        displayColor = NeoBrutalism.green;
        break;
      case IndicatorMode.done:
        text = '';
        rotation = 0;
        displayColor = backgroundColor;
        break;
      default:
        text = '';
        rotation = 0;
        displayColor = backgroundColor;
    }

    // Only show when there's content
    if (text.isEmpty && state.mode == IndicatorMode.inactive) {
      return const SizedBox.shrink();
    }

    return _NeoBrutalismIndicator(
      text: text,
      rotation: rotation,
      backgroundColor: displayColor,
      borderColor: borderColor,
      textStyle: textStyle,
      isFooter: true,
      isProcessing: state.mode == IndicatorMode.processing,
      progress: state.offset / triggerOffset,
    );
  }
}

/// Internal widget for Neo-Brutalism indicator
class _NeoBrutalismIndicator extends StatelessWidget {
  const _NeoBrutalismIndicator({
    required this.text,
    required this.rotation,
    required this.backgroundColor,
    required this.borderColor,
    this.textStyle,
    required this.isFooter,
    required this.isProcessing,
    required this.progress,
  });

  final String text;
  final double rotation;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle? textStyle;
  final bool isFooter;
  final bool isProcessing;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final effectiveTextStyle =
        textStyle ??
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: NeoBrutalism.black,
        );

    return Container(
      alignment: isFooter ? Alignment.topCenter : Alignment.bottomCenter,
      // Header: distance from top, Footer: distance from bottom
      padding: EdgeInsets.only(
        top: isFooter ? 0 : 24,
        bottom: isFooter ? 24 : 0,
      ),
      child: _NeoBrutalismIndicatorBox(
        text: text,
        rotation: rotation,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        textStyle: effectiveTextStyle,
        isProcessing: isProcessing,
        progress: progress,
      ),
    );
  }
}

/// Neo-Brutalism styled indicator box
class _NeoBrutalismIndicatorBox extends StatelessWidget {
  const _NeoBrutalismIndicatorBox({
    required this.text,
    required this.rotation,
    required this.backgroundColor,
    required this.borderColor,
    required this.textStyle,
    required this.isProcessing,
    required this.progress,
  });

  final String text;
  final double rotation;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle textStyle;
  final bool isProcessing;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: NeoBrutalism.shapeDecoration(
        color: backgroundColor,
        borderColor: borderColor,
        hasShadow: true,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon/Indicator
          _buildIndicator(),
          const SizedBox(width: 10),
          // Text
          Text(text, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    if (isProcessing) {
      // Smaller animated loading indicator
      return SizedBox(
        width: 20,
        height: 20,
        child: _NeoBrutalismProgressIndicator(color: borderColor),
      );
    }

    // Arrow icon with smooth rotation - smaller size
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 20,
        height: 20,
        decoration: NeoBrutalism.shapeDecoration(
          color: backgroundColor,
          borderColor: borderColor,
          radius: 6,
          hasShadow: true,
        ),
        child: Center(
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 14,
            weight: 700,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}

/// Custom progress indicator in Neo-Brutalism style
class _NeoBrutalismProgressIndicator extends StatefulWidget {
  const _NeoBrutalismProgressIndicator({required this.color});

  final Color color;

  @override
  State<_NeoBrutalismProgressIndicator> createState() =>
      _NeoBrutalismProgressIndicatorState();
}

class _NeoBrutalismProgressIndicatorState
    extends State<_NeoBrutalismProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _NeoBrutalismSpinnerPainter(
            color: widget.color,
            progress: _animation.value,
          ),
        );
      },
    );
  }
}

/// Custom painter for Neo-Brutalism spinner
class _NeoBrutalismSpinnerPainter extends CustomPainter {
  const _NeoBrutalismSpinnerPainter({
    required this.color,
    required this.progress,
  });

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw segments in Neo-Brutalism style - smaller and cleaner
    final Paint paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const segmentCount = 8;
    for (int i = 0; i < segmentCount; i++) {
      final startAngle = (i / segmentCount) * 2 * math.pi;
      final sweepAngle = (1 / segmentCount) * 2 * math.pi * 0.5;

      // Calculate opacity based on rotation with smoother fade
      final segmentProgress = (progress + i / segmentCount) % 1.0;
      final opacity = math
          .pow(1 - segmentProgress, 2)
          .toDouble()
          .clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: opacity);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw smaller center dot
    final centerDotPaint = Paint()
      ..color = color.withValues(alpha: 0.3 + 0.7 * (1 - progress))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 2.5, centerDotPaint);
  }

  @override
  bool shouldRepaint(_NeoBrutalismSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
