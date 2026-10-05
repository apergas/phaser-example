import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';

abstract final class PlacementDataMock {
  static const PlacementData mock = PlacementData(
    blueprint: BlueprintId.house,
    position: PositionEntity(x: 1, y: 2),
    isValid: true,
  );

  static const PositionEntity movedPosition = PositionEntity(x: 3, y: 4);

  static const PlacementData moved = PlacementData(
    blueprint: BlueprintId.house,
    position: PositionEntity(x: 3, y: 4),
    isValid: true,
  );
}
