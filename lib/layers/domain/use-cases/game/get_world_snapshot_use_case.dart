import 'package:injectable/injectable.dart';

import '../../entities/game/world_snapshot_entity.dart';
import '../../repositories/session/game_session_repository.dart';

@Injectable()
final class GetWorldSnapshotUseCase {
  final GameSessionRepository _sessionRepository;

  const GetWorldSnapshotUseCase({required this._sessionRepository});

  WorldSnapshotEntity call() {
    final world = _sessionRepository.current().world;
    return WorldSnapshotEntity(
      width: world.width,
      height: world.height,
      trees: world.trees,
      items: world.items,
      decorations: world.decorations,
      buildings: world.buildings,
    );
  }
}
