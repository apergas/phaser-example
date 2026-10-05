import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/world/extensions/blueprint_rules.dart';

import '../../../../mocks/domain/entities/building/blueprint_entity_mock.dart';

void main() {
  test('testWhenWoodIsBelowTheCostThenIsNotAffordable', () {
    // given
    const blueprint = BlueprintEntityMock.mock;

    // when
    final isAffordable = blueprint.isAffordableWith(blueprint.woodCost - 1);

    // then
    expect(isAffordable, isFalse);
  });

  test('testWhenWoodEqualsTheCostThenIsAffordable', () {
    // given
    const blueprint = BlueprintEntityMock.mock;

    // when
    final isAffordable = blueprint.isAffordableWith(blueprint.woodCost);

    // then
    expect(isAffordable, isTrue);
  });

  test('testWhenWoodExceedsTheCostThenIsAffordable', () {
    // given
    const blueprint = BlueprintEntityMock.mock;

    // when
    final isAffordable = blueprint.isAffordableWith(blueprint.woodCost + 1);

    // then
    expect(isAffordable, isTrue);
  });
}
