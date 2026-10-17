import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../../domain/entities/rock/rock_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import '../render/rock_motion.dart';
import 'atlas_sprite_component.dart';

class RockComponent extends AtlasSpriteComponent {
  final String rockId;
  final PositionEntity base;
  final LpcAssets _assets;
  double _direction = 1;
  double? _hitElapsedMs;
  double? _breakElapsedMs;

  RockComponent({required LpcAssets assets, required RockEntity rock})
    : rockId = rock.id,
      base = rock.position,
      _assets = assets,
      super.fromFrame(
        frame: assets.frame(SpriteNames.rock),
        sprite: assets.sprite(SpriteNames.rock),
        position: rock.position.toVector2(),
        priority: RenderDepth.bySortY(rock.position.y),
      );

  bool get isBreaking => _breakElapsedMs != null;

  @override
  bool containsPoint(Vector2 point) {
    if (isBreaking || !boundsContain(point)) return false;
    final area = bounds;
    return _assets.isOpaque(frame, (point.x - area.left).floor(), (point.y - area.top).floor());
  }

  void hit(double fromX) {
    _direction = RockMotion.direction(fromX: fromX, baseX: base.x);
    _hitElapsedMs = 0;
  }

  void shatter() {
    _hitElapsedMs = null;
    position.setValues(base.x, base.y);
    _breakElapsedMs = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsedMs = dt * 1000;
    final breakElapsed = _breakElapsedMs;
    if (breakElapsed != null) {
      final total = breakElapsed + elapsedMs;
      _breakElapsedMs = total;
      scale.setAll(RockMotion.breakScale(total));
      opacity = RockMotion.breakOpacity(total);
      if (RockMotion.hasBroken(total)) removeFromParent();
      return;
    }
    final hitElapsed = _hitElapsedMs;
    if (hitElapsed == null) return;
    final total = hitElapsed + elapsedMs;
    position.setValues(base.x + RockMotion.shakeX(elapsedMs: total, direction: _direction), base.y);
    _hitElapsedMs = total >= RockMotion.shakeMs ? null : total;
  }
}
