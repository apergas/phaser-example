import '../../../core/config/constants/enum/arena_level_id.dart';
import '../../../core/config/constants/enum/enemy_kind.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../entities/combat/arena_level_entity.dart';
import '../entities/combat/enemy_entity.dart';
import '../entities/hero/combat_stats_entity.dart';

abstract final class ArenaLevels {
  static const List<ArenaLevelEntity> all = [
    ArenaLevelEntity(
      id: ArenaLevelId.banditRookie,
      enemies: [
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 3, defense: 0, health: 20)),
      ],
      reward: {Resource.gold: 10},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.banditVeteran,
      enemies: [
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
      ],
      reward: {Resource.gold: 20},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.banditTrio,
      enemies: [
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
        EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntity(attack: 4, defense: 1, health: 20)),
      ],
      reward: {Resource.gold: 40},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.barbarian,
      enemies: [
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 12, defense: 4, health: 60)),
      ],
      reward: {Resource.gold: 50},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.barbarianPair,
      enemies: [
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 9, defense: 4, health: 50)),
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 9, defense: 4, health: 50)),
      ],
      reward: {Resource.gold: 65},
    ),
    ArenaLevelEntity(
      id: ArenaLevelId.barbarianChief,
      enemies: [
        EnemyEntity(kind: EnemyKind.barbarianChief, stats: CombatStatsEntity(attack: 12, defense: 5, health: 70)),
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
        EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntity(attack: 6, defense: 2, health: 30)),
      ],
      reward: {Resource.gold: 100},
    ),
  ];

  static ArenaLevelEntity byId(ArenaLevelId id) => all.firstWhere((level) => level.id == id);
}
