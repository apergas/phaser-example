import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/layers/domain/entities/decoration/decoration_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/domain/entities/item/ground_item_entity_mock.dart';

void main() {
  test('testWhenCopyingItemWithSameValuesThenItIsEqual', () {
    // given
    const item = GroundItemEntityMock.mock;

    // when
    final copy = item.copyWith(position: const PositionEntity(x: 150, y: 100));

    // then
    expect(copy, item);
    expect(copy.hashCode, item.hashCode);
  });

  test('testWhenComparingDecorationsThenKindAndPositionMatter', () {
    // given
    const decoration = DecorationEntity(
      id: 'decoration-1',
      kind: DecorationKind.rock,
      position: PositionEntity(x: 1, y: 2),
    );

    // when
    final isEqual = decoration == decoration.copyWith(kind: DecorationKind.rock);
    final isDifferent = decoration == decoration.copyWith(kind: DecorationKind.leaves);

    // then
    expect(isEqual, isTrue);
    expect(isDifferent, isFalse);
  });
}
