import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/entities/building/blueprint_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';

void main() {
  test('testWhenAskingForTheHouseThenReturnsItsCostHitsAndFootprint', () {
    // given
    const id = BlueprintId.house;

    // when
    final blueprint = Blueprints.of(id);

    // then
    expect(
      blueprint,
      const BlueprintEntity(id: BlueprintId.house, woodCost: 15, hitsToBuild: 8, footprintRadius: 40),
    );
    expect(Blueprints.all, [Blueprints.house]);
  });
}
