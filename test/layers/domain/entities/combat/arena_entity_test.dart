import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/combat/arena_entity_mock.dart';
import '../../../../mocks/domain/entities/combat/arena_level_status_entity_mock.dart';

void main() {
  test('testWhenCopyingWithTheSameLevelsThenTheArenaIsEqual', () {
    // given
    const arena = ArenaEntityMock.onlyRookie;

    // when
    final copy = arena.copyWith(levels: [ArenaLevelStatusEntityMock.rookieForNewHero]);

    // then
    expect(copy, arena);
    expect(copy.hashCode, arena.hashCode);
  });

  test('testWhenALevelStatusDiffersThenTheArenasAreNotEqual', () {
    // given
    const arena = ArenaEntityMock.onlyRookie;

    // when
    final copy = arena.copyWith(levels: [ArenaLevelStatusEntityMock.rookieForVeteran]);

    // then
    expect(copy == arena, isFalse);
  });
}
