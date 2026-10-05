import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/player_render_data.dart';
import '../atlas/lpc_assets.dart';
import '../render/player_frame.dart';
import '../render/player_frames.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import 'shadow_component.dart';

class PlayerComponent extends PositionComponent {
  static const double shadowWidth = 22;
  static const double shadowHeight = 7;
  static const double shadowOffsetY = -1;

  final LpcAssets _assets;
  final ShadowComponent shadow;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  PlayerRenderData _player;
  String _animationKey;
  double _animationSeconds = 0;

  PlayerComponent({required this._assets, required PlayerRenderData player})
    : _player = player,
      _animationKey = PlayerFrames.animationKey(player),
      shadow = ShadowComponent(
        center: player.position.toVector2()..y += shadowOffsetY,
        size: Vector2(shadowWidth, shadowHeight),
      ),
      super(position: player.position.toVector2(), priority: RenderDepth.bySortY(player.position.y));

  PlayerFrame get currentFrame => PlayerFrames.frame(_player, _animationSeconds);

  void show(PlayerRenderData player) {
    final key = PlayerFrames.animationKey(player);
    if (key != _animationKey) {
      _animationKey = key;
      _animationSeconds = 0;
    }
    _player = player;
    position.setValues(player.position.x, player.position.y);
    priority = RenderDepth.bySortY(player.position.y);
    shadow.position.setValues(player.position.x, player.position.y + shadowOffsetY);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationSeconds += dt;
  }

  @override
  void render(Canvas canvas) {
    final frame = currentFrame;
    final cell = frame.cellSize;
    canvas.drawImageRect(
      _assets.sheet(frame.sheet),
      Rect.fromLTWH(frame.column * cell, frame.row * cell, cell, cell),
      Rect.fromLTWH(-cell / 2, -cell * frame.anchorY, cell, cell),
      _paint,
    );
  }
}
