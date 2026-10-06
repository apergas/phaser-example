import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/arena_level_status_entity_mock.dart';
import '../../../../mocks/domain/world/funds_mock.dart';

void main() {
  test('testWhenCopyingWithClearedAndAThirdOfTheRewardThenTheLevelIsKept', () {
    // given
    const status = ArenaLevelStatusEntityMock.rookieForNewHero;

    // when
    final copy = status.copyWith(isCleared: true, nextReward: FundsMock.threeGold);

    // then
    expect(copy, ArenaLevelStatusEntityMock.rookieForVeteran);
    expect(copy.hashCode, ArenaLevelStatusEntityMock.rookieForVeteran.hashCode);
  });
}
