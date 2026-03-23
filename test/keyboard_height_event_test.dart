import 'package:flutter_test/flutter_test.dart';
import 'package:smart_keyboard/smart_keyboard.dart';

void main() {
  group('KeyboardHeightEvent', () {
    test('constructor creates event with correct values', () {
      const event = KeyboardHeightEvent(
        height: 300.0,
        targetHeight: 350.0,
        isAnimating: true,
        isVisible: true,
      );

      expect(event.height, 300.0);
      expect(event.targetHeight, 350.0);
      expect(event.isAnimating, true);
      expect(event.isVisible, true);
    });

    test('fromMap creates event from platform map', () {
      final map = <dynamic, dynamic>{
        'height': 250.5,
        'targetHeight': 300.0,
        'isAnimating': true,
        'isVisible': true,
      };

      final event = KeyboardHeightEvent.fromMap(map);

      expect(event.height, 250.5);
      expect(event.targetHeight, 300.0);
      expect(event.isAnimating, true);
      expect(event.isVisible, true);
    });

    test('fromMap handles integer height', () {
      final map = <dynamic, dynamic>{
        'height': 300,
        'targetHeight': 300,
        'isAnimating': false,
        'isVisible': true,
      };

      final event = KeyboardHeightEvent.fromMap(map);

      expect(event.height, 300.0);
      expect(event.targetHeight, 300.0);
      expect(event.isAnimating, false);
      expect(event.isVisible, true);
    });

    test('fromMap handles missing keys with defaults', () {
      final map = <dynamic, dynamic>{};

      final event = KeyboardHeightEvent.fromMap(map);

      expect(event.height, 0.0);
      expect(event.targetHeight, 0.0);
      expect(event.isAnimating, false);
      expect(event.isVisible, false);
    });

    test('fromMap handles null values with defaults', () {
      final map = <dynamic, dynamic>{
        'height': null,
        'targetHeight': null,
        'isAnimating': null,
        'isVisible': null,
      };

      final event = KeyboardHeightEvent.fromMap(map);

      expect(event.height, 0.0);
      expect(event.targetHeight, 0.0);
      expect(event.isAnimating, false);
      expect(event.isVisible, false);
    });

    test('toMap produces correct map', () {
      const event = KeyboardHeightEvent(
        height: 320.0,
        targetHeight: 350.0,
        isAnimating: false,
        isVisible: true,
      );

      final map = event.toMap();

      expect(map['height'], 320.0);
      expect(map['targetHeight'], 350.0);
      expect(map['isAnimating'], false);
      expect(map['isVisible'], true);
      expect(map.length, 4);
    });

    test('fromMap and toMap are symmetric', () {
      const original = KeyboardHeightEvent(
        height: 275.5,
        targetHeight: 300.0,
        isAnimating: true,
        isVisible: true,
      );

      final reconstructed = KeyboardHeightEvent.fromMap(original.toMap());

      expect(reconstructed, original);
    });

    test('hidden constant has correct values', () {
      expect(KeyboardHeightEvent.hidden.height, 0.0);
      expect(KeyboardHeightEvent.hidden.targetHeight, 0.0);
      expect(KeyboardHeightEvent.hidden.isAnimating, false);
      expect(KeyboardHeightEvent.hidden.isVisible, false);
    });

    group('equality', () {
      test('equal events are equal', () {
        const a = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );
        const b = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different height makes events unequal', () {
        const a = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );
        const b = KeyboardHeightEvent(
          height: 301.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );

        expect(a, isNot(b));
      });

      test('different targetHeight makes events unequal', () {
        const a = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );
        const b = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 360.0,
          isAnimating: true,
          isVisible: true,
        );

        expect(a, isNot(b));
      });

      test('different isAnimating makes events unequal', () {
        const a = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );
        const b = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: false,
          isVisible: true,
        );

        expect(a, isNot(b));
      });

      test('different isVisible makes events unequal', () {
        const a = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: true,
        );
        const b = KeyboardHeightEvent(
          height: 300.0,
          targetHeight: 350.0,
          isAnimating: true,
          isVisible: false,
        );

        expect(a, isNot(b));
      });
    });

    test('toString produces readable output', () {
      const event = KeyboardHeightEvent(
        height: 300.0,
        targetHeight: 350.0,
        isAnimating: true,
        isVisible: true,
      );

      expect(
        event.toString(),
        'KeyboardHeightEvent(height: 300.0, targetHeight: 350.0, isAnimating: true, isVisible: true)',
      );
    });
  });
}
