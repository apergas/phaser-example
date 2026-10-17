import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/item/ground_item_entity.dart';
import '../../../datasources/save/local/dbo/save_item_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveGroundItemMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveGroundItemMapperDBO({required this._positionMapperDBO});

  SaveItemDBO toDBO(GroundItemEntity item) {
    return SaveItemDBO(id: item.id, kind: item.kind.name, x: item.position.x, y: item.position.y);
  }

  GroundItemEntity toEntity(SaveItemDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'item without id'));
    final kind =
        ToolKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'item $id: unknown kind "${dbo.kind}"'));
    return GroundItemEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'item $id'),
    );
  }
}
