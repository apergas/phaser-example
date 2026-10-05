import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/game/game_session_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';

import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenSessionsShareWorldAndQuestLogThenTheyAreEqual', () {
    // given
    final world = WorldMock.make();
    final quests = QuestLog();
    final session = GameSessionEntity(world: world, quests: quests);

    // when
    final sameSession = session == GameSessionEntity(world: world, quests: quests);
    final otherQuests = session == GameSessionEntity(world: world, quests: QuestLog());

    // then
    expect(sameSession, isTrue);
    expect(otherQuests, isFalse);
  });
}
