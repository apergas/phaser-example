import '../../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../../core/utils/kebab_case.dart';

abstract final class SpriteNames {
  static const String stump = 'stump';
  static const String sapling = 'sapling';
  static const String rock = 'rock-large';

  static String tree(TreeKind kind) => 'tree-${kind.name.toKebabCase()}';

  static String decoration(DecorationKind kind) => 'decor-${kind.name.toKebabCase()}';

  static String building(BlueprintId id) => switch (id) {
    BlueprintId.house => 'house',
    BlueprintId.forge => 'forge',
    BlueprintId.armory => 'armory',
    BlueprintId.mageTower => 'mage-tower',
    BlueprintId.camp => 'camp',
    BlueprintId.storehouse => 'storehouse',
    BlueprintId.quarry => 'quarry',
    BlueprintId.workshop => 'workshop',
  };

  static String item(ToolKind kind) => switch (kind) {
    ToolKind.axe => 'axe-pickup',
    ToolKind.pickaxe => 'pickaxe-pickup',
  };
}
