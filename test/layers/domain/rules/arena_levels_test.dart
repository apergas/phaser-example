import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
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

  test('testWhenListingLevelsThenTheBeastsSitBetweenTheHumans', () {
    // given
    final levels = ArenaLevels.all;

    // when
    final ids = levels.map((level) => level.id);

    // then
    expect(ids, [
      ArenaLevelId.banditRookie,
      ArenaLevelId.wolf,
      ArenaLevelId.banditVeteran,
      ArenaLevelId.wolfPair,
      ArenaLevelId.bear,
      ArenaLevelId.banditTrio,
      ArenaLevelId.barbarian,
      ArenaLevelId.wolfPack,
      ArenaLevelId.barbarianPair,
      ArenaLevelId.barbarianChief,
    ]);
  });

  test('testWhenFindingTheBeastLevelsThenTheirEnemiesPowerAndGoldMatchTheTable', () {
    // given
    const ids = [ArenaLevelId.wolf, ArenaLevelId.wolfPair, ArenaLevelId.bear, ArenaLevelId.wolfPack];

    // when
    final levels = ids.map(ArenaLevels.byId).toList();

    // then
    expect(levels.map((level) => level.enemies.map((enemy) => enemy.kind).toList()), [
      [EnemyKind.wolf],
      [EnemyKind.wolf, EnemyKind.wolf],
      [EnemyKind.bear],
      [EnemyKind.wolf, EnemyKind.wolf, EnemyKind.wolf],
    ]);
    expect(levels.map((level) => (level.power, level.reward[Resource.gold])), [(30, 15), (60, 25), (59, 35), (84, 55)]);
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
