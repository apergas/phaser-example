import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';
import '../../../../../core/config/constants/enum/quest_line.dart';

class QuestItemData {
  final QuestLine line;
  final String title;
  final String progressText;
  final QuestItemStatus status;

  const QuestItemData({required this.line, required this.title, required this.progressText, required this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestItemData &&
          other.line == line &&
          other.title == title &&
          other.progressText == progressText &&
          other.status == status;

  @override
  int get hashCode => Object.hash(line, title, progressText, status);
}
