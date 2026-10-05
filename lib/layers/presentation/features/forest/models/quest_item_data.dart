import '../../../../../core/config/constants/enum/forest/quest_item_status.dart';

class QuestItemData {
  final String title;
  final String progressText;
  final QuestItemStatus status;

  const QuestItemData({required this.title, required this.progressText, required this.status});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestItemData && other.title == title && other.progressText == progressText && other.status == status;

  @override
  int get hashCode => Object.hash(title, progressText, status);
}
