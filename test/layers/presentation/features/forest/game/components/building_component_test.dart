import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/building_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenASiteIsPlacedThenIsDrawnBelowItsFootprintAndTranslucent', (game) async {
    // given
    final building = BuildingComponent(assets: LpcAssetsMock.create(), building: ForestDataMock.house);

    // when
    await game.ensureAdd(building);

    // then
    expect(building.position, Vector2(200, 204));
    expect(building.front.y, ForestDataMock.house.position.y + 24);
    expect(building.priority, RenderDepth.bySortY(204));
    expect(building.opacity, closeTo(0.35, 0.01));
  });

  testWithFlameGame('testWhenHammeredThenBecomesMoreSolid', (game) async {
    // given
    final building = BuildingComponent(assets: LpcAssetsMock.create(), building: ForestDataMock.house);
    await game.ensureAdd(building);

    // when
    building.hammered(0.5);

    // then
    expect(building.progress, 0.5);
    expect(building.opacity, closeTo(0.675, 0.01));
  });

  testWithFlameGame('testWhenCompletedThenSettlesWithABounce', (game) async {
    // given
    final building = BuildingComponent(assets: LpcAssetsMock.create(), building: ForestDataMock.house);
    await game.ensureAdd(building);

    // when
    building.complete();
    final squashed = building.scale.y;
    game.update(0.35);

    // then
    expect(squashed, closeTo(0.92, 1e-6));
    expect(building.isComplete, isTrue);
    expect(building.opacity, closeTo(1, 0.01));
    expect(building.scale.y, closeTo(1, 1e-6));
  });
}
