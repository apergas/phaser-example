import '../../../core/config/constants/enum/construction_rejection.dart';
import '../entities/building/blueprint_entity.dart';
import '../entities/building/building_entity.dart';
import '../entities/game/construction_result_entity.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/building_rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/position_geometry.dart';
import 'work.dart';
import 'world_state.dart';

final class Construction implements Work<ConstructIntentEntity> {
  const Construction();

  static bool canPlace(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
    final radius = blueprint.footprintRadius;
    final player = state.player;
    final overlapsPlayer = position.distanceTo(player.position) < radius + player.radius;
    final overlapsItem = state.items.values.any((item) => position.distanceTo(item.position) < radius);
    return state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem;
  }

  static ConstructionResultEntity place(WorldState state, BlueprintEntity blueprint, PositionEntity position) {
    final paid = state.player.inventory.spendWood(blueprint.woodCost);
    if (paid == null) return const ConstructionRejectedEntity(reason: ConstructionRejection.notEnoughWood);
    if (!canPlace(state, blueprint, position)) {
      return const ConstructionRejectedEntity(reason: ConstructionRejection.blocked);
    }
    state.player = state.player.withInventory(paid);
    final building = BuildingEntity(id: state.nextId('building'), blueprint: blueprint, position: position);
    state.buildings[building.id] = building;
    return ConstructionStartedEntity(building: building);
  }

  @override
  double get intervalMs => Rules.hammerIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, ConstructIntentEntity intent) {
    final building = state.buildings[intent.buildingId];
    if (building == null || building.isComplete) return null;
    return building.footprint;
  }

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) => [
    PositionEntity(x: target.position.x, y: target.position.y + distance),
  ];

  @override
  bool impact(WorldState state, ConstructIntentEntity intent, List<GameEventEntity> events) {
    final building = state.buildings[intent.buildingId]?.hammer();
    if (building == null) return true;
    state.buildings[building.id] = building;
    events.add(BuildingHammeredEventEntity(buildingId: building.id, progress: building.progress));
    if (!building.isComplete) return false;
    events.add(BuildingCompletedEventEntity(buildingId: building.id, blueprint: building.blueprint.id));
    return true;
  }
}
