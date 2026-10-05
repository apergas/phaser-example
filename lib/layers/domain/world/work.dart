import '../entities/game/game_event_entity.dart';
import '../entities/geometry/obstacle_entity.dart';
import '../entities/geometry/position_entity.dart';
import '../entities/player/intent_entity.dart';
import 'construction.dart';
import 'woodcutting.dart';
import 'world_state.dart';

abstract interface class Work<I extends IntentEntity> {
  double get intervalMs;

  ObstacleEntity? target(WorldState state, I intent);

  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side);

  bool impact(WorldState state, I intent, List<GameEventEntity> events);
}

final class BoundWork<I extends IntentEntity> {
  const BoundWork(this._work, this._intent);

  final Work<I> _work;
  final I _intent;

  double get intervalMs => _work.intervalMs;

  ObstacleEntity? target(WorldState state) => _work.target(state, _intent);

  List<PositionEntity> preferredSpots(ObstacleEntity target, double distance, int side) =>
      _work.preferredSpots(target, distance, side);

  bool impact(WorldState state, List<GameEventEntity> events) => _work.impact(state, _intent, events);
}

BoundWork<IntentEntity> workFor(IntentEntity intent) => switch (intent) {
  ChopIntentEntity() => BoundWork<ChopIntentEntity>(const Woodcutting(), intent),
  ConstructIntentEntity() => BoundWork<ConstructIntentEntity>(const Construction(), intent),
};
