import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/domain/entities/player/inventory_entity.dart';

abstract final class InventoryEntityMock {
  static const InventoryEntity mock = InventoryEntity();

  static const InventoryEntity withWood = InventoryEntity(resources: {Resource.wood: 6});

  static const InventoryEntity withAxe = InventoryEntity(tools: {ToolKind.axe});

  static const InventoryEntity withIronAxe = InventoryEntity(tools: {ToolKind.axe}, toolLevels: {ToolKind.axe: 2});

  static const InventoryEntity mixedLoad = InventoryEntity(
    resources: {Resource.wood: 6, Resource.stone: 3, Resource.gold: 5, Resource.mana: 2},
    tools: {ToolKind.axe, ToolKind.pickaxe},
    toolLevels: {ToolKind.axe: 2},
  );

  static const InventoryEntity mixedLoadWithoutStone = InventoryEntity(
    resources: {Resource.wood: 6, Resource.gold: 5, Resource.mana: 2},
    tools: {ToolKind.axe, ToolKind.pickaxe},
    toolLevels: {ToolKind.axe: 2},
  );

  static const InventoryEntity mixedLoadUnloaded = InventoryEntity(
    resources: {Resource.gold: 5, Resource.mana: 2},
    tools: {ToolKind.axe, ToolKind.pickaxe},
    toolLevels: {ToolKind.axe: 2},
  );

  static const InventoryEntity fullOfWood = InventoryEntity(resources: {Resource.wood: 10});

  static const InventoryEntity overloaded = InventoryEntity(resources: {Resource.wood: 9, Resource.stone: 4});

  static const InventoryEntity onlyGoldAndMana = InventoryEntity(resources: {Resource.gold: 50, Resource.mana: 20});

  static const Map<Resource, int> stoneOnly = {Resource.stone: 3};

  static const Map<Resource, int> woodAndStone = {Resource.wood: 6, Resource.stone: 3};

  static const Map<Resource, int> tenWood = {Resource.wood: 10};

  static const Map<Resource, int> zeroWood = {Resource.wood: 0};

  static const Map<Resource, int> negativeWood = {Resource.wood: -1};

  static const Map<Resource, int> sixteenWood = {Resource.wood: 16};

  static const Map<Resource, int> twoWood = {Resource.wood: 2};

  static const Map<Resource, int> fourWood = {Resource.wood: 4};

  static const Map<Resource, int> fiveWood = {Resource.wood: 5};

  static const Map<Resource, int> fifteenWood = {Resource.wood: 15};

  static InventoryEntity make({
    int wood = 0,
    int stone = 0,
    int gold = 0,
    int mana = 0,
    Set<ToolKind> tools = const {},
    Map<ToolKind, int> toolLevels = const {},
  }) => InventoryEntity(
    resources: {
      if (wood > 0) Resource.wood: wood,
      if (stone > 0) Resource.stone: stone,
      if (gold > 0) Resource.gold: gold,
      if (mana > 0) Resource.mana: mana,
    },
    tools: tools,
    toolLevels: toolLevels,
  );
}
