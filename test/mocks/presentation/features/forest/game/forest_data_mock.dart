import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/core/config/constants/enum/decoration_kind.dart';
import 'package:farming/core/config/constants/enum/forest/facing.dart';
import 'package:farming/core/config/constants/enum/gear_id.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/building/building_entity.dart';
import 'package:farming/layers/domain/entities/decoration/decoration_entity.dart';
import 'package:farming/layers/domain/entities/game/world_snapshot_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/tree/stump_entity.dart';
import 'package:farming/layers/domain/entities/rock/rock_entity.dart';
import 'package:farming/layers/domain/entities/tree/tree_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:farming/layers/presentation/features/forest/models/forest_effect.dart';
import 'package:farming/layers/presentation/features/forest/models/placement_data.dart';
import 'package:farming/layers/presentation/features/forest/models/player_pose.dart';
import 'package:farming/layers/presentation/features/forest/models/player_render_data.dart';

abstract final class ForestDataMock {
  static final TreeEntity tree = TreeEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: const PositionEntity(x: 100, y: 120),
    trunkRadius: 12,
    woodYield: 5,
    hitsToFell: 5,
  );

  static final TreeEntity frontTree = TreeEntity(
    id: 'tree-2',
    kind: TreeKind.pine,
    position: const PositionEntity(x: 102, y: 122),
    trunkRadius: 12,
    woodYield: 6,
    hitsToFell: 5,
  );

  static final DecorationEntity grass = DecorationEntity(
    id: 'decoration-1',
    kind: DecorationKind.tallGrass,
    position: const PositionEntity(x: 200, y: 200),
  );

  static final BuildingEntity house = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: const PositionEntity(x: 200, y: 180),
    hitsDone: 0,
  );

  static final BuildingEntity halfBuiltHouse = BuildingEntity(
    id: 'building-1',
    blueprint: Blueprints.house,
    position: const PositionEntity(x: 200, y: 180),
    hitsDone: 4,
  );

  static const StumpEntity stump = StumpEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 100, y: 120),
  );

  static const StumpEntity sapling = StumpEntity(
    id: 'tree-1',
    kind: TreeKind.oak,
    position: PositionEntity(x: 100, y: 120),
    elapsedMs: 60000,
  );

  static final RockEntity rock = RockEntity(
    id: 'rock-1',
    position: const PositionEntity(x: 300, y: 250),
    radius: 22,
    stoneYield: 8,
    hitsToBreak: 7,
  );

  static final BuildingEntity loadedHouse = BuildingEntity(
    id: 'house',
    blueprint: Blueprints.house,
    position: const PositionEntity(x: 200, y: 176),
    hitsDone: 8,
  );

  static WorldSnapshotEntity _snapshot({
    List<TreeEntity>? trees,
    List<StumpEntity> stumps = const [],
    List<RockEntity> rocks = const [],
    List<BuildingEntity> buildings = const [],
  }) => WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: trees ?? [tree, frontTree],
    decorations: [grass],
    buildings: buildings,
    stumps: stumps,
    rocks: rocks,
  );

  static final WorldSnapshotEntity world = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    decorations: [grass],
    buildings: const [],
    stumps: const [],
    rocks: const [],
  );

  static final WorldSnapshotEntity worldWithoutFirstTree = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [frontTree],
    decorations: [grass],
    buildings: const [],
    stumps: [stump],
    rocks: const [],
  );

  static final WorldSnapshotEntity worldWithHouse = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    decorations: [grass],
    buildings: [house],
    stumps: const [],
    rocks: const [],
  );

  static final WorldSnapshotEntity worldWithHalfBuiltHouse = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    decorations: [grass],
    buildings: [halfBuiltHouse],
    stumps: const [],
    rocks: const [],
  );

  static final PlayerRenderData player = PlayerRenderData(
    position: const PositionEntity(x: 150, y: 150),
    facing: Facing.down,
    pose: const IdlePose(withAxe: false),
  );

  static final PlacementData validPlacement = PlacementData(
    blueprint: BlueprintId.house,
    position: const PositionEntity(x: 300, y: 200),
    invalidReason: null,
  );

  static final PlacementData invalidPlacement = PlacementData(
    blueprint: BlueprintId.house,
    position: const PositionEntity(x: 100, y: 100),
    invalidReason: ConstructionRejection.blocked,
  );

  static final PlacementData forgePlacement = PlacementData(
    blueprint: BlueprintId.forge,
    position: const PositionEntity(x: 300, y: 200),
    invalidReason: null,
  );

  static final ForestData initial = ForestData(world: world, player: player);

  static final ForestData treeHit = ForestData(
    world: world,
    player: player,
    effects: const [TreeHitEffect(treeId: 'tree-1', fromX: 90)],
  );

  static final ForestData treeFelled = ForestData(
    world: worldWithoutFirstTree,
    player: player,
    effects: const [TreeFelledEffect(treeId: 'tree-1', fromX: 90, wood: 5)],
  );

  static final ForestData housePlaced = ForestData(
    world: worldWithHouse,
    player: player,
    effects: [BuildingPlacedEffect(building: house)],
  );

  static final ForestData houseHammered = ForestData(
    world: worldWithHalfBuiltHouse,
    player: player,
    effects: const [BuildingHammeredEffect(buildingId: 'building-1', progress: 0.5)],
  );

  static final ForestData placing = ForestData(world: world, player: player, placement: validPlacement);

  static final ForestData placingForge = ForestData(world: world, player: player, placement: forgePlacement);

  static final ForestData gearPurchased = ForestData(
    world: world,
    player: player,
    effects: const [GearPurchasedEffect(gear: GearId.shortSword)],
  );

  static final ForestData skillLearned = ForestData(
    world: world,
    player: player,
    effects: const [SkillLearnedEffect(skill: SkillId.doubleStrike)],
  );

  static final ForestData withStump = ForestData(
    world: _snapshot(trees: [frontTree], stumps: [stump]),
    player: player,
  );

  static final ForestData stumpSprouted = ForestData(
    world: _snapshot(trees: [frontTree], stumps: [sapling]),
    player: player,
    effects: const [TreeSproutedEffect(stumpId: 'tree-1')],
  );

  static final ForestData stumpGone = ForestData(
    world: _snapshot(trees: [frontTree]),
    player: player,
  );

  static final ForestData treeRegrown = ForestData(
    world: _snapshot(trees: [frontTree, tree]),
    player: player,
    effects: const [TreeRegrownEffect(treeId: 'tree-1')],
  );

  static final ForestData withRock = ForestData(
    world: _snapshot(rocks: [rock]),
    player: player,
  );

  static final ForestData rockBroken = ForestData(
    world: _snapshot(),
    player: player,
    effects: const [RockBrokenEffect(rockId: 'rock-1', stone: 8)],
  );

  static final ForestData rockHit = ForestData(
    world: _snapshot(rocks: [rock]),
    player: player,
    effects: const [RockHitEffect(rockId: 'rock-1', fromX: 270)],
  );

  static final ForestData loadedWithAHouse = ForestData(
    world: _snapshot(buildings: [loadedHouse]),
    player: player,
  );
}
