import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/learn_skill_result.dart';
import '../../../../core/config/constants/enum/skill_id.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/skills.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/hero_rules.dart';

@Injectable()
final class LearnSkillUseCase {
  final GameSessionRepository _sessionRepository;

  const LearnSkillUseCase({required this._sessionRepository});

  LearnSkillResult call({required SkillId id}) {
    final world = _sessionRepository.current().world;
    if (!world.buildings.hasComplete(Skills.building)) return LearnSkillResult.missingBuilding;
    final skill = Skills.byId(id);
    final level = world.hero.levelOf(id);
    if (level == skill.maxLevel) return LearnSkillResult.maxed;
    if (!world.spend(skill.costOf(level + 1))) return LearnSkillResult.notEnoughResources;
    world.updateHero((hero) => hero.withSkill(id, level: level + 1));
    return level == 0 ? LearnSkillResult.ok : LearnSkillResult.upgraded;
  }
}
