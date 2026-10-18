import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
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

  test('testWhenAskingForTheVillageBuildingsThenTheyHaveTheirCostsHitsAndWhatTheyAccept', () {
    // given
    const ids = [BlueprintId.storehouse, BlueprintId.quarry, BlueprintId.workshop, BlueprintId.camp];

    // when
    final blueprints = ids.map(Blueprints.of).toList();

    // then
    expect(blueprints, [
      BlueprintEntityMock.storehouse,
      BlueprintEntityMock.quarry,
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

  test('testWhenListingBlueprintsThenTheStorehouseQuarryAndWorkshopComeSecondThirdFourthAndTheCampLast', () {
    // given
    final ids = Blueprints.all.map((blueprint) => blueprint.id).toList();

    // when
    final positions = (
      ids.indexOf(BlueprintId.storehouse),
      ids.indexOf(BlueprintId.quarry),
      ids.indexOf(BlueprintId.workshop),
      ids.last,
    );

    // then
    expect(ids.toSet(), BlueprintId.values.toSet());
    expect(ids, hasLength(BlueprintId.values.length));
    expect(positions, (1, 2, 3, BlueprintId.camp));
  });

  test('testWhenAskingWhichBlueprintsCanBeBuiltThenOnlyTheCampCannot', () {
    // given
    const blueprints = Blueprints.all;

    // when
    final notBuildable = blueprints.where((blueprint) => !blueprint.isBuildable).map((blueprint) => blueprint.id);

    // then
    expect(notBuildable, [BlueprintId.camp]);
  });

  test('testWhenAskingWhatEachBlueprintAcceptsThenOnlyTheDropOffsTakeCargo', () {
    // given
    const blueprints = Blueprints.all;

    // when
    final accepts = {for (final blueprint in blueprints) blueprint.id: blueprint.accepts};

    // then
    expect(accepts, {
      BlueprintId.house: <Resource>{},
      BlueprintId.storehouse: {Resource.wood, Resource.stone},
      BlueprintId.quarry: {Resource.stone},
      BlueprintId.workshop: <Resource>{},
      BlueprintId.forge: <Resource>{},
      BlueprintId.armory: <Resource>{},
      BlueprintId.mageTower: <Resource>{},
      BlueprintId.camp: {Resource.wood, Resource.stone},
    });
  });
}
