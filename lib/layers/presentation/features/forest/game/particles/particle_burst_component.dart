import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/enum/forest/particle_kind.dart';
import '../../../../../domain/entities/geometry/position_entity.dart';
import '../render/render_depth.dart';
import 'particle.dart';

class ParticleBurstComponent extends Component {
  static const Color chipDark = Color(0xFF8A5A2B);
  static const Color chipLight = Color(0xFFC89A5E);
  static const Color dustColor = Color(0xFFD8CDB0);
  static const double dustRadius = 3;
  static const Color sparkleColor = Color(0xFFF4D77A);
  static const double sparkleSize = 3;
  static const Rect chipBody = Rect.fromLTWH(-1.5, -1, 3, 2);
  static const Rect chipHighlight = Rect.fromLTWH(-1.5, -1, 2, 1);
  static const Color magicSparkleColor = Color(0xFF8FC8FF);
  static const Color bloodColor = Color(0xFF9E1B1B);
  static const Rect bloodDrop = Rect.fromLTWH(-1, -1, 2, 2);

  final List<Particle> _particles;
  final Paint _paint = Paint();
  double _ageSeconds = 0;

  ParticleBurstComponent({required this._particles, required double sortY})
    : super(priority: RenderDepth.bySortY(sortY) + 1);

  int get aliveCount => _particles.where((particle) => particle.isAlive(_ageSeconds)).length;

  @override
  void update(double dt) {
    super.update(dt);
    _ageSeconds += dt;
    if (aliveCount == 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      if (!particle.isAlive(_ageSeconds)) continue;
      final at = particle.position(_ageSeconds);
      final alpha = particle.alpha(_ageSeconds);
      switch (particle.kind) {
        case ParticleKind.woodChip:
          _renderChip(canvas, at, particle.rotationDegrees, alpha);
        case ParticleKind.dust:
          _paint.color = dustColor.withValues(alpha: alpha);
          canvas.drawCircle(Offset(at.x, at.y), dustRadius * particle.scale(_ageSeconds), _paint);
        case ParticleKind.sparkle:
          _renderSparkle(canvas, at, sparkleSize * particle.scale(_ageSeconds), sparkleColor.withValues(alpha: alpha));
        case ParticleKind.bloodDrop:
          _paint.color = bloodColor.withValues(alpha: alpha);
          canvas.drawRect(bloodDrop.shift(Offset(at.x, at.y)), _paint);
        case ParticleKind.magicSparkle:
          _renderSparkle(
            canvas,
            at,
            sparkleSize * particle.scale(_ageSeconds),
            magicSparkleColor.withValues(alpha: alpha),
          );
      }
    }
  }

  void _renderSparkle(Canvas canvas, PositionEntity at, double size, Color color) {
    _paint.color = color;
    canvas.drawRect(Rect.fromCenter(center: Offset(at.x, at.y), width: size, height: size), _paint);
  }

  void _renderChip(Canvas canvas, PositionEntity at, double rotationDegrees, double alpha) {
    canvas.save();
    canvas.translate(at.x, at.y);
    canvas.rotate(rotationDegrees * math.pi / 180);
    _paint.color = chipDark.withValues(alpha: alpha);
    canvas.drawRect(chipBody, _paint);
    _paint.color = chipLight.withValues(alpha: alpha);
    canvas.drawRect(chipHighlight, _paint);
    canvas.restore();
  }
}
