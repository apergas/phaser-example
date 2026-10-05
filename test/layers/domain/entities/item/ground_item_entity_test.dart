import 'package:flutter_test/flutter_test.dart';
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
}
