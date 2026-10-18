import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/entities/building/placement_rule_entity.dart';

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
    final others = [
      BlueprintEntityMock.make(cost: InventoryEntityMock.tenWood),
      BlueprintEntityMock.make(hitsToBuild: 4),
      BlueprintEntityMock.make(footprintRadius: 20),
      BlueprintEntityMock.make(isBuildable: false),
      BlueprintEntityMock.make(accepts: {Resource.stone}),
      BlueprintEntityMock.make(placementRule: const NearRockPlacementRuleEntity(range: 120)),
    ];

    // then
    expect(others.where((other) => other == blueprint), isEmpty);
  });

  test('testWhenCreatedWithoutExtrasThenItIsBuildableAnywhereAndAcceptsNothing', () {
    // given
    const blueprint = BlueprintEntityMock.mock;

    // when
    final extras = (blueprint.isBuildable, blueprint.accepts.isEmpty, blueprint.placementRule);

    // then
    expect(extras, (true, true, const AnywherePlacementRuleEntity()));
  });
}
