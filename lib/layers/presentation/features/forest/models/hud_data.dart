import 'package:collection/collection.dart';

import 'build_item_data.dart';
import 'hero_panel_data.dart';
import 'quest_item_data.dart';
import 'resource_item_data.dart';
import 'tool_item_data.dart';
import 'upgrade_item_data.dart';

class HudData {
  static const int pendingQuestsShown = 2;

  final List<ResourceItemData> stock;
  final List<ToolItemData> tools;
  final String questBadge;
  final List<QuestItemData> quests;
  final List<BuildItemData> buildItems;
  final List<UpgradeItemData> upgradeItems;
  final bool isBuildLocked;
  final HeroPanelData hero;

  const HudData({
    required this.stock,
    required this.tools,
    required this.questBadge,
    required this.quests,
    required this.buildItems,
    required this.upgradeItems,
    required this.isBuildLocked,
    required this.hero,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HudData &&
          const ListEquality<ResourceItemData>().equals(other.stock, stock) &&
          const ListEquality<ToolItemData>().equals(other.tools, tools) &&
          other.questBadge == questBadge &&
          const ListEquality<QuestItemData>().equals(other.quests, quests) &&
          const ListEquality<BuildItemData>().equals(other.buildItems, buildItems) &&
          const ListEquality<UpgradeItemData>().equals(other.upgradeItems, upgradeItems) &&
          other.isBuildLocked == isBuildLocked &&
          other.hero == hero;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(stock),
    Object.hashAll(tools),
    questBadge,
    Object.hashAll(quests),
    Object.hashAll(buildItems),
    Object.hashAll(upgradeItems),
    isBuildLocked,
    hero,
  );
}
