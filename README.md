# smart_keyboard

[![pub package](https://img.shields.io/pub/v/smart_keyboard.svg)](https://pub.dev/packages/smart_keyboard)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter plugin for **real-time keyboard height tracking** with smooth animation support, configurable throttling, and programmatic show/hide on iOS and Android.

Unlike simple visibility listeners, `smart_keyboard` gives you the **exact keyboard height on every animation frame** — enabling pixel-perfect UI transitions that follow the keyboard in real time.

## Features

- **Frame-by-frame height tracking** — Get the keyboard height on every animation frame, not just open/close events.
- **Target height available immediately** — Know the final keyboard height from the very first event, before the animation completes.
- **Configurable throttling** — Control event frequency with a trailing-edge throttle that never drops the final state.
- **Visibility stream** — Simple `true`/`false` stream for basic show/hide detection.
- **Programmatic control** — Show or hide the keyboard from code.
- **Zero dependencies** — Only `flutter` and `plugin_platform_interface`.

## Platform Support

| Platform | Minimum Version | Implementation |
|----------|----------------|----------------|
| **Android** | API 21 (5.0) | `WindowInsetsAnimationCompat` (API 30+) with `OnGlobalLayoutListener` fallback |
| **iOS** | 12.0 | Keyboard notifications + `CADisplayLink` interpolation |

## Getting Started

### Installation

```yaml
dependencies:
  smart_keyboard: ^0.1.0
```

```bash
flutter pub get
```

No additional setup required. No permissions needed.

## Usage

### Listen to Keyboard Height (Real-Time)

```dart
import 'package:smart_keyboard/smart_keyboard.dart';

// Full frequency — every native event forwarded
SmartKeyboard.listenHeight().listen((event) {
  print('Height: ${event.height}');
  print('Animating: ${event.isAnimating}');
});

// Throttled to ~60fps
SmartKeyboard.listenHeight(
  interval: const Duration(milliseconds: 16),
).listen((event) {
  print('Height: ${event.height}');
});
```

### Listen to Visibility Changes

```dart
SmartKeyboard.onVisibilityChanged.listen((isVisible) {
  print('Keyboard visible: $isVisible');
});
```

### Get Target Height Before Animation Completes

When the keyboard starts opening, `targetHeight` tells you the final height immediately — even while the animation is still running. This is useful for pre-allocating space or starting your own animations.

```dart
SmartKeyboard.onTargetHeightChanged.listen((targetHeight) {
  print('Final height will be: $targetHeight');
});
```

### Get Current Height (One-Shot)

```dart
final height = await SmartKeyboard.keyboardHeight;
print('Current height: ${height}px');
```

### Show / Hide Keyboard Programmatically

```dart
// Show keyboard (requires a focused text field)
await SmartKeyboard.showKeyboard();

// Hide keyboard
await SmartKeyboard.hideKeyboard();
```

### Full Example with StatefulWidget

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_keyboard/smart_keyboard.dart';

class KeyboardAwarePage extends StatefulWidget {
  const KeyboardAwarePage({super.key});

  @override
  State<KeyboardAwarePage> createState() => _KeyboardAwarePageState();
}

class _KeyboardAwarePageState extends State<KeyboardAwarePage> {
  double _keyboardHeight = 0.0;
  double _targetHeight = 0.0;
  bool _isAnimating = false;

  StreamSubscription<KeyboardHeightEvent>? _heightSub;
  StreamSubscription<double>? _targetSub;

  @override
  void initState() {
    super.initState();

    _heightSub = SmartKeyboard.listenHeight(
      interval: const Duration(milliseconds: 16),
    ).listen((event) {
      setState(() {
        _keyboardHeight = event.height;
        _isAnimating = event.isAnimating;
      });
    });

    _targetSub = SmartKeyboard.onTargetHeightChanged.listen((target) {
      setState(() => _targetHeight = target);
    });
  }

  @override
  void dispose() {
    _heightSub?.cancel();
    _targetSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(/* your content */),
          ),
          // This container follows the keyboard pixel-by-pixel
          AnimatedContainer(
            duration: const Duration(milliseconds: 16),
            height: _keyboardHeight,
          ),
        ],
      ),
    );
  }
}
```

## API Reference

### `SmartKeyboard`

All methods are static. No initialization required.

| Method / Getter | Return Type | Description |
|---|---|---|
| `listenHeight({Duration? interval})` | `Stream<KeyboardHeightEvent>` | Real-time keyboard height events. Optional throttle interval. |
| `onTargetHeightChanged` | `Stream<double>` | Emits the final keyboard height as soon as animation starts. Deduplicated. |
| `onVisibilityChanged` | `Stream<bool>` | Emits `true` when keyboard shows, `false` when hidden. Deduplicated. |
| `keyboardHeight` | `Future<double>` | Current keyboard height (one-shot). |
| `showKeyboard()` | `Future<void>` | Programmatically show the keyboard. |
| `hideKeyboard()` | `Future<void>` | Programmatically hide the keyboard. |

### `KeyboardHeightEvent`

| Property | Type | Description |
|---|---|---|
| `height` | `double` | Current keyboard height in logical pixels. Interpolates during animation. |
| `targetHeight` | `double` | Final keyboard height, available from the first event. `0.0` when hiding. |
| `isAnimating` | `bool` | `true` while the keyboard is animating (opening or closing). |
| `isVisible` | `bool` | `true` when the keyboard is partially or fully visible. |

**Constants:**
- `KeyboardHeightEvent.hidden` — A const event representing a fully hidden keyboard (all fields zero/false).

## How It Works

### Android

On **API 30+**, the plugin uses `WindowInsetsAnimationCompat` to receive real-time keyboard animation callbacks:

- **`onStart`** — Captures the target keyboard height immediately.
- **`onProgress`** — Emits the current height on every animation frame with `isAnimating: true`.
- **`onEnd`** — Emits the final height with `isAnimating: false`.

On **API 21–29**, the plugin falls back to `ViewTreeObserver.OnGlobalLayoutListener`, which provides discrete layout-change events (no smooth animation tracking).

### iOS

The plugin listens to `UIResponder` keyboard notifications (`keyboardWillShow`, `keyboardDidShow`, etc.) and uses a `CADisplayLink` to interpolate the keyboard height at the display's refresh rate (~60fps) with a cubic ease-out curve, producing smooth frame-by-frame updates that closely match the system keyboard animation.

## Throttling

The `interval` parameter in `listenHeight()` uses a **trailing-edge throttle**:

- The **first event** is always delivered immediately.
- Subsequent events within the throttle window are dropped, but the **last event is always delivered** when the window expires.
- This guarantees you never miss the final keyboard state, even with aggressive throttling.

```dart
// No throttling — every native frame event (recommended for animations)
SmartKeyboard.listenHeight();

// ~60fps — good balance for most UI updates
SmartKeyboard.listenHeight(interval: Duration(milliseconds: 16));

// Reduced frequency — saves CPU for non-animation use cases
SmartKeyboard.listenHeight(interval: Duration(milliseconds: 100));
```

## Notes

- `showKeyboard()` on iOS requires a text input field to be focused. If no field is focused, the call is a no-op.
- On Android API 21–29 (legacy fallback), animation events are not available — you get discrete height changes only.
- All height values are in **logical pixels** (density-independent).

## License

MIT License. See [LICENSE](LICENSE) for details.
