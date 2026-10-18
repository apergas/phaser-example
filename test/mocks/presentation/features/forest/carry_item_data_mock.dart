import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/presentation/features/forest/models/carry_item_data.dart';

abstract final class CarryItemDataMock {
  static CarryItemData get empty => of(0);

  static CarryItemData get sevenOfTen => of(7);

  static CarryItemData get full => of(Rules.carryCapacity);

  static CarryItemData of(int amount) => CarryItemData(
    text: Internationalize.forestCarry(amount: amount, capacity: Rules.carryCapacity),
    isFull: amount >= Rules.carryCapacity,
  );
}
