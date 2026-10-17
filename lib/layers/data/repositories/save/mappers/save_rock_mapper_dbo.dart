import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/rock/rock_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/save/local/dbo/save_rock_dbo.dart';
import 'save_position_mapper_dbo.dart';

@Injectable()
class SaveRockMapperDBO {
  final SavePositionMapperDBO _positionMapperDBO;

  const SaveRockMapperDBO({required this._positionMapperDBO});

  SaveRockDBO toDBO(RockEntity rock) {
    return SaveRockDBO(id: rock.id, x: rock.position.x, y: rock.position.y, hitsTaken: rock.hitsTaken);
  }

  RockEntity toEntity(SaveRockDBO dbo) {
    final id = dbo.id ?? (throw const InvalidSaveException(data: 'rock without id'));
    final hitsTaken = dbo.hitsTaken ?? 0;
    if (hitsTaken < 0 || hitsTaken >= Rules.rockHitsToBreak) {
      throw InvalidSaveException(data: 'rock $id: $hitsTaken hits taken of ${Rules.rockHitsToBreak}');
    }
    return RockEntity(
      id: id,
      position: _positionMapperDBO.toEntity(x: dbo.x, y: dbo.y, owner: 'rock $id'),
      radius: Rules.rockRadius,
      stoneYield: Rules.rockStoneYield,
      hitsToBreak: Rules.rockHitsToBreak,
      hitsTaken: hitsTaken,
    );
  }
}
