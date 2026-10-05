import 'package:flutter_test/flutter_test.dart';

import '../../../../../mocks/presentation/features/forest/placement_data_mock.dart';

void main() {
  test('testWhenCopyingWithANewPositionThenKeepsTheRest', () {
    // given
    final placement = PlacementDataMock.mock;

    // when
    final moved = placement.copyWith(position: PlacementDataMock.movedPosition);

    // then
    expect(moved, PlacementDataMock.moved);
  });
}
