import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/enum/arena/fighter_pose.dart';
import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../../../forest/game/components/shadow_component.dart';
import '../../../forest/game/render/position_conversion.dart';
import '../../../forest/game/render/render_depth.dart';
import '../../models/fighter_render_data.dart';
import '../atlas/arena_assets.dart';
import '../render/arena_frames.dart';
import '../render/arena_render_constants.dart';
import 'health_bar_component.dart';

class FighterComponent extends PositionComponent {
  static const double shadowWidth = 22;
  static const double shadowHeight = 7;

  final ArenaAssets _assets;
  final ShadowComponent shadow;
  final HealthBarComponent healthBar;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  FighterRenderData _fighter;
  double _animationSeconds = 0;
  double _blinkMs = 0;

  FighterComponent({required this._assets, required FighterRenderData fighter})
    : _fighter = fighter,
      shadow = ShadowComponent(
        center: ArenaFrames.spot(fighter.side, fighter.index).toVector2(),
        size:
            Vector2(shadowWidthOf(fighter.enemyKind), shadowHeight) *
            ArenaRenderConstants.fighterScale(fighter.enemyKind),
      ),
      healthBar = HealthBarComponent(
        position: ArenaFrames.spot(fighter.side, fighter.index).toVector2()
          ..y -= ArenaRenderConstants.healthBarLift * ArenaRenderConstants.fighterScale(fighter.enemyKind),
      ),
      super(
        position: ArenaFrames.spot(fighter.side, fighter.index).toVector2(),
        scale: Vector2.all(ArenaRenderConstants.fighterScale(fighter.enemyKind)),
        priority: RenderDepth.bySortY(ArenaFrames.spot(fighter.side, fighter.index).y),
      ) {
    healthBar
      ..show(health: fighter.health, maxHealth: fighter.maxHealth)
      ..snap();
    _place();
  }

  static double shadowWidthOf(EnemyKind? kind) =>
      ArenaFrames.isBeast(kind) ? ArenaRenderConstants.beastShadowWidth : shadowWidth;

  FighterRenderData get fighter => _fighter;

  String get frameName => ArenaFrames.frameName(_fighter, _animationSeconds);

  bool get tipsOver => _fighter.pose == FighterPose.down && !ArenaFrames.isBeast(_fighter.enemyKind);

  bool get isBlinkedOut =>
      _blinkMs > 0 && ((ArenaRenderConstants.hurtBlinkMs - _blinkMs) ~/ ArenaRenderConstants.blinkPeriodMs).isOdd;

  PositionEntity get impactPoint => PositionEntity(
    x: position.x,
    y: position.y - ArenaRenderConstants.impactHeight * scale.y,
  );

  PositionEntity get headPoint => PositionEntity(
    x: position.x,
    y: position.y - ArenaRenderConstants.floatingTextHeight * scale.y,
  );

  void show(FighterRenderData fighter) {
    _fighter = fighter;
    healthBar.show(health: fighter.health, maxHealth: fighter.maxHealth);
    _place();
  }

  void hit() {
    _blinkMs = ArenaRenderConstants.hurtBlinkMs;
  }

  void _place() {
    final ground = ArenaFrames.groundSpot(_fighter);
    final lift = ArenaFrames.lift(_fighter);
    shadow.position.setValues(ground.x, ground.y);
    position.setValues(ground.x, ground.y - lift);
    healthBar.position.setValues(ground.x, ground.y - lift - ArenaRenderConstants.healthBarLift * scale.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animationSeconds += dt;
    _blinkMs = math.max(0, _blinkMs - dt * 1000);
  }

  @override
  void render(Canvas canvas) {
    if (isBlinkedOut) return;
    final frame = _assets.frame(frameName);
    final sprite = _assets.sprite(frameName);
    final isDown = _fighter.pose == FighterPose.down;
    _paint.color = Color.fromRGBO(255, 255, 255, isDown ? ArenaRenderConstants.fallenAlpha : 1);
    canvas.save();
    if (tipsOver) canvas.rotate((_fighter.side == FightSide.hero ? -1 : 1) * math.pi / 2);
    sprite.render(
      canvas,
      position: Vector2(-frame.width * frame.pivotX, -frame.height * frame.pivotY),
      overridePaint: _paint,
    );
    canvas.restore();
  }
}
