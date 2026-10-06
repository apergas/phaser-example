import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';

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
    final otherCost = blueprint == BlueprintEntityMock.make(cost: {Resource.wood: 10});
    final otherHits = blueprint == BlueprintEntityMock.make(hitsToBuild: 4);
    final otherRadius = blueprint == BlueprintEntityMock.make(footprintRadius: 20);

    // then
    expect(otherCost, isFalse);
    expect(otherHits, isFalse);
    expect(otherRadius, isFalse);
  });
}
