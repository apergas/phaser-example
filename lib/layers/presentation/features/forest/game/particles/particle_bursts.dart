import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
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
  static const int sparklesPerPurchase = 10;
  static const double sparkleLift = 24;
  static const double sparkleSpreadX = 10;
  static const double sparkleAngleMin = 200;
  static const double sparkleAngleMax = 340;
  static const double sparkleSpeedMin = 15;
  static const double sparkleSpeedMax = 40;
  static const double sparkleLifespanSeconds = 0.6;
  static const double sparkleAlphaStart = 1;
  static const double sparkleAlphaEnd = 0;
  static const double sparkleScaleStart = 1;
  static const double sparkleScaleEnd = 0.4;
  static const int bloodDropsMin = 4;
  static const int bloodDropsMax = 6;
  static const double bloodAngleAwayFromLeftMin = 280;
  static const double bloodAngleAwayFromLeftMax = 340;
  static const double bloodAngleAwayFromRightMin = 200;
  static const double bloodAngleAwayFromRightMax = 260;
  static const double bloodSpeedMin = 25;
  static const double bloodSpeedMax = 60;
  static const double bloodGravity = 260;
  static const double bloodLifespanSeconds = 0.4;
  static const double bloodAlphaStart = 1;
  static const double bloodAlphaEnd = 0;
  static const double bloodScale = 1;

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

  static List<Particle> dust({required PositionEntity front, required math.Random random}) {
    return List.generate(dustPerHammer, (_) {
      final speed = _between(random, dustSpeedMin, dustSpeedMax);
      final angle = _between(random, dustAngleMin, dustAngleMax) * math.pi / 180;
      return Particle(
        kind: ParticleKind.dust,
        origin: PositionEntity(x: front.x, y: front.y - dustLift),
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

  static List<Particle> sparkles({required PositionEntity feet, required math.Random random}) {
    return List.generate(sparklesPerPurchase, (_) {
      final speed = _between(random, sparkleSpeedMin, sparkleSpeedMax);
      final angle = _between(random, sparkleAngleMin, sparkleAngleMax) * math.pi / 180;
      return Particle(
        kind: ParticleKind.sparkle,
        origin: PositionEntity(x: feet.x + _between(random, -sparkleSpreadX, sparkleSpreadX), y: feet.y - sparkleLift),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 0,
        rotationDegrees: 0,
        lifespanSeconds: sparkleLifespanSeconds,
        alphaStart: sparkleAlphaStart,
        alphaEnd: sparkleAlphaEnd,
        scaleStart: sparkleScaleStart,
        scaleEnd: sparkleScaleEnd,
      );
    });
  }

  static List<Particle> bloodDrops({
    required PositionEntity impact,
    required bool attackerOnLeft,
    required math.Random random,
  }) {
    final minAngle = attackerOnLeft ? bloodAngleAwayFromLeftMin : bloodAngleAwayFromRightMin;
    final maxAngle = attackerOnLeft ? bloodAngleAwayFromLeftMax : bloodAngleAwayFromRightMax;
    final count = bloodDropsMin + random.nextInt(bloodDropsMax - bloodDropsMin + 1);
    return List.generate(count, (_) {
      final speed = _between(random, bloodSpeedMin, bloodSpeedMax);
      final angle = _between(random, minAngle, maxAngle) * math.pi / 180;
      return Particle(
        kind: ParticleKind.bloodDrop,
        origin: impact,
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: bloodGravity,
        rotationDegrees: 0,
        lifespanSeconds: bloodLifespanSeconds,
        alphaStart: bloodAlphaStart,
        alphaEnd: bloodAlphaEnd,
        scaleStart: bloodScale,
        scaleEnd: bloodScale,
      );
    });
  }

  static double sparklesSortY(PositionEntity feet) => feet.y + sortYOffset;

  static double chipsSortY(PositionEntity trunkBase) => trunkBase.y + sortYOffset;

  static double dustSortY(PositionEntity front) => front.y + sortYOffset;

  static double _between(math.Random random, double min, double max) => min + random.nextDouble() * (max - min);
}
