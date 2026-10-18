import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/presentation/features/forest/models/placement_data.dart';

import 'forest_scenario_mock.dart';

abstract final class PlacementDataMock {
  static const PlacementData mock = PlacementData(
    blueprint: BlueprintId.house,
    position: PositionEntity(x: 1, y: 2),
    invalidReason: null,
  );

  static const PositionEntity movedPosition = PositionEntity(x: 3, y: 4);

  static const PlacementData moved = PlacementData(
    blueprint: BlueprintId.house,
    position: PositionEntity(x: 3, y: 4),
    invalidReason: null,
  );

  static const PlacementData blockedNextToFarTree = PlacementData(
    blueprint: BlueprintId.house,
    position: ForestScenarioMock.siteNextToFarTree,
    invalidReason: ConstructionRejection.blocked,
  );

  static const PlacementData quarryFarFromRocks = PlacementData(
    blueprint: BlueprintId.quarry,
    position: PositionEntity(x: 1, y: 2),
    invalidReason: ConstructionRejection.needsNearbyRock,
  );
}
