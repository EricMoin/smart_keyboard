import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keyboard/src/smart_keyboard_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelSmartKeyboard', () {
    late MethodChannelSmartKeyboard platform;

    setUp(() {
      platform = MethodChannelSmartKeyboard();
    });

    test('getKeyboardHeight returns value from method channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.smart.keyboard/method'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'getKeyboardHeight') {
                return 300.0;
              }
              return null;
            },
          );

      final height = await platform.getKeyboardHeight();
      expect(height, 300.0);
    });

    test('getKeyboardHeight returns 0.0 when null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.smart.keyboard/method'),
            (MethodCall methodCall) async {
              return null;
            },
          );

      final height = await platform.getKeyboardHeight();
      expect(height, 0.0);
    });

    test('showKeyboard invokes correct method', () async {
      String? invokedMethod;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.smart.keyboard/method'),
            (MethodCall methodCall) async {
              invokedMethod = methodCall.method;
              return null;
            },
          );

      await platform.showKeyboard();
      expect(invokedMethod, 'showKeyboard');
    });

    test('hideKeyboard invokes correct method', () async {
      String? invokedMethod;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.smart.keyboard/method'),
            (MethodCall methodCall) async {
              invokedMethod = methodCall.method;
              return null;
            },
          );

      await platform.hideKeyboard();
      expect(invokedMethod, 'hideKeyboard');
    });
  });
}
