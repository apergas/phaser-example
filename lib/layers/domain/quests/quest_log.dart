import 'dart:math';

import '../../../core/config/constants/enum/quest_id.dart';
import '../../../core/config/constants/enum/quest_line.dart';
import '../entities/game/game_event_entity.dart';
import '../entities/game/quest_progress_entity.dart';
import '../world/world.dart';
import 'quest.dart';
import 'quests.dart';

class QuestLog {
  QuestLog({List<Quest>? quests}) : _quests = quests ?? Quests.all;

  final List<Quest> _quests;
  final Set<QuestId> _completed = {};

  List<QuestCompletedEventEntity> update(World world) {
    final fulfilled = _quests
        .where((quest) => !_completed.contains(quest.id) && quest.progress(world) >= quest.target)
        .toList();
    _completed.addAll(fulfilled.map((quest) => quest.id));
    return [for (final quest in fulfilled) QuestCompletedEventEntity(questId: quest.id)];
  }

  List<QuestProgressEntity> status(World world) {
    final current = <QuestLine, QuestId>{};
    for (final quest in _quests) {
      if (!_completed.contains(quest.id)) current.putIfAbsent(quest.line, () => quest.id);
    }
    return [
      for (final quest in _quests)
        QuestProgressEntity(
          id: quest.id,
          line: quest.line,
          progress: _completed.contains(quest.id) ? quest.target : min(quest.progress(world), quest.target),
          target: quest.target,
          isCompleted: _completed.contains(quest.id),
          isCurrent: current[quest.line] == quest.id,
        ),
    ];
  }
}
