import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/learn_skill_result.dart';
import '../../../../core/config/constants/enum/skill_id.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/skills.dart';
import '../../world/extensions/building_rules.dart';

@Injectable()
final class LearnSkillUseCase {
  final GameSessionRepository _sessionRepository;

  const LearnSkillUseCase({required this._sessionRepository});

  LearnSkillResult call({required SkillId id}) {
    final world = _sessionRepository.current().world;
    if (!world.buildings.hasComplete(Skills.building)) return LearnSkillResult.missingBuilding;
    if (world.hero.skills.contains(id)) return LearnSkillResult.alreadyKnown;
    if (!world.spend(Skills.byId(id).cost)) return LearnSkillResult.notEnoughResources;
    world.updateHero((hero) => hero.copyWith(skills: {...hero.skills, id}));
    return LearnSkillResult.ok;
  }
}
