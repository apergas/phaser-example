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
    expect(
      blueprint,
      BlueprintEntityMock.mock,
    );
    expect(Blueprints.all, [Blueprints.house]);
  });
}
