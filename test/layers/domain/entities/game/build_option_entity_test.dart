import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/game/build_option_entity_mock.dart';
import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

void main() {
  test('testWhenComparingBuildOptionsThenAffordabilityMatters', () {
    // given
    const option = BuildOptionEntityMock.mock;

    // when
    final isEqual = option == BuildOptionEntityMock.make();
    final notAffordable = option == BuildOptionEntityMock.make(missing: InventoryEntityMock.fiveWood);

    // then
    expect(isEqual, isTrue);
    expect(notAffordable, isFalse);
  });

  test('testWhenSomethingIsMissingThenIsNotAffordable', () {
    // given
    final option = BuildOptionEntityMock.make(missing: InventoryEntityMock.fiveWood);

    // when
    final isAffordable = option.isAffordable;

    // then
    expect(isAffordable, isFalse);
    expect(BuildOptionEntityMock.mock.isAffordable, isTrue);
  });
}
