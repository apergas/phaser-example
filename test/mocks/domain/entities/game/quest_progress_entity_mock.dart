import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/quest_line.dart';
import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';

abstract final class QuestProgressEntityMock {
  static const QuestProgressEntity mock = QuestProgressEntity(
    line: QuestLine.village,
    id: QuestId.gatherWood,
    progress: 3,
    target: 15,
    isCompleted: false,
    isCurrent: true,
  );

  static const QuestProgressEntity pickUpAxePending = QuestProgressEntity(
    line: QuestLine.village,
    id: QuestId.pickUpAxe,
    progress: 0,
    target: 1,
    isCompleted: false,
    isCurrent: true,
  );

  static const QuestProgressEntity gatherWoodPending = QuestProgressEntity(
    line: QuestLine.village,
    id: QuestId.gatherWood,
    progress: 0,
    target: 15,
    isCompleted: false,
    isCurrent: false,
  );

  static const QuestProgressEntity gatherWoodCurrent = QuestProgressEntity(
    line: QuestLine.village,
    id: QuestId.gatherWood,
    progress: 0,
    target: 15,
    isCompleted: false,
    isCurrent: true,
  );

  static const QuestProgressEntity buildHousePending = QuestProgressEntity(
    line: QuestLine.village,
    id: QuestId.buildHouse,
    progress: 0,
    target: 1,
    isCompleted: false,
    isCurrent: false,
  );

  static const QuestProgressEntity gatherWoodCompleted = QuestProgressEntity(
    line: QuestLine.village,
    id: QuestId.gatherWood,
    progress: 15,
    target: 15,
    isCompleted: true,
    isCurrent: false,
  );

  static const QuestProgressEntity buildForgeCurrent = QuestProgressEntity(
    id: QuestId.buildForge,
    line: QuestLine.hero,
    progress: 0,
    target: 1,
    isCompleted: false,
    isCurrent: true,
  );

  static QuestProgressEntity make({bool isCurrent = true}) {
    return QuestProgressEntity(
      line: QuestLine.village,
      id: QuestId.gatherWood,
      progress: 3,
      target: 15,
      isCompleted: false,
      isCurrent: isCurrent,
    );
  }
}
