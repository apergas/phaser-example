import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/building/blueprint_entity_mock.dart';
import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';

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
    final otherCost = blueprint == BlueprintEntityMock.make(cost: InventoryEntityMock.tenWood);
    final otherHits = blueprint == BlueprintEntityMock.make(hitsToBuild: 4);
    final otherRadius = blueprint == BlueprintEntityMock.make(footprintRadius: 20);

    // then
    expect(otherCost, isFalse);
    expect(otherHits, isFalse);
    expect(otherRadius, isFalse);
  });
}
