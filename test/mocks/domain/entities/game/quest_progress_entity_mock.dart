import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';

abstract final class QuestProgressEntityMock {
  static const QuestProgressEntity mock = QuestProgressEntity(
    id: QuestId.gatherWood,
    progress: 3,
    target: 15,
    isCompleted: false,
    isCurrent: true,
  );

  static const QuestProgressEntity pickUpAxePending = QuestProgressEntity(
    id: QuestId.pickUpAxe,
    progress: 0,
    target: 1,
    isCompleted: false,
    isCurrent: true,
  );

  static const QuestProgressEntity gatherWoodPending = QuestProgressEntity(
    id: QuestId.gatherWood,
    progress: 0,
    target: 15,
    isCompleted: false,
    isCurrent: false,
  );

  static const QuestProgressEntity buildHousePending = QuestProgressEntity(
    id: QuestId.buildHouse,
    progress: 0,
    target: 1,
    isCompleted: false,
    isCurrent: false,
  );

  static const QuestProgressEntity gatherWoodCompleted = QuestProgressEntity(
    id: QuestId.gatherWood,
    progress: 15,
    target: 15,
    isCompleted: true,
    isCurrent: false,
  );

  static QuestProgressEntity make({bool isCurrent = true}) {
    return QuestProgressEntity(
      id: QuestId.gatherWood,
      progress: 3,
      target: 15,
      isCompleted: false,
      isCurrent: isCurrent,
    );
  }
}
