import '../../../../../core/config/constants/enum/blueprint_id.dart';

class BuildItemData {
  final BlueprintId blueprint;
  final String name;
  final String costText;
  final String? missingText;
  final bool isEnabled;

  const BuildItemData({
    required this.blueprint,
    required this.name,
    required this.costText,
    this.missingText,
    required this.isEnabled,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildItemData &&
          other.blueprint == blueprint &&
          other.name == name &&
          other.costText == costText &&
          other.missingText == missingText &&
          other.isEnabled == isEnabled;

  @override
  int get hashCode => Object.hash(blueprint, name, costText, missingText, isEnabled);
}
