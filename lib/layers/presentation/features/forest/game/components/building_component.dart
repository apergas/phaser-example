import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../render/render_constants.dart';
import '../../../../../domain/entities/building/building_entity.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/easing.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';

class BuildingComponent extends AtlasSpriteComponent {
  static const double siteOpacity = 0.35;
  static const double barWidth = 60;
  static const double barHeight = 5;
  static const double barMargin = 6;
  static const double bounceMs = 350;
  static const double bounceFrom = 0.92;

  final String buildingId;
  final PositionEntity footprint;
  final Paint _barBackground = Paint()..color = const Color(0x99000000);
  final Paint _barFill = Paint()..color = const Color(0xFFE8C05A);
  double _progress = 0;
  bool _isComplete = false;
  double? _bounceElapsedMs;

  BuildingComponent({required LpcAssets assets, required BuildingEntity building})
    : buildingId = building.id,
      footprint = building.position,
      super.fromFrame(
        frame: assets.frame(SpriteNames.house),
        sprite: assets.sprite(SpriteNames.house),
        position: Vector2(building.position.x, building.position.y + RenderConstants.houseFrontOffset),
        priority: RenderDepth.bySortY(building.position.y + RenderConstants.houseFrontOffset),
      ) {
    progress = building.progress;
  }

  double get progress => _progress;

  bool get isComplete => _isComplete;

  set progress(double value) {
    _progress = value;
    opacity = siteOpacity + (1 - siteOpacity) * value;
  }

  void hammered(double value) {
    progress = value;
  }

  void complete() {
    progress = 1;
    _isComplete = true;
    _bounceElapsedMs = 0;
    scale.y = bounceFrom;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final bounceElapsed = _bounceElapsedMs;
    if (bounceElapsed == null) return;
    final total = bounceElapsed + dt * 1000;
    final bounce = math.min(1.0, total / bounceMs);
    scale.y = bounce >= 1 ? 1 : bounceFrom + (1 - bounceFrom) * Easing.backOut(bounce);
    _bounceElapsedMs = bounce >= 1 ? null : total;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_isComplete) return;
    final left = size.x / 2 - barWidth / 2;
    const top = -barMargin - barHeight;
    canvas.drawRect(Rect.fromLTWH(left - 1, top - 1, barWidth + 2, barHeight + 2), _barBackground);
    canvas.drawRect(Rect.fromLTWH(left, top, barWidth * _progress, barHeight), _barFill);
  }
}
