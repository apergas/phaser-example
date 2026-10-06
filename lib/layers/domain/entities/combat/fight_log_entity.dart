import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/fight_outcome.dart';
import '../../../../core/config/constants/enum/resource.dart';
import '../hero/combat_stats_entity.dart';
import 'enemy_entity.dart';
import 'fight_turn_entity.dart';

class FightLogEntity {
  final ArenaLevelId levelId;
  final CombatStatsEntity heroStats;
  final List<EnemyEntity> enemies;
  final List<FightTurnEntity> turns;
  final FightOutcome outcome;
  final Map<Resource, int> reward;

  const FightLogEntity({
    required this.levelId,
    required this.heroStats,
    required this.enemies,
    required this.turns,
    required this.outcome,
    required this.reward,
  });

  bool get isVictory => outcome == FightOutcome.victory;

  int get rounds => turns.isEmpty ? 0 : turns.last.round;

  FightLogEntity copyWith({
    ArenaLevelId? levelId,
    CombatStatsEntity? heroStats,
    List<EnemyEntity>? enemies,
    List<FightTurnEntity>? turns,
    FightOutcome? outcome,
    Map<Resource, int>? reward,
  }) {
    return FightLogEntity(
      levelId: levelId ?? this.levelId,
      heroStats: heroStats ?? this.heroStats,
      enemies: enemies ?? this.enemies,
      turns: turns ?? this.turns,
      outcome: outcome ?? this.outcome,
      reward: reward ?? this.reward,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FightLogEntity &&
      other.levelId == levelId &&
      other.heroStats == heroStats &&
      const ListEquality<EnemyEntity>().equals(other.enemies, enemies) &&
      const ListEquality<FightTurnEntity>().equals(other.turns, turns) &&
      other.outcome == outcome &&
      const MapEquality<Resource, int>().equals(other.reward, reward);

  @override
  int get hashCode => Object.hash(
    levelId,
    heroStats,
    const ListEquality<EnemyEntity>().hash(enemies),
    const ListEquality<FightTurnEntity>().hash(turns),
    outcome,
    const MapEquality<Resource, int>().hash(reward),
  );
}
