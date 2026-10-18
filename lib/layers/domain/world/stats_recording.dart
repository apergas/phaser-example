import '../entities/game/game_event_entity.dart';
import '../entities/game/stats_entity.dart';
import 'extensions/stats_rules.dart';
import 'world_state.dart';

abstract final class StatsRecording {
  static void record(WorldState state, List<GameEventEntity> events) {
    for (final event in events) {
      state.stats = _recorded(event, state);
    }
  }

  static StatsEntity _recorded(GameEventEntity event, WorldState state) {
    final stats = state.stats;
    return switch (event) {
      ItemPickedUpEventEntity() || PlayerBlockedEventEntity() || TreeHitEventEntity() => stats,
      TreeFelledEventEntity(:final treeId) => stats.fellingTree(state.stumps[treeId]?.kind),
      BuildingHammeredEventEntity() => stats,
      BuildingCompletedEventEntity() => stats.completingBuilding(),
      QuestCompletedEventEntity() || TreeSproutedEventEntity() => stats,
      TreeRegrownEventEntity() => stats.regrowingTree(),
      RockHitEventEntity() || RockBrokenEventEntity() => stats,
    };
  }
}
