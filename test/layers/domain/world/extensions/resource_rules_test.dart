import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/layers/domain/world/extensions/resource_rules.dart';

void main() {
  test('testWhenAskingWhichResourcesTakeCargoThenOnlyWoodAndStoneDo', () {
    // given
    const resources = Resource.values;

    // when
    final cargo = {for (final resource in resources) resource: resource.takesCargo};

    // then
    expect(cargo, {Resource.wood: true, Resource.gold: false, Resource.mana: false, Resource.stone: true});
  });
}
