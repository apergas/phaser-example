import 'package:farming/core/config/constants/enum/decoration_kind.dart';
import 'package:farming/layers/domain/entities/decoration/decoration_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';

abstract final class DecorationEntityMock {
  static const DecorationEntity mock = DecorationEntity(
    id: 'decoration-1',
    kind: DecorationKind.rock,
    position: PositionEntity(x: 1, y: 2),
  );
}
