import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/layers/presentation/features/forest/models/tool_item_data.dart';

abstract final class ToolItemDataMock {
  static ToolItemData axe({required bool isOwned}) => ToolItemData(
    tool: ToolKind.axe,
    name: Internationalize.forestTool(tool: ToolKind.axe),
    isOwned: isOwned,
  );

  static ToolItemData of(ToolKind tool, {required bool isOwned}) => ToolItemData(
    tool: tool,
    name: Internationalize.forestTool(tool: tool),
    isOwned: isOwned,
  );

  static ToolItemData get ironAxe => ToolItemData(
    tool: ToolKind.axe,
    name: Internationalize.forestUpgradeName(id: UpgradeId.ironAxe),
    isOwned: true,
  );
}
