import '../../../../core/config/constants/enum/quest_id.dart';
import '../../../../core/config/constants/enum/quest_line.dart';

class QuestProgressEntity {
  final QuestId id;
  final QuestLine line;
  final int progress;
  final int target;
  final bool isCompleted;
  final bool isCurrent;

  const QuestProgressEntity({
    required this.id,
    required this.line,
    required this.progress,
    required this.target,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  bool operator ==(Object other) =>
      other is QuestProgressEntity &&
      other.id == id &&
      other.line == line &&
      other.progress == progress &&
      other.target == target &&
      other.isCompleted == isCompleted &&
      other.isCurrent == isCurrent;

  @override
  int get hashCode => Object.hash(id, line, progress, target, isCompleted, isCurrent);

  @override
  String toString() =>
      'QuestProgressEntity(id: $id, line: $line, progress: $progress, target: $target, '
      'isCompleted: $isCompleted, isCurrent: $isCurrent)';
}
