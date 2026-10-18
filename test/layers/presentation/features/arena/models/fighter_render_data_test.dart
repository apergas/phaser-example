import 'package:flutter_test/flutter_test.dart';

import '../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';

void main() {
  test('testWhenTheArmorDiffersThenFightersAreNotEqual', () {
    // given
    const hero = FighterRenderDataMock.heroIdle;

    // when
    final equal = hero == FighterRenderDataMock.heroIdleInLeather;

    // then
    expect(equal, isFalse);
  });

  test('testWhenEveryFieldMatchesThenFightersAreEqualWithTheSameHash', () {
    // given
    const hero = FighterRenderDataMock.heroInPlateIdle;

    // when
    final copy = FighterRenderDataMock.heroInPlateIdleCopy;

    // then
    expect(copy, hero);
    expect(copy.hashCode, hero.hashCode);
  });
}
