import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  test('testWhenTilingTheForestThenCoversItWithWholeTiles', () {
    // given
    const width = 1600.0;
    const height = 1200.0;

    // when
    final columns = GroundComponent.columnsFor(width);
    final rows = GroundComponent.rowsFor(height);

    // then
    expect(columns, 50);
    expect(rows, 38);
  });

  testWithFlameGame('testWhenMountingTheGroundThenItSitsUnderEverything', (game) async {
    // given
    final ground = GroundComponent(tile: LpcAssetsMock.create().ground, worldWidth: 400, worldHeight: 300);

    // when
    await game.ensureAdd(ground);

    // then
    expect(ground.size, Vector2(400, 300));
    expect(ground.priority, RenderDepth.ground);
  });
}
