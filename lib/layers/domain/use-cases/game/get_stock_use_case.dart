import 'package:injectable/injectable.dart';

import '../../entities/stock/stock_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class GetStockUseCase {
  final GameSessionRepository _sessionRepository;

  const GetStockUseCase({required this._sessionRepository});

  StockEntity call() => _sessionRepository.current().world.stock;
}
