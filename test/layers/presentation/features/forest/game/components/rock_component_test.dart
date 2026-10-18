import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/presentation/features/forest/game/components/rock_component.dart';
import 'package:farming/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenARockIsAddedThenItSitsOnItsBaseSortedByIt', (game) async {
    // given
    final rock = RockComponent(assets: LpcAssetsMock.create(), rock: ForestDataMock.rock);

    // when
    await game.ensureAdd(rock);

    // then
    expect(rock.position, Vector2(300, 250));
    expect(rock.priority, RenderDepth.bySortY(250));
    expect(rock.rockId, 'rock-1');
  });

  testWithFlameGame('testWhenTappingTheRockThenOnlyItsOpaquePixelsCount', (game) async {
    // given
    final rock = RockComponent(assets: LpcAssetsMock.create(), rock: ForestDataMock.rock);
    await game.ensureAdd(rock);

    // when
    final solid = rock.containsPoint(Vector2(302, 248));
    final clear = rock.containsPoint(Vector2(297, 248));

    // then
    expect((solid, clear), (true, false));
  });

  testWithFlameGame('testWhenHitFromTheLeftThenItShakesRightAndSettlesBack', (game) async {
    // given
    final rock = RockComponent(assets: LpcAssetsMock.create(), rock: ForestDataMock.rock);
    await game.ensureAdd(rock);

    // when
    rock.hit(270);
    game.update(0.06);
    final shaken = rock.position.x;
    game.update(0.07);

    // then
    expect(shaken, closeTo(301.5, 1e-6));
    expect(rock.position.x, 300);
  });

  testWithFlameGame('testWhenItShattersThenItCannotBeTappedShrinksFadesAndIsRemoved', (game) async {
    // given
    final rock = RockComponent(assets: LpcAssetsMock.create(), rock: ForestDataMock.rock);
    await game.ensureAdd(rock);

    // when
    rock.shatter();
    final tappable = rock.containsPoint(Vector2(302, 248));
    game.update(0.35);
    await game.ready();

    // then
    expect(tappable, isFalse);
    expect(rock.isBreaking, isTrue);
    expect(rock.isMounted, isFalse);
  });
}
