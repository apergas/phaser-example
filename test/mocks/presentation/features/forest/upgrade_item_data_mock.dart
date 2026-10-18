import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/presentation/features/forest/models/upgrade_item_data.dart';

abstract final class UpgradeItemDataMock {
  static const int fewerHitsPercent = 40;

  static UpgradeItemData ironAxe({String? reasonText, bool canBuy = false, bool isOwned = false}) =>
      _make(UpgradeId.ironAxe, wood: 15, stone: 15, reasonText: reasonText, canBuy: canBuy, isOwned: isOwned);

  static UpgradeItemData ironPickaxe({String? reasonText, bool canBuy = false, bool isOwned = false}) =>
      _make(UpgradeId.ironPickaxe, wood: 10, stone: 20, reasonText: reasonText, canBuy: canBuy, isOwned: isOwned);

  static List<UpgradeItemData> get withoutWorkshop => [
    ironAxe(reasonText: Internationalize.forestUpgradeNeedsWorkshop),
    ironPickaxe(reasonText: Internationalize.forestUpgradeNeedsWorkshop),
  ];

  static List<UpgradeItemData> get fiveStoneShortOfTheAxe => [
    ironAxe(reasonText: missing(stone: 5)),
    ironPickaxe(reasonText: missing(stone: 10)),
  ];

  static List<UpgradeItemData> get axeAffordable => [
    ironAxe(canBuy: true),
    ironPickaxe(reasonText: missing(stone: 5)),
  ];

  static List<UpgradeItemData> get axeOwnedAndPickaxeShort => [
    ironAxe(isOwned: true),
    ironPickaxe(reasonText: missing(wood: 10, stone: 20)),
  ];

  static UpgradeItemData get axeOption => ironAxe(canBuy: true);

  static String missing({int wood = 0, int stone = 0}) => Internationalize.forestMissing(
    amounts: [
      if (wood > 0) Internationalize.forestAmount(resource: Resource.wood, amount: wood),
      if (stone > 0) Internationalize.forestAmount(resource: Resource.stone, amount: stone),
    ].join(', '),
  );

  static UpgradeItemData _make(
    UpgradeId id, {
    required int wood,
    required int stone,
    required String? reasonText,
    required bool canBuy,
    required bool isOwned,
  }) => UpgradeItemData(
    id: id,
    name: Internationalize.forestUpgradeName(id: id),
    effectText: Internationalize.forestUpgradeEffect(id: id, percent: fewerHitsPercent),
    costText: isOwned
        ? Internationalize.forestUpgradeOwned
        : [
            Internationalize.forestAmount(resource: Resource.wood, amount: wood),
            Internationalize.forestAmount(resource: Resource.stone, amount: stone),
          ].join(', '),
    reasonText: reasonText,
    canBuy: canBuy,
  );
}
