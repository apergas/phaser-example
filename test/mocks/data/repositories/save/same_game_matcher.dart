import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/entities/game/game_session_entity.dart';

void expectSameGame(GameSessionEntity actual, GameSessionEntity expected) {
  expect((actual.world.width, actual.world.height), (expected.world.width, expected.world.height));
  expect(actual.world.player, expected.world.player);
  expect(actual.world.trees, expected.world.trees);
  expect(actual.world.stumps, expected.world.stumps);
  expect(actual.world.rocks, expected.world.rocks);
  expect(actual.world.decorations, expected.world.decorations);
  expect(actual.world.buildings, expected.world.buildings);
  expect(actual.world.hero, expected.world.hero);
  expect(actual.world.stats, expected.world.stats);
  expect(actual.world.stock, expected.world.stock);
  expect(actual.world.idCounters, expected.world.idCounters);
  expect(actual.quests.completed, expected.quests.completed);
}
