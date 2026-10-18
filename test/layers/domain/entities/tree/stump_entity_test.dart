import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/tree/stump_entity.dart';

import '../../../../mocks/domain/entities/tree/stump_entity_mock.dart';

void main() {
  test('testWhenCopyingWithTheElapsedTimeThenTheRestIsKept', () {
    // given
    const stump = StumpEntityMock.fresh;

    // when
    final copy = stump.copyWith(elapsedMs: 60000);

    // then
    expect(copy, StumpEntityMock.sapling);
    expect(copy.hashCode, StumpEntityMock.sapling.hashCode);
    expect(stump.copyWith(), stump);
  });

  test('testWhenIdKindOrTimeDifferThenStumpsAreNotEqual', () {
    // given
    const stump = StumpEntityMock.fresh;

    // when
    final others = [StumpEntityMock.otherId, StumpEntityMock.freshOak, StumpEntityMock.almostSapling];

    // then
    expect(others.where((other) => other == stump), isEmpty);
    expect(stump.copyWith(kind: TreeKind.oak), StumpEntityMock.freshOak);
  });

  test('testWhenTheElapsedTimeIsNegativeThenItAsserts', () {
    // given
    const stump = StumpEntityMock.fresh;

    // when
    StumpEntity negative() => stump.copyWith(elapsedMs: -1);

    // then
    expect(negative, throwsA(isA<AssertionError>()));
  });
}
