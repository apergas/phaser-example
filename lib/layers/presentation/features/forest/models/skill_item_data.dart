import '../../../../../core/config/constants/enum/skill_id.dart';

class SkillItemData {
  final SkillId id;
  final String name;
  final String description;
  final String? levelText;
  final String? nextText;
  final String? costText;
  final String? reasonText;
  final String? buttonText;
  final bool isKnown;
  final bool canLearn;

  const SkillItemData({
    required this.id,
    required this.name,
    required this.description,
    this.levelText,
    this.nextText,
    this.costText,
    this.reasonText,
    this.buttonText,
    required this.isKnown,
    required this.canLearn,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillItemData &&
          other.id == id &&
          other.name == name &&
          other.description == description &&
          other.levelText == levelText &&
          other.nextText == nextText &&
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.buttonText == buttonText &&
          other.isKnown == isKnown &&
          other.canLearn == canLearn;

  @override
  int get hashCode =>
      Object.hash(id, name, description, levelText, nextText, costText, reasonText, buttonText, isKnown, canLearn);

  @override
  String toString() =>
      'SkillItemData($id, $name, $levelText, $nextText, $costText, $reasonText, $buttonText, '
      'isKnown: $isKnown, canLearn: $canLearn)';
}
