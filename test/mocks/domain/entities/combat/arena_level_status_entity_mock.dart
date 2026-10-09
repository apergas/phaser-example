import 'package:rpg/layers/domain/entities/combat/arena_level_status_entity.dart';

import '../../world/funds_mock.dart';
import 'arena_level_entity_mock.dart';

abstract final class ArenaLevelStatusEntityMock {
  static const ArenaLevelStatusEntity rookieForNewHero = ArenaLevelStatusEntity(
    level: ArenaLevelEntityMock.banditRookie,
    isUnlocked: true,
    isCleared: false,
    nextReward: FundsMock.tenGold,
  );

  static const ArenaLevelStatusEntity rookieForVeteran = ArenaLevelStatusEntity(
    level: ArenaLevelEntityMock.banditRookie,
    isUnlocked: true,
    isCleared: true,
    nextReward: FundsMock.threeGold,
  );
}
