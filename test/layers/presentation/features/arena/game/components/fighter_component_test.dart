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

  testWithFlameGame('testWhenTheChiefIsShownThenItUsesItsOwnArtBigger', (game) async {
    // given
    final chief = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.chiefIdle);

    // when
    await game.ensureAdd(chief);

    // then
    expect(chief.scale, Vector2.all(1.25));
    expect(chief.frameName, 'barbarian-chief-idle-0');
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

  testWithFlameGame('testWhenTheWolfLeapsThenItsShadowAndBarFollowAndItLandsBackOnItsSpot', (game) async {
    // given
    final wolf = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.wolfIdle);
    await game.ensureAdd(wolf);

    // when
    wolf.show(FighterRenderDataMock.wolfLeaping(0.5));
    final atTheHero = (wolf.position.clone(), wolf.shadow.position.clone(), wolf.healthBar.position.clone());
    wolf.show(FighterRenderDataMock.wolfLeaping(0.2));
    final inTheAir = wolf.position.y - wolf.shadow.position.y;
    wolf.show(FighterRenderDataMock.wolfIdle);

    // then
    expect(atTheHero, (Vector2(220, 170), Vector2(220, 170), Vector2(220, 118)));
    expect(inTheAir, closeTo(-10, 1e-9));
    expect((wolf.position, wolf.shadow.position), (Vector2(300, 170), Vector2(300, 170)));
    expect(wolf.shadow.size.x, 44);
    expect(wolf.frameName, startsWith('wolf-idle-'));
  });

  testWithFlameGame('testWhenTheWolfFallsThenItLiesOnItsOwnFrameInsteadOfTippingOver', (game) async {
    // given
    final wolf = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.wolfIdle);
    final bandit = FighterComponent(assets: ArenaAssetsMock.create(), fighter: FighterRenderDataMock.rookieBanditIdle);
    await game.ensureAdd(wolf);
    await game.ensureAdd(bandit);

    // when
    wolf.show(FighterRenderDataMock.wolfDown);
    bandit.show(FighterRenderDataMock.rookieBanditDown);

    // then
    expect((wolf.frameName, wolf.tipsOver), ('wolf-down', false));
    expect((bandit.frameName, bandit.tipsOver), ('bandit-idle-0', true));
  });
}
