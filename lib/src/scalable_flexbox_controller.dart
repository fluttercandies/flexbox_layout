import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// The display mode for scalable flexbox.
enum FlexboxScaleMode {
  /// Display items in a uniform square grid (1:1 aspect ratio).
  grid1x1,

  /// Display items preserving their original aspect ratios.
  aspectRatio,
}

/// A controller that manages the scale state of a scalable flexbox.
///
/// This controller provides a Google Photos-like pinch-to-zoom experience with:
/// - **Responsive scaling**: Follows pinch gestures in real-time
/// - **Smooth snap animation**: Snaps to predefined points with spring physics
/// - **Mode switching**: Automatically switches between 1:1 grid and aspect ratio modes
/// - **Velocity-based momentum**: Continues motion based on gesture velocity
///
/// Example:
/// ```dart
/// final controller = FlexboxScaleController(
///   initialExtent: 150.0,
///   minExtent: 80.0,
///   maxExtent: 300.0,
///   snapPoints: [80, 120, 160, 200, 250, 300],
/// );
///
/// // Use with a TickerProvider (e.g., SingleTickerProviderStateMixin)
/// controller.attachTickerProvider(this);
///
/// // In your widget's dispose:
/// controller.dispose();
/// ```
class FlexboxScaleController extends ChangeNotifier {
  /// Creates a flexbox scale controller.
  ///
  /// [initialExtent] is the starting extent value.
  /// [minExtent] is the minimum allowed extent (maximum zoom in).
  /// [maxExtent] is the maximum allowed extent (maximum zoom out).
  /// [snapPoints] are the extent values to snap to after gesture ends.
  /// [gridModeThreshold] is the extent threshold to switch to 1:1 grid mode.
  FlexboxScaleController({
    required double initialExtent,
    required this.minExtent,
    required this.maxExtent,
    List<double>? snapPoints,
    this.gridModeThreshold,
    this.enableSnap = true,
  })  : assert(minExtent > 0, 'minExtent must be positive'),
        assert(maxExtent >= minExtent, 'maxExtent must be >= minExtent'),
        assert(initialExtent >= minExtent && initialExtent <= maxExtent,
            'initialExtent must be within [minExtent, maxExtent]'),
        _currentExtent = initialExtent,
        _baseExtent = initialExtent,
        _snapPoints =
            snapPoints ?? _generateDefaultSnapPoints(minExtent, maxExtent);

  /// The minimum allowed extent (maximum zoom in, more items visible).
  final double minExtent;

  /// The maximum allowed extent (maximum zoom out, fewer items visible).
  final double maxExtent;

  /// The extent threshold to switch to 1:1 grid mode.
  /// When current extent >= this value, mode switches to [FlexboxScaleMode.grid1x1].
  /// Set to null to disable automatic mode switching.
  final double? gridModeThreshold;

  /// Whether to enable snapping to predefined points.
  final bool enableSnap;

  final List<double> _snapPoints;
  double _currentExtent;
  double _baseExtent;
  bool _isScaling = false;
  double _fillFactor = 1.0;

  AnimationController? _animationController;
  Animation<double>? _animation;
  AnimationController? _fillFactorController;
  Animation<double>? _fillFactorAnimation;

  /// The current extent value.
  double get currentExtent => _currentExtent;

  /// Whether a scale gesture is currently active.
  bool get isScaling => _isScaling;

  /// The fill factor for layout transitions (0.0-1.0).
  ///
  /// - 0.0: Items sized exactly at targetExtent, rows may have empty space
  /// - 1.0: Items scaled to fill the row completely
  ///
  /// This value animates from 0.0 to 1.0 when scaling ends, creating a
  /// smooth transition from "scaling mode" to "filled mode".
  double get fillFactor => _fillFactor;

  /// Whether a snap animation is currently running.
  bool get isAnimating => _animationController?.isAnimating ?? false;

  /// Whether the fill factor animation is running.
  bool get isFillAnimating => _fillFactorController?.isAnimating ?? false;

  /// The current display mode based on extent.
  FlexboxScaleMode get mode {
    if (gridModeThreshold != null && _currentExtent >= gridModeThreshold!) {
      return FlexboxScaleMode.grid1x1;
    }
    return FlexboxScaleMode.aspectRatio;
  }

  /// Whether zooming in is possible (current extent > minExtent).
  bool get canZoomIn => _currentExtent > minExtent;

  /// Whether zooming out is possible (current extent < maxExtent).
  bool get canZoomOut => _currentExtent < maxExtent;

  /// The normalized scale factor (0.0 = min extent, 1.0 = max extent).
  double get normalizedScale =>
      (_currentExtent - minExtent) / (maxExtent - minExtent);

  /// The snap points for extent values.
  List<double> get snapPoints => List.unmodifiable(_snapPoints);

  /// Attaches a [TickerProvider] for animations.
  ///
  /// This must be called before using snap animations. Typically called
  /// in [State.initState] with `this` as the ticker provider.
  void attachTickerProvider(TickerProvider provider) {
    _animationController?.dispose();
    _animationController = AnimationController(vsync: provider);
    _animationController!.addListener(_onAnimationUpdate);

    _fillFactorController?.dispose();
    _fillFactorController = AnimationController(
      vsync: provider,
      duration: const Duration(milliseconds: 200),
    );
    _fillFactorController!.addListener(_onFillFactorUpdate);
  }

  void _onFillFactorUpdate() {
    if (_fillFactorAnimation != null) {
      _fillFactor = _fillFactorAnimation!.value;
      notifyListeners();
    }
  }

  void _onAnimationUpdate() {
    if (_animation != null) {
      _currentExtent = _animation!.value;
      notifyListeners();
    }
  }

  /// Sets the current extent directly without animation.
  void setExtent(double extent) {
    final newExtent = extent.clamp(minExtent, maxExtent);
    if (_currentExtent != newExtent) {
      _currentExtent = newExtent;
      _baseExtent = newExtent;
      notifyListeners();
    }
  }

  /// Animates to the specified extent with spring physics.
  void animateToExtent(double targetExtent, {double velocity = 0.0}) {
    if (_animationController == null) {
      setExtent(targetExtent);
      return;
    }

    final clampedTarget = targetExtent.clamp(minExtent, maxExtent);

    // Use softer spring for smoother, more natural animation
    // Lower stiffness = slower approach to target
    // Lower damping = more bounce (but we want minimal bounce)
    const spring = SpringDescription(
      mass: 1.0,
      stiffness: 150.0, // Softer spring for smoother feel
      damping: 18.0, // Balanced damping - minimal overshoot
    );

    final simulation = SpringSimulation(
      spring,
      _currentExtent,
      clampedTarget,
      velocity,
    );

    _animation = _animationController!.drive(
      Tween<double>(begin: _currentExtent, end: clampedTarget),
    );

    _animationController!.animateWith(simulation);
  }

  /// Finds the nearest snap point for the given extent.
  double findNearestSnapPoint(double extent) {
    if (_snapPoints.isEmpty) return extent.clamp(minExtent, maxExtent);

    double nearest = _snapPoints.first;
    double minDistance = (extent - nearest).abs();

    for (final point in _snapPoints) {
      final distance = (extent - point).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = point;
      }
    }

    return nearest;
  }

  /// Called when a scale gesture starts.
  void onScaleStart(ScaleStartDetails details) {
    _animationController?.stop();
    _fillFactorController?.stop();
    _baseExtent = _currentExtent;
    _isScaling = true;
    _fillFactor = 0.0; // Reset to unfilled mode during scaling
    notifyListeners();
  }

  /// Called when a scale gesture updates.
  void onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1.0) return; // Ignore single-finger pan

    // Calculate new extent proportional to scale
    // Pinch out (scale > 1) = zoom in = larger extent = larger items
    // Pinch in (scale < 1) = zoom out = smaller extent = smaller items
    final newExtent = _baseExtent * details.scale;
    final clampedExtent = newExtent.clamp(minExtent, maxExtent);

    if (_currentExtent != clampedExtent) {
      _currentExtent = clampedExtent;
      notifyListeners();
    }
  }

  /// Called when a scale gesture ends.
  void onScaleEnd(ScaleEndDetails details) {
    _baseExtent = _currentExtent;
    _isScaling = false;

    // Animate fillFactor from 0 to 1 for smooth transition
    _animateFillFactor();

    if (!enableSnap) {
      return;
    }
  }

  /// Animates the fill factor from 0.0 to 1.0 for smooth layout transition.
  void _animateFillFactor() {
    if (_fillFactorController == null) {
      _fillFactor = 1.0;
      notifyListeners();
      return;
    }

    _fillFactorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fillFactorController!,
        curve: Curves.easeOut,
      ),
    );
    _fillFactorController!.forward(from: 0.0);
  }

  /// Handles double tap to toggle between extremes or snap points.
  void onDoubleTap() {
    final midExtent = (minExtent + maxExtent) / 2;
    double targetExtent;

    if (_currentExtent <= midExtent) {
      // Zoom out to max or nearest larger snap point
      targetExtent = enableSnap
          ? _snapPoints.lastWhere(
              (p) => p > _currentExtent,
              orElse: () => maxExtent,
            )
          : maxExtent;
    } else {
      // Zoom in to min or nearest smaller snap point
      targetExtent = enableSnap
          ? _snapPoints.firstWhere(
              (p) => p < _currentExtent,
              orElse: () => minExtent,
            )
          : minExtent;
    }

    animateToExtent(targetExtent);
  }

  /// Zooms in (decreases extent, shows more items).
  void zoomIn() {
    if (!canZoomIn) return;

    if (enableSnap) {
      // Find next smaller snap point
      final target = _snapPoints.lastWhere(
        (p) => p < _currentExtent,
        orElse: () => minExtent,
      );
      animateToExtent(target);
    } else {
      animateToExtent(_currentExtent - 40);
    }
  }

  /// Zooms out (increases extent, shows fewer items).
  void zoomOut() {
    if (!canZoomOut) return;

    if (enableSnap) {
      // Find next larger snap point
      final target = _snapPoints.firstWhere(
        (p) => p > _currentExtent,
        orElse: () => maxExtent,
      );
      animateToExtent(target);
    } else {
      animateToExtent(_currentExtent + 40);
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _fillFactorController?.dispose();
    super.dispose();
  }

  /// Generates default snap points evenly distributed between min and max.
  static List<double> _generateDefaultSnapPoints(double min, double max) {
    final points = <double>[];
    final step = (max - min) / 5;
    for (var i = 0; i <= 5; i++) {
      points.add(min + (step * i));
    }
    return points;
  }
}
