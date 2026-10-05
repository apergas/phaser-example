import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';

class Particle {
  final ParticleKind kind;
  final PositionEntity origin;
  final double velocityX;
  final double velocityY;
  final double gravity;
  final double rotationDegrees;
  final double lifespanSeconds;
  final double alphaStart;
  final double alphaEnd;
  final double scaleStart;
  final double scaleEnd;

  const Particle({
    required this.kind,
    required this.origin,
    required this.velocityX,
    required this.velocityY,
    required this.gravity,
    required this.rotationDegrees,
    required this.lifespanSeconds,
    required this.alphaStart,
    required this.alphaEnd,
    required this.scaleStart,
    required this.scaleEnd,
  });

  bool isAlive(double ageSeconds) => ageSeconds < lifespanSeconds;

  PositionEntity position(double ageSeconds) {
    return PositionEntity(
      x: origin.x + velocityX * ageSeconds,
      y: origin.y + velocityY * ageSeconds + 0.5 * gravity * ageSeconds * ageSeconds,
    );
  }

  double alpha(double ageSeconds) => alphaStart + (alphaEnd - alphaStart) * _progress(ageSeconds);

  double scale(double ageSeconds) => scaleStart + (scaleEnd - scaleStart) * _progress(ageSeconds);

  double _progress(double ageSeconds) => (ageSeconds / lifespanSeconds).clamp(0, 1).toDouble();
}
