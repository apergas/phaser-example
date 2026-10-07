import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_frames.dart';

import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';

void main() {
  test('testWhenAFighterSwingsThenTheSlashFrameFollowsTheChopSequence', () {
    // given
    final start = FighterRenderDataMock.heroSwinging(0);
    final impact = FighterRenderDataMock.heroSwinging(0.5);

    // when
    final startName = ArenaFrames.frameName(start, 0);
    final impactName = ArenaFrames.frameName(impact, 0);

    // then
    expect(startName, 'hero-slash-0');
    expect(impactName, 'hero-slash-4');
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
    expect(ArenaFrames.frameName(FighterRenderDataMock.chiefIdle, 0), 'barbarian-idle-0');
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
}
