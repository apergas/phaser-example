import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/domain/entities/combat/enemy_entity.dart';

import '../hero/combat_stats_entity_mock.dart';

abstract final class EnemyEntityMock {
  static const EnemyEntity bandit = EnemyEntity(kind: EnemyKind.bandit, stats: CombatStatsEntityMock.bandit);

  static const EnemyEntity brute = EnemyEntity(kind: EnemyKind.barbarian, stats: CombatStatsEntityMock.brute);
}
