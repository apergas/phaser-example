import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/placement_ghost_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenPlacingOnAFreeSpotThenTheGhostIsGreen', (game) async {
    // given
    final ghost = PlacementGhostComponent(assets: LpcAssetsMock.create());
    await game.ensureAdd(ghost);

    // when
    ghost.show(ForestDataMock.validPlacement);

    // then
    expect(ghost.position, Vector2(300, 224));
    expect(ghost.priority, RenderDepth.overlay);
    expect(ghost.opacity, closeTo(0.6, 0.01));
    expect(ghost.paint.colorFilter, const ColorFilter.mode(PlacementGhostComponent.validTint, BlendMode.modulate));
  });

  testWithFlameGame('testWhenPlacingOnABlockedSpotThenTheGhostIsRed', (game) async {
    // given
    final ghost = PlacementGhostComponent(assets: LpcAssetsMock.create());
    await game.ensureAdd(ghost);

    // when
    ghost.show(ForestDataMock.invalidPlacement);

    // then
    expect(ghost.isValid, isFalse);
    expect(ghost.paint.colorFilter, const ColorFilter.mode(PlacementGhostComponent.invalidTint, BlendMode.modulate));
  });
}
