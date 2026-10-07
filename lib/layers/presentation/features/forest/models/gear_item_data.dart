import '../../../../../core/config/constants/enum/gear_id.dart';

class GearItemData {
  final GearId id;
  final String name;
  final String statsText;
  final String? costText;
  final String? reasonText;
  final bool canBuy;

  const GearItemData({
    required this.id,
    required this.name,
    required this.statsText,
    this.costText,
    this.reasonText,
    required this.canBuy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearItemData &&
          other.id == id &&
          other.name == name &&
          other.statsText == statsText &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.canBuy == canBuy;

  @override
  int get hashCode => Object.hash(id, name, statsText, costText, reasonText, canBuy);

  @override
  String toString() => 'GearItemData($id, $name, $statsText, $costText, $reasonText, canBuy: $canBuy)';
}
