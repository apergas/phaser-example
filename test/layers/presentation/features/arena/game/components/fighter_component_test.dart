import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/components/fighter_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/arena/fighter_render_data_mock.dart';
import '../../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenCreatedThenStandsOnItsSpotWithAFullBar', (game) async {
    // given
    final fighter = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);

    // when
    await game.ensureAdd(fighter);

    // then
    expect(fighter.position, Vector2(300, 170));
    expect(fighter.priority, RenderDepth.bySortY(170));
    expect(fighter.healthBar.position, Vector2(300, 118));
    expect(fighter.healthBar.displayedFraction, 1);
    expect(fighter.frameName, 'bandit-idle-0');
  });

  testWithFlameGame('testWhenTheChiefIsShownThenItIsTheBarbarianBigger', (game) async {
    // given
    final chief = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.chiefIdle);

    // when
    await game.ensureAdd(chief);

    // then
    expect(chief.scale, Vector2.all(1.25));
    expect(chief.frameName, 'barbarian-idle-0');
    expect(chief.healthBar.position, Vector2(300, 105));
  });

  testWithFlameGame('testWhenHitThenBlinksForAMomentAndTheBarFollowsTheHealth', (game) async {
    // given
    final fighter = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);
    await game.ensureAdd(fighter);

    // when
    fighter
      ..show(FighterRenderDataMock.rookieBanditHurt)
      ..hit();
    game.update(0.1);
    final blinking = fighter.isBlinkedOut;
    game.update(0.25);

    // then
    expect(blinking, isTrue);
    expect(fighter.isBlinkedOut, isFalse);
    expect(fighter.healthBar.targetFraction, 0.8);
  });
}
