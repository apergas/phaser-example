import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/render_constants.dart';
import '../../models/placement_data.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';

class PlacementGhostComponent extends AtlasSpriteComponent {
  static const double ghostOpacity = 0.6;
  static const Color validTint = Color(0xFFB8FFB8);
  static const Color invalidTint = Color(0xFFFF8080);

  bool _isValid = false;

  PlacementGhostComponent({required LpcAssets assets})
    : super.fromFrame(
        frame: assets.frame(SpriteNames.house),
        sprite: assets.sprite(SpriteNames.house),
        position: Vector2.zero(),
        priority: RenderDepth.overlay,
      ) {
    opacity = ghostOpacity;
  }

  bool get isValid => _isValid;

  void show(PlacementData placement) {
    position.setValues(placement.position.x, placement.position.y + RenderConstants.houseFrontOffset);
    _isValid = placement.isValid;
    paint.colorFilter = ColorFilter.mode(placement.isValid ? validTint : invalidTint, BlendMode.modulate);
  }
}
