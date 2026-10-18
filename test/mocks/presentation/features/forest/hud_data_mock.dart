import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/presentation/features/forest/models/hero_panel_data.dart';
import 'package:farming/layers/presentation/features/forest/models/hud_data.dart';
import 'package:farming/layers/presentation/features/forest/models/resource_item_data.dart';
import 'package:farming/layers/presentation/features/forest/models/tool_item_data.dart';

import 'build_item_data_mock.dart';
import 'hero_panel_data_mock.dart';
import 'quest_item_data_mock.dart';
import 'resource_item_data_mock.dart';
import 'tool_item_data_mock.dart';
import 'upgrade_item_data_mock.dart';

abstract final class HudDataMock {
  static HudData get mock => _make(wood: 0);

  static HudData get mockCopy => _make(wood: 0);

  static HudData get withWood => _make(wood: 6);

  static HudData get withPickaxeOwned => _make(wood: 0, isPickaxeOwned: true);

  static HudData get withHeroReadyToBuy => _make(wood: 0, hero: HeroPanelDataMock.readyToBuySword);

  static HudData get withUpgradeReady => HudData(
    stock: stockWith(wood: 15),
    tools: tools(),
    questBadge: '0/3',
    quests: [QuestItemDataMock.gatherWoodCurrent],
    buildItems: [BuildItemDataMock.affordable],
    upgradeItems: UpgradeItemDataMock.axeAffordable,
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get withSkillReadyToLearn => _make(wood: 0, hero: HeroPanelDataMock.readyToLearnDoubleStrike);

  static HudData get start => HudData(
    stock: stockWith(wood: 0),
    tools: tools(),
    questBadge: '0/3',
    quests: [QuestItemDataMock.current, QuestItemDataMock.pending],
    buildItems: [BuildItemDataMock.unaffordable],
    upgradeItems: const [],
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get gathering => HudData(
    stock: stockWith(wood: 23),
    tools: tools(),
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    upgradeItems: const [],
    isBuildLocked: false,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get placing => HudData(
    stock: stockWith(wood: 23),
    tools: tools(),
    questBadge: '1/3',
    quests: QuestItemDataMock.all,
    buildItems: [BuildItemDataMock.affordable],
    upgradeItems: const [],
    isBuildLocked: true,
    hero: HeroPanelDataMock.newHero,
  );

  static HudData get withEveryResourceAndTool => HudData(
    stock: [for (final resource in Resource.values) ResourceItemDataMock.of(resource, 9999)],
    tools: [for (final tool in ToolKind.values) ToolItemDataMock.of(tool, isOwned: true)],
    questBadge: '19/19',
    quests: QuestItemDataMock.all,
    buildItems: BuildItemDataMock.everyBlueprintUnaffordable,
    upgradeItems: UpgradeItemDataMock.fiveStoneShortOfTheAxe,
    isBuildLocked: false,
    hero: HeroPanelDataMock.readyToBuySword,
  );

  static List<ResourceItemData> stockWith({int wood = 0, int stone = 0}) => [
    for (final resource in Resource.values)
      ResourceItemDataMock.of(resource, switch (resource) {
        Resource.wood => wood,
        Resource.stone => stone,
        Resource.gold || Resource.mana => 0,
      }),
  ];

  static List<ToolItemData> tools({bool isPickaxeOwned = false}) => [
    ToolItemDataMock.axe(isOwned: true),
    ToolItemDataMock.of(ToolKind.pickaxe, isOwned: isPickaxeOwned),
  ];

  static HudData _make({required int wood, bool isPickaxeOwned = false, HeroPanelData? hero}) {
    return HudData(
      stock: stockWith(wood: wood),
      tools: tools(isPickaxeOwned: isPickaxeOwned),
      questBadge: '0/3',
      quests: [QuestItemDataMock.gatherWoodCurrent],
      buildItems: [BuildItemDataMock.makeUnaffordable(missingWood: 15)],
      upgradeItems: const [],
      isBuildLocked: false,
      hero: hero ?? HeroPanelDataMock.newHero,
    );
  }
}
