import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/game/player_status_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../world/extensions/activity_rules.dart';
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
      activity: player.activity.playerActivity,
      target: world.playerTarget,
      swingProgress: world.workProgress,
      wood: player.inventory.wood,
      hasAxe: player.inventory.hasTool(ToolKind.axe),
    );
  }
}
