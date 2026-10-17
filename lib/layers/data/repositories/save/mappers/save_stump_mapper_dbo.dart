import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/tree/stump_entity.dart';
import '../../../datasources/save/local/dbo/save_stump_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveStumpMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveStumpMapperDBO({required this._positionMapperDBO});

  SaveStumpDBO toDBO(StumpEntity stump) {
    return SaveStumpDBO(
      id: stump.id,
      kind: stump.kind.name,
      x: stump.position.x,
      y: stump.position.y,
      elapsedMs: stump.elapsedMs,
    );
  }

  StumpEntity toEntity(SaveStumpDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'stump without id'));
    final kind =
        TreeKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'stump $id: unknown kind "${dbo.kind}"'));
    final elapsedMs = dbo.elapsedMs ?? 0;
    if (elapsedMs < 0) throw InvalidSaveException(data: 'stump $id: elapsed $elapsedMs ms');
    return StumpEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'stump $id'),
      elapsedMs: elapsedMs,
    );
  }
}
