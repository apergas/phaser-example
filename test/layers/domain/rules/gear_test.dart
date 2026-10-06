import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/layers/domain/entities/gear/gear_entity.dart';
import 'package:rpg/layers/domain/rules/gear.dart';

void main() {
  test('testWhenListingGearThenEveryGearIdAppearsOnce', () {
    // given
    final ids = Gear.all.map((gear) => gear.id).toList();

    // when
    final unique = ids.toSet();

    // then
    expect(ids, hasLength(GearId.values.length));
    expect(unique, GearId.values.toSet());
  });

  test('testWhenListingEachSlotThenTiersGoFromZeroToMaxWithoutGaps', () {
    for (final slot in GearSlot.values) {
      // given
      final tiers = Gear.all.where((gear) => gear.slot == slot).map((gear) => gear.tier).toList()..sort();

      // when
      final expected = List.generate(Gear.maxTier(slot) + 1, (tier) => tier);

      // then
      expect(tiers, expected);
    }
  });

  test('testWhenLookingAtTierZeroThenItIsFree', () {
    for (final slot in GearSlot.values) {
      // given
      final basic = Gear.of(slot, 0);

      // when
      final cost = basic.cost;

      // then
      expect(cost, isEmpty);
    }
  });

  test('testWhenLookingForATierOutOfRangeThenThereIsNone', () {
    // given
    const slot = GearSlot.weapon;

    // when
    final gear = Gear.find(slot, Gear.maxTier(slot) + 1);

    // then
    expect(gear, isNull);
  });

  test('testWhenGettingATierOutOfRangeThenItThrowsStateError', () {
    // given
    const slot = GearSlot.armor;
    final tier = Gear.maxTier(slot) + 1;

    // when
    GearEntity action() => Gear.of(slot, tier);

    // then
    expect(action, throwsStateError);
  });

  test('testWhenFindingByIdThenItReturnsThatGear', () {
    // given
    const id = GearId.chainMail;

    // when
    final gear = Gear.byId(id);

    // then
    expect((gear.slot, gear.tier), (GearSlot.armor, 2));
  });
}
