import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_constants.dart';

void main() {
  test('testWhenNamingFightersThenTheChiefBorrowsTheBarbarianArt', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final names = [ArenaSpriteNames.fighter(null), for (final kind in kinds) ArenaSpriteNames.fighter(kind)];

    // then
    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian', 'bandit', 'barbarian']);
    expect(ArenaSpriteNames.idle('bandit', 1), 'bandit-idle-1');
    expect(ArenaSpriteNames.slash('hero', 5), 'hero-slash-5');
  });

  test('testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists', () {
    // given
    final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
    final fighters = [ArenaSpriteNames.fighter(null), ...EnemyKind.values.map(ArenaSpriteNames.fighter)];

    // when
    final wanted = [
      ArenaSpriteNames.grass,
      ArenaSpriteNames.fence,
      for (final fighter in fighters) ...[
        for (var column = 0; column < RenderConstants.idleColumns; column++) ArenaSpriteNames.idle(fighter, column),
        for (var column = 0; column < RenderConstants.workColumns; column++) ArenaSpriteNames.slash(fighter, column),
      ],
    ];

    // then
    expect(wanted.where((name) => !frames.contains(name)), isEmpty);
  });
}
