import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/player/inventory_entity.dart';
import '../../../../domain/rules/upgrades.dart';
import '../../../../domain/world/extensions/inventory_rules.dart';
import '../../../datasources/save/local/dbo/save_inventory_dbo.dart';

@Injectable()
class SaveInventoryMapperDBO {
  SaveInventoryDBO toDBO(InventoryEntity inventory) {
    return SaveInventoryDBO(
      tools: [for (final tool in inventory.tools) tool.name],
      toolLevels: {for (final MapEntry(key: tool, value: level) in inventory.toolLevels.entries) tool.name: level},
    );
  }

  InventoryEntity toEntity(SaveInventoryDBO? dbo, {required String owner}) {
    if (dbo == null) return const InventoryEntity();
    var inventory = const InventoryEntity();
    for (final name in dbo.tools ?? const <String>[]) {
      inventory = inventory.addTool(_tool(name, owner: owner));
    }
    for (final MapEntry(key: name, value: level) in (dbo.toolLevels ?? const <String, int>{}).entries) {
      final tool = _tool(name, owner: owner);
      if (level < 1) throw InvalidSaveException(data: '$owner: ${tool.name} level $level');
      inventory = inventory.withToolLevel(tool, min(level, Upgrades.maxLevel(tool)));
    }
    return inventory;
  }

  ToolKind _tool(String name, {required String owner}) {
    return ToolKind.values.asNameMap()[name] ?? (throw InvalidSaveException(data: '$owner: unknown tool "$name"'));
  }
}
