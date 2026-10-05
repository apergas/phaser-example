import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../atlas/atlas_frame.dart';
import '../atlas/lpc_assets.dart';

class AtlasSpriteComponent extends SpriteComponent {
  final AtlasFrame frame;

  AtlasSpriteComponent.fromFrame({
    required this.frame,
    required Sprite sprite,
    required Vector2 position,
    required int priority,
  }) : super(
         sprite: sprite,
         position: position,
         size: Vector2(frame.width.toDouble(), frame.height.toDouble()),
         anchor: Anchor(frame.pivotX, frame.pivotY),
         priority: priority,
         paint: Paint()..filterQuality = FilterQuality.none,
       );

  factory AtlasSpriteComponent({
    required LpcAssets assets,
    required String frameName,
    required PositionEntity at,
    required int priority,
  }) {
    return AtlasSpriteComponent.fromFrame(
      frame: assets.frame(frameName),
      sprite: assets.sprite(frameName),
      position: Vector2(at.x, at.y),
      priority: priority,
    );
  }

  Rect get bounds => Rect.fromLTWH(
    position.x - frame.width * frame.pivotX,
    position.y - frame.height * frame.pivotY,
    frame.width.toDouble(),
    frame.height.toDouble(),
  );

  bool boundsContain(Vector2 point) {
    final area = bounds;
    return point.x >= area.left && point.x <= area.right && point.y >= area.top && point.y <= area.bottom;
  }
}
