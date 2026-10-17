import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/decoration/decoration_entity.dart';
import '../../../datasources/save/local/dbo/save_decoration_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveDecorationMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveDecorationMapperDBO({required this._positionMapperDBO});

  SaveDecorationDBO toDBO(DecorationEntity decoration) {
    return SaveDecorationDBO(
      id: decoration.id,
      kind: decoration.kind.name,
      x: decoration.position.x,
      y: decoration.position.y,
    );
  }

  DecorationEntity toEntity(SaveDecorationDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'decoration without id'));
    final kind =
        DecorationKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'decoration $id: unknown kind "${dbo.kind}"'));
    return DecorationEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'decoration $id'),
    );
  }
}
