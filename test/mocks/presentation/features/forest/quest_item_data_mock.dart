import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

abstract final class QuestItemDataMock {
  static QuestItemData get done => QuestItemData(
    title: Internationalize.forestQuestTitle(id: QuestId.pickUpAxe),
    progressText: Internationalize.forestQuestDone,
    status: QuestItemStatus.done,
  );

  static QuestItemData get current => QuestItemData(
    title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
    progressText: '6/15',
    status: QuestItemStatus.current,
  );

  static QuestItemData get pending => QuestItemData(
    title: Internationalize.forestQuestTitle(id: QuestId.buildHouse),
    progressText: '',
    status: QuestItemStatus.pending,
  );

  static QuestItemData get pickUpAxeCurrent => QuestItemData(
    title: Internationalize.forestQuestTitle(id: QuestId.pickUpAxe),
    progressText: '',
    status: QuestItemStatus.current,
  );

  static QuestItemData get gatherWoodPending => QuestItemData(
    title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
    progressText: '0/15',
    status: QuestItemStatus.pending,
  );

  static List<QuestItemData> get all => [done, current, pending];
}
