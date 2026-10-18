import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/player/player_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../../domain/world/extensions/inventory_rules.dart';
import '../../../datasources/save/local/dbo/save_player_dbo.dart';
import 'save_inventory_mapper_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SavePlayerMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;
  final SaveInventoryMapperDBO _inventoryMapperDBO;

  const SavePlayerMapperDBO({required this._positionMapperDBO, required this._inventoryMapperDBO});

  SavePlayerDBO toDBO(PlayerEntity player) {
    return SavePlayerDBO(
      x: player.position.x,
      y: player.position.y,
      inventory: _inventoryMapperDBO.toDBO(player.inventory),
    );
  }

  PlayerEntity toEntity(SavePlayerDBO? dbo) {
    final player = dbo ?? (throw const InvalidSaveException(data: 'missing player'));
    final inventory = _inventoryMapperDBO.toEntity(player.inventory, owner: 'player');
    if (inventory.load > Rules.carryCapacity) {
      throw InvalidSaveException(data: 'player carries ${inventory.load} of ${Rules.carryCapacity}');
    }
    return PlayerEntity(
      position: _positionMapperDBO.toEntity(x: player.x, y: player.y, owner: 'player'),
      speed: Rules.playerSpeed,
      radius: Rules.playerRadius,
      inventory: inventory,
    );
  }
}
