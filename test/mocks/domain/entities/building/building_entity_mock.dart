import 'package:rpg/layers/domain/entities/building/building_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

abstract final class BuildingEntityMock {
  static const BuildingEntity mock = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: PositionEntity(x: 0, y: 0),
  );
}
