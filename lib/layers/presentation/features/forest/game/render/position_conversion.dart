import 'package:flame/extensions.dart';

import '../../../../../domain/entities/geometry/position_entity.dart';

extension PositionEntityVector on PositionEntity {
  Vector2 toVector2() => Vector2(x, y);
}

extension Vector2PositionEntity on Vector2 {
  PositionEntity toPositionEntity() => PositionEntity(x: x, y: y);
}
