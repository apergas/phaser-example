import '../../../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';

abstract final class ArenaRenderConstants {
  static const double leadInMs = 400;
  static const double turnMs = 600;
  static const double impactShare = 0.5;

  static const double stageWidth = 480;
  static const double stageHeight = 270;
  static const double fenceY = 72;
  static const double minZoom = 1;
  static const double maxZoom = 3;
  static const int backgroundColor = 0xFF0E150E;

  static const PositionEntity heroSpot = PositionEntity(x: 190, y: 170);
  static const List<PositionEntity> enemySpots = [
    PositionEntity(x: 300, y: 170),
    PositionEntity(x: 340, y: 140),
    PositionEntity(x: 340, y: 200),
  ];
  static const double chiefScale = 1.25;

  static double fighterScale(EnemyKind? kind) => switch (kind) {
    null || EnemyKind.bandit || EnemyKind.barbarian => 1,
    EnemyKind.barbarianChief => chiefScale,
    EnemyKind.wolf || EnemyKind.bear => 1,
  };

  static const double impactHeight = 28;
  static const double floatingTextHeight = 36;
  static const double hurtBlinkMs = 300;
  static const double blinkPeriodMs = 80;
  static const double fallenAlpha = 0.8;

  static const double healthBarWidth = 28;
  static const double healthBarHeight = 4;
  static const double healthBarLift = 52;
  static const double healthBarEaseMs = 300;
  static const double healthBarWarning = 0.5;
  static const double healthBarDanger = 0.25;
}
