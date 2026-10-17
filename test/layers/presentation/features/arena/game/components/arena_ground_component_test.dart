import 'dart:ui';

import 'package:farming/layers/presentation/features/arena/game/components/arena_ground_component.dart';
import 'package:farming/layers/presentation/features/arena/game/render/arena_render_constants.dart';
import 'package:farming/layers/presentation/features/forest/game/render/render_depth.dart';
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenMountingTheArenaGroundThenItSitsUnderEverythingAtTheStageSize', (game) async {
    // given
    final ground = ArenaGroundComponent(assets: ArenaAssetsMock.create());

    // when
    await game.ensureAdd(ground);

    // then
    expect(ground.size, Vector2(ArenaRenderConstants.stageWidth, ArenaRenderConstants.stageHeight));
    expect(ground.priority, RenderDepth.ground);
  });

  test('testWhenDrawingTheArenaGroundZoomedAtAFractionalOffsetThenNoSeamsBetweenTilesShow', () async {
    // given
    final ground = ArenaGroundComponent(assets: ArenaAssetsMock.create());
    final width = (ArenaRenderConstants.stageWidth * 2).ceil();
    final height = (ArenaRenderConstants.stageHeight * 2).ceil();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(const Color(0xFF000000), BlendMode.src);
    canvas
      ..scale(2)
      ..translate(0.37, 0.53);

    // when
    ground.render(canvas);
    final image = await recorder.endRecording().toImageSync(width, height).toByteData();
    final pixels = image!;

    // then
    final firstGrassRow = (ArenaRenderConstants.fenceY * 2).ceil() + 4;
    final seams = [
      for (var y = firstGrassRow; y < height - 2; y++)
        for (var x = 2; x < width - 2; x++)
          if (pixels.getUint8((y * width + x) * 4) < 255) (x, y),
    ];
    expect(seams, isEmpty);
  });
}
