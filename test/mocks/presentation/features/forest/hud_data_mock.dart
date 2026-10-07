import 'package:rpg/layers/presentation/features/forest/models/hero_panel_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/hud_data.dart';

import 'build_item_data_mock.dart';
import 'hero_panel_data_mock.dart';
import 'quest_item_data_mock.dart';
import 'resource_item_data_mock.dart';
import 'tool_item_data_mock.dart';

abstract final class HudDataMock {
  static HudData get mock => _make(wood: 0);

  static HudData get mockCopy => _make(wood: 0);

  static HudData get withWood => _make(wood: 6);

  static HudData get withAxeOwned => _make(wood: 0, isAxeOwned: true);

  static HudData get withHeroReadyToBuy => _make(wood: 0, hero: HeroPanelDataMock.readyToBuySword);

  static HudData get start => HudData(
    resources: [ResourceItemDataMock.wood(0)],
    tools: [ToolItemDataMock.axe(isOwned: false)],
    questBadge: '0/3',
    quests: [QuestItemDataMock.current, QuestItemDataMock.pending],
    buildItems: [BuildItemDataMock.unaffordable],
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get gathering => HudData(
    resources: [ResourceItemDataMock.wood(23)],
    tools: [ToolItemDataMock.axe(isOwned: true)],
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get placing => HudData(
    resources: [ResourceItemDataMock.wood(23)],
    tools: [ToolItemDataMock.axe(isOwned: true)],
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: true,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get withEveryResourceAndTool => HudData(
    resources: [ResourceItemDataMock.wood(999), ResourceItemDataMock.gold(999)],
    tools: [ToolItemDataMock.axe(isOwned: true)],
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    isBuildLocked: false,
    hero: HeroPanelDataMock.readyToBuySword,
  );

  static HudData _make({required int wood, bool isAxeOwned = false, HeroPanelData? hero}) {
    return HudData(
      resources: [ResourceItemDataMock.wood(wood)],
      tools: [ToolItemDataMock.axe(isOwned: isAxeOwned)],
      questBadge: '0/3',
      quests: [QuestItemDataMock.pickUpAxeCurrent],
      buildItems: [BuildItemDataMock.makeUnaffordable(missingWood: 15)],
      isBuildLocked: false,
      hero: hero ?? HeroPanelDataMock.newHero,
    );
  }
}
