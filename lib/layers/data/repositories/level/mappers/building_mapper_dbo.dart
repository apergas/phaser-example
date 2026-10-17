import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/building/building_entity.dart';
import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/rules/blueprints.dart';
import '../../../datasources/level/local/dbo/building_dbo.dart';

@Injectable()
class BuildingMapperDBO {
  BuildingEntity toEntity(BuildingDBO dbo, {required int index}) {
    final buildingId = dbo.id ?? 'level-building-${index + 1}';
    final blueprintId =
        BlueprintId.values.firstWhereOrNull((id) => id.name == dbo.blueprint) ??
        (throw InvalidLevelException(data: 'unknown blueprint $buildingId: "${dbo.blueprint ?? ''}"'));
    final blueprint = Blueprints.of(blueprintId);
    return BuildingEntity(
      id: buildingId,
      blueprint: blueprint,
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      hitsDone: blueprint.hitsToBuild,
    );
  }
}
