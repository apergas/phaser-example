import 'dart:ui';

import 'package:flame/components.dart';

import '../render/render_depth.dart';

class ShadowComponent extends PositionComponent {
  static final Paint _paint = Paint()..color = const Color(0x4D000000);

  ShadowComponent({required Vector2 center, required Vector2 size})
    : super(position: center, size: size, anchor: Anchor.center, priority: RenderDepth.shadow);

  @override
  void render(Canvas canvas) {
    canvas.drawOval(size.toRect(), _paint);
  }
}
