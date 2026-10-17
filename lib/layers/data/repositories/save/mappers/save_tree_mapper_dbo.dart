import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/tree/tree_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/save/local/dbo/save_tree_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveTreeMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveTreeMapperDBO({required this._positionMapperDBO});

  SaveTreeDBO toDBO(TreeEntity tree) {
    return SaveTreeDBO(
      id: tree.id,
      kind: tree.kind.name,
      x: tree.position.x,
      y: tree.position.y,
      hitsTaken: tree.hitsTaken,
    );
  }

  TreeEntity toEntity(SaveTreeDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'tree without id'));
    final kind =
        TreeKind.values.asNameMap()[dbo.kind] ??
        (throw InvalidSaveException(data: 'tree $id: unknown kind "${dbo.kind}"'));
    final stats =
        Rules.treeKindStats[kind] ?? (throw InvalidSaveException(data: 'tree $id: no stats for ${kind.name}'));
    final hitsTaken = dbo.hitsTaken ?? 0;
    if (hitsTaken < 0 || hitsTaken >= stats.hitsToFell) {
      throw InvalidSaveException(data: 'tree $id: $hitsTaken hits taken of ${stats.hitsToFell}');
    }
    return TreeEntity(
      id: id,
      kind: kind,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'tree $id'),
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: stats.woodYield,
      hitsToFell: stats.hitsToFell,
      hitsTaken: hitsTaken,
    );
  }
}
