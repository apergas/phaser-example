import '../../../core/config/constants/enum/chop_result.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import '../rules/rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/tree_rules.dart';
import 'work.dart';
import 'world_state.dart';

final class Woodcutting implements Work<ChopIntentEntity> {
  const Woodcutting();

  static ChopResult check(WorldState state, String treeId) {
    if (!state.trees.containsKey(treeId)) return ChopResult.unknownTree;
    if (!state.player.inventory.hasTool(ToolKind.axe)) return ChopResult.noAxe;
    return ChopResult.ok;
  }

  @override
  double get intervalMs => Rules.chopIntervalMs;

  @override
  ObstacleEntity? target(WorldState state, ChopIntentEntity intent) => state.trees[intent.treeId]?.footprint;

  @override
  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) {
    final position = target.position;
    return [
      PositionEntity(x: position.x + side * distance, y: position.y + 1),
      PositionEntity(x: position.x - side * distance, y: position.y + 1),
    ];
  }

  @override
  bool impact(WorldState state, ChopIntentEntity intent, List<GameEventEntity> events) {
    final tree = state.trees[intent.treeId]?.hit();
    if (tree == null) return true;
    events.add(TreeHitEventEntity(treeId: tree.id, hitsRemaining: tree.hitsRemaining));
    if (!tree.isFelled) {
      state.trees[tree.id] = tree;
      return false;
    }
    state.trees.remove(tree.id);
    state.player = state.player.withInventory(state.player.inventory.addWood(tree.woodYield));
    events.add(TreeFelledEventEntity(treeId: tree.id, wood: tree.woodYield));
    return true;
  }
}
