import 'package:injectable/injectable.dart';

import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/building/building_entity.dart';
import '../../../../domain/rules/blueprints.dart';
import '../../../datasources/save/local/dbo/save_building_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveBuildingMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveBuildingMapperDBO({required this._positionMapperDBO});

  SaveBuildingDBO toDBO(BuildingEntity building) {
    return SaveBuildingDBO(
      id: building.id,
      blueprint: building.blueprint.id.name,
      x: building.position.x,
      y: building.position.y,
      hitsDone: building.hitsDone,
    );
  }

  BuildingEntity toEntity(SaveBuildingDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'building without id'));
    final blueprintId =
        BlueprintId.values.asNameMap()[dbo.blueprint] ??
        (throw InvalidSaveException(data: 'building $id: unknown blueprint "${dbo.blueprint}"'));
    final blueprint = Blueprints.of(blueprintId);
    final hitsDone = dbo.hitsDone ?? 0;
    if (hitsDone < 0 || hitsDone > blueprint.hitsToBuild) {
      throw InvalidSaveException(data: 'building $id: $hitsDone hits of ${blueprint.hitsToBuild}');
    }
    return BuildingEntity(
      id: id,
      blueprint: blueprint,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'building $id'),
      hitsDone: hitsDone,
    );
  }
}
