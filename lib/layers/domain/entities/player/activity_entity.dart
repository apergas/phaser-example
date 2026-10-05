import '../geometry/position_entity.dart';
import 'intent_entity.dart';

sealed class ActivityEntity {
  const ActivityEntity();
}

final class IdleActivityEntity extends ActivityEntity {
  const IdleActivityEntity();

  @override
  bool operator ==(Object other) => other is IdleActivityEntity;

  @override
  int get hashCode => (IdleActivityEntity).hashCode;
}

final class WalkingActivityEntity extends ActivityEntity {
  final PositionEntity destination;
  final IntentEntity? intent;

  const WalkingActivityEntity({required this.destination, this.intent});

  @override
  bool operator ==(Object other) =>
      other is WalkingActivityEntity && other.destination == destination && other.intent == intent;

  @override
  int get hashCode => Object.hash(WalkingActivityEntity, destination, intent);
}

final class WorkingActivityEntity extends ActivityEntity {
  final IntentEntity intent;
  final double elapsedMs;

  const WorkingActivityEntity({required this.intent, required this.elapsedMs});

  WorkingActivityEntity copyWith({IntentEntity? intent, double? elapsedMs}) {
    return WorkingActivityEntity(intent: intent ?? this.intent, elapsedMs: elapsedMs ?? this.elapsedMs);
  }

  @override
  bool operator ==(Object other) =>
      other is WorkingActivityEntity && other.intent == intent && other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(WorkingActivityEntity, intent, elapsedMs);
}
