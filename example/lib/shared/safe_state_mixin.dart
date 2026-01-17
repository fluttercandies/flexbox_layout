import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A mixin that provides safe setState methods that handle various scenarios:
/// - Checking if widget is still mounted
/// - Handling setState during build/layout/paint phases
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage> with SafeStateMixin {
///   void _someAsyncOperation() async {
///     final result = await fetchData();
///     setSafeState(() {
///       _data = result;
///     });
///   }
///
///   void _onScaleChanged() {
///     // For gesture callbacks, use immediate setState
///     setStateIfMounted(() {});
///   }
/// }
/// ```
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  bool _scheduledSetState = false;
  final List<VoidCallback> _pendingCallbacks = [];

  /// Calls setState immediately if mounted.
  ///
  /// Use this for gesture callbacks and other cases where you need
  /// immediate response without frame delay.
  void setStateIfMounted([VoidCallback? fn]) {
    if (mounted) setState(fn ?? () {});
  }

  /// Calls setState safely, deferring to next frame if called during
  /// build/layout/paint phases.
  ///
  /// If called during a build/layout/paint phase, the state update
  /// will be scheduled for the next frame to avoid frame scheduling errors.
  ///
  /// This is useful for async operations where the widget might be
  /// disposed before the operation completes, or when setState might
  /// be called from layout callbacks.
  void setSafeState(VoidCallback fn) {
    if (!mounted) return;

    // Check if we're in a safe phase to call setState
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isSafePhase =
        phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (isSafePhase) {
      setState(fn);
    } else {
      // Schedule for next frame
      _pendingCallbacks.add(fn);
      if (!_scheduledSetState) {
        _scheduledSetState = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _processPendingCallbacks();
        });
      }
    }
  }

  void _processPendingCallbacks() {
    _scheduledSetState = false;
    if (!mounted || _pendingCallbacks.isEmpty) {
      _pendingCallbacks.clear();
      return;
    }

    final callbacks = List<VoidCallback>.from(_pendingCallbacks);
    _pendingCallbacks.clear();

    setState(() {
      for (final callback in callbacks) {
        callback();
      }
    });
  }
}
