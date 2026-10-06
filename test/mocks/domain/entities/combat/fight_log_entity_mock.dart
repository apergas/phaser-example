import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/fight_outcome.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/combat/fight_log_entity.dart';

import '../hero/combat_stats_entity_mock.dart';
import 'enemy_entity_mock.dart';
import 'fight_turn_entity_mock.dart';

abstract final class FightLogEntityMock {
  static FightLogEntity victoryOverBandit() => FightLogEntity(
    levelId: ArenaLevelId.banditRookie,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.bandit],
    turns: FightTurnEntityMock.victoryOverBandit(),
    outcome: FightOutcome.victory,
    reward: const {Resource.gold: 10},
  );

  static FightLogEntity defeatByBrute() => FightLogEntity(
    levelId: ArenaLevelId.barbarian,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.brute],
    turns: FightTurnEntityMock.defeatByBrute(),
    outcome: FightOutcome.defeat,
    reward: const {},
  );

  static FightLogEntity allActions() => FightLogEntity(
    levelId: ArenaLevelId.banditRookie,
    heroStats: CombatStatsEntityMock.heroBase,
    enemies: const [EnemyEntityMock.bandit],
    turns: FightTurnEntityMock.allActions(),
    outcome: FightOutcome.victory,
    reward: const {Resource.gold: 10},
  );
}
