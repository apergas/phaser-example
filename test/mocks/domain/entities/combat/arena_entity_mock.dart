import 'package:rpg/layers/domain/entities/combat/arena_entity.dart';

import 'arena_level_status_entity_mock.dart';

abstract final class ArenaEntityMock {
  static const ArenaEntity onlyRookie = ArenaEntity(
    heroPower: 31,
    levels: [ArenaLevelStatusEntityMock.rookieForNewHero],
  );
}
