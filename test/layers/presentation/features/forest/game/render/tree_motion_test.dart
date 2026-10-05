import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/tree_motion.dart';

double _degrees(double value) => value * math.pi / 180;

void main() {
  test('testWhenThePlayerIsOnTheLeftThenTheTreeMovesRight', () {
    // given
    const baseX = 100.0;

    // when
    final fromLeft = TreeMotion.direction(fromX: 90, baseX: baseX);
    final fromRight = TreeMotion.direction(fromX: 110, baseX: baseX);

    // then
    expect(fromLeft, 1);
    expect(fromRight, -1);
  });

  test('testWhenShakingThenPeaksAtThreeDegreesAndComesBack', () {
    // given
    const direction = 1.0;

    // when
    final start = TreeMotion.shakeAngle(elapsedMs: 0, direction: direction);
    final quarter = TreeMotion.shakeAngle(elapsedMs: 35, direction: direction);
    final peak = TreeMotion.shakeAngle(elapsedMs: 70, direction: direction);
    final end = TreeMotion.shakeAngle(elapsedMs: 140, direction: direction);

    // then
    expect(start, closeTo(0, 1e-9));
    expect(quarter, closeTo(_degrees(3 * math.sin(math.pi / 4)), 1e-9));
    expect(peak, closeTo(_degrees(3), 1e-9));
    expect(end, 0);
  });

  test('testWhenFallingThenRotatesAwayAndFadesWithQuadIn', () {
    // given
    const direction = -1.0;

    // when
    final angle = TreeMotion.fallAngle(elapsedMs: 350, direction: direction);
    final opacity = TreeMotion.fallOpacity(350);

    // then
    expect(angle, closeTo(_degrees(-85 * 0.25), 1e-9));
    expect(opacity, closeTo(0.75, 1e-9));
    expect(TreeMotion.hasFallen(699), isFalse);
    expect(TreeMotion.hasFallen(700), isTrue);
  });
}
