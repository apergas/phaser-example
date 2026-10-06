import 'package:injectable/injectable.dart';

import '../../entities/combat/arena_entity.dart';
import '../../entities/combat/arena_level_status_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/arena_levels.dart';
import '../../world/extensions/arena_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class GetArenaUseCase {
  final GameSessionRepository _sessionRepository;

  const GetArenaUseCase({required this._sessionRepository});

  ArenaEntity call() {
    final hero = _sessionRepository.current().world.hero;
    return ArenaEntity(
      heroPower: hero.power,
      levels: [
        for (final level in ArenaLevels.all)
          ArenaLevelStatusEntity(
            level: level,
            isUnlocked: hero.isUnlocked(level),
            isCleared: hero.hasCleared(level.id),
            nextReward: hero.rewardFor(level),
          ),
      ],
    );
  }
}
