import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/forest/facing.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/layers/domain/entities/building/building_entity.dart';
import 'package:rpg/layers/domain/entities/decoration/decoration_entity.dart';
import 'package:rpg/layers/domain/entities/game/world_snapshot_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/entities/item/ground_item_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';
import 'package:rpg/layers/presentation/features/forest/models/placement_data.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_pose.dart';
import 'package:rpg/layers/presentation/features/forest/models/player_render_data.dart';

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

  static final GroundItemEntity axe = GroundItemEntity(
    id: 'axe',
    kind: ToolKind.axe,
    position: const PositionEntity(x: 60, y: 60),
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

  static final WorldSnapshotEntity world = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: [axe],
    decorations: [grass],
    buildings: const [],
  );

  static final WorldSnapshotEntity worldWithoutFirstTree = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [frontTree],
    items: [axe],
    decorations: [grass],
    buildings: const [],
  );

  static final WorldSnapshotEntity worldWithoutAxe = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: const [],
    decorations: [grass],
    buildings: const [],
  );

  static final WorldSnapshotEntity worldWithHouse = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: [axe],
    decorations: [grass],
    buildings: [house],
  );

  static final WorldSnapshotEntity worldWithHalfBuiltHouse = WorldSnapshotEntity(
    width: 400,
    height: 300,
    trees: [tree, frontTree],
    items: [axe],
    decorations: [grass],
    buildings: [halfBuiltHouse],
  );

  static final PlayerRenderData player = PlayerRenderData(
    position: const PositionEntity(x: 150, y: 150),
    facing: Facing.down,
    pose: const IdlePose(withAxe: false),
  );

  static final PlacementData validPlacement = PlacementData(
    blueprint: BlueprintId.house,
    position: const PositionEntity(x: 300, y: 200),
    isValid: true,
  );

  static final PlacementData invalidPlacement = PlacementData(
    blueprint: BlueprintId.house,
    position: const PositionEntity(x: 100, y: 100),
    isValid: false,
  );

  static final PlacementData forgePlacement = PlacementData(
    blueprint: BlueprintId.forge,
    position: const PositionEntity(x: 300, y: 200),
    isValid: true,
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
    effects: const [TreeFelledEffect(treeId: 'tree-1', fromX: 90)],
  );

  static final ForestData axePickedUp = ForestData(
    world: worldWithoutAxe,
    player: player,
    effects: const [ItemPickedUpEffect(itemId: 'axe')],
  );

  static final ForestData axeGone = ForestData(world: worldWithoutAxe, player: player);

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
}
