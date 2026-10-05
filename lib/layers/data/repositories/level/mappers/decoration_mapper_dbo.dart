import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/decoration_kind.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../../core/utils/kebab_case.dart';
import '../../../../domain/entities/decoration/decoration_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../datasources/level/local/dbo/decoration_dbo.dart';

@Injectable()
class DecorationMapperDBO {
  DecorationEntity toEntity(DecorationDBO dbo, {required int index}) {
    final decorationId = dbo.id ?? 'decoration-${index + 1}';
    return DecorationEntity(
      id: decorationId,
      kind: _kind(decorationId, dbo.kind),
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
    );
  }

  DecorationKind _kind(String decorationId, String? name) {
    for (final kind in DecorationKind.values) {
      if (kind.name.toKebabCase() == name) return kind;
    }
    throw UnknownDecorationKindException(data: '$decorationId: "${name ?? ''}"');
  }
}
