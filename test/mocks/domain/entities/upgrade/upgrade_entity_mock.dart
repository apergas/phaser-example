import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/domain/entities/upgrade/upgrade_entity.dart';

abstract final class UpgradeEntityMock {
  static const UpgradeEntity ironAxe = UpgradeEntity(
    id: UpgradeId.ironAxe,
    tool: ToolKind.axe,
    level: 2,
    cost: {Resource.wood: 15, Resource.stone: 15},
  );

  static const UpgradeEntity ironPickaxe = UpgradeEntity(
    id: UpgradeId.ironPickaxe,
    tool: ToolKind.pickaxe,
    level: 2,
    cost: {Resource.wood: 10, Resource.stone: 20},
  );

  static const UpgradeEntity steelAxe = UpgradeEntity(
    id: UpgradeId.ironAxe,
    tool: ToolKind.axe,
    level: 3,
    cost: {Resource.wood: 15, Resource.stone: 15},
  );
}
