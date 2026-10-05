import 'package:collection/collection.dart';

import 'build_item_data.dart';
import 'quest_item_data.dart';

class HudData {
  final int wood;
  final bool hasAxe;
  final String questBadge;
  final List<QuestItemData> quests;
  final List<BuildItemData> buildItems;
  final bool isBuildLocked;

  const HudData({
    required this.wood,
    required this.hasAxe,
    required this.questBadge,
    required this.quests,
    required this.buildItems,
    required this.isBuildLocked,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudData &&
          other.wood == wood &&
          other.hasAxe == hasAxe &&
          other.questBadge == questBadge &&
          const ListEquality<QuestItemData>().equals(other.quests, quests) &&
          const ListEquality<BuildItemData>().equals(other.buildItems, buildItems) &&
          other.isBuildLocked == isBuildLocked;

  @override
  int get hashCode =>
      Object.hash(wood, hasAxe, questBadge, Object.hashAll(quests), Object.hashAll(buildItems), isBuildLocked);
}
