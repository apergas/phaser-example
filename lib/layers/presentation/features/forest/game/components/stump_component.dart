import 'package:flame/components.dart';

import '../../../../../domain/entities/tree/stump_entity.dart';
import '../../../../../domain/world/extensions/stump_rules.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/growth_motion.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import 'atlas_sprite_component.dart';

class StumpComponent extends AtlasSpriteComponent {
  final String stumpId;
  final bool isSapling;
  double? _growElapsedMs;

  StumpComponent({required LpcAssets assets, required StumpEntity stump})
    : stumpId = stump.id,
      isSapling = stump.isSapling,
      super.fromFrame(
        frame: assets.frame(_frameName(stump)),
        sprite: assets.sprite(_frameName(stump)),
        position: stump.position.toVector2(),
        priority: RenderDepth.bySortY(stump.position.y - 1),
      );

  static String _frameName(StumpEntity stump) => stump.isSapling ? SpriteNames.sapling : SpriteNames.stump;

  void grow() {
    _growElapsedMs = 0;
    scale.setAll(GrowthMotion.startScale);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final growElapsed = _growElapsedMs;
    if (growElapsed == null) return;
    final total = growElapsed + dt * 1000;
    scale.setAll(GrowthMotion.scale(total));
    _growElapsedMs = GrowthMotion.hasGrown(total) ? null : total;
  }
}
