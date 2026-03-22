import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'keyboard_height_event.dart';
import 'smart_keyboard_method_channel.dart';

/// The interface that implementations of smart_keyboard must implement.
///
/// Platform implementations should extend this class rather than implement it,
/// as `implements` does not consider newly added methods to be breaking changes.
abstract class SmartKeyboardPlatform extends PlatformInterface {
  /// Constructs a SmartKeyboardPlatform.
  SmartKeyboardPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmartKeyboardPlatform _instance = MethodChannelSmartKeyboard();

  /// The default instance of [SmartKeyboardPlatform] to use.
  static SmartKeyboardPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SmartKeyboardPlatform].
  static set instance(SmartKeyboardPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Returns a stream of [KeyboardHeightEvent]s as the keyboard changes.
  ///
  /// Native code emits events at full frequency. Throttling is applied
  /// on the Dart side via [SmartKeyboard.listenHeight].
  Stream<KeyboardHeightEvent> get keyboardEventStream;

  /// Returns the current keyboard height.
  ///
  /// If the keyboard is not visible, returns 0.0.
  Future<double> getKeyboardHeight();

  /// Requests the platform to show the soft keyboard.
  ///
  /// On iOS, this only works if a text field is currently focused.
  Future<void> showKeyboard();

  /// Requests the platform to hide the soft keyboard.
  Future<void> hideKeyboard();
}
