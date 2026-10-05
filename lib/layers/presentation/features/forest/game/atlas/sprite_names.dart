import '../../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../../core/utils/kebab_case.dart';

abstract final class SpriteNames {
  static const String house = 'house';
  static const String stump = 'stump';
  static const String axePickup = 'axe-pickup';

  static String tree(TreeKind kind) => 'tree-${kind.name.toKebabCase()}';

  static String decoration(DecorationKind kind) => 'decor-${kind.name.toKebabCase()}';
}
