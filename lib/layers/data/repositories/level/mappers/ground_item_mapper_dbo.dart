import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/entities/item/ground_item_entity.dart';
import '../../../datasources/level/local/dbo/item_dbo.dart';

@Injectable()
class GroundItemMapperDBO {
  GroundItemEntity toEntity(ItemDBO dbo) {
    final itemId = dbo.id ?? '';
    return GroundItemEntity(
      id: itemId,
      kind: _kind(itemId, dbo.kind),
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
    );
  }

  ToolKind _kind(String itemId, String? name) {
    for (final kind in ToolKind.values) {
      if (kind.name.toLowerCase() == name?.toLowerCase()) return kind;
    }
    throw UnknownItemKindException(data: '$itemId: "${name ?? ''}"');
  }
}
