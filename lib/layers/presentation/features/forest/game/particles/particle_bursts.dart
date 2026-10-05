import 'dart:math' as math;

import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../../../../../../core/config/constants/render_constants.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import 'particle.dart';

abstract final class ParticleBursts {
  static const int chipsPerHit = 8;
  static const double impactHeight = 10;
  static const int dustPerHammer = 6;
  static const double dustLift = 4;

  static List<Particle> woodChips({
    required PositionEntity trunkBase,
    required bool playerOnLeft,
    required math.Random random,
  }) {
    final minAngle = playerOnLeft ? 200.0 : 250.0;
    final maxAngle = playerOnLeft ? 290.0 : 340.0;
    return List.generate(chipsPerHit, (_) {
      final speed = _between(random, 30, 80);
      final angle = _between(random, minAngle, maxAngle) * math.pi / 180;
      return Particle(
        kind: ParticleKind.woodChip,
        origin: PositionEntity(x: trunkBase.x, y: trunkBase.y - impactHeight),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 220,
        rotationDegrees: _between(random, 0, 360),
        lifespanSeconds: 0.5,
        alphaStart: 1,
        alphaEnd: 0,
        scaleStart: 1,
        scaleEnd: 1,
      );
    });
  }

  static List<Particle> dust({required PositionEntity buildingCenter, required math.Random random}) {
    final front = buildingCenter.y + RenderConstants.houseFrontOffset;
    return List.generate(dustPerHammer, (_) {
      final speed = _between(random, 10, 35);
      final angle = _between(random, 180, 360) * math.pi / 180;
      return Particle(
        kind: ParticleKind.dust,
        origin: PositionEntity(x: buildingCenter.x, y: front - dustLift),
        velocityX: speed * math.cos(angle),
        velocityY: speed * math.sin(angle),
        gravity: 0,
        rotationDegrees: 0,
        lifespanSeconds: 0.45,
        alphaStart: 0.7,
        alphaEnd: 0,
        scaleStart: 0.8,
        scaleEnd: 0.2,
      );
    });
  }

  static double chipsSortY(PositionEntity trunkBase) => trunkBase.y + 1;

  static double dustSortY(PositionEntity buildingCenter) => buildingCenter.y + RenderConstants.houseFrontOffset + 1;

  static double _between(math.Random random, double min, double max) => min + random.nextDouble() * (max - min);
}
