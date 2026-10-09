import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../combat/combat.dart';
import '../../entities/combat/fight_result_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/arena_levels.dart';
import '../../world/extensions/arena_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class StartFightUseCase {
  final GameSessionRepository _sessionRepository;

  const StartFightUseCase({required this._sessionRepository});

  FightResultEntity call({required ArenaLevelId levelId}) {
    final world = _sessionRepository.current().world;
    final hero = world.hero;
    final level = ArenaLevels.byId(levelId);
    if (!hero.isUnlocked(level)) return const FightLockedEntity();
    final fight = Combat.resolve(level: level, heroStats: hero.stats, skills: hero.skills, seed: hero.fightsFought);
    final log = fight.isVictory ? fight.copyWith(reward: hero.rewardFor(level)) : fight;
    if (log.isVictory) world.earn(log.reward);
    world.updateHero((current) => current.afterFight(log));
    return FightPlayedEntity(
      log: log,
      advice: Combat.adviceFor(log),
      isFirstChampionship: log.isVictory && level.id == ArenaLevels.championship && !hero.isChampion,
    );
  }
}
