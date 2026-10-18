import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/core/config/constants/enum/quest_line.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/building/blueprint_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';
import 'package:farming/layers/domain/quests/quest.dart';
import 'package:farming/layers/domain/quests/quests.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../mocks/domain/entities/game/stats_entity_mock.dart';
import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  Quest quest(QuestId id) => Quests.all.firstWhere((quest) => quest.id == id);

  int progress(QuestId id, World world) => quest(id).progress(world);

  World withBuildings(List<BlueprintEntity> complete, {List<BlueprintEntity> sites = const []}) => WorldMock.restored(
    buildings: [
      for (final (index, blueprint) in complete.indexed) BuildingEntityMock.completed(blueprint, id: 'building-$index'),
      for (final (index, blueprint) in sites.indexed) BuildingEntityMock.site(blueprint, id: 'site-$index'),
    ],
  );

  test('testWhenListingTheQuestsThenThereAreNineteenElevenOfTheVillageBeforeEightOfTheHero', () {
    // given
    final quests = Quests.all;

    // when
    final lines = quests.map((quest) => quest.line).toList();

    // then
    expect(quests, hasLength(19));
    expect(lines.where((line) => line == QuestLine.village), hasLength(11));
    expect(lines.indexOf(QuestLine.hero), 11);
    expect(lines.skip(11).toSet(), {QuestLine.hero});
  });

  test('testWhenListingTheVillageQuestsThenTheyFollowTheChapterOrderWithTheirTargets', () {
    // given
    final village = Quests.all.where((quest) => quest.line == QuestLine.village);

    // when
    final table = [for (final quest in village) (quest.id, quest.target)];

    // then
    expect(table, [
      (QuestId.gatherWood, 15),
      (QuestId.buildHouse, 1),
      (QuestId.fellTenTrees, 10),
      (QuestId.fellAnOak, 1),
      (QuestId.gatherFortyWood, 40),
      (QuestId.buildTwoHouses, 2),
      (QuestId.seeATreeRegrow, 1),
      (QuestId.gatherTwentyStone, 20),
      (QuestId.buildQuarry, 1),
      (QuestId.buildWorkshop, 1),
      (QuestId.upgradeAxe, 1),
    ]);
  });

  test('testWhenListingTheHeroQuestsThenTheyFollowTheArenaOrderWithTheirTargets', () {
    // given
    final hero = Quests.all.where((quest) => quest.line == QuestLine.hero);

    // when
    final table = [for (final quest in hero) (quest.id, quest.target)];

    // then
    expect(table, [
      (QuestId.buildForge, 1),
      (QuestId.winFirstFight, 1),
      (QuestId.buyFirstWeapon, 1),
      (QuestId.buildArmory, 1),
      (QuestId.buildMageTower, 1),
      (QuestId.learnASkill, 1),
      (QuestId.clearHalfArena, 5),
      (QuestId.becomeChampion, 1),
    ]);
  });

  test('testWhenTheWoodIsCarriedButNotStoredThenTheWoodQuestsDoNotCountIt', () {
    // given
    final world = WorldMock.restored(
      player: PlayerEntityMock.mock.copyWith(inventory: InventoryEntityMock.make(wood: 10)),
    );

    // when
    final measures = (progress(QuestId.gatherWood, world), progress(QuestId.gatherFortyWood, world));

    // then
    expect(measures, (0, 0));
  });

  test('testWhenTheWoodAndStoneAreStoredThenTheGatheringQuestsCountThem', () {
    // given
    final world = WorldMock.restored(stock: StockEntityMock.make(wood: 42, stone: 21));

    // when
    final measures = [
      progress(QuestId.gatherWood, world),
      progress(QuestId.gatherFortyWood, world),
      progress(QuestId.gatherTwentyStone, world),
    ];

    // then
    expect(measures, [42, 42, 21]);
  });

  test('testWhenTreesAreFelledOrRegrownThenTheTreeQuestsReadTheStats', () {
    // given
    final world = WorldMock.restored(stats: StatsEntityMock.afterTenTrees);
    final regrown = WorldMock.restored(stats: StatsEntityMock.afterOneRegrowth);

    // when
    final measures = [
      progress(QuestId.fellTenTrees, world),
      progress(QuestId.fellAnOak, world),
      progress(QuestId.seeATreeRegrow, world),
      progress(QuestId.seeATreeRegrow, regrown),
    ];

    // then
    expect(measures, [10, 1, 0, 1]);
  });

  test('testWhenOnlyPinesWereFelledThenTheOakQuestIsNotDone', () {
    // given
    final world = WorldMock.restored(stats: StatsEntityMock.afterNineTrees);

    // when
    final measures = (progress(QuestId.fellTenTrees, world), progress(QuestId.fellAnOak, world));

    // then
    expect(measures, (9, 0));
  });

  test('testWhenBuildingsAreFinishedThenTheBuildingQuestsCountThemAndSitesDoNot', () {
    // given
    final world = withBuildings(
      [Blueprints.house, Blueprints.quarry, Blueprints.workshop, Blueprints.forge, Blueprints.armory],
      sites: [Blueprints.house, Blueprints.mageTower],
    );

    // when
    final measures = [
      for (final id in [
        QuestId.buildHouse,
        QuestId.buildTwoHouses,
        QuestId.buildQuarry,
        QuestId.buildWorkshop,
        QuestId.buildForge,
        QuestId.buildArmory,
        QuestId.buildMageTower,
      ])
        progress(id, world),
    ];

    // then
    expect(measures, [1, 1, 1, 1, 1, 1, 0]);
    expect(progress(QuestId.buildTwoHouses, withBuildings([Blueprints.house, Blueprints.house])), 2);
  });

  test('testWhenTheAxeIsUpgradedThenTheUpgradeQuestIsDone', () {
    // given
    PlayerEntity holding(int level) => PlayerEntityMock.withAxe.copyWith(
      inventory: InventoryEntityMock.make(tools: {ToolKind.axe}, toolLevels: {ToolKind.axe: level}),
    );

    // when
    final measures = [
      progress(QuestId.upgradeAxe, WorldMock.restored(player: PlayerEntityMock.withAxe)),
      progress(QuestId.upgradeAxe, WorldMock.restored(player: holding(2))),
    ];

    // then
    expect(measures, [0, 1]);
  });

  test('testWhenTheHeroFightsAndLearnsThenTheHeroQuestsReadTheHero', () {
    // given
    final world = WorldMock.restored(hero: HeroEntityMock.championWithEveryQuestDone);

    // when
    final measures = [
      for (final id in [
        QuestId.winFirstFight,
        QuestId.buyFirstWeapon,
        QuestId.learnASkill,
        QuestId.clearHalfArena,
        QuestId.becomeChampion,
      ])
        progress(id, world),
    ];

    // then
    expect(measures, [1, 1, 1, 6, 1]);
    expect(progress(QuestId.becomeChampion, WorldMock.restored(hero: HeroEntityMock.withShortSword)), 0);
    expect(HeroEntityMock.championWithEveryQuestDone.clearedLevels, contains(ArenaLevelId.barbarianChief));
  });
}
