import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

import '../../../mocks/domain/entities/building/blueprint_entity_mock.dart';

void main() {
  test('testWhenAskingForTheHouseThenReturnsItsCostHitsAndFootprint', () {
    // given
    const id = BlueprintId.house;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(blueprint, BlueprintEntityMock.mock);
  });

  test('testWhenAskingForTheWorkshopsThenTheyCostTwentyFiveWoodAndTakeTenHits', () {
    // given
    const forge = BlueprintId.forge;
    const armory = BlueprintId.armory;

    // when
    final blueprints = (Blueprints.of(forge), Blueprints.of(armory));

    // then
    expect(blueprints, (BlueprintEntityMock.forge, BlueprintEntityMock.armory));
  });

  test('testWhenAskingForTheMageTowerThenItCostsWoodAndGoldAndTakesTwelveHits', () {
    // given
    const id = BlueprintId.mageTower;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(blueprint, BlueprintEntityMock.mageTower);
  });

  test('testWhenListingBlueprintsThenEveryIdAppearsOnceInDeclarationOrder', () {
    // given
    final ids = Blueprints.all.map((blueprint) => blueprint.id).toList();

    // when
    final expected = BlueprintId.values;

    // then
    expect(ids, expected);
  });
}
