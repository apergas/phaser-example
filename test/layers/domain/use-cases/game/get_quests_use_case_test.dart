import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/use-cases/game/get_quests_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetQuestsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetQuestsUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenGameStartsThenFirstQuestIsCurrentAndNoneIsCompleted', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final quests = sut();

    // then
    expect(quests.map((quest) => quest.id), QuestId.values);
    expect(quests.any((quest) => quest.isCompleted), isFalse);
    expect(quests.where((quest) => quest.isCurrent).map((quest) => quest.id), [QuestId.pickUpAxe, QuestId.buildForge]);
  });
}
