import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/presentation/features/forest/game/render/growth_motion.dart';

void main() {
  test('testWhenGrowingStartsThenTheScaleIsAThirdAndItEndsAtFullSizeAfterSixHundredMilliseconds', () {
    // given
    const times = [0.0, 600.0];

    // when
    final scales = times.map(GrowthMotion.scale).toList();

    // then
    expect(scales[0], closeTo(0.35, 1e-9));
    expect(scales[1], closeTo(1, 1e-9));
  });

  test('testWhenGrowingThenItOvershootsBeforeSettling', () {
    // given
    final times = [for (var ms = 0.0; ms < 600; ms += 10) ms];

    // when
    final peak = times.map(GrowthMotion.scale).reduce((a, b) => a > b ? a : b);

    // then
    expect(peak, greaterThan(1));
  });

  test('testWhenSixHundredMillisecondsPassThenItHasGrown', () {
    // given
    const before = 599.0;

    // when
    final grown = (GrowthMotion.hasGrown(before), GrowthMotion.hasGrown(600));

    // then
    expect(grown, (false, true));
  });
}
