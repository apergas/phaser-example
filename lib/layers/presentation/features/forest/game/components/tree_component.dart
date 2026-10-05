import 'package:flame/components.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../../../domain/entities/tree/tree_entity.dart';
import '../atlas/lpc_assets.dart';
import '../atlas/sprite_names.dart';
import '../render/position_conversion.dart';
import '../render/render_depth.dart';
import '../render/tree_motion.dart';
import 'atlas_sprite_component.dart';

class TreeComponent extends AtlasSpriteComponent {
  final String treeId;
  final PositionEntity base;
  final LpcAssets _assets;
  double _direction = 1;
  double? _hitElapsedMs;
  double? _fallElapsedMs;

  TreeComponent({required LpcAssets assets, required TreeEntity tree})
    : treeId = tree.id,
      base = tree.position,
      _assets = assets,
      super.fromFrame(
        frame: assets.frame(SpriteNames.tree(tree.kind)),
        sprite: assets.sprite(SpriteNames.tree(tree.kind)),
        position: tree.position.toVector2(),
        priority: RenderDepth.bySortY(tree.position.y),
      );

  bool get isFalling => _fallElapsedMs != null;

  @override
  bool containsPoint(Vector2 point) {
    if (isFalling || !boundsContain(point)) return false;
    final area = bounds;
    return _assets.isOpaque(frame, (point.x - area.left).floor(), (point.y - area.top).floor());
  }

  void hit(double fromX) {
    _direction = TreeMotion.direction(fromX: fromX, baseX: base.x);
    _hitElapsedMs = 0;
  }

  void fell(double fromX) {
    _direction = TreeMotion.direction(fromX: fromX, baseX: base.x);
    _hitElapsedMs = null;
    _fallElapsedMs = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final elapsedMs = dt * 1000;
    final fallElapsed = _fallElapsedMs;
    if (fallElapsed != null) {
      final total = fallElapsed + elapsedMs;
      _fallElapsedMs = total;
      angle = TreeMotion.fallAngle(elapsedMs: total, direction: _direction);
      opacity = TreeMotion.fallOpacity(total);
      if (TreeMotion.hasFallen(total)) removeFromParent();
      return;
    }
    final hitElapsed = _hitElapsedMs;
    if (hitElapsed == null) return;
    final total = hitElapsed + elapsedMs;
    angle = TreeMotion.shakeAngle(elapsedMs: total, direction: _direction);
    _hitElapsedMs = total >= TreeMotion.shakeMs ? null : total;
  }
}
