import 'package:injectable/injectable.dart';

import '../../entities/hero/hero_status_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../world/extensions/arena_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class GetHeroStatusUseCase {
  final GameSessionRepository _sessionRepository;

  const GetHeroStatusUseCase({required this._sessionRepository});

  HeroStatusEntity call() {
    final hero = _sessionRepository.current().world.hero;
    return HeroStatusEntity(hero: hero, stats: hero.stats, power: hero.power, isChampion: hero.isChampion);
  }
}
