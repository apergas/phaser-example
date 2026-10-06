import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/rules/arena_levels.dart';

void main() {
  test('testWhenListingLevelsThenEveryArenaLevelIdAppearsOnce', () {
    // given
    final ids = ArenaLevels.all.map((level) => level.id).toList();

    // when
    final unique = ids.toSet();

    // then
    expect(ids, hasLength(ArenaLevelId.values.length));
    expect(unique, ArenaLevelId.values.toSet());
  });

  test('testWhenListingLevelsThenEachOneHasBetweenOneAndThreeEnemies', () {
    for (final level in ArenaLevels.all) {
      // given
      final enemies = level.enemies;

      // when
      final count = enemies.length;

      // then
      expect(count, inInclusiveRange(1, 3), reason: '${level.id}');
    }
  });

  test('testWhenListingLevelsThenEachOnePaysSomeGold', () {
    for (final level in ArenaLevels.all) {
      // given
      final reward = level.reward;

      // when
      final gold = reward[Resource.gold] ?? 0;

      // then
      expect(gold, greaterThan(0), reason: '${level.id}');
    }
  });

  test('testWhenListingLevelsThenTheRookieBanditOpensTheArena', () {
    // given
    final levels = ArenaLevels.all;

    // when
    final first = levels.first.id;

    // then
    expect(first, ArenaLevelId.banditRookie);
  });

  test('testWhenFindingByIdThenItReturnsThatLevel', () {
    // given
    const id = ArenaLevelId.barbarianChief;

    // when
    final level = ArenaLevels.byId(id);

    // then
    expect((level.id, level.enemies.length, level.power), (ArenaLevelId.barbarianChief, 3, 173));
  });
}
