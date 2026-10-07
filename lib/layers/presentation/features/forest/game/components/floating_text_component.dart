import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../theme/colors/custom_colors.dart';
import '../render/easing.dart';
import '../render/render_depth.dart';

class FloatingTextComponent extends TextComponent<TextPaint> {
  static const Color defaultColor = CustomColors.hudAccent;
  static const Color outlineColor = CustomColors.black;
  static const double fontSize = 9;
  static const double startLift = 20;
  static const double rise = 18;
  static const double lifetimeMs = 900;
  static const double fadeStart = 0.5;

  final Color color;
  final double _startY;
  double _elapsedMs = 0;

  FloatingTextComponent({required String text, required PositionEntity at, this.color = defaultColor})
    : _startY = at.y - startLift,
      super(
        text: text,
        textRenderer: TextPaint(style: _style(color, 1)),
        position: Vector2(at.x, at.y - startLift),
        anchor: Anchor.bottomCenter,
        priority: RenderDepth.overlay,
      );

  double get alpha {
    final progress = _progress;
    if (progress <= fadeStart) return 1;
    return 1 - (progress - fadeStart) / (1 - fadeStart);
  }

  double get _progress => math.min(1.0, _elapsedMs / lifetimeMs);

  static TextStyle _style(Color color, double alpha) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color.withValues(alpha: alpha),
    shadows: [
      Shadow(
        color: outlineColor.withValues(alpha: alpha),
        offset: const Offset(0.5, 0.5),
      ),
    ],
  );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsedMs += dt * 1000;
    position.y = _startY - rise * Easing.sineOut(_progress);
    textRenderer = TextPaint(style: _style(color, alpha));
    if (_progress >= 1) removeFromParent();
  }
}
