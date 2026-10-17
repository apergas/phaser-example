import '../entities/game/game_event_entity.dart';
import '../entities/tree/stump_entity.dart';
import '../entities/tree/tree_entity.dart';
import '../rules/rules.dart';
import 'extensions/obstacle_rules.dart';
import 'extensions/stump_rules.dart';
import 'world_state.dart';

abstract final class Regrowth {
  static void advance(WorldState state, double deltaMs, List<GameEventEntity> events) {
    for (final stump in state.stumps.values.toList()) {
      final grown = stump.grown(deltaMs);
      if (!stump.isSapling && grown.isSapling) events.add(TreeSproutedEventEntity(stumpId: stump.id));
      final tree = grown.isReadyToRegrow ? _regrownTree(state, grown) : null;
      if (tree == null) {
        state.stumps[stump.id] = grown;
        continue;
      }
      state.stumps.remove(stump.id);
      state.trees[tree.id] = tree;
      events.add(TreeRegrownEventEntity(tree: tree));
    }
  }

  static TreeEntity? _regrownTree(WorldState state, StumpEntity stump) {
    final stats = Rules.treeKindStats[stump.kind];
    if (stats == null) return null;
    final tree = TreeEntity(
      id: stump.id,
      kind: stump.kind,
      position: stump.position,
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: stats.woodYield,
      hitsToFell: stats.hitsToFell,
    );
    final player = state.player;
    if (tree.footprint.blocks(player.position, player.radius) || state.isBlocked(tree.position, tree.trunkRadius)) {
      return null;
    }
    return tree;
  }
}
