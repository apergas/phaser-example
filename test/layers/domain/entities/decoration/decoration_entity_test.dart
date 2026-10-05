import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';

import '../../../../mocks/domain/entities/decoration/decoration_entity_mock.dart';

void main() {
  test('testWhenComparingDecorationsThenKindAndPositionMatter', () {
    // given
    const decoration = DecorationEntityMock.mock;

    // when
    final isEqual = decoration == decoration.copyWith(kind: DecorationKind.rock);
    final isDifferent = decoration == decoration.copyWith(kind: DecorationKind.leaves);

    // then
    expect(isEqual, isTrue);
    expect(isDifferent, isFalse);
  });
}
