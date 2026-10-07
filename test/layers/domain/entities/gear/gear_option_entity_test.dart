import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_option_state.dart';

import '../../../../mocks/domain/entities/gear/gear_option_entity_mock.dart';

void main() {
  test('testWhenComparingOptionsThenGearStateAndMissingAllCount', () {
    // given
    final option = GearOptionEntityMock.shortSwordAvailable;

    // when
    final sameOption = option == GearOptionEntityMock.shortSwordAvailable;
    final otherMissing = option == GearOptionEntityMock.shortSwordFiveGoldShort;
    final otherState = option == option.copyWith(state: GearOptionState.locked);

    // then
    expect(sameOption, isTrue);
    expect(option.hashCode, GearOptionEntityMock.shortSwordAvailable.hashCode);
    expect(otherMissing, isFalse);
    expect(otherState, isFalse);
  });

  test('testWhenTheOptionIsAvailableThenItCanBeBoughtAndNoOtherStateCan', () {
    // given
    final available = GearOptionEntityMock.shortSwordAvailable;
    final others = [
      GearOptionEntityMock.equipped(GearId.woodcutterAxe),
      GearOptionEntityMock.shortSwordFiveGoldShort,
      GearOptionEntityMock.make(GearId.shortSword, GearOptionState.needsBuilding),
      GearOptionEntityMock.make(GearId.ironSword, GearOptionState.locked),
    ];

    // when
    final buyable = others.where((option) => option.canBuy).toList();

    // then
    expect(available.canBuy, isTrue);
    expect(buyable, isEmpty);
  });
}
