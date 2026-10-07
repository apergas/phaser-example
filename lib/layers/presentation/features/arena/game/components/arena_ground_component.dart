import 'dart:ui';

import 'package:flame/components.dart';

import '../../../forest/game/render/render_depth.dart';
import '../atlas/arena_assets.dart';
import '../atlas/arena_sprite_names.dart';
import '../render/arena_render_constants.dart';

class ArenaGroundComponent extends PositionComponent {
  final Sprite _grass;
  final Sprite _fence;
  final Vector2 _grassSize;
  final Vector2 _fenceSize;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  ArenaGroundComponent({required ArenaAssets assets})
    : _grass = assets.sprite(ArenaSpriteNames.grass),
      _fence = assets.sprite(ArenaSpriteNames.fence),
      _grassSize = assets.sprite(ArenaSpriteNames.grass).srcSize,
      _fenceSize = assets.sprite(ArenaSpriteNames.fence).srcSize,
      super(
        size: Vector2(ArenaRenderConstants.stageWidth, ArenaRenderConstants.stageHeight),
        priority: RenderDepth.ground,
      );

  int get fencePosts => (ArenaRenderConstants.stageWidth / _fenceSize.x).ceil();

  @override
  void render(Canvas canvas) {
    for (var y = 0.0; y < size.y; y += _grassSize.y) {
      for (var x = 0.0; x < size.x; x += _grassSize.x) {
        _grass.render(canvas, position: Vector2(x, y), overridePaint: _paint);
      }
    }
    for (var post = 0; post < fencePosts; post++) {
      _fence.render(
        canvas,
        position: Vector2(post * _fenceSize.x, ArenaRenderConstants.fenceY - _fenceSize.y),
        overridePaint: _paint,
      );
    }
  }
}
