import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';
import 'package:rpg/layers/domain/entities/player/intent_entity.dart';

import 'intent_entity_mock.dart';

abstract final class ActivityEntityMock {
  static const IdleActivityEntity idle = IdleActivityEntity();

  static const WalkingActivityEntity walking = WalkingActivityEntity(destination: PositionEntity(x: 50, y: 60));

  static const WalkingActivityEntity walkingToChop = WalkingActivityEntity(
    destination: PositionEntity(x: 50, y: 60),
    intent: IntentEntityMock.chop,
  );

  static const WorkingActivityEntity working = WorkingActivityEntity(intent: IntentEntityMock.chop, elapsedMs: 100);

  static IdleActivityEntity makeIdle() {
    // ignore: prefer_const_constructors
    return IdleActivityEntity();
  }

  static WalkingActivityEntity makeWalking({double x = 50, double y = 60, IntentEntity? intent}) =>
      WalkingActivityEntity(
        destination: PositionEntity(x: x, y: y),
        intent: intent,
      );

  static WorkingActivityEntity makeWorking({
    IntentEntity intent = IntentEntityMock.chop,
    double elapsedMs = 100,
  }) => WorkingActivityEntity(intent: intent, elapsedMs: elapsedMs);
}
