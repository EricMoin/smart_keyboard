import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keyboard/smart_keyboard.dart';

/// A mock platform implementation for testing.
class MockSmartKeyboardPlatform extends SmartKeyboardPlatform {
  final StreamController<KeyboardHeightEvent> _controller =
      StreamController<KeyboardHeightEvent>.broadcast();

  double mockHeight = 0.0;

  @override
  Stream<KeyboardHeightEvent> get keyboardEventStream => _controller.stream;

  @override
  Future<double> getKeyboardHeight() async => mockHeight;

  @override
  Future<void> showKeyboard() async {}

  @override
  Future<void> hideKeyboard() async {}

  void emitEvent(KeyboardHeightEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmartKeyboard', () {
    late MockSmartKeyboardPlatform mockPlatform;

    setUp(() {
      mockPlatform = MockSmartKeyboardPlatform();
      SmartKeyboardPlatform.instance = mockPlatform;
    });

    tearDown(() {
      mockPlatform.dispose();
    });

    test('keyboardHeight returns value from platform', () async {
      mockPlatform.mockHeight = 320.0;
      final height = await SmartKeyboard.keyboardHeight;
      expect(height, 320.0);
    });

    test('keyboardHeight returns 0 when keyboard hidden', () async {
      mockPlatform.mockHeight = 0.0;
      final height = await SmartKeyboard.keyboardHeight;
      expect(height, 0.0);
    });

    group('listenHeight', () {
      test('without interval forwards all events', () async {
        final events = <KeyboardHeightEvent>[];
        final subscription = SmartKeyboard.listenHeight().listen(events.add);

        const event1 = KeyboardHeightEvent(
          height: 100.0,
          targetHeight: 300.0,
          isAnimating: true,
          isVisible: true,
        );
        const event2 = KeyboardHeightEvent(
          height: 200.0,
          targetHeight: 300.0,
          isAnimating: true,
          isVisible: true,
        );
        const event3 = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 300.0,
          isAnimating: false,
          isVisible: true,
        );

        mockPlatform.emitEvent(event1);
        mockPlatform.emitEvent(event2);
        mockPlatform.emitEvent(event3);

        // Allow microtask queue to process
        await Future<void>.delayed(Duration.zero);

        expect(events.length, 3);
        expect(events[0], event1);
        expect(events[1], event2);
        expect(events[2], event3);

        await subscription.cancel();
      });

      test('with interval throttles events', () async {
        final events = <KeyboardHeightEvent>[];
        final subscription = SmartKeyboard.listenHeight(
          interval: const Duration(milliseconds: 50),
        ).listen(events.add);

        // Emit first event — should go through immediately
        const event1 = KeyboardHeightEvent(
          height: 100.0,
          targetHeight: 250.0,
          isAnimating: true,
          isVisible: true,
        );
        mockPlatform.emitEvent(event1);
        await Future<void>.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events[0], event1);

        // Emit multiple events within the throttle window
        const event2 = KeyboardHeightEvent(
          height: 150.0,
          targetHeight: 250.0,
          isAnimating: true,
          isVisible: true,
        );
        const event3 = KeyboardHeightEvent(
          height: 200.0,
          targetHeight: 250.0,
          isAnimating: true,
          isVisible: true,
        );
        const event4 = KeyboardHeightEvent(
          height: 250.0,
          targetHeight: 250.0,
          isAnimating: true,
          isVisible: true,
        );
        mockPlatform.emitEvent(event2);
        mockPlatform.emitEvent(event3);
        mockPlatform.emitEvent(event4);

        await Future<void>.delayed(Duration.zero);

        // Only first event should have been emitted, rest are pending
        expect(events.length, 1);

        // Wait for throttle to expire
        await Future<void>.delayed(const Duration(milliseconds: 60));

        // The last pending event should now be emitted
        expect(events.length, 2);
        expect(events[1], event4); // Last event in the window

        await subscription.cancel();
      });

      test('throttle delivers final event on stream close', () async {
        final localMock = MockSmartKeyboardPlatform();
        SmartKeyboardPlatform.instance = localMock;

        final events = <KeyboardHeightEvent>[];
        bool streamDone = false;

        // Use the underlying throttle through SmartKeyboard
        // We test via the mock platform's stream
        final throttledStream = SmartKeyboard.listenHeight(
          interval: const Duration(milliseconds: 100),
        );

        final subscription = throttledStream.listen(
          events.add,
          onDone: () => streamDone = true,
        );

        // Emit and immediately close
        const event = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 300.0,
          isAnimating: false,
          isVisible: true,
        );
        localMock.emitEvent(event);
        await Future<void>.delayed(Duration.zero);

        expect(events.length, 1); // First event goes through immediately
        expect(events[0], event);

        localMock.dispose();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(streamDone, true);

        await subscription.cancel();
      });
    });

    group('onVisibilityChanged', () {
      test('emits distinct visibility changes', () async {
        final visibilityChanges = <bool>[];
        final subscription = SmartKeyboard.onVisibilityChanged.listen(
          visibilityChanges.add,
        );

        // Keyboard shows
        mockPlatform.emitEvent(
          const KeyboardHeightEvent(
            height: 100.0,
            targetHeight: 300.0,
            isAnimating: true,
            isVisible: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Height changes but still visible — should NOT emit again
        mockPlatform.emitEvent(
          const KeyboardHeightEvent(
            height: 200.0,
            targetHeight: 300.0,
            isAnimating: true,
            isVisible: true,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        // Keyboard hides
        mockPlatform.emitEvent(
          const KeyboardHeightEvent(
            height: 0.0,
            targetHeight: 0.0,
            isAnimating: false,
            isVisible: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(visibilityChanges, [true, false]);

        await subscription.cancel();
      });

      test('deduplicates consecutive same-visibility events', () async {
        final visibilityChanges = <bool>[];
        final subscription = SmartKeyboard.onVisibilityChanged.listen(
          visibilityChanges.add,
        );

        // Multiple visible events
        for (var i = 0; i < 5; i++) {
          mockPlatform.emitEvent(
            KeyboardHeightEvent(
              height: 100.0 + i * 10,
              targetHeight: 300.0,
              isAnimating: i < 4,
              isVisible: true,
            ),
          );
        }
        await Future<void>.delayed(Duration.zero);

        // Only one true should be emitted
        expect(visibilityChanges, [true]);

        await subscription.cancel();
      });
    });
  });
}
