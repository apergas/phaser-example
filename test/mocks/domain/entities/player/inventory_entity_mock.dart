import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/player/inventory_entity.dart';

abstract final class InventoryEntityMock {
  static const InventoryEntity mock = InventoryEntity();

  static const InventoryEntity withWood = InventoryEntity(resources: {Resource.wood: 6});

  static const InventoryEntity withAxe = InventoryEntity(tools: {ToolKind.axe});

  static const Map<Resource, int> tenWood = {Resource.wood: 10};

  static const Map<Resource, int> zeroWood = {Resource.wood: 0};

  static const Map<Resource, int> negativeWood = {Resource.wood: -1};

  static const Map<Resource, int> sixteenWood = {Resource.wood: 16};

  static const Map<Resource, int> twoWood = {Resource.wood: 2};

  static const Map<Resource, int> fourWood = {Resource.wood: 4};

  static const Map<Resource, int> fiveWood = {Resource.wood: 5};

  static const Map<Resource, int> fifteenWood = {Resource.wood: 15};

  static InventoryEntity make({int wood = 0, Set<ToolKind> tools = const {}}) =>
      InventoryEntity(resources: {if (wood > 0) Resource.wood: wood}, tools: tools);
}
