import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_item_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  test('testWhenBobbingThenFloatsBetweenEightAndElevenPixelsUp', () {
    // given
    const times = [0.0, 700.0, 1400.0];

    // when
    final offsets = times.map(GroundItemComponent.bobOffset).toList();

    // then
    expect(offsets[0], closeTo(-8, 1e-9));
    expect(offsets[1], closeTo(-11, 1e-9));
    expect(offsets[2], closeTo(-8, 1e-9));
  });

  testWithFlameGame('testWhenPickedUpThenRisesFadesAndDisappearsWithItsShadow', (game) async {
    // given
    final item = GroundItemComponent(assets: LpcAssetsMock.create(), item: ForestDataMock.axe);
    await game.ensureAdd(item.shadow);
    await game.ensureAdd(item);

    // when
    item.pickUp();
    game.update(0.15);
    final halfwayOpacity = item.opacity;
    game.update(0.16);
    await game.ready();

    // then
    expect(item.priority, RenderDepth.bySortY(ForestDataMock.axe.position.y));
    expect(halfwayOpacity, closeTo(0.5, 0.01));
    expect(item.isMounted, isFalse);
    expect(item.shadow.isMounted, isFalse);
  });
}
