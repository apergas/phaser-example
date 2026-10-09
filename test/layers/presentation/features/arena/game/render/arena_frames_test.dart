import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_frames.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_render_constants.dart';

import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';

void main() {
  test('testWhenAPersonAttacksThenItWalksStrikesWithTheChopSequenceAndWalksBack', () {
    // given
    final progresses = [0.1, 0.35, 0.5, 0.9];

    // when
    final names = [
      for (final progress in progresses) ArenaFrames.frameName(FighterRenderDataMock.heroSwinging(progress), 0),
    ];

    // then
    expect(names, ['hero-walk-1', 'hero-slash-0', 'hero-slash-4', 'hero-walk-1']);
  });

  test('testWhenAFighterIsIdleHurtOrDownThenTheIdleFramesAreUsed', () {
    // given
    const idle = FighterRenderDataMock.rookieBanditIdle;
    const hurt = FighterRenderDataMock.rookieBanditHurt;
    const down = FighterRenderDataMock.rookieBanditDown;

    // when
    final names = [ArenaFrames.frameName(idle, 0.6), ArenaFrames.frameName(hurt, 0), ArenaFrames.frameName(down, 0.6)];

    // then
    expect(names, ['bandit-idle-1', 'bandit-idle-0', 'bandit-idle-0']);
    expect(ArenaFrames.frameName(FighterRenderDataMock.chiefIdle, 0), 'barbarian-chief-idle-0');
  });

  test('testWhenPlacingFightersThenTheHeroFacesTheEnemiesFromTheLeft', () {
    // given
    // when
    final hero = ArenaFrames.spot(FightSide.hero, 0);
    final enemies = [for (var index = 0; index < 3; index++) ArenaFrames.spot(FightSide.enemy, index)];

    // then
    expect(hero, const PositionEntity(x: 190, y: 170));
    expect(enemies, const [
      PositionEntity(x: 300, y: 170),
      PositionEntity(x: 340, y: 140),
      PositionEntity(x: 340, y: 200),
    ]);
  });

  test('testWhenABeastAttacksThenTheAttackFrameFollowsItsSequenceWithTheWidestBiteOnImpact', () {
    // given
    final wolfStart = FighterRenderDataMock.wolfLeaping(0);
    final wolfImpact = FighterRenderDataMock.wolfLeaping(0.5);
    final bearImpact = FighterRenderDataMock.bearLeaping(0.5);

    // when
    final names = [
      ArenaFrames.frameName(wolfStart, 0),
      ArenaFrames.frameName(wolfImpact, 0),
      ArenaFrames.frameName(bearImpact, 0),
    ];

    // then
    expect(names, ['wolf-attack-0', 'wolf-attack-2', 'bear-attack-2']);
  });

  test('testWhenABeastIsDownThenItLiesOnItsOwnFrame', () {
    // given
    const down = FighterRenderDataMock.wolfDown;

    // when
    final name = ArenaFrames.frameName(down, 0.6);

    // then
    expect(name, 'wolf-down');
    expect((ArenaFrames.isBeast(EnemyKind.wolf), ArenaFrames.isBeast(EnemyKind.barbarian)), (true, false));
  });

  test('testWhenTheWolfLeapsThenItJumpsTowardsTheHeroStopsShortAndComesBack', () {
    // given
    final progresses = [0.0, 0.2, 0.5, 0.8, 0.999];

    // when
    final spots = [
      for (final progress in progresses) ArenaFrames.groundSpot(FighterRenderDataMock.wolfLeaping(progress)),
    ];
    final lifts = [for (final progress in progresses) ArenaFrames.lift(FighterRenderDataMock.wolfLeaping(progress))];

    // then
    expect(spots.map((spot) => spot.y), everyElement(170));
    expect(spots[0].x, 300);
    expect(spots[1].x, closeTo(300 - 80 * math.sqrt(0.5), 1e-9));
    expect(spots[2].x, 190 + ArenaRenderConstants.leapGap);
    expect(spots[3].x, closeTo(260, 1e-9));
    expect(spots[4].x, closeTo(300, 0.01));
    expect(lifts[0], 0);
    expect(lifts[1], closeTo(ArenaRenderConstants.leapHeight, 1e-9));
    expect(lifts[2], 0);
    expect(lifts[3], closeTo(ArenaRenderConstants.leapHeight, 1e-9));
  });

  test('testWhenAPersonAttacksThenItWalksUpToItsTargetStopsShortAndWalksBackWithoutJumping', () {
    // given
    final progresses = [0.0, 0.5, 0.999];

    // when
    final spots = [
      for (final progress in progresses) ArenaFrames.groundSpot(FighterRenderDataMock.heroSwinging(progress)),
    ];
    final lift = ArenaFrames.lift(FighterRenderDataMock.heroSwinging(0.2));

    // then
    expect(spots.map((spot) => spot.y), everyElement(170));
    expect(spots[0].x, 190);
    expect(spots[1].x, 300 - ArenaRenderConstants.approachGap);
    expect(spots[2].x, closeTo(190, 0.01));
    expect(lift, 0);
  });

  test('testWhenTheHeroHoldsASwordThenItsFramesAreTheSwordOnes', () {
    // given
    const hero = FighterRenderDataMock.heroWithSteelSwordIdle;

    // when
    final name = ArenaFrames.frameName(hero, 0);

    // then
    expect(name, 'hero-steel-sword-idle-0');
  });
}
