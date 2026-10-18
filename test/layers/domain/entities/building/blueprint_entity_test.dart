import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../../mocks/domain/entities/building/blueprint_entity_mock.dart';

void main() {
  test('testWhenComparingBlueprintsWithSameValuesThenTheyAreEqual', () {
    // given
    const blueprint = BlueprintEntityMock.mock;

    // when
    final copy = BlueprintEntityMock.make();

    // then
    expect(copy, blueprint);
    expect(copy.hashCode, blueprint.hashCode);
  });

  test('testWhenAnyBlueprintFieldDiffersThenTheyAreNotEqual', () {
    // given
    const blueprint = BlueprintEntityMock.mock;

    // when
    final others = [
      BlueprintEntityMock.make(cost: StockEntityMock.tenWood),
      BlueprintEntityMock.make(hitsToBuild: 4),
      BlueprintEntityMock.make(footprintRadius: 20),
    ];

    // then
    expect(others.where((other) => other == blueprint), isEmpty);
  });
}
