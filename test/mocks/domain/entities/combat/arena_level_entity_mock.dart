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

  static const ArenaLevelEntity banditVeteran = ArenaLevelEntity(
    id: ArenaLevelId.banditVeteran,
    enemies: [EnemyEntityMock.veteranBandit],
    reward: {Resource.gold: 20},
  );

  static const ArenaLevelEntity barbarianChief = ArenaLevelEntity(
    id: ArenaLevelId.barbarianChief,
    enemies: [EnemyEntityMock.barbarianChief, EnemyEntityMock.barbarianGuard, EnemyEntityMock.barbarianGuard],
    reward: {Resource.gold: 100},
  );

  static const ArenaLevelEntity duel = ArenaLevelEntity(
    id: ArenaLevelId.banditVeteran,
    enemies: [EnemyEntityMock.duelist],
    reward: {Resource.gold: 20},
  );

  static const ArenaLevelEntity wall = ArenaLevelEntity(
    id: ArenaLevelId.barbarian,
    enemies: [EnemyEntityMock.wall],
    reward: {Resource.gold: 50},
  );

  static const ArenaLevelEntity brute = ArenaLevelEntity(
    id: ArenaLevelId.barbarian,
    enemies: [EnemyEntityMock.brute],
    reward: {Resource.gold: 50},
  );

  static const ArenaLevelEntity banditRookieWithWood = ArenaLevelEntity(
    id: ArenaLevelId.banditRookie,
    enemies: [EnemyEntityMock.bandit],
    reward: {Resource.wood: 2, Resource.gold: 10},
  );
}
