import 'dart:ui';

import 'package:flame/components.dart';

import '../../../forest/game/components/ground_component.dart';
import '../atlas/arena_assets.dart';
import '../atlas/arena_sprite_names.dart';
import '../render/arena_render_constants.dart';

class ArenaGroundComponent extends GroundComponent {
  final Sprite _fence;
  final Vector2 _fenceSize;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  ArenaGroundComponent({required ArenaAssets assets})
    : _fence = assets.sprite(ArenaSpriteNames.fence),
      _fenceSize = assets.sprite(ArenaSpriteNames.fence).srcSize,
      super(
        tile: assets.ground,
        worldWidth: ArenaRenderConstants.stageWidth,
        worldHeight: ArenaRenderConstants.stageHeight,
      );

  int get fencePosts => (ArenaRenderConstants.stageWidth / _fenceSize.x).ceil();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (var post = 0; post < fencePosts; post++) {
      _fence.render(
        canvas,
        position: Vector2(post * _fenceSize.x, ArenaRenderConstants.fenceY - _fenceSize.y),
        overridePaint: _paint,
      );
    }
  }
}
