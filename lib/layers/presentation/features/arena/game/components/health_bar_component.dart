import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../theme/colors/custom_colors.dart';
import '../../../forest/game/render/easing.dart';
import '../../../forest/game/render/render_depth.dart';
import '../render/arena_render_constants.dart';

class HealthBarComponent extends PositionComponent {
  static const Color trackColor = Color(0xCC1C1610);

  final Paint _trackPaint = Paint()..color = trackColor;
  final Paint _fillPaint = Paint();
  double _from = 1;
  double _target = 1;
  double _elapsedMs = ArenaRenderConstants.healthBarEaseMs;

  HealthBarComponent({required Vector2 position})
    : super(
        position: position,
        size: Vector2(ArenaRenderConstants.healthBarWidth, ArenaRenderConstants.healthBarHeight),
        anchor: Anchor.bottomCenter,
        priority: RenderDepth.overlay - 1,
      );

  double get targetFraction => _target;

  double get displayedFraction {
    final progress = math.min(1.0, _elapsedMs / ArenaRenderConstants.healthBarEaseMs);
    return _from + (_target - _from) * Easing.sineOut(progress);
  }

  Color get fillColor {
    final fraction = displayedFraction;
    if (fraction > ArenaRenderConstants.healthBarWarning) return CustomColors.success;
    if (fraction > ArenaRenderConstants.healthBarDanger) return CustomColors.warning;
    return CustomColors.error;
  }

  void show({required int health, required int maxHealth}) {
    final target = maxHealth <= 0 ? 0.0 : (health / maxHealth).clamp(0, 1).toDouble();
    if (target == _target) return;
    _from = displayedFraction;
    _target = target;
    _elapsedMs = 0;
  }

  void snap() {
    _from = _target;
    _elapsedMs = ArenaRenderConstants.healthBarEaseMs;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedMs += dt * 1000;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _trackPaint);
    _fillPaint.color = fillColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x * displayedFraction, size.y), _fillPaint);
  }
}
