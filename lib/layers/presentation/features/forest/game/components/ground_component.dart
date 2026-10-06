import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../render/render_depth.dart';

class GroundComponent extends PositionComponent {
  static final Float64List _identity = Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

  final Image tile;
  late final Paint _paint = Paint()
    ..isAntiAlias = false
    ..shader = ImageShader(tile, TileMode.repeated, TileMode.repeated, _identity, filterQuality: FilterQuality.none);

  GroundComponent({required this.tile, required double worldWidth, required double worldHeight})
    : super(size: Vector2(worldWidth, worldHeight), priority: RenderDepth.ground);

  @override
  void render(Canvas canvas) => canvas.drawRect(size.toRect(), _paint);
}
