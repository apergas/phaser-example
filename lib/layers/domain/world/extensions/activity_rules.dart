import '../../../../core/config/constants/enum/player_activity.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';

extension ActivityRules on ActivityEntity {
  PlayerActivity get playerActivity => switch (this) {
    IdleActivityEntity() => PlayerActivity.idle,
    WalkingActivityEntity() => PlayerActivity.walking,
    WorkingActivityEntity(:final intent) => switch (intent) {
      ChopIntentEntity() => PlayerActivity.chopping,
      ConstructIntentEntity() => PlayerActivity.constructing,
    },
  };
}
