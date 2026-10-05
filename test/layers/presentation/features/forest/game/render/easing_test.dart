import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/easing.dart';

void main() {
  test('testWhenEasingTheEndsThenStartsAtZeroAndEndsAtOne', () {
    // given
    final curves = [Easing.sineOut, Easing.sineInOut, Easing.quadIn, Easing.backOut];

    // when
    final starts = curves.map((curve) => curve(0)).toList();
    final ends = curves.map((curve) => curve(1)).toList();

    // then
    for (final start in starts) {
      expect(start, closeTo(0, 1e-9));
    }
    for (final end in ends) {
      expect(end, closeTo(1, 1e-9));
    }
  });

  test('testWhenEasingHalfwayThenMatchesTheStandardFormulas', () {
    // given
    const half = 0.5;

    // when
    final values = [Easing.sineOut(half), Easing.sineInOut(half), Easing.quadIn(half), Easing.backOut(half)];

    // then
    expect(values[0], closeTo(0.7071067811865476, 1e-9));
    expect(values[1], closeTo(0.5, 1e-9));
    expect(values[2], closeTo(0.25, 1e-9));
    expect(values[3], closeTo(1.0876975, 1e-6));
  });
}
