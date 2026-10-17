import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/deposit_result.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class DepositUseCase {
  final GameSessionRepository _sessionRepository;

  const DepositUseCase({required this._sessionRepository});

  DepositResult call({required String buildingId}) => _sessionRepository.current().world.orderDeposit(buildingId);
}
