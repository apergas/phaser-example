import 'package:rpg/core/config/constants/enum/forest/quest_item_status.dart';
import 'package:rpg/layers/presentation/features/forest/models/quest_item_data.dart';

abstract final class QuestItemDataMock {
  static final QuestItemData done = QuestItemData(
    title: 'Recoge el hacha',
    progressText: 'Hecha',
    status: QuestItemStatus.done,
  );

  static final QuestItemData current = QuestItemData(
    title: 'Consigue al menos 15 de madera',
    progressText: '6/15',
    status: QuestItemStatus.current,
  );

  static final QuestItemData pending = QuestItemData(
    title: 'Construye una casa',
    progressText: '',
    status: QuestItemStatus.pending,
  );

  static final List<QuestItemData> all = [done, current, pending];
}
