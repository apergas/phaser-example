import 'package:flutter_test/flutter_test.dart';

import '../../../../../mocks/presentation/features/forest/placement_data_mock.dart';

void main() {
  test('testWhenThereIsNoInvalidReasonThenThePlacementIsValid', () {
    // given
    const placement = PlacementDataMock.mock;

    // when
    final isValid = placement.isValid;

    // then
    expect(isValid, isTrue);
  });

  test('testWhenThereIsAnInvalidReasonThenThePlacementIsNotValid', () {
    // given
    const placements = [PlacementDataMock.blockedNextToFarTree, PlacementDataMock.houseWithoutResources];

    // when
    final valid = placements.where((placement) => placement.isValid);

    // then
    expect(valid, isEmpty);
  });

  test('testWhenComparingPlacementsThenBlueprintPositionAndReasonAllCount', () {
    // given
    const placement = PlacementDataMock.mock;

    // when
    final same = placement == PlacementDataMock.mock;
    final otherPosition = placement == PlacementDataMock.moved;
    final otherReason = placement == PlacementDataMock.houseWithoutResources;

    // then
    expect(same, isTrue);
    expect(placement.hashCode, PlacementDataMock.mock.hashCode);
    expect(otherPosition, isFalse);
    expect(otherReason, isFalse);
  });
}
