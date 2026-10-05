import 'package:injectable/injectable.dart';

import '../../../../domain/entities/game/game_session_entity.dart';
import '../source/game_session_local_datasource.dart';

@LazySingleton(as: GameSessionLocalDatasource)
class GameSessionLocalDatasourceImpl implements GameSessionLocalDatasource {
  GameSessionEntity? _session;

  @override
  GameSessionEntity? get() => _session;

  @override
  void set(GameSessionEntity session) {
    _session = session;
  }
}
