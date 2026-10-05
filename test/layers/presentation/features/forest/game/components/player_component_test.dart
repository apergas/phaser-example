import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/player_sheet.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/player_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';
import '../../../../../../mocks/presentation/features/forest/player_render_data_mock.dart';

void main() {
  testWithFlameGame('testWhenIdleThenBreathesAtTwoFramesPerSecond', (game) async {
    // given
    final player = PlayerComponent(assets: LpcAssetsMock.create(), player: ForestDataMock.player);
    await game.ensureAdd(player.shadow);
    await game.ensureAdd(player);

    // when
    game.update(0.5);

    // then
    expect(player.currentFrame.sheet, PlayerSheet.idle);
    expect(player.currentFrame.column, 1);
    expect(player.currentFrame.row, 2);
    expect(player.priority, RenderDepth.bySortY(150));
    expect(player.shadow.position, Vector2(150, 149));
  });

  testWithFlameGame('testWhenThePoseChangesThenTheAnimationRestarts', (game) async {
    // given
    final player = PlayerComponent(assets: LpcAssetsMock.create(), player: ForestDataMock.player);
    await game.ensureAdd(player);
    game.update(0.5);

    // when
    player.show(PlayerRenderDataMock.walkingWithAxeNearby);

    // then
    expect(player.currentFrame.sheet, PlayerSheet.walkAxe);
    expect(player.currentFrame.column, 1);
    expect(player.currentFrame.row, 3);
    expect(player.position, Vector2(160, 155));
    expect(player.priority, RenderDepth.bySortY(155));
  });
}
