import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/game/quest_progress_entity_mock.dart';

void main() {
  test('testWhenComparingQuestProgressThenEveryFieldMatters', () {
    // given
    const progress = QuestProgressEntityMock.mock;

    // when
    final isEqual = progress == QuestProgressEntityMock.make();
    final notCurrent = progress == QuestProgressEntityMock.make(isCurrent: false);

    // then
    expect(isEqual, isTrue);
    expect(notCurrent, isFalse);
  });
}
