import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../theme/colors/custom_colors.dart';
import '../../../forest/game/render/render_depth.dart';
import '../render/arena_render_constants.dart';

class TargetRingComponent extends PositionComponent {
  static final Paint _paint = Paint()
    ..color = CustomColors.hudAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = ArenaRenderConstants.targetRingStroke;

  bool isShown = false;

  TargetRingComponent({required Vector2 center, required Vector2 size})
    : super(position: center, size: size, anchor: Anchor.center, priority: RenderDepth.shadow);

  @override
  void render(Canvas canvas) {
    if (!isShown) return;
    canvas.drawOval(size.toRect(), _paint);
  }
}
