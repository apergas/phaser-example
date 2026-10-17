import 'package:injectable/injectable.dart';

import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../../domain/entities/rock/rock_entity.dart';
import '../../../../domain/rules/rules.dart';
import '../../../datasources/level/local/dbo/rock_dbo.dart';

@Injectable()
class RockMapperDBO {
  RockEntity toEntity(RockDBO dbo, {required int index}) {
    return RockEntity(
      id: dbo.id ?? 'rock-${index + 1}',
      position: PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0),
      radius: Rules.rockRadius,
      stoneYield: Rules.rockStoneYield,
      hitsToBreak: Rules.rockHitsToBreak,
    );
  }
}
