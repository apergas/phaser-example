import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/tree_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/utils/kebab_case.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/entities/tree/tree_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/level/local/dbo/tree_dbo.dart';

@Injectable()
class TreeMapperDBO {
  TreeEntity toEntity(TreeDBO dbo, {required int index}) {
    final treeId = dbo.id ?? 'tree-${index + 1}';
    return TreeEntity(
      id: treeId,
      kind: _kind(treeId, dbo.kind),
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      trunkRadius: Rules.treeTrunkRadius,
      woodYield: dbo.wood ?? 0,
      hitsToFell: Rules.hitsToFellTree,
    );
  }

  TreeKind _kind(String treeId, String? name) {
    for (final kind in TreeKind.values) {
      if (kind.name.toKebabCase() == name) return kind;
    }
    throw UnknownTreeKindException(data: '$treeId: "${name ?? ''}"');
  }
}
