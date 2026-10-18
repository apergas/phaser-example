import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/upgrade_option_state.dart';

import '../../../../mocks/domain/entities/upgrade/upgrade_option_entity_mock.dart';

void main() {
  test('testWhenComparingOptionsThenUpgradeStateAndMissingAllCount', () {
    // given
    const option = UpgradeOptionEntityMock.ironAxeAvailable;

    // when
    final same = option == option.copyWith();
    final others = [
      UpgradeOptionEntityMock.ironAxeOwned,
      UpgradeOptionEntityMock.ironPickaxeAvailable,
      option.copyWith(missing: UpgradeOptionEntityMock.ironAxeFiveStoneShort.missing),
    ];

    // then
    expect(same, isTrue);
    expect(option.hashCode, option.copyWith().hashCode);
    expect(others.where((other) => other == option), isEmpty);
    expect(option.copyWith(state: UpgradeOptionState.owned), UpgradeOptionEntityMock.ironAxeOwned);
  });

  test('testWhenTheOptionIsAvailableThenItCanBeBoughtAndNoOtherStateCan', () {
    // given
    const others = [
      UpgradeOptionEntityMock.ironAxeOwned,
      UpgradeOptionEntityMock.ironAxeWithoutWorkshop,
      UpgradeOptionEntityMock.ironAxeFiveStoneShort,
    ];

    // when
    final buyable = others.where((option) => option.canBuy);

    // then
    expect(UpgradeOptionEntityMock.ironAxeAvailable.canBuy, isTrue);
    expect(buyable, isEmpty);
  });
}
