import '../../../../../core/config/constants/enum/upgrade_id.dart';

class UpgradeItemData {
  final UpgradeId id;
  final String name;
  final String effectText;
  final String costText;
  final String? reasonText;
  final bool canBuy;

  const UpgradeItemData({
    required this.id,
    required this.name,
    required this.effectText,
    required this.costText,
    this.reasonText,
    required this.canBuy,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpgradeItemData &&
          other.id == id &&
          other.name == name &&
          other.effectText == effectText &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.canBuy == canBuy;

  @override
  int get hashCode => Object.hash(id, name, effectText, costText, reasonText, canBuy);
}
