import '../../../core/config/constants/enum/deposit_result.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/building_rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'work.dart';
import 'world_state.dart';

final class Depositing implements Work<DepositIntentEntity> {
  const Depositing();

  static DepositResult check(WorldState state, String buildingId) {
    final building = state.buildings[buildingId];
    if (building == null) return DepositResult.unknownBuilding;
    if (!building.acceptsDeposits) return DepositResult.notADropOff;
    if (state.player.inventory.load == 0) return DepositResult.emptyLoad;
    return DepositResult.ok;
  }

  @override
  double get intervalMs => Rules.depositIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, DepositIntentEntity intent) {
    final building = state.buildings[intent.buildingId];
    if (building == null || !building.acceptsDeposits) return null;
    return building.footprint;
  }

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) => [
    PositionEntity(x: target.position.x, y: target.position.y + distance),
  ];

  @override
  bool impact(WorldState state, DepositIntentEntity intent, List<GameEventEntity> events) {
    final load = state.player.inventory.cargo;
    if (load.isEmpty) return true;
    state.player = state.player.withInventory(state.player.inventory.unloading());
    state.stock = state.stock.adding(load);
    events.add(DepositedEventEntity(buildingId: intent.buildingId, load: load));
    return true;
  }
}
