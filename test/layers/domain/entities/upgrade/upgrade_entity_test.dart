import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/entities/upgrade/upgrade_entity.dart';

import '../../../../mocks/domain/entities/upgrade/upgrade_entity_mock.dart';

void main() {
  test('testWhenComparingUpgradesThenIdToolLevelAndCostAllCount', () {
    // given
    const upgrade = UpgradeEntityMock.ironAxe;

    // when
    final same = upgrade == upgrade.copyWith();
    final others = [UpgradeEntityMock.ironPickaxe, UpgradeEntityMock.steelAxe, upgrade.copyWith(cost: const {})];

    // then
    expect(same, isTrue);
    expect(upgrade.hashCode, upgrade.copyWith().hashCode);
    expect(others.where((other) => other == upgrade), isEmpty);
    expect(upgrade.copyWith(level: 3), UpgradeEntityMock.steelAxe);
  });

  test('testWhenTheLevelIsOneThenItAsserts', () {
    // given
    const upgrade = UpgradeEntityMock.ironAxe;

    // when
    UpgradeEntity levelOne() => upgrade.copyWith(level: 1);

    // then
    expect(levelOne, throwsA(isA<AssertionError>()));
  });
}
