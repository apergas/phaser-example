import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

void main() {
  test('testWhenComparingPositionsWithSameCoordinatesThenTheyAreEqual', () {
    // given
    const position = PositionEntity(x: 3, y: 4);

    // when
    final isEqual = position == const PositionEntity(x: 3, y: 4);
    final isDifferent = position == const PositionEntity(x: 4, y: 3);

    // then
    expect(isEqual, isTrue);
    expect(isDifferent, isFalse);
    expect(position.hashCode, const PositionEntity(x: 3, y: 4).hashCode);
  });

  test('testWhenCopyingWithXThenOnlyXChanges', () {
    // given
    const position = PositionEntity(x: 3, y: 4);

    // when
    final copy = position.copyWith(x: 10);

    // then
    expect(copy, const PositionEntity(x: 10, y: 4));
  });
}
