import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/presentation/features/forest/game/render/rock_motion.dart';

void main() {
  test('testWhenTheRockIsHitThenItShakesOneAndAHalfPixelsAndIsStillAgainAfterOneHundredTwentyMilliseconds', () {
    // given
    final direction = RockMotion.direction(fromX: 10, baseX: 20);

    // when
    final offsets = [0.0, 60.0, 120.0].map((ms) => RockMotion.shakeX(elapsedMs: ms, direction: direction)).toList();

    // then
    expect(direction, 1);
    expect(offsets, [0, closeTo(1.5, 1e-9), 0]);
    expect(RockMotion.direction(fromX: 30, baseX: 20), -1);
  });

  test('testWhenTheRockBreaksThenItShrinksToSixTenthsAndFadesOutInThreeHundredFiftyMilliseconds', () {
    // given
    const end = 350.0;

    // when
    final atEnd = (RockMotion.breakScale(end), RockMotion.breakOpacity(end), RockMotion.hasBroken(end));
    final atStart = (RockMotion.breakScale(0), RockMotion.breakOpacity(0), RockMotion.hasBroken(349));

    // then
    expect(atEnd.$1, closeTo(0.6, 1e-9));
    expect(atEnd.$2, closeTo(0, 1e-9));
    expect(atEnd.$3, isTrue);
    expect(atStart, (1, 1, false));
  });
}
