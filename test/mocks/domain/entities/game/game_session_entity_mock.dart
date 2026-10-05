import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../../world/world_mock.dart';

abstract final class GameSessionEntityMock {
  static GameSessionEntity make({World? world, QuestLog? quests}) {
    return GameSessionEntity(world: world ?? WorldMock.make(), quests: quests ?? QuestLog());
  }

  static GameSessionEntity playing(World world) => GameSessionEntity(world: world, quests: QuestLog());
}
