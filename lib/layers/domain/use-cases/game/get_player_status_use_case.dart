import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/player_activity.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/game/player_status_entity.dart';
import '../../entities/player/activity_entity.dart';
import '../../entities/player/intent_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../world/extensions/inventory_rules.dart';

@Injectable()
final class GetPlayerStatusUseCase {
  final GameSessionRepository _sessionRepository;

  const GetPlayerStatusUseCase({required this._sessionRepository});

  PlayerStatusEntity call() {
    final world = _sessionRepository.current().world;
    final player = world.player;
    return PlayerStatusEntity(
      position: player.position,
      activity: _activityOf(player.activity),
      target: world.playerTarget,
      swingProgress: world.workProgress,
      wood: player.inventory.wood,
      hasAxe: player.inventory.hasTool(ToolKind.axe),
    );
  }

  PlayerActivity _activityOf(ActivityEntity activity) => switch (activity) {
    IdleActivityEntity() => PlayerActivity.idle,
    WalkingActivityEntity() => PlayerActivity.walking,
    WorkingActivityEntity(:final intent) => switch (intent) {
      ChopIntentEntity() => PlayerActivity.chopping,
      ConstructIntentEntity() => PlayerActivity.constructing,
    },
  };
}
