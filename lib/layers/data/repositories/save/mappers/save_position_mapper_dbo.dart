import 'package:injectable/injectable.dart';

import '../../../../../core/error-handling/exceptions/app_exceptions.dart';
import '../../../../domain/entities/geometry/position_entity.dart';

@Injectable()
class SavePositionMapperDBO {
  PositionEntity toEntity({required double? x, required double? y, required String owner}) {
    return PositionEntity(
      x: x ?? (throw InvalidSaveException(data: '$owner without x')),
      y: y ?? (throw InvalidSaveException(data: '$owner without y')),
    );
  }
}
