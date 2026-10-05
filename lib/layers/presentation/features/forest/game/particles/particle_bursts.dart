import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../render/render_constants.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import 'particle.dart';

abstract final class ParticleBursts {
  static const int chipsPerHit = 8;
  static const double impactHeight = 10;
  static const int dustPerHammer = 6;
  static const double dustLift = 4;
  static const double chipAngleLeftMin = 200;
  static const double chipAngleLeftMax = 290;
  static const double chipAngleRightMin = 250;
  static const double chipAngleRightMax = 340;
  static const double chipSpeedMin = 30;
  static const double chipSpeedMax = 80;
  static const double chipGravity = 220;
  static const double chipRotationMax = 360;
  static const double chipLifespanSeconds = 0.5;
  static const double chipAlphaStart = 1;
  static const double chipAlphaEnd = 0;
  static const double chipScale = 1;
  static const double dustAngleMin = 180;
  static const double dustAngleMax = 360;
  static const double dustSpeedMin = 10;
  static const double dustSpeedMax = 35;
  static const double dustLifespanSeconds = 0.45;
  static const double dustAlphaStart = 0.7;
  static const double dustAlphaEnd = 0;
  static const double dustScaleStart = 0.8;
  static const double dustScaleEnd = 0.2;
  static const double sortYOffset = 1;

  static List<Particle> woodChips({
    required PositionEntity trunkBase,
    required bool playerOnLeft,
    required math.Random random,
  }) {
    final minAngle = playerOnLeft ? chipAngleLeftMin : chipAngleRightMin;
    final maxAngle = playerOnLeft ? chipAngleLeftMax : chipAngleRightMax;
    return List.generate(chipsPerHit, (_) {
      final speed = _between(random, chipSpeedMin, chipSpeedMax);
      final angle = _between(random, minAngle, maxAngle) * math.pi / 180;
      return Particle(
        kind: ParticleKind.woodChip,
        origin: PositionEntity(x: trunkBase.x, y: trunkBase.y - impactHeight),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: chipGravity,
        rotationDegrees: _between(random, 0, chipRotationMax),
        lifespanSeconds: chipLifespanSeconds,
        alphaStart: chipAlphaStart,
        alphaEnd: chipAlphaEnd,
        scaleStart: chipScale,
        scaleEnd: chipScale,
      );
    });
  }

  static List<Particle> dust({required PositionEntity buildingCenter, required math.Random random}) {
    final front = buildingCenter.y + RenderConstants.houseFrontOffset;
    return List.generate(dustPerHammer, (_) {
      final speed = _between(random, dustSpeedMin, dustSpeedMax);
      final angle = _between(random, dustAngleMin, dustAngleMax) * math.pi / 180;
      return Particle(
        kind: ParticleKind.dust,
        origin: PositionEntity(x: buildingCenter.x, y: front - dustLift),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 0,
        rotationDegrees: 0,
        lifespanSeconds: dustLifespanSeconds,
        alphaStart: dustAlphaStart,
        alphaEnd: dustAlphaEnd,
        scaleStart: dustScaleStart,
        scaleEnd: dustScaleEnd,
      );
    });
  }

  static double chipsSortY(PositionEntity trunkBase) => trunkBase.y + sortYOffset;

  static double dustSortY(PositionEntity buildingCenter) =>
      buildingCenter.y + RenderConstants.houseFrontOffset + sortYOffset;

  static double _between(math.Random random, double min, double max) => min + random.nextDouble() * (max - min);
}
