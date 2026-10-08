import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_render_constants.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_constants.dart';

void main() {
  test('testWhenNamingFightersThenTheChiefBorrowsTheBarbarianArtAndTheBeastsHaveTheirOwn', () {
    // given
    const kinds = EnemyKind.values;

    // when
    final names = [ArenaSpriteNames.fighter(null), for (final kind in kinds) ArenaSpriteNames.fighter(kind)];

    // then
    expect(names, ['hero', 'bandit', 'barbarian', 'barbarian', 'wolf', 'bear']);
    expect(ArenaSpriteNames.idle('bandit', 1), 'bandit-idle-1');
    expect(ArenaSpriteNames.slash('hero', 5), 'hero-slash-5');
  });

  test('testWhenReadingTheArenaAtlasThenEveryFrameTheSceneAsksForExists', () {
    // given
    final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
    const kinds = <EnemyKind?>[null, ...EnemyKind.values];

    // when
    final wanted = [
      ArenaSpriteNames.grass,
      ArenaSpriteNames.fence,
      for (final kind in kinds) ...[
        for (var column = 0; column < RenderConstants.idleColumns; column++)
          ArenaSpriteNames.idle(ArenaSpriteNames.fighter(kind), column),
        ...switch (ArenaRenderConstants.leapSequence(kind)) {
          null => [
            for (var column = 0; column < RenderConstants.workColumns; column++)
              ArenaSpriteNames.slash(ArenaSpriteNames.fighter(kind), column),
          ],
          final sequence => [
            for (final column in sequence.toSet()) ArenaSpriteNames.attack(ArenaSpriteNames.fighter(kind), column),
            ArenaSpriteNames.down(ArenaSpriteNames.fighter(kind)),
          ],
        },
      ],
    ];

    // then
    expect(wanted.where((name) => !frames.contains(name)), isEmpty);
  });

  test('testWhenReadingTheArenaAtlasThenTheWolfAndTheBearHaveTheirIdleAttackAndDownFrames', () {
    // given
    final json = jsonDecode(File('lib/core/assets/images/lpc/arena.json').readAsStringSync()) as Map<String, dynamic>;
    final frames = (json['frames'] as Map<String, dynamic>).keys.toSet();
    const beasts = [('wolf', 5), ('bear', 3)];

    // when
    final wanted = [
      for (final (beast, attackColumns) in beasts) ...[
        for (var column = 0; column < RenderConstants.idleColumns; column++) ArenaSpriteNames.idle(beast, column),
        for (var column = 0; column < attackColumns; column++) ArenaSpriteNames.attack(beast, column),
        ArenaSpriteNames.down(beast),
      ],
    ];

    // then
    expect(wanted.where((name) => !frames.contains(name)), isEmpty);
    expect((ArenaSpriteNames.attack('wolf', 4), ArenaSpriteNames.down('bear')), ('wolf-attack-4', 'bear-down'));
  });
}
