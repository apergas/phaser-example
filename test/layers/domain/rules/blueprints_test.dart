import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

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

  test('testWhenAskingForTheVillageBuildingsThenTheyHaveTheirCostsAndHits', () {
    // given
    const ids = [BlueprintId.workshop, BlueprintId.camp];

    // when
    final blueprints = ids.map(Blueprints.of).toList();

    // then
    expect(blueprints, [
      BlueprintEntityMock.workshop,
      BlueprintEntityMock.camp,
    ]);
  });

  test('testWhenAskingForTheWorkshopsThenTheyCostTwentyFiveWoodAndTenStoneAndTakeTenHits', () {
    // given
    const forge = BlueprintId.forge;
    const armory = BlueprintId.armory;

    // when
    final blueprints = (Blueprints.of(forge), Blueprints.of(armory));

    // then
    expect(blueprints, (BlueprintEntityMock.forge, BlueprintEntityMock.armory));
  });

  test('testWhenAskingForTheMageTowerThenItCostsWoodGoldAndStoneAndTakesTwelveHits', () {
    // given
    const id = BlueprintId.mageTower;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(blueprint, BlueprintEntityMock.mageTower);
  });

  test('testWhenListingBlueprintsThenTheHouseAndTheWorkshopComeFirstAndTheCampLast', () {
    // given
    final ids = Blueprints.all.map((blueprint) => blueprint.id).toList();

    // when
    final positions = (ids.first, ids.indexOf(BlueprintId.workshop), ids.last);

    // then
    expect(ids.toSet(), BlueprintId.values.toSet());
    expect(ids, hasLength(BlueprintId.values.length));
    expect(positions, (BlueprintId.house, 1, BlueprintId.camp));
  });

  test('testWhenAskingWhichBlueprintsCanBeBuiltThenOnlyTheCampCannot', () {
    // given
    const blueprints = Blueprints.all;

    // when
    final notBuildable = blueprints.where((blueprint) => !blueprint.isBuildable).map((blueprint) => blueprint.id);

    // then
    expect(notBuildable, [BlueprintId.camp]);
  });
}
