/// Represents a keyboard height change event from the native platform.
class KeyboardHeightEvent {
  /// Creates a [KeyboardHeightEvent].
  const KeyboardHeightEvent({
    required this.height,
    required this.isAnimating,
    required this.isVisible,
  });

  /// The current keyboard height in logical pixels.
  ///
  /// This value is 0.0 when the keyboard is fully hidden.
  /// During animation, this value interpolates between 0 and the final height.
  final double height;

  /// Whether the keyboard is currently animating (opening or closing).
  ///
  /// When `true`, [height] represents an intermediate value during animation.
  /// When `false`, [height] represents the final resting value.
  final bool isAnimating;

  /// Whether the keyboard is currently visible (fully or partially).
  final bool isVisible;

  /// Creates a [KeyboardHeightEvent] from a platform map.
  factory KeyboardHeightEvent.fromMap(Map<dynamic, dynamic> map) {
    return KeyboardHeightEvent(
      height: (map['height'] as num?)?.toDouble() ?? 0.0,
      isAnimating: map['isAnimating'] as bool? ?? false,
      isVisible: map['isVisible'] as bool? ?? false,
    );
  }

  /// Converts this event to a map for platform communication.
  Map<String, dynamic> toMap() {
    return {
      'height': height,
      'isAnimating': isAnimating,
      'isVisible': isVisible,
    };
  }

  /// Returns a hidden keyboard event with zero height.
  static const KeyboardHeightEvent hidden = KeyboardHeightEvent(
    height: 0.0,
    isAnimating: false,
    isVisible: false,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyboardHeightEvent &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          isAnimating == other.isAnimating &&
          isVisible == other.isVisible;

  @override
  int get hashCode => Object.hash(height, isAnimating, isVisible);

  @override
  String toString() =>
      'KeyboardHeightEvent(height: $height, isAnimating: $isAnimating, isVisible: $isVisible)';
}
