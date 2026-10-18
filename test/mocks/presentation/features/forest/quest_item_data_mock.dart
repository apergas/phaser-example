import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/core/config/constants/enum/quest_line.dart';
import 'package:farming/layers/presentation/features/forest/models/quest_item_data.dart';

abstract final class QuestItemDataMock {
  static const QuestId seeATreeRegrowId = QuestId.seeATreeRegrow;

  static QuestItemData get done => QuestItemData(
    line: QuestLine.village,
    title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
    progressText: Internationalize.forestQuestDone,
    status: QuestItemStatus.done,
  );

  static QuestItemData get current => QuestItemData(
    line: QuestLine.village,
    title: Internationalize.forestQuestTitle(id: QuestId.fellTenTrees),
    progressText: '6/10',
    status: QuestItemStatus.current,
  );

  static QuestItemData get pending => QuestItemData(
    line: QuestLine.village,
    title: Internationalize.forestQuestTitle(id: QuestId.fellAnOak),
    progressText: '',
    status: QuestItemStatus.pending,
  );

  static QuestItemData get gatherWoodCurrent => QuestItemData(
    line: QuestLine.village,
    title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
    progressText: '0/15',
    status: QuestItemStatus.current,
  );

  static QuestItemData get gatherWoodPending => QuestItemData(
    line: QuestLine.village,
    title: Internationalize.forestQuestTitle(id: QuestId.gatherWood),
    progressText: '0/15',
    status: QuestItemStatus.pending,
  );

  static QuestItemData get buildForgeCurrent => QuestItemData(
    line: QuestLine.hero,
    title: Internationalize.forestQuestTitle(id: QuestId.buildForge),
    progressText: '',
    status: QuestItemStatus.current,
  );

  static List<QuestItemData> get withBothLines => [done, current, pending, buildForgeCurrent];

  static List<QuestItemData> get all => [done, current, pending];

  static QuestItemData get foldedThree => folded(3);

  static QuestItemData pendingOf(QuestId id, {QuestLine line = QuestLine.village, String progressText = ''}) =>
      QuestItemData(
        line: line,
        title: Internationalize.forestQuestTitle(id: id),
        progressText: progressText,
        status: QuestItemStatus.pending,
      );

  static QuestItemData currentOf(QuestId id, {QuestLine line = QuestLine.village, String progressText = ''}) =>
      QuestItemData(
        line: line,
        title: Internationalize.forestQuestTitle(id: id),
        progressText: progressText,
        status: QuestItemStatus.current,
      );

  static QuestItemData folded(int count, {QuestLine line = QuestLine.village}) => QuestItemData(
    line: line,
    title: Internationalize.forestQuestsDone(count: count),
    progressText: '',
    status: QuestItemStatus.folded,
  );

  static List<QuestItemData> get atTheStart => [
    gatherWoodCurrent,
    pendingOf(QuestId.buildHouse),
    pendingOf(QuestId.fellTenTrees, progressText: '0/10'),
    buildForgeCurrent,
    pendingOf(QuestId.winFirstFight, line: QuestLine.hero),
    pendingOf(QuestId.buyFirstWeapon, line: QuestLine.hero),
  ];

  static List<QuestItemData> get afterTheFirstTwoVillageQuests => [
    folded(2),
    currentOf(QuestId.fellTenTrees, progressText: '0/10'),
    pendingOf(QuestId.fellAnOak),
    pendingOf(QuestId.gatherFortyWood, progressText: '15/40'),
    buildForgeCurrent,
    pendingOf(QuestId.winFirstFight, line: QuestLine.hero),
    pendingOf(QuestId.buyFirstWeapon, line: QuestLine.hero),
  ];

  static List<QuestItemData> get withTheVillageDone => [
    folded(11),
    buildForgeCurrent,
    pendingOf(QuestId.winFirstFight, line: QuestLine.hero),
    pendingOf(QuestId.buyFirstWeapon, line: QuestLine.hero),
  ];
}
