import '../../../../core/config/constants/enum/construction_rejection.dart';
import '../../entities/building/placement_rule_entity.dart';
import '../../entities/geometry/position_entity.dart';
import '../world_state.dart';
import 'position_geometry.dart';

extension PlacementRuleRules on PlacementRuleEntity {
  ConstructionRejection? rejection(WorldState state, PositionEntity position) => switch (this) {
    AnywherePlacementRuleEntity() => null,
    NearRockPlacementRuleEntity(:final range) =>
      state.rocks.values.any((rock) => position.distanceTo(rock.position) < range)
          ? null
          : ConstructionRejection.needsNearbyRock,
  };
}
