import 'package:injectable/injectable.dart';

import '../../../../domain/entities/geometry/position_entity.dart';
import '../../../datasources/level/local/dbo/point_dbo.dart';

@Injectable()
class PositionMapperDBO {
  PositionEntity toEntity(PointDBO dbo) {
    return PositionEntity(x: dbo.x ?? 0, y: dbo.y ?? 0);
  }
}
