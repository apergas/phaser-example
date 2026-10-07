import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

import '../../../../../mocks/presentation/features/arena/arena_effect_mock.dart';

void main() {
  test('testWhenComparingEffectsThenTheyAreEqualByValue', () {
    // given
    const effects = ArenaEffectMock.victoryOverBandit;

    // when
    final hits = effects.whereType<HitEffect>().toSet();

    // then
    expect(hits, {ArenaEffectMock.banditHitForFour, ArenaEffectMock.heroHitForTwo});
    expect(ArenaEffectMock.won, isNot(ArenaEffectMock.lost));
    expect(ArenaEffectMock.heroDodged.side, FightSide.hero);
    expect(ArenaEffectMock.heroHealedTwelve.hashCode, ArenaEffectMock.heroHealedTwelve.hashCode);
  });
}
