import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenSessionsShareWorldAndQuestLogThenTheyAreEqual', () {
    // given
    final world = WorldMock.make();
    final quests = QuestLog();
    final session = GameSessionEntityMock.make(world: world, quests: quests);

    // when
    final sameSession = session == GameSessionEntityMock.make(world: world, quests: quests);
    final otherQuests = session == GameSessionEntityMock.make(world: world, quests: QuestLog());

    // then
    expect(sameSession, isTrue);
    expect(otherQuests, isFalse);
  });
}
