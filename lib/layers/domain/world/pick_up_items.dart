import '../entities/game/game_event_entity.dart';
import '../rules/rules.dart';
import 'extensions/inventory_rules.dart';
import 'extensions/player_rules.dart';
import 'extensions/position_geometry.dart';
import 'world_state.dart';

void pickUpItems(WorldState state, List<GameEventEntity> events) {
  for (final item in state.items.values.toList()) {
    if (item.position.distanceTo(state.player.position) > Rules.pickUpRange) continue;
    state.items.remove(item.id);
    state.player = state.player.withInventory(state.player.inventory.addTool(item.kind));
    events.add(ItemPickedUpEventEntity(itemId: item.id, kind: item.kind));
  }
}
