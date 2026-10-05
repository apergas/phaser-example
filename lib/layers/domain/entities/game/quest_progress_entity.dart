import '../../../../core/config/constants/enum/quest_id.dart';

class QuestProgressEntity {
  final QuestId id;
  final int progress;
  final int target;
  final bool isCompleted;
  final bool isCurrent;

  const QuestProgressEntity({
    required this.id,
    required this.progress,
    required this.target,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  bool operator ==(Object other) =>
      other is QuestProgressEntity &&
      other.id == id &&
      other.progress == progress &&
      other.target == target &&
      other.isCompleted == isCompleted &&
      other.isCurrent == isCurrent;

  @override
  int get hashCode => Object.hash(id, progress, target, isCompleted, isCurrent);

  @override
  String toString() =>
      'QuestProgressEntity(id: $id, progress: $progress, target: $target, isCompleted: $isCompleted, isCurrent: $isCurrent)';
}
