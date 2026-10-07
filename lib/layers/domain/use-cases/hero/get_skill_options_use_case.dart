import 'package:injectable/injectable.dart';

import '../../../../core/config/constants/enum/skill_option_state.dart';
import '../../entities/hero/skill_entity.dart';
import '../../entities/hero/skill_option_entity.dart';
import '../../repositories/session/game_session_repository.dart';
import '../../rules/skills.dart';
import '../../world/extensions/building_rules.dart';
import '../../world/extensions/inventory_rules.dart';
import '../../world/world.dart';

@Injectable()
final class GetSkillOptionsUseCase {
  final GameSessionRepository _sessionRepository;

  const GetSkillOptionsUseCase({required this._sessionRepository});

  List<SkillOptionEntity> call() {
    final world = _sessionRepository.current().world;
    return [for (final skill in Skills.all) _option(world, skill)];
  }

  SkillOptionEntity _option(World world, SkillEntity skill) {
    if (world.hero.skills.contains(skill.id)) return SkillOptionEntity(skill: skill, state: SkillOptionState.known);
    final missing = world.funds.missing(skill.cost);
    final SkillOptionState state;
    if (!world.buildings.hasComplete(Skills.building)) {
      state = SkillOptionState.needsBuilding;
    } else if (missing.isNotEmpty) {
      state = SkillOptionState.unaffordable;
    } else {
      state = SkillOptionState.available;
    }
    return SkillOptionEntity(skill: skill, state: state, missing: missing);
  }
}
