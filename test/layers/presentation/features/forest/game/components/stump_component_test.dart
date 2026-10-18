import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/presentation/features/forest/game/components/stump_component.dart';
import 'package:farming/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenAStumpIsAddedThenItSitsOnTheTrunkBaseJustBehindIt', (game) async {
    // given
    final stump = StumpComponent(assets: LpcAssetsMock.create(), stump: ForestDataMock.stump);

    // when
    await game.ensureAdd(stump);

    // then
    expect(stump.position, Vector2(100, 120));
    expect(stump.priority, RenderDepth.bySortY(119));
    expect((stump.isSapling, stump.stumpId), (false, 'tree-1'));
    expect(stump.scale.x, 1);
  });

  testWithFlameGame('testWhenASaplingIsAddedThenItKnowsItIsASapling', (game) async {
    // given
    final sapling = StumpComponent(assets: LpcAssetsMock.create(), stump: ForestDataMock.sapling);

    // when
    await game.ensureAdd(sapling);

    // then
    expect(sapling.isSapling, isTrue);
  });

  testWithFlameGame('testWhenItGrowsThenItGoesFromAThirdToFullSizeInSixHundredMilliseconds', (game) async {
    // given
    final sapling = StumpComponent(assets: LpcAssetsMock.create(), stump: ForestDataMock.sapling);
    await game.ensureAdd(sapling);

    // when
    sapling.grow();
    final start = sapling.scale.x;
    game.update(0.3);
    final middle = sapling.scale.x;
    game.update(0.3);

    // then
    expect(start, closeTo(0.35, 1e-6));
    expect(middle, greaterThan(start));
    expect(sapling.scale.x, closeTo(1, 1e-6));
  });
}
