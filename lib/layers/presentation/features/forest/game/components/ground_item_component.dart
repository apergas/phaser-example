import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../../domain/entities/item/ground_item_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/easing.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';
import 'shadow_component.dart';

class GroundItemComponent extends AtlasSpriteComponent {
  static const double floatHeight = 8;
  static const double bobHeight = 3;
  static const double bobMs = 700;
  static const double pickUpRise = 16;
  static const double pickUpMs = 300;
  static const double shadowWidth = 16;
  static const double shadowHeight = 5;

  final String itemId;
  final PositionEntity ground;
  final ShadowComponent shadow;
  double _elapsedMs = 0;
  double? _pickUpElapsedMs;
  double _pickUpStartY = 0;

  GroundItemComponent({required LpcAssets assets, required GroundItemEntity item})
    : itemId = item.id,
      ground = item.position,
      shadow = ShadowComponent(center: item.position.toVector2(), size: Vector2(shadowWidth, shadowHeight)),
      super.fromFrame(
        frame: assets.frame(SpriteNames.axePickup),
        sprite: assets.sprite(SpriteNames.axePickup),
        position: item.position.toVector2()..y -= floatHeight,
        priority: RenderDepth.bySortY(item.position.y),
      );

  bool get isPickingUp => _pickUpElapsedMs != null;

  static double bobOffset(double elapsedMs) {
    final phase = (elapsedMs % (bobMs * 2)) / bobMs;
    final leg = phase <= 1 ? phase : 2 - phase;
    return -floatHeight - bobHeight * Easing.sineInOut(leg);
  }

  void pickUp() {
    shadow.removeFromParent();
    _pickUpElapsedMs = 0;
    _pickUpStartY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsedMs = dt * 1000;
    final pickUpElapsed = _pickUpElapsedMs;
    if (pickUpElapsed != null) {
      final total = pickUpElapsed + elapsedMs;
      _pickUpElapsedMs = total;
      final progress = math.min(1.0, total / pickUpMs);
      position.y = _pickUpStartY - pickUpRise * progress;
      opacity = 1 - progress;
      if (progress >= 1) removeFromParent();
      return;
    }
    _elapsedMs += elapsedMs;
    position.y = ground.y + bobOffset(_elapsedMs);
  }
}
