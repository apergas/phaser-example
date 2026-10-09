import '../../../../../core/config/constants/enum/skill_id.dart';

class SkillItemData {
  final SkillId id;
  final String name;
  final String description;
  final String? costText;
  final String? reasonText;
  final bool isKnown;
  final bool canLearn;

  const SkillItemData({
    required this.id,
    required this.name,
    required this.description,
    this.costText,
    this.reasonText,
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
          other.costText == costText &&
          other.reasonText == reasonText &&
          other.isKnown == isKnown &&
          other.canLearn == canLearn;

  @override
  int get hashCode => Object.hash(id, name, description, costText, reasonText, isKnown, canLearn);

  @override
  String toString() => 'SkillItemData($id, $name, $costText, $reasonText, isKnown: $isKnown, canLearn: $canLearn)';
}
