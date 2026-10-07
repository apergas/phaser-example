import 'dart:ui';

import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';

abstract final class ArenaAssetsMock {
  static const int frameSize = 8;

  static final List<String> frameNames = [
    ArenaSpriteNames.grass,
    ArenaSpriteNames.fence,
    for (final fighter in [ArenaSpriteNames.hero, ...EnemyKind.values.map(ArenaSpriteNames.enemy)]) ...[
      for (var column = 0; column < 2; column++) ArenaSpriteNames.idle(fighter, column),
      for (var column = 0; column < 6; column++) ArenaSpriteNames.slash(fighter, column),
    ],
  ];

  static ArenaAssets create() {
    return ArenaAssets(
      atlas: _image(frameSize, frameSize),
      frames: {
        for (final name in frameNames)
          name: AtlasFrame(name: name, x: 0, y: 0, width: frameSize, height: frameSize, pivotX: 0.5, pivotY: 1),
      },
    );
  }

  static Image _image(int width, int height) {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    return recorder.endRecording().toImageSync(width, height);
  }
}
