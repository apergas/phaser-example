import 'dart:math';

import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../entities/player/inventory_entity.dart';
import '../../rules/rules.dart';

extension InventoryRules on InventoryEntity {
  InventoryEntity addTool(ToolKind tool) => copyWith(tools: {...tools, tool});

  bool hasTool(ToolKind tool) => tools.contains(tool);

  int toolLevel(ToolKind tool) => toolLevels[tool] ?? 1;

  InventoryEntity withToolLevel(ToolKind tool, int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'A ${tool.name} level starts at 1');
    }
    return copyWith(toolLevels: {...toolLevels, tool: level});
  }

  int hitsNeeded(ToolKind tool, int hits) {
    if (toolLevel(tool) == 1) return hits;
    return max(1, (hits * Rules.upgradedHitsPercent + 99) ~/ 100);
  }
}
