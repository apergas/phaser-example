import 'package:farming/layers/domain/entities/stock/stock_entity.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/game/game_session_entity.dart';
import 'package:farming/layers/domain/entities/game/stats_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/hero/hero_entity.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';
import 'package:farming/layers/domain/entities/player/player_entity.dart';
import 'package:farming/layers/domain/quests/quest_log.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../entities/building/building_entity_mock.dart';
import '../entities/decoration/decoration_entity_mock.dart';
import '../entities/item/ground_item_entity_mock.dart';
import '../entities/rock/rock_entity_mock.dart';
import '../entities/tree/stump_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';

abstract final class SaveScenarioMock {
  static const PlayerEntity player = PlayerEntity(
    position: PositionEntity(x: 420, y: 380),
    speed: 110,
    radius: 8,
    inventory: InventoryEntity(
      tools: {ToolKind.axe, ToolKind.pickaxe},
      toolLevels: {ToolKind.axe: 2},
    ),
  );

  static const HeroEntity hero = HeroEntity(
    weaponTier: 2,
    armorTier: 1,
    skillLevels: {SkillId.doubleStrike: 2, SkillId.dodge: 1},
    clearedLevels: {ArenaLevelId.banditRookie, ArenaLevelId.wolf},
    fightsFought: 5,
  );

  static const StatsEntity stats = StatsEntity(
    treesFelled: 4,
    treesFelledByKind: {TreeKind.pine: 3, TreeKind.oak: 1},
    buildingsCompleted: 2,
    treesRegrown: 1,
  );

  static const StockEntity stock = StockEntity(
    resources: {Resource.wood: 30, Resource.gold: 45, Resource.mana: 12, Resource.stone: 9},
  );

  static const StockEntity stockWithTheVersionOneLoad = StockEntity(
    resources: {Resource.wood: 34, Resource.gold: 45, Resource.mana: 12, Resource.stone: 12},
  );

  static const Map<String, int> idCounters = {'building': 3};

  static const Set<QuestId> completedQuests = {QuestId.gatherWood, QuestId.buildHouse, QuestId.buildForge};

  static World everything() => World.restore(
    width: 1600,
    height: 1200,
    player: player,
    trees: [TreeEntityMock.withThreeHitsTaken, TreeEntityMock.neighbour],
    stumps: [
      StumpEntityMock.elsewhereAlmostSapling,
      StumpEntityMock.sapling.copyWith(id: 'tree-9'),
    ],
    rocks: [RockEntityMock.onceHit],
    items: [GroundItemEntityMock.mock],
    decorations: [DecorationEntityMock.mock],
    buildings: [
      BuildingEntityMock.finishedHouse,
      BuildingEntityMock.completed(Blueprints.house, id: 'building-1', position: const PositionEntity(x: 600, y: 300)),
      BuildingEntityMock.site(
        Blueprints.forge,
        id: 'building-3',
        position: const PositionEntity(x: 900, y: 300),
      ).copyWith(hitsDone: 4),
    ],
    hero: hero,
    stats: stats,
    stock: stock,
    idCounters: idCounters,
  );

  static GameSessionEntity session() => GameSessionEntity(
    world: everything(),
    quests: QuestLog(completed: completedQuests),
  );
}
