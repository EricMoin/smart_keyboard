import 'package:flutter/services.dart';

import 'keyboard_height_event.dart';
import 'smart_keyboard_platform.dart';

/// An implementation of [SmartKeyboardPlatform] that uses MethodChannel
/// and EventChannel for platform communication.
class MethodChannelSmartKeyboard extends SmartKeyboardPlatform {
  /// The method channel used to interact with the native platform.
  static const MethodChannel _methodChannel = MethodChannel(
    'com.smart.keyboard/method',
  );

  /// The event channel used to receive keyboard height events.
  static const EventChannel _eventChannel = EventChannel(
    'com.smart.keyboard/event',
  );

  Stream<KeyboardHeightEvent>? _eventStream;

  @override
  Stream<KeyboardHeightEvent> get keyboardEventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is Map)
        .map(
          (event) =>
              KeyboardHeightEvent.fromMap(event as Map<dynamic, dynamic>),
        );
    return _eventStream!;
  }

  @override
  Future<double> getKeyboardHeight() async {
    final height = await _methodChannel.invokeMethod<double>(
      'getKeyboardHeight',
    );
    return height ?? 0.0;
  }

  @override
  Future<void> showKeyboard() async {
    await _methodChannel.invokeMethod<void>('showKeyboard');
  }

  @override
  Future<void> hideKeyboard() async {
    await _methodChannel.invokeMethod<void>('hideKeyboard');
  }
}
