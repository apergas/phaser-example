import 'dart:math';

import '../../../core/config/constants/enum/mine_result.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/building_rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/rock_rules.dart';
import 'work.dart';
import 'world_state.dart';

final class Mining implements Work<MineIntentEntity> {
  const Mining();

  static MineResult check(WorldState state, String rockId) {
    if (!state.rocks.containsKey(rockId)) return MineResult.unknownRock;
    if (!state.player.inventory.hasTool(ToolKind.pickaxe)) return MineResult.noPickaxe;
    if (state.player.inventory.isLoadFull) return MineResult.carryFull;
    return MineResult.ok;
  }

  @override
  double intervalMs(WorldState state, MineIntentEntity intent) {
    final rock = state.rocks[intent.rockId];
    if (rock == null) return Rules.mineIntervalMs;
    final isBoosted = state.buildings.values.any((building) => building.boostsMining(rock.position));
    return isBoosted ? Rules.quarryMineIntervalMs : Rules.mineIntervalMs;
  }

  @override
  ObstacleEntity? target(WorldState state, MineIntentEntity intent) => state.rocks[intent.rockId]?.footprint;

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) {
    final position = target.position;
    return [
      PositionEntity(x: position.x + side * distance, y: position.y + 1),
      PositionEntity(x: position.x - side * distance, y: position.y + 1),
    ];
  }

  @override
  bool impact(WorldState state, MineIntentEntity intent, List<GameEventEntity> events) {
    final rock = state.rocks[intent.rockId]?.hit();
    if (rock == null) return true;
    events.add(RockHitEventEntity(rockId: rock.id));
    if (!rock.isBroken) {
      state.rocks[rock.id] = rock;
      return false;
    }
    state.rocks.remove(rock.id);
    final stone = min(rock.stoneYield, state.player.inventory.freeLoad);
    state.player = state.player.withInventory(state.player.inventory.add(Resource.stone, stone));
    events.add(RockBrokenEventEntity(rockId: rock.id, stone: stone));
    return true;
  }
}
