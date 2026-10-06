import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenMountingTheGroundThenItSitsUnderEverything', (game) async {
    // given
    final ground = GroundComponent(tile: LpcAssetsMock.create().ground, worldWidth: 400, worldHeight: 300);

    // when
    await game.ensureAdd(ground);

    // then
    expect(ground.size, Vector2(400, 300));
    expect(ground.priority, RenderDepth.ground);
  });

  test('testWhenDrawingTheGroundZoomedAtAFractionalOffsetThenNoSeamsBetweenTilesShow', () async {
    // given
    final ground = GroundComponent(tile: LpcAssetsMock.groundTile(), worldWidth: 40, worldHeight: 40);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(const Color(0xFF000000), BlendMode.src);
    canvas
      ..scale(2)
      ..translate(0.37, 0.53);

    // when
    ground.render(canvas);
    final image = await recorder.endRecording().toImage(80, 80);
    final pixels = (await image.toByteData())!;

    // then
    final seams = [
      for (var y = 2; y < 78; y++)
        for (var x = 2; x < 78; x++)
          if (pixels.getUint8((y * 80 + x) * 4) < 255) (x, y),
    ];
    expect(seams, isEmpty);
  });
}
