/// A Flutter plugin for real-time keyboard height tracking with configurable
/// throttling, and programmatic keyboard show/hide on iOS and Android.
library;

import 'dart:async';

import 'src/keyboard_height_event.dart';
import 'src/smart_keyboard_platform.dart';

export 'src/keyboard_height_event.dart';
export 'src/smart_keyboard_platform.dart';

/// The main entry point for the SmartKeyboard plugin.
///
/// Provides static methods to:
/// - Listen to real-time keyboard height changes with configurable throttling
/// - Get the current/final keyboard height
/// - Programmatically show and hide the soft keyboard
/// - Observe keyboard visibility changes
///
/// ## Example
///
/// ```dart
/// // Listen to keyboard height with 16ms throttle (≈60fps)
/// SmartKeyboard.listenHeight(interval: Duration(milliseconds: 16)).listen((event) {
///   print('Keyboard height: ${event.height}, animating: ${event.isAnimating}');
/// });
///
/// // Get current keyboard height
/// final height = await SmartKeyboard.keyboardHeight;
///
/// // Show/hide keyboard
/// await SmartKeyboard.showKeyboard();
/// await SmartKeyboard.hideKeyboard();
///
/// // Listen to visibility changes
/// SmartKeyboard.onVisibilityChanged.listen((isVisible) {
///   print('Keyboard visible: $isVisible');
/// });
/// ```
class SmartKeyboard {
  SmartKeyboard._();

  static SmartKeyboardPlatform get _platform => SmartKeyboardPlatform.instance;

  /// Returns a stream of [KeyboardHeightEvent]s representing real-time
  /// keyboard height changes.
  ///
  /// The [interval] parameter controls the minimum time between consecutive
  /// events. This is useful for throttling high-frequency updates during
  /// keyboard animations to avoid unnecessary rebuilds.
  ///
  /// - If [interval] is `null`, all events from the native platform are
  ///   forwarded without throttling (full frequency).
  /// - If [interval] is provided, at most one event is emitted per interval.
  ///   The last event in each interval window is always delivered to ensure
  ///   the final state is never missed.
  ///
  /// Example:
  /// ```dart
  /// // Full frequency (every native frame)
  /// SmartKeyboard.listenHeight().listen((e) => print(e.height));
  ///
  /// // Throttled to ~60fps
  /// SmartKeyboard.listenHeight(
  ///   interval: Duration(milliseconds: 16),
  /// ).listen((e) => print(e.height));
  ///
  /// // Throttled to ~30fps
  /// SmartKeyboard.listenHeight(
  ///   interval: Duration(milliseconds: 33),
  /// ).listen((e) => print(e.height));
  /// ```
  static Stream<KeyboardHeightEvent> listenHeight({Duration? interval}) {
    final stream = _platform.keyboardEventStream;
    if (interval == null) {
      return stream;
    }
    return _throttle(stream, interval);
  }

  /// Returns the current keyboard height in logical pixels.
  ///
  /// Returns `0.0` if the keyboard is not visible.
  /// When the keyboard is animating, this returns the height at the
  /// moment of the call, which may be an intermediate value.
  static Future<double> get keyboardHeight => _platform.getKeyboardHeight();

  /// Returns a stream that emits `true` when the keyboard becomes visible
  /// and `false` when it becomes hidden.
  ///
  /// This stream is derived from the keyboard event stream and only emits
  /// when the visibility state actually changes (deduplicated).
  static Stream<bool> get onVisibilityChanged {
    return _platform.keyboardEventStream
        .map((event) => event.isVisible)
        .distinct();
  }

  /// Requests the platform to show the soft keyboard.
  ///
  /// On iOS, this only works if a text input field is currently focused.
  /// If no text field is focused, this call is a no-op.
  ///
  /// On Android, this will attempt to show the keyboard for the currently
  /// focused view.
  static Future<void> showKeyboard() => _platform.showKeyboard();

  /// Requests the platform to hide the soft keyboard.
  ///
  /// This works on both iOS and Android regardless of focus state.
  static Future<void> hideKeyboard() => _platform.hideKeyboard();

  /// Throttles a stream so that at most one event is emitted per [interval].
  ///
  /// Uses a trailing-edge strategy: the last event received within each
  /// interval window is emitted when the timer fires. This guarantees that
  /// the final keyboard state is never lost.
  static Stream<KeyboardHeightEvent> _throttle(
    Stream<KeyboardHeightEvent> source,
    Duration interval,
  ) {
    return Stream<KeyboardHeightEvent>.multi((controller) {
      Timer? timer;
      KeyboardHeightEvent? lastEvent;
      bool hasPendingEvent = false;

      final subscription = source.listen(
        (event) {
          lastEvent = event;
          if (timer == null || !timer!.isActive) {
            // No active throttle — emit immediately and start timer
            controller.add(event);
            hasPendingEvent = false;
            timer = Timer(interval, () {
              // Timer expired — emit any pending event
              if (hasPendingEvent && lastEvent != null) {
                controller.add(lastEvent!);
                hasPendingEvent = false;
              }
            });
          } else {
            // Throttle active — mark as pending
            hasPendingEvent = true;
          }
        },
        onError: controller.addError,
        onDone: () {
          // Flush any remaining pending event
          if (hasPendingEvent && lastEvent != null) {
            controller.add(lastEvent!);
          }
          timer?.cancel();
          controller.close();
        },
      );

      controller.onCancel = () {
        timer?.cancel();
        subscription.cancel();
      };
    });
  }
}
