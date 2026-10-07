import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

abstract final class CustomIcons {
  static const String _path = 'lib/core/assets/images/icons';

  static const String wood = '$_path/wood.svg';
  static const String gold = '$_path/gold.svg';
  static const String axe = '$_path/axe.svg';
  static const String arena = '$_path/arena.svg';

  static String resource(Resource resource) => switch (resource) {
    Resource.wood => wood,
    Resource.gold => gold,
  };

  static String tool(ToolKind tool) => switch (tool) {
    ToolKind.axe => axe,
  };
}
