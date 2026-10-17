import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/player/inventory_entity.dart';
import '../../../../domain/entities/player/player_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../../domain/world/world.dart';
import '../../../datasources/level/local/dbo/level_dbo.dart';
import 'building_mapper_dbo.dart';
import 'decoration_mapper_dbo.dart';
import 'ground_item_mapper_dbo.dart';
import 'position_mapper_dbo.dart';
import 'rock_mapper_dbo.dart';
import 'tree_mapper_dbo.dart';

@Injectable()
class LevelMapperDBO {
  final PositionMapperDBO _positionMapperDBO;
  final TreeMapperDBO _treeMapperDBO;
  final DecorationMapperDBO _decorationMapperDBO;
  final GroundItemMapperDBO _groundItemMapperDBO;
  final RockMapperDBO _rockMapperDBO;
  final BuildingMapperDBO _buildingMapperDBO;

  const LevelMapperDBO({
    required this._positionMapperDBO,
    required this._treeMapperDBO,
    required this._decorationMapperDBO,
    required this._groundItemMapperDBO,
    required this._rockMapperDBO,
    required this._buildingMapperDBO,
  });

  World toEntity(LevelDBO dbo) {
    final width = dbo.width ?? (throw const InvalidLevelException(data: 'missing width'));
    final height = dbo.height ?? (throw const InvalidLevelException(data: 'missing height'));
    final playerStart = dbo.playerStart ?? (throw const InvalidLevelException(data: 'missing player start'));
    final trees = dbo.trees ?? const [];
    final items = dbo.items ?? const [];
    final decorations = dbo.decorations ?? const [];
    final rocks = dbo.rocks ?? const [];
    final buildings = dbo.buildings ?? const [];
    return World(
      width: width,
      height: height,
      player: PlayerEntity(
        position: _positionMapperDBO.toEntity(playerStart),
        speed: Rules.playerSpeed,
        radius: Rules.playerRadius,
        inventory: const InventoryEntity(tools: {ToolKind.axe}),
      ),
      trees: [for (var index = 0; index < trees.length; index++) _treeMapperDBO.toEntity(trees[index], index: index)],
      items: items.map(_groundItemMapperDBO.toEntity).toList(),
      decorations: [
        for (var index = 0; index < decorations.length; index++)
          _decorationMapperDBO.toEntity(decorations[index], index: index),
      ],
      rocks: [for (var index = 0; index < rocks.length; index++) _rockMapperDBO.toEntity(rocks[index], index: index)],
      buildings: [
        for (var index = 0; index < buildings.length; index++)
          _buildingMapperDBO.toEntity(buildings[index], index: index),
      ],
    );
  }
}
