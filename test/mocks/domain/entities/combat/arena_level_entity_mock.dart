import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/layers/domain/entities/combat/arena_level_entity.dart';

import 'enemy_entity_mock.dart';

abstract final class ArenaLevelEntityMock {
  static const ArenaLevelEntity banditRookie = ArenaLevelEntity(
    id: ArenaLevelId.banditRookie,
    enemies: [EnemyEntityMock.bandit],
    reward: {Resource.gold: 10},
  );

  static const ArenaLevelEntity banditTrio = ArenaLevelEntity(
    id: ArenaLevelId.banditTrio,
    enemies: [EnemyEntityMock.bandit, EnemyEntityMock.bandit, EnemyEntityMock.bandit],
    reward: {Resource.gold: 40},
  );
}
