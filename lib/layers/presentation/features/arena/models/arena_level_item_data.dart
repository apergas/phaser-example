import '../../../../../core/config/constants/enum/arena/arena_level_item_status.dart';
import '../../../../../core/config/constants/enum/arena/power_tone.dart';
import '../../../../../core/config/constants/enum/arena_level_id.dart';

class ArenaLevelItemData {
  final ArenaLevelId id;
  final String name;
  final String enemiesText;
  final String powerText;
  final PowerTone tone;
  final String rewardText;
  final ArenaLevelItemStatus status;

  const ArenaLevelItemData({
    required this.id,
    required this.name,
    required this.enemiesText,
    required this.powerText,
    required this.tone,
    required this.rewardText,
    required this.status,
  });

  bool get isPlayable => status != ArenaLevelItemStatus.locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArenaLevelItemData &&
          other.id == id &&
          other.name == name &&
          other.enemiesText == enemiesText &&
          other.powerText == powerText &&
          other.tone == tone &&
          other.rewardText == rewardText &&
          other.status == status;

  @override
  int get hashCode => Object.hash(id, name, enemiesText, powerText, tone, rewardText, status);
}
